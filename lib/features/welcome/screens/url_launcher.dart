import 'package:url_launcher/url_launcher.dart';

/// Helper class for launching external URLs
class UrlLauncher {
  /// Launch privacy policy URL
  static Future<void> launchPrivacyPolicy() async {
    // Replace with your actual privacy policy URL
    final uri = Uri.parse('https://chatmeal.app/privacy-policy');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Launch terms of service URL
  static Future<void> launchTermsOfService() async {
    // Replace with your actual terms of service URL
    final uri = Uri.parse('https://chatmeal.app/terms-of-service');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// Export functions for easier import
void launchPrivacyPolicy() => UrlLauncher.launchPrivacyPolicy();
void launchTermsOfService() => UrlLauncher.launchTermsOfService();
