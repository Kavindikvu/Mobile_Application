import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Provides a shared instance of [GoogleSignIn] so that sign-in and sign-out
/// calls operate on the same underlying client configuration.
/// 
/// **Important Configuration Notes:**
/// - serverClientId: Web client ID from google-services.json (client_type: 3)
/// - This ensures the OAuth consent screen uses the correct app branding
/// - For Android, the serverClientId is optional but recommended for ID token access
/// - To fix double icon issue: Update OAuth consent screen icon in Google Cloud Console
///   Go to: https://console.cloud.google.com/apis/credentials/consent?project=skillora-family-app
///   Upload assets/app_icon/skillora_icon.png to the App logo field
/// 
/// **Project Details:**
/// - Project ID: skillora-family-app
/// - Project Number: 848298920340
/// - OAuth Consent Screen: https://console.cloud.google.com/apis/credentials/consent?project=skillora-family-app
/// 
/// **Note:** serverClientId will be updated once the web OAuth client (client_type: 3) is available
/// in the google-services.json file after proper Firebase configuration.
final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn(
    // Web client ID from google-services.json (client_type: 3)
    // This ensures the OAuth consent screen uses the correct app branding
    serverClientId: '848298920340-kqueausp55ksmmo22j70v4v9um2mvoqv.apps.googleusercontent.com',
    scopes: const <String>[
      'email',
    ],
    // Additional configuration for better UX
    // hostedDomain: null, // Uncomment if restricting to specific domain
    // forceCodeForRefreshToken: false, // Default behavior
  );
});


