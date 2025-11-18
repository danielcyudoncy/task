# 🔧 Firebase Setup: Creating Test Users

**Status**: Pre-Testing Configuration  
**Objective**: Set up test users for authenticated user testing

---

## 📋 Overview

Before running authenticated tests, you need 3 test users:
1. **Admin User** - Full access to all operations
2. **Manager User** - Limited assignment permissions
3. **Reporter User** - Minimal permissions

---

## ✅ Method 1: Create Users via Firebase Console (Recommended)

### Step 1: Open Firebase Console
1. Go to https://console.firebase.google.com/
2. Select your project: `task`
3. Click on **Authentication** in left sidebar

### Step 2: Create Test Admin User
1. Click **Users** tab
2. Click **+ Create user** button
3. Fill in the form:
   ```
   Email: admin.test@task.local
   Password: TestAdmin123!@#
   ```
4. Click **Create user**

**Result**: User created in Firebase Auth ✅

### Step 3: Create Test Manager User
1. Click **+ Create user** button
2. Fill in:
   ```
   Email: manager.test@task.local
   Password: TestManager123!@#
   ```
3. Click **Create user**

**Result**: User created ✅

### Step 4: Create Test Reporter User
1. Click **+ Create user** button
2. Fill in:
   ```
   Email: reporter.test@task.local
   Password: TestReporter123!@#
   ```
3. Click **Create user**

**Result**: User created ✅

---

## 🗂️ Method 2: Firestore Role Configuration

After creating users in Firebase Auth, you need to set their roles in Firestore.

### Step 1: Open Firestore Console
1. Go to https://console.firebase.google.com/
2. Select your project
3. Click **Firestore Database** in left sidebar

### Step 2: Find Admin User Document
1. Click **Collection**: `users`
2. Find the admin.test@task.local user document
3. Click on it to open

### Step 3: Update Admin User Role
The document should look like:
```json
{
  "uid": "[AUTO_GENERATED_UID]",
  "email": "admin.test@task.local",
  "fullName": "Admin Test User",
  "role": "Reporter"  // <-- CHANGE THIS
}
```

Edit the document:
1. Click the edit icon (pencil)
2. Change `role` field to: `Admin`
3. Click **Update**

**Result**: User role set to Admin ✅

### Step 4: Update Manager User Role
1. Find manager.test@task.local user document
2. Edit it
3. Change `role` to: `Manager`
4. Click **Update**

**Result**: User role set to Manager ✅

### Step 5: Reporter Role (Already Set)
The reporter user should already have role `Reporter` from signup, but verify:
1. Find reporter.test@task.local user document
2. Verify `role` field is: `Reporter`
3. If not, edit and set it to `Reporter`

**Result**: User role verified ✅

---

## 👤 Method 3: Set Admin Custom Claim (Optional but Recommended)

The admin custom claim gives admin privileges in Firestore rules.

### Option A: Using Firebase Console (Easiest)

Unfortunately, Firebase Console doesn't have a UI for custom claims. Use Option B instead.

### Option B: Using Firebase Functions Shell (Advanced)

1. Make sure you have Firebase CLI installed:
```bash
npm install -g firebase-tools
firebase login
```

2. Start the functions shell:
```bash
cd functions
firebase functions:shell
```

3. Set admin claim for admin user:
```javascript
setAdminClaim({uid: "[ADMIN_USER_UID]"})
```

4. Get the UID from Firebase Console:
   - Go to **Authentication** → **Users**
   - Find admin.test@task.local
   - Copy the UID (long alphanumeric string)
   - Paste it in the command above

5. Press Enter to execute

**Result**: Admin custom claim set ✅

### Option C: Using Cloud Functions Callable (Manual)

If functions shell doesn't work, you can call it from your app:

1. In your app, temporarily add this to a controller:
```dart
Future<void> setAdminClaimForTest(String uid) async {
  try {
    await FirebaseFunctions.instance
        .httpsCallable('setAdminClaim')
        .call({'uid': uid});
    print('✅ Admin claim set for: $uid');
  } catch (e) {
    print('❌ Error: $e');
  }
}
```

2. Call it once, then remove it
3. Alternative: Use this Firebase CLI command:
```bash
firebase auth:import users.json --hash-algo=scrypt \
  --rounds=8 --mem-cost=14
```

---

## 🔐 Verify Setup

### Check Firebase Auth
```bash
# List all users (using Firebase CLI)
firebase auth:export users.json

# Check if your test users exist
cat users.json | grep "admin.test"
```

### Check Firestore Roles
1. Go to Firebase Console → Firestore Database
2. Collection: `users`
3. Verify each test user document has correct role:
   - admin.test@task.local: `role: "Admin"`
   - manager.test@task.local: `role: "Manager"`
   - reporter.test@task.local: `role: "Reporter"`

### Check Audit Collections Exist
1. Go to Firestore Database
2. Verify these collections exist:
   - `audit_logs` (empty initially)
   - `task_audits` (empty initially)
   - If they don't exist, they'll be created when first audit is logged

---

## 📋 Test User Quick Reference

```
ADMIN TEST USER
├─ Email: admin.test@task.local
├─ Password: TestAdmin123!@#
├─ Role (Firestore): Admin
└─ Expected Permissions: Full access to all operations

MANAGER TEST USER
├─ Email: manager.test@task.local
├─ Password: TestManager123!@#
├─ Role (Firestore): Manager
└─ Expected Permissions: Limited task assignment, no approval

REPORTER TEST USER
├─ Email: reporter.test@task.local
├─ Password: TestReporter123!@#
├─ Role (Firestore): Reporter
└─ Expected Permissions: View own tasks only, no admin operations
```

---

## ⚠️ Important Security Notes

### For Testing ONLY
```
⚠️ DO NOT use these test passwords in production
⚠️ DO NOT commit these credentials to version control
⚠️ DO NOT use for real user accounts
⚠️ DELETE these users before production deployment
```

### Password Requirements
Passwords must be:
- At least 6 characters
- Recommended: Mix of uppercase, lowercase, numbers, symbols

### Before Production
1. Delete all test users from Firebase Auth
2. Delete all test user documents from Firestore
3. Clear any test data from audit collections
4. Verify production users have secure passwords

---

## 🧪 Verify Test Users Work

### Test Login Flow

1. **Start the app**:
```bash
flutter run -v -d 146624053J000176
```

2. **Navigate to login screen**
3. **Try logging in as Admin**:
   ```
   Email: admin.test@task.local
   Password: TestAdmin123!@#
   ```

4. **Verify**:
   - ✅ Login succeeds
   - ✅ Redirected to dashboard
   - ✅ User role shown as "Admin"
   - ✅ No permission errors

5. **Check logs**:
```bash
adb -s 146624053J000176 logcat | grep -i "admin\|role"

# Should see:
# I/flutter: Role loaded: Admin, navigating...
```

---

## 🔧 Troubleshooting

### Issue: User created but login fails
**Solution**:
1. Verify user exists in Firebase Auth (Authentication → Users)
2. Verify user document exists in Firestore (Firestore Database → users collection)
3. Try clearing app cache: `adb shell pm clear com.task`
4. Restart app: `flutter run`

### Issue: User logs in but role not recognized
**Solution**:
1. Check user document in Firestore has `role` field
2. Verify role value is exactly: `Admin`, `Manager`, or `Reporter` (capitalized)
3. Clear app cache and restart

### Issue: Admin operations still blocked
**Solution**:
1. Verify admin custom claim is set: Check Firebase Console → Auth → Users → admin user
2. Check that `isAdmin.value` is true in app logs
3. Check Firestore rules are deployed: `firebase deploy --only firestore:rules`

### Issue: Cannot set admin claim
**Solution**:
1. Ensure `setAdminClaim` Cloud Function exists in `functions/index.js`
2. Ensure functions are deployed: `firebase deploy --only functions`
3. Ensure admin user UID is correct (copy from Firebase Console)
4. Check Cloud Function logs for errors: Firebase Console → Functions → Logs

---

## ✅ Pre-Testing Checklist

Before starting authenticated tests, verify:

- [ ] 3 test users created in Firebase Auth
- [ ] Each user has correct role in Firestore
- [ ] Admin custom claim set (if using)
- [ ] Firestore rules deployed
- [ ] Cloud Functions deployed
- [ ] App rebuilt with latest code
- [ ] Device connected and app running
- [ ] All test users can login successfully
- [ ] No permission errors during normal login

---

## 🚀 Next Steps

Once test users are set up:

1. **Run Manual Tests**: See `MANUAL_TESTING_QUICK_START.md`
2. **Run Integration Tests**: 
   ```bash
   flutter test test/authenticated_user_testing.dart
   ```
3. **Document Results**: Fill out test report in test report template
4. **Fix Issues**: Address any failures found
5. **Production Cleanup**: Delete test users before deployment

---

## 📞 Support

If you encounter issues:

1. **Check Firebase Console** for error messages
2. **Check app logs**: `adb logcat | grep -i flutter`
3. **Check Cloud Function logs**: Firebase Console → Functions → Logs
4. **Check Firestore rules**: Ensure they're deployed and correct

---

**Setup Status**: READY  
**Test Users**: 0 / 3 Created  
**Next Action**: Create test users above ⬆️

Once all ✅ are checked, proceed to `MANUAL_TESTING_QUICK_START.md`
