# Complete OpenAI Flow: From App Launch to User Interaction

This document explains in detail how OpenAI (ChatGPT) works in the ChatMeal app, step by step.

---

## 🚀 **PHASE 1: App Launch & Initialization**

### Step 1: User Opens the App
- App navigates to `HomeScreen` after authentication/onboarding

### Step 2: Service Initialization (in `initState()`)

#### A. VoiceService Initialization
```dart
_voiceService = VoiceService();
_voiceService.initialize()
```

**What happens:**
1. **Microphone Permission Check**
   - Checks if app has permission to record audio
   - Uses `AudioRecorder.hasPermission()` from `record` package
   - If denied → returns `false`, voice features won't work

2. **OpenAI Service Initialization**
   - Calls `_openAIService.initialize()`
   - Loads API key from `SharedPreferences` (local storage)
   - Returns `true` if API key exists, `false` otherwise

3. **Audio Player Setup**
   - Initializes `just_audio` player for TTS playback
   - Sets up listeners for playback state (started, completed)

**Result:** VoiceService is ready to record audio and play TTS

---

#### B. OpenAI Service Initialization
```dart
_openAIService = OpenAIService();
_openAIService.initialize()
```

**What happens:**
1. **Load API Key**
   - Reads from `SharedPreferences` using key: `'openai_api_key'`
   - Stores in memory: `_apiKey` variable

2. **Check API Key Status**
   - If no API key found → Shows dialog to user
   - If API key exists → Service is ready

**Result:** OpenAI service is ready to make API calls

---

### Step 3: Initial Greeting (First OpenAI TTS Call)

**Timing:** 500ms after app loads

```dart
_voiceService.speak("Welcome to ChatMeal! What would you like to do today?");
```

**What happens internally:**

1. **VoiceService.speak() is called**
   - Checks if OpenAI API key is set
   - If no key → logs error, returns (no voice output)

2. **OpenAI TTS API Call** (if key exists)
   ```
   POST https://api.openai.com/v1/audio/speech
   Headers:
     - Authorization: Bearer {API_KEY}
     - Content-Type: application/json
   Body:
     {
       "model": "tts-1",
       "input": "Welcome to ChatMeal! What would you like to do today?",
       "voice": "nova",
       "response_format": "mp3",
       "speed": 1.0
     }
   ```

3. **Response Handling**
   - **Success (200):** Returns MP3 audio bytes
   - **Error (401):** Invalid API key
   - **Error (429):** Rate limit or insufficient quota
   - **Error (other):** Network/API error

4. **Audio Playback**
   - Saves MP3 bytes to temporary file: `/tmp/tts_{timestamp}.mp3`
   - Uses `just_audio` to play the file
   - When playback completes → deletes temp file

**User Experience:**
- User hears: "Welcome to ChatMeal! What would you like to do today?"
- Voice sounds like ChatGPT (OpenAI's "nova" voice)

---

## 🎤 **PHASE 2: User Speaks (Voice Input)**

### Step 1: User Taps Microphone Button

```dart
_voiceService.startListening()
```

**What happens:**

1. **Permission Check**
   - Verifies microphone permission
   - Verifies OpenAI API key is set
   - If either fails → shows error, returns

2. **Start Audio Recording**
   - Creates temporary file: `/tmp/recording_{timestamp}.m4a`
   - Starts recording using `AudioRecorder`:
     - Format: AAC-LC
     - Bitrate: 128 kbps
     - Sample rate: 44.1 kHz
   - Sets `_isListening = true`
   - Triggers `onListeningStarted` callback → UI shows "listening" indicator

**User Experience:**
- Microphone button shows "listening" animation
- App is recording audio

---

### Step 2: User Stops Recording (Taps button again or auto-stop)

```dart
_voiceService.stopListening()
```

**What happens:**

1. **Stop Recording**
   - Calls `_audioRecorder.stop()`
   - Gets path to recorded audio file
   - Sets `_isListening = false`
   - Triggers `onListeningStopped` callback

2. **Read Audio File**
   - Reads the `.m4a` file as bytes
   - Gets file size (e.g., 50KB for 3 seconds of speech)

3. **OpenAI Whisper API Call** (Speech-to-Text)
   ```
   POST https://api.openai.com/v1/audio/transcriptions
   Headers:
     - Authorization: Bearer {API_KEY}
   Body (multipart/form-data):
     - file: {audio_bytes} (audio.m4a)
     - model: "whisper-1"
     - language: "en"
   ```

4. **Response Handling**
   - **Success (200):** Returns JSON:
     ```json
     {
       "text": "I want to order pizza"
     }
     ```
   - **Error (401):** Invalid API key
   - **Error (429):** Rate limit or insufficient quota
   - **Error (other):** Network/API error

5. **Cleanup**
   - Deletes temporary recording file
   - If transcription successful → calls `onResult` callback with text
   - If transcription failed → calls `onError` callback

**User Experience:**
- Recording stops
- App shows "processing..." indicator
- After 1-3 seconds, text appears in chat: "I want to order pizza"

---

## 🧠 **PHASE 3: ChatGPT Processing (Understanding & Response)**

### Step 1: Text Sent to ChatGPT

```dart
_handleVoiceInput("I want to order pizza")
```

**What happens:**

1. **Add User Message to Chat UI**
   - Displays: "I want to order pizza" (user message bubble)

2. **Build Full Context**
   ```dart
   String context = _buildFullContext();
   ```
   
   **Context includes:**
   - All restaurant data (names, cuisines, ratings, delivery times)
   - All menu items with prices
   - Current app state (viewing menu? browsing restaurants?)
   - Example context:
     ```
     FULL RESTAURANT DATABASE:
     Total restaurants: 8
     
     Pizza (2 restaurants):
     - Pizza Palace (Italian, Rating: 4.8, Delivery: 25-35 min)
       Menu: Margherita Pizza ($12.99), Pepperoni Pizza ($14.99), ...
     - Bella Italia (Italian, Rating: 4.9, Delivery: 30-40 min)
       Menu: Spaghetti Carbonara ($13.99), ...
     
     CURRENT STATE: User is in main chat view.
     ```

3. **OpenAI Chat API Call** (GPT-3.5-turbo)
   ```
   POST https://api.openai.com/v1/chat/completions
   Headers:
     - Authorization: Bearer {API_KEY}
     - Content-Type: application/json
   Body:
     {
       "model": "gpt-3.5-turbo",
       "messages": [
         {
           "role": "system",
           "content": "You are ChatMeal, a powerful AI assistant... [full system message with capabilities]"
         },
         {
           "role": "system",
           "content": "Current context: [full restaurant database and state]"
         },
         {
           "role": "user",
           "content": "I want to order pizza"
         }
       ],
       "temperature": 0.7,
       "max_tokens": 300
     }
   ```

4. **System Message** (tells ChatGPT how to behave):
   ```
   You are ChatMeal, a powerful AI assistant with full access to the food ordering app.
   You can search, filter, and access ALL restaurant data...
   
   YOUR CAPABILITIES:
   1. SEARCH & FILTER RESTAURANTS
   2. ACCESS RESTAURANT DATA
   3. PERFORM ACTIONS
   4. RECOMMENDATIONS
   
   When you want to perform an action, include it in your response naturally.
   ```

5. **Response Handling**
   - **Success (200):** Returns JSON:
     ```json
     {
       "choices": [{
         "message": {
           "content": "I'd be happy to help you order pizza! Let me show you the pizza restaurants available..."
         }
       }]
     }
     ```
   - **Error (401):** Invalid API key → Returns user-friendly message
   - **Error (429):** Insufficient quota → Returns: "Your OpenAI account needs credits..."
   - **Error (other):** Network error → Returns error message

**User Experience:**
- Shows "AI is thinking..." indicator
- After 2-5 seconds, ChatGPT response appears in chat

---

### Step 2: Process ChatGPT Response

```dart
_processAIResponse(aiResponse, userInput)
```

**What happens:**

1. **Parse Response for Actions**
   - Checks if response contains keywords like:
     - "show restaurants", "browse" → Triggers showing restaurant list
     - Restaurant names → Triggers selecting that restaurant
     - Cuisine types → Triggers filtering by category
     - "best rated", "top rated" → Triggers rating filter
     - Menu items → Triggers search by menu item

2. **Execute Actions**
   - Updates UI state (shows restaurants, selects restaurant, filters, etc.)
   - Example: If ChatGPT says "Let me show you Pizza Palace"
     → App automatically opens Pizza Palace menu

3. **Update Conversation History**
   - Adds user message and AI response to `_conversationHistory`
   - Keeps last 10 messages for context in future conversations
   - This allows ChatGPT to remember what was said earlier

**User Experience:**
- ChatGPT response appears: "I'd be happy to help you order pizza! Let me show you the pizza restaurants..."
- App automatically shows pizza restaurants (if ChatGPT mentioned showing them)

---

## 🔊 **PHASE 4: AI Speaks Response (TTS)**

### Step 1: Convert Text to Speech

```dart
_voiceService.speak(aiResponse)
```

**What happens:**

1. **OpenAI TTS API Call** (same as initial greeting)
   ```
   POST https://api.openai.com/v1/audio/speech
   Headers:
     - Authorization: Bearer {API_KEY}
     - Content-Type: application/json
   Body:
     {
       "model": "tts-1",
       "input": "I'd be happy to help you order pizza! Let me show you the pizza restaurants available...",
       "voice": "nova",
       "response_format": "mp3",
       "speed": 1.0
     }
   ```

2. **Response Handling**
   - **Success:** Returns MP3 audio bytes
   - **Error:** Logs error, no voice output

3. **Audio Playback**
   - Saves MP3 to temp file
   - Plays using `just_audio`
   - Deletes temp file after playback

**User Experience:**
- User hears ChatGPT's voice saying the response
- Voice sounds natural and conversational (OpenAI's "nova" voice)

---

## 🔄 **PHASE 5: Continuous Conversation**

### After AI Finishes Speaking

**Optional Auto-Listen:**
- If `_autoListenAfterSpeaking` is enabled
- After TTS completes → automatically starts listening again
- User can speak immediately without tapping microphone

**Conversation Flow:**
1. User speaks → Whisper transcribes
2. Text sent to ChatGPT with full context + conversation history
3. ChatGPT responds (knows previous messages)
4. Response spoken via TTS
5. (Optional) Auto-listen for next input
6. Repeat...

---

## 📊 **Complete Flow Diagram**

```
┌─────────────────────────────────────────────────────────────┐
│                    USER OPENS APP                            │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  INITIALIZATION                                              │
│  • VoiceService.initialize()                                 │
│    - Check microphone permission                             │
│    - Load OpenAI API key                                     │
│  • OpenAIService.initialize()                                │
│    - Load API key from storage                               │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  INITIAL GREETING (OpenAI TTS)                              │
│  • speak("Welcome to ChatMeal!...")                         │
│  • OpenAI TTS API → MP3 audio                               │
│  • Play audio → User hears greeting                         │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  USER TAPS MICROPHONE                                        │
│  • startListening()                                         │
│  • Record audio to .m4a file                                │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  USER STOPS RECORDING                                        │
│  • stopListening()                                           │
│  • Read audio file bytes                                     │
│  • OpenAI Whisper API → Transcribe audio                     │
│  • Returns: "I want to order pizza"                         │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  PROCESS USER INPUT                                          │
│  • Build full context (restaurants, menus, state)           │
│  • OpenAI Chat API (GPT-3.5-turbo)                          │
│    - System message (capabilities)                           │
│    - Context (restaurant data)                              │
│    - User message                                            │
│    - Conversation history                                    │
│  • Returns: "I'd be happy to help..."                        │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  PROCESS AI RESPONSE                                         │
│  • Parse for actions (show restaurants, select, filter)     │
│  • Execute actions (update UI)                              │
│  • Update conversation history                               │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  AI SPEAKS RESPONSE (OpenAI TTS)                            │
│  • speak(aiResponse)                                         │
│  • OpenAI TTS API → MP3 audio                              │
│  • Play audio → User hears response                          │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  (OPTIONAL) AUTO-LISTEN                                      │
│  • After TTS completes → startListening()                   │
│  • Ready for next user input                                 │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔑 **Key Points**

### 1. **Three OpenAI APIs Used:**
   - **Whisper API:** Speech-to-text (transcribes voice to text)
   - **Chat Completions API (GPT-3.5-turbo):** Conversations (understands and responds)
   - **TTS API:** Text-to-speech (converts text to voice)

### 2. **Full Context Provided:**
   - ChatGPT receives ALL restaurant data
   - ChatGPT knows current app state
   - ChatGPT remembers conversation history
   - This makes ChatGPT very intelligent about the app

### 3. **Action Extraction:**
   - ChatGPT's responses are parsed for keywords
   - App automatically performs actions (show restaurants, select, filter)
   - Makes the app feel "smart" and responsive

### 4. **Error Handling:**
   - Invalid API key → User-friendly message
   - Insufficient quota → Tells user to add credits
   - Network errors → Graceful fallback
   - All errors are spoken to user via TTS

### 5. **No Device Services:**
   - Everything uses OpenAI APIs
   - No device speech recognition
   - No device TTS
   - 100% ChatGPT-powered

---

## 💰 **API Costs (Approximate)**

- **Whisper API:** ~$0.006 per minute of audio
- **GPT-3.5-turbo:** ~$0.0015 per 1K tokens (very cheap)
- **TTS API:** ~$0.015 per 1K characters

**Example conversation:**
- 10 seconds of speech → Whisper: ~$0.001
- ChatGPT response (100 tokens) → ~$0.00015
- TTS response (200 characters) → ~$0.003
- **Total per interaction: ~$0.004** (less than half a cent!)

---

## 🎯 **Summary**

The app is **fully controlled by ChatGPT**:
1. **Voice Input** → OpenAI Whisper (transcribes)
2. **Understanding** → GPT-3.5-turbo (ChatGPT brain)
3. **Voice Output** → OpenAI TTS (speaks)

Everything flows through OpenAI APIs, making it a true ChatGPT-powered food ordering experience!
