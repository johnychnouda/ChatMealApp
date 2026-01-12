# App Icon Setup

Place your ChatMeal logo file here as `app_icon.png`.

## Requirements:
- **Format**: PNG with transparency (recommended)
- **Size**: At least 1024x1024 pixels (larger is better for quality)
- **Background**: Transparent background (no background color)
- **Filename**: `app_icon.png`

## After adding the logo:

Run the following command to generate all app icon sizes for iOS and Android:

```bash
flutter pub run flutter_launcher_icons
```

This will automatically generate all required icon sizes for both platforms.
