# Email Link Authentication Setup Guide

This guide explains how to configure Firebase Console for email link authentication in your app.

## Firebase Console Configuration

### 1. Enable Email Link Authentication

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Authentication** > **Sign-in method**
4. Click on **Email/Password** provider
5. Enable **Email link (passwordless sign-in)**
6. Click **Save**

### 2. Configure Authorized Domains

1. In the **Authentication** section, go to **Settings** tab
2. Scroll down to **Authorized domains**
3. Add your app's domain (e.g., `task-app.firebaseapp.com`)
4. For development, you can also add `localhost`

### 3. Configure Dynamic Links (Optional)

If you want to use custom domains for email links:

1. Go to **Dynamic Links** in the Firebase Console
2. Set up a custom domain
3. Update the `url` parameter in `ActionCodeSettings` in your code

## App Configuration

### Android Configuration

1. Add intent filters to `android/app/src/main/AndroidManifest.xml`:

```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    android:launchMode="singleTop"
    android:theme="@style/LaunchTheme">
    
    <!-- Existing intent filter -->
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
    </intent-filter>
    
    <!-- Add this for email link handling -->
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="https"
              android:host="task-app.firebaseapp.com" />
    </intent-filter>
</activity>
```

### iOS Configuration

1. Add URL schemes to `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <!-- Existing URL schemes -->
    
    <!-- Add this for email link handling -->
    <dict>
        <key>CFBundleURLName</key>
        <string>task-app.firebaseapp.com</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>https</string>
        </array>
    </dict>
</array>
```

## How It Works

1. **Send Email Link**: User enters email and clicks "Send Login Link to Email"
2. **Receive Email**: User receives an email with a sign-in link
3. **Click Link**: User clicks the link, which opens the app
4. **Complete Sign-in**: App processes the link and signs the user in

## Features Implemented

- ✅ Send authentication link to email
- ✅ Handle email link sign-in
- ✅ Email validation
- ✅ Local email storage for seamless experience
- ✅ Error handling and user feedback
- ✅ Integration with existing authentication flow
- ✅ Automatic navigation based on user role

## Usage

1. On the login screen, enter your email address
2. Click "Send Login Link to Email"
3. Check your email for the authentication link
4. Click the link to complete sign-in
5. If prompted, confirm your email address in the app

## Security Notes

- Email links are single-use and expire after a certain time
- The app validates the email link before processing
- User email is temporarily stored locally for convenience
- All authentication follows Firebase security best practices

## Troubleshooting

- **Link doesn't work**: Ensure the domain is added to authorized domains in Firebase Console
- **App doesn't open**: Check that intent filters (Android) or URL schemes (iOS) are properly configured
- **Email not received**: Check spam folder and ensure email address is valid