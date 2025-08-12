# Google Sign-In Fix Guide

## Issue Identified

The Google Sign-In is failing because the `GoogleService-Info.plist` file is missing the `REVERSED_CLIENT_ID` field, which is essential for the OAuth callback to work properly.

## Root Cause

Starting from April 2023, Firebase only includes `CLIENT_ID` and `REVERSED_CLIENT_ID` in the configuration file when Google Sign-In is properly enabled in the Firebase Console.

## Solution Steps

### Step 1: Enable Google Sign-In in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `task-e5a96`
3. Navigate to **Authentication** → **Sign-in method**
4. Find **Google** in the list of providers
5. Click on **Google** to configure it
6. Toggle **Enable** to ON
7. Add your support email (required)
8. Click **Save**

### Step 2: Download Updated Configuration File

1. In Firebase Console, go to **Project Settings** (gear icon)
2. Scroll down to **Your apps** section
3. Find your iOS app (`com.example.task`)
4. Click **Download GoogleService-Info.plist**
5. Replace the existing file in `ios/Runner/GoogleService-Info.plist`

### Step 3: Update Info.plist with Correct URL Scheme

1. Open the new `GoogleService-Info.plist` file
2. Find the `REVERSED_CLIENT_ID` value
3. Copy this value
4. Open `ios/Runner/Info.plist`
5. Replace the placeholder URL scheme with the actual `REVERSED_CLIENT_ID`

### Step 4: Clean and Rebuild

```bash
# Clean the project
flutter clean

# Get dependencies
flutter pub get

# For iOS specifically
cd ios
pod install
cd ..

# Run the app
flutter run
```

## What I've Already Fixed

✅ Added `CFBundleURLTypes` configuration to `Info.plist`
✅ Added placeholder `REVERSED_CLIENT_ID` to `GoogleService-Info.plist`
✅ Set up the URL scheme structure

## What You Need to Do

🔧 **Enable Google Sign-In in Firebase Console** (most important)
🔧 **Download new GoogleService-Info.plist**
🔧 **Replace the placeholder REVERSED_CLIENT_ID with the real value**

## Expected Behavior After Fix

1. User taps "Sign in with Google"
2. Google OAuth screen appears
3. User selects their email
4. App receives the authentication token
5. User is signed in and redirected to appropriate screen

## Troubleshooting

If the issue persists after following these steps:

1. **Check Bundle ID**: Ensure the Bundle ID in Xcode matches Firebase (`com.example.task`)
2. **Verify URL Scheme**: The URL scheme should exactly match the `REVERSED_CLIENT_ID`
3. **Check Firebase Project**: Ensure you're using the correct Firebase project
4. **Test on Device**: Google Sign-In works better on physical devices than simulators

## Technical Details

The Google Sign-In flow works as follows:
1. App opens Google OAuth in Safari/Chrome
2. User authenticates with Google
3. Google redirects back to app using the URL scheme
4. App receives the authentication token
5. Token is exchanged for Firebase credentials

Without the proper URL scheme configuration, step 3 fails, which is why "nothing happens" after email selection.