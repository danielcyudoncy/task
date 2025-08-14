# FCM Migration Guide: Legacy API to HTTP v1

This guide explains the migration from Firebase Cloud Messaging (FCM) Legacy API to the HTTP v1 API, which was completed in this project.

## What Changed

The FCM Legacy API has been deprecated and will be shut down on June 20, 2024. This project has been migrated to use the FCM HTTP v1 API.

### Key Changes

1. **Authentication Method**:
   - **Before**: Server Key authentication
   - **After**: OAuth 2.0 access token authentication

2. **Endpoint URL**:
   - **Before**: `https://fcm.googleapis.com/fcm/send`
   - **After**: `https://fcm.googleapis.com/v1/projects/{project-id}/messages:send`

3. **Message Payload Structure**:
   - **Before**: `{"to": token, "notification": {...}}`
   - **After**: `{"message": {"token": token, "notification": {...}}}`

## Setup Instructions

### Step 1: Create a Service Account

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Project Settings** > **Service Accounts**
4. Click **Generate New Private Key**
5. Download the JSON file

### Step 2: Configure the Service Account

1. Replace the placeholder content in `assets/service-account.json` with your downloaded service account JSON
2. Update `assets/.env` with your Firebase Project ID:

   FIREBASE_PROJECT_ID=your-actual-project-id

### Step 3: Security Considerations

⚠️ **Important**: Never commit the actual service account JSON file to version control!

1. Add `assets/service-account.json` to your `.gitignore`
2. Use environment-specific configuration for production
3. Store the service account JSON securely (e.g., encrypted secrets)

## Technical Implementation

### Files Modified

- `lib/service/fcm_service.dart`: Updated to use HTTP v1 API
- `pubspec.yaml`: Added `googleapis_auth` dependency
- `assets/.env`: Updated configuration
- `assets/service-account.json`: Added service account template

### New Dependencies

```yaml
dependencies:
  googleapis_auth: ^1.6.0
```

### Code Changes

The `FCMService` class now includes:

- `_getAccessToken()`: Obtains OAuth 2.0 access tokens
- `_getProjectId()`: Retrieves Firebase project ID from environment
- Updated HTTP requests to use the new v1 endpoint
- Modified message payload structure

## Testing

1. Ensure your Firebase project has FCM enabled
2. Configure the service account and project ID
3. Test notifications through the app's task approval system
4. Monitor logs for any authentication or delivery issues

## Troubleshooting

### Common Issues

1. **Authentication Errors**:
   - Verify service account JSON is valid
   - Check that the service account has FCM permissions
   - Ensure project ID matches your Firebase project

2. **Token Errors**:
   - Verify FCM tokens are still valid
   - Check device registration status

3. **Payload Errors**:
   - Ensure message structure follows HTTP v1 format
   - Validate JSON payload structure

### Debug Logs

The service includes comprehensive logging. Check the console for:

- Access token generation status
- HTTP request/response details
- Firestore notification storage confirmation

## Migration Benefits

1. **Future-proof**: HTTP v1 API is the current standard
2. **Enhanced Security**: OAuth 2.0 token-based authentication
3. **Better Error Handling**: More detailed error responses
4. **Improved Reliability**: Modern API with better uptime guarantees

## Next Steps

1. Test the notification system thoroughly
2. Monitor for any issues in production
3. Consider implementing retry logic for failed notifications
4. Set up monitoring for FCM delivery rates

For more information, refer to the [official Firebase documentation](https://firebase.google.com/docs/cloud-messaging/migrate-v1).
