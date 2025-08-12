# Google and Apple Sign-In Setup Guide

This guide explains how to complete the setup for Google and Apple Sign-In functionality that has been implemented in the Task Manager app.

## ✅ What's Already Implemented

### Code Implementation

- ✅ Added Google Sign-In and Apple Sign-In dependencies to `pubspec.yaml`
- ✅ Implemented `signInWithGoogle()` method in `AuthController`
- ✅ Implemented `signInWithApple()` method in `AuthController`
- ✅ Updated login screen buttons to use the new authentication methods
- ✅ Added proper error handling and user feedback
- ✅ Integrated with existing user management system

### Features

- ✅ New users get default "Reporter" role
- ✅ Existing users maintain their current roles and data
- ✅ Proper FCM token handling for notifications
- ✅ Profile completion flow integration
- ✅ Presence service integration

## 🔧 Required Configuration Steps

### 1. Google Sign-In Setup

#### Firebase Console Configuration

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Authentication** > **Sign-in method**
4. Enable **Google** sign-in provider
5. Add your app's SHA-1 fingerprint:

   ```bash
   # Get debug SHA-1
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   
   # Get release SHA-1 (when you have a release keystore)
   keytool -list -v -keystore /path/to/your/release.keystore -alias your-alias
   ```

#### iOS Configuration

1. Download `GoogleService-Info.plist` from Firebase Console
2. Add it to `ios/Runner/` directory in Xcode
3. Add URL scheme to `ios/Runner/Info.plist`:

   ```xml
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleURLName</key>
           <string>REVERSED_CLIENT_ID</string>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>YOUR_REVERSED_CLIENT_ID</string>
           </array>
       </dict>
   </array>
   ```

   Replace `YOUR_REVERSED_CLIENT_ID` with the value from `GoogleService-Info.plist`

#### Android Configuration

1. Download `google-services.json` from Firebase Console
2. Place it in `android/app/` directory
3. The necessary Gradle configurations should already be in place

### 2. Apple Sign-In Setup

#### Apple Developer Account

1. Go to [Apple Developer Console](https://developer.apple.com/account/)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Select your App ID
4. Enable **Sign In with Apple** capability
5. Configure your app's bundle identifier

#### Firebase Console

1. In Firebase Console, go to **Authentication** > **Sign-in method**
2. Enable **Apple** sign-in provider
3. Add your Apple Team ID and Bundle ID
4. Upload your Apple Sign-In key (if using custom configuration)

<!-- #### iOS Configuration -->

Apple Sign-In capability should be added to your iOS project:

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select your target
3. Go to **Signing & Capabilities**
4. Add **Sign In with Apple** capability

## 🧪 Testing

### Google Sign-In Testing

1. Ensure you're using a device/simulator with Google Play Services
2. Test with different Google accounts
3. Verify new user creation and existing user login

### Apple Sign-In Testing

1. Test on physical iOS device (required for Apple Sign-In)
2. Use different Apple IDs
3. Test both new account creation and existing account login

## 🔍 Troubleshooting

### Common Google Sign-In Issues

- **"Sign in failed"**: Check SHA-1 fingerprint configuration
- **"Network error"**: Verify `google-services.json` is properly placed
- **"Invalid client"**: Ensure bundle ID matches Firebase configuration

### Common Apple Sign-In Issues

- **"Not available"**: Apple Sign-In requires iOS 13+ and physical device for testing
- **"Authorization failed"**: Check Apple Developer account configuration
- **"Invalid configuration"**: Verify bundle ID and Team ID in Firebase

## 📱 User Experience

### New Users

1. Tap Google/Apple sign-in button
2. Complete OAuth flow
3. Automatically assigned "Reporter" role
4. Redirected to profile completion screen
5. Can update role and other details

### Existing Users

1. Tap Google/Apple sign-in button
2. Complete OAuth flow
3. Automatically logged in with existing role and data
4. Redirected to appropriate dashboard based on role

## 🔐 Security Features

- **Nonce validation** for Apple Sign-In (prevents replay attacks)
- **Secure token handling** for both providers
- **Proper error handling** to prevent information leakage
- **FCM token management** for secure notifications

## 📋 Next Steps

1. Complete Firebase and Apple Developer configuration
2. Test on physical devices
3. Update app store listings to mention social sign-in
4. Consider adding additional OAuth providers if needed
5. Monitor authentication analytics in Firebase Console

---

**Note**: The code implementation is complete and ready to use. You only need to complete the platform-specific configuration steps above to enable the functionality.
