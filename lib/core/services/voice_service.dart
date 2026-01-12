import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'openai_service.dart';

/// Service to handle voice interactions using ONLY OpenAI services
/// - OpenAI Whisper API for speech-to-text (ChatGPT's speech recognition)
/// - OpenAI TTS API for text-to-speech (ChatGPT's voice)
class VoiceService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final OpenAIService _openAIService = OpenAIService();
  
  bool _isListening = false;
  bool _isInitialized = false;
  bool _isSpeaking = false;
  File? _currentTempFile; // Track current temp file for cleanup
  String? _currentRecordingPath; // Track current recording file
  
  // Callbacks
  Function(String)? onResult;
  Function(String)? onError;
  VoidCallback? onListeningStarted;
  VoidCallback? onListeningStopped;
  VoidCallback? onSpeakingStarted;
  VoidCallback? onSpeakingCompleted;
  
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  
  /// Initialize the voice service
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      // Check microphone permission
      if (await _audioRecorder.hasPermission()) {
        debugPrint('Voice Service: Microphone permission granted');
      } else {
        debugPrint('Voice Service: Microphone permission denied');
        return false;
      }
      
      // Initialize OpenAI service
      await _openAIService.initialize();
      
      // Setup audio player listeners
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _isSpeaking = false;
          onSpeakingCompleted?.call();
          _cleanupTempFile();
        } else if (state.processingState == ProcessingState.ready && state.playing) {
          if (!_isSpeaking) {
            _isSpeaking = true;
            onSpeakingStarted?.call();
          }
        }
      });
      
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Voice service initialization error: $e');
      return false;
    }
  }
  
  /// Start listening for speech using OpenAI Whisper
  Future<void> startListening() async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        onError?.call('Voice service not available');
        return;
      }
    }
    
    // Check if OpenAI API key is available
    if (!_openAIService.hasApiKey) {
      onError?.call('OpenAI API key not set');
      return;
    }
    
    if (_isListening) return;
    
    try {
      _isListening = true;
      onListeningStarted?.call();
      
      // Get temporary directory for recording
      final tempDir = await getTemporaryDirectory();
      _currentRecordingPath = '${tempDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
      
      debugPrint('Voice Service: Starting recording to $_currentRecordingPath');
      
      // Start recording
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );
      
      debugPrint('Voice Service: Recording started');
    } catch (e) {
      debugPrint('Error starting recording: $e');
      _isListening = false;
      onError?.call('Failed to start recording');
      onListeningStopped?.call();
    }
  }
  
  /// Stop listening and transcribe using OpenAI Whisper
  Future<void> stopListening() async {
    if (!_isListening) return;
    
    try {
      // Stop recording
      final path = await _audioRecorder.stop();
      _isListening = false;
      onListeningStopped?.call();
      
      if (path == null || path.isEmpty) {
        debugPrint('Voice Service: No recording path returned');
        return;
      }
      
      debugPrint('Voice Service: Recording stopped, transcribing with Whisper...');
      
      // Read audio file
      final audioFile = File(path);
      if (!await audioFile.exists()) {
        debugPrint('Voice Service: Recording file does not exist');
        return;
      }
      
      final audioBytes = await audioFile.readAsBytes();
      debugPrint('Voice Service: Audio file size: ${audioBytes.length} bytes');
      
      // Transcribe using OpenAI Whisper API
      final transcription = await _openAIService.transcribeAudio(
        audioBytes: audioBytes,
        language: 'en', // English
      );
      
      // Clean up recording file
      try {
        if (await audioFile.exists()) {
          await audioFile.delete();
          debugPrint('Voice Service: Recording file deleted');
        }
      } catch (e) {
        debugPrint('Error deleting recording file: $e');
      }
      
      if (transcription != null && transcription.isNotEmpty) {
        debugPrint('Voice Service: Transcription: $transcription');
        onResult?.call(transcription);
      } else {
        debugPrint('Voice Service: Transcription failed or empty');
        onError?.call('Could not transcribe audio');
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      _isListening = false;
      onError?.call('Failed to process recording');
      onListeningStopped?.call();
    }
  }
  
  /// Cancel listening
  Future<void> cancelListening() async {
    if (!_isListening) return;
    
    try {
      await _audioRecorder.stop();
      _isListening = false;
      onListeningStopped?.call();
      
      // Clean up recording file
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
        _currentRecordingPath = null;
      }
    } catch (e) {
      debugPrint('Error canceling recording: $e');
    }
  }
  
  /// Speak text using OpenAI TTS API
  Future<void> speak(String text) async {
    if (text.isEmpty) {
      debugPrint('TTS: Empty text, skipping');
      return;
    }
    
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        debugPrint('TTS not initialized');
        return;
      }
    }
    
    // Check if OpenAI API key is available
    if (!_openAIService.hasApiKey) {
      debugPrint('TTS: OpenAI API key not set');
      return;
    }
    
    if (_isSpeaking) {
      await stopSpeaking();
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    try {
      debugPrint('TTS: Generating speech for: $text');
      
      // Generate speech using OpenAI TTS
      final audioBytes = await _openAIService.generateSpeech(text: text);
      
      if (audioBytes == null || audioBytes.isEmpty) {
        debugPrint('TTS: Failed to generate audio');
        _isSpeaking = false;
        return;
      }
      
      debugPrint('TTS: Audio generated, ${audioBytes.length} bytes');
      
      // Clean up previous temp file if exists
      _cleanupTempFile();
      
      // Create a temporary file to store the audio
      final tempDir = await getTemporaryDirectory();
      _currentTempFile = File('${tempDir.path}/tts_${DateTime.now().millisecondsSinceEpoch}.mp3');
      await _currentTempFile!.writeAsBytes(audioBytes);
      
      // Play the audio
      await _audioPlayer.setFilePath(_currentTempFile!.path);
      await _audioPlayer.play();
      
    } catch (e) {
      debugPrint('Error speaking: $e');
      _isSpeaking = false;
    }
  }
  
  /// Stop speaking
  Future<void> stopSpeaking() async {
    if (!_isSpeaking) return;
    
    try {
      await _audioPlayer.stop();
      _isSpeaking = false;
    } catch (e) {
      debugPrint('Error stopping TTS: $e');
    }
  }
  
  /// Pause speaking
  Future<void> pauseSpeaking() async {
    if (!_isSpeaking) return;
    
    try {
      await _audioPlayer.pause();
    } catch (e) {
      debugPrint('Error pausing TTS: $e');
    }
  }
  
  /// Clean up temporary audio file
  void _cleanupTempFile() {
    if (_currentTempFile != null) {
      Future.delayed(const Duration(seconds: 1), () {
        try {
          if (_currentTempFile!.existsSync()) {
            _currentTempFile!.deleteSync();
            debugPrint('TTS: Temp file deleted');
          }
        } catch (e) {
          debugPrint('Error deleting temp file: $e');
        } finally {
          _currentTempFile = null;
        }
      });
    }
  }
  
  /// Dispose resources
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _cleanupTempFile();
    
    // Clean up recording file if exists
    if (_currentRecordingPath != null) {
      final file = File(_currentRecordingPath!);
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
  }
}
