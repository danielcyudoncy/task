# 🔐 Authenticated User Testing Guide

**Status**: Ready for Testing  
**Date**: November 16, 2025  
**Objective**: Verify permission guards work correctly for authenticated users

---

## 📋 Testing Overview

This guide covers testing the 5 security fixes with authenticated users. All permission errors we saw earlier validate that security is working - now we need to verify that authenticated users can perform authorized operations.

### Test Scenarios

| Scenario | User Role | Operation | Expected Result |
|----------|-----------|-----------|-----------------|
| 1 | Admin | Load dashboard data | ✅ Success - all data visible |
| 2 | Admin | Approve task | ✅ Success + audit log created |
| 3 | Admin | Reject task | ✅ Success + audit log created |
| 4 | Admin | Assign task | ✅ Success + audit log created |
| 5 | Manager | Load dashboard data | ✅ Success - limited data |
| 6 | Manager | Approve task | ❌ Blocked - not authorized |
| 7 | Manager | Assign task | ✅ Success - limited scope |
| 8 | Reporter | Load dashboard data | ✅ Success - own tasks only |
| 9 | Reporter | Approve task | ❌ Blocked - not authorized |
| 10 | Reporter | Modify audit logs | ❌ Blocked - immutable |

---

## 🚀 Setup: Creating Test Users

### Option 1: Manual Creation in Firebase Console (Easiest)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Authentication** → **Users**
4. Click **Create user** for each test user

### Option 2: Create via App (Hardest - Requires Signup Flow)

Use the app's signup screens to create test users. You'll need to run through the full signup flow.

### Recommended Test Users to Create

```
TEST ADMIN USER
  Email: admin.test@task.local
  Password: TestAdmin123!@#
  Role: Admin (set via custom claim or Firestore)
  
TEST MANAGER USER
  Email: manager.test@task.local
  Password: TestManager123!@#
  Role: Manager (set in users/uid document)
  
TEST REPORTER USER
  Email: reporter.test@task.local
  Password: TestReporter123!@#
  Role: Reporter (set in users/uid document)
```

### Setting Roles via Firebase Console

After creating users, update their Firestore records:

1. Go to **Firestore Database** → **Collection: users**
2. For each user document, add/update:
   ```
   role: "Admin" | "Manager" | "Reporter"
   ```

### Setting Admin Custom Claim (For Admin Testing)

Option A: Use Cloud Functions (if available)
```bash
firebase functions:shell
> setAdminClaim({uid: "USER_UID"})
```

Option B: Update custom claim directly
```dart
// In admin_controller.dart or auth_controller.dart
await FirebaseAuth.instance.currentUser?.getIdTokenResult(forceRefresh: true);
```

---

## 🧪 Test Execution Guide

### Phase 1: Admin User Testing

#### Test 1A: Admin Login & Dashboard Access
```dart
// LOGIN STEP
Email: admin.test@task.local
Password: TestAdmin123!@#

// VERIFICATION POINTS
✅ Login successful
✅ Redirected to admin dashboard
✅ Dashboard loads without permission errors
✅ All user data visible
✅ All tasks visible
✅ Admin statistics displayed
```

**What to Check in Logs**:
- Should NOT see permission denied errors for dashboard queries
- Should see "Role loaded: Admin, navigating..."
- Should see Firestore queries completing successfully

#### Test 1B: Admin Task Approval
```dart
// PRECONDITION
- One pending task exists in database
- Current user is Admin
- Task has status = "pending" (not "approved" or "rejected")

// EXECUTE
1. Navigate to Tasks view
2. Find a pending task
3. Click "Approve" button
4. Observe approval dialog/confirmation

// VERIFICATION POINTS
✅ Approval succeeds
✅ Task status changes to "approved"
✅ "approvedBy" field set to admin email
✅ "approvalTimestamp" set to current time
✅ Audit log created in audit_logs collection
✅ Task audit created in task_audits collection
```

**Audit Log Entry Should Look Like**:
```json
{
  "operationType": "task_approved",
  "userId": "[ADMIN_UID]",
  "resourceId": "[TASK_ID]",
  "resourceType": "task",
  "details": {
    "taskId": "[TASK_ID]",
    "approvalStatus": "approved",
    "approvedBy": "[ADMIN_EMAIL]"
  },
  "timestamp": "[SERVER_TIMESTAMP]",
  "ipAddress": "[IF_AVAILABLE]"
}
```

#### Test 1C: Admin Task Rejection
```dart
// PRECONDITION
- One pending task exists
- Current user is Admin
- Task has status = "pending"

// EXECUTE
1. Navigate to Tasks view
2. Find a different pending task
3. Click "Reject" button
4. Enter rejection reason (if prompted)
5. Confirm rejection

// VERIFICATION POINTS
✅ Rejection succeeds
✅ Task status changes to "rejected"
✅ "rejectedBy" field set to admin email
✅ Rejection reason saved (if applicable)
✅ Audit log created
✅ Task audit created
```

#### Test 1D: Admin Task Assignment
```dart
// PRECONDITION
- One unassigned task exists
- Current user is Admin
- A Reporter or Cameraman user exists to assign to

// EXECUTE
1. Navigate to Admin → Manage Tasks or Task Details
2. Find an unassigned task
3. Click "Assign" button
4. Select a user to assign to
5. Confirm assignment

// VERIFICATION POINTS
✅ Assignment succeeds
✅ Task.assignedTo set to selected user
✅ Task.assignedBy set to admin email
✅ Audit log created
✅ Notification sent to assigned user
```

---

### Phase 2: Manager User Testing

#### Test 2A: Manager Login & Dashboard Access
```dart
// LOGIN STEP
Email: manager.test@task.local
Password: TestManager123!@#

// VERIFICATION POINTS
✅ Login successful
✅ Redirected to manager dashboard
✅ Dashboard loads (no permission errors)
✅ User data visible (limited scope)
✅ Only assigned tasks visible
✅ Manager statistics displayed
```

#### Test 2B: Manager Cannot Approve Tasks
```dart
// PRECONDITION
- Current user is Manager
- One pending task exists

// EXECUTE
1. Navigate to Tasks view
2. Find a pending task
3. Try to click "Approve" button

// VERIFICATION POINTS
✅ Approve button is disabled OR
✅ Clicking it shows permission error OR
✅ Request to backend fails with permission denied
❌ No audit log created (operation was blocked)
```

**Expected Error**:
```
Error: Admin approval required
Details: User role 'Manager' cannot approve tasks
```

#### Test 2C: Manager Can Assign Tasks (If Role Allows)
```dart
// PRECONDITION
- Current user is Manager
- One unassigned task exists

// EXECUTE
1. Navigate to Tasks view
2. Find an unassigned task
3. Try to assign it to a Reporter

// VERIFICATION POINTS
✅ Assignment allowed (if Manager role includes this permission)
   OR
✅ Assignment denied with permission error (if not allowed)
```

---

### Phase 3: Reporter User Testing

#### Test 3A: Reporter Login & Dashboard Access
```dart
// LOGIN STEP
Email: reporter.test@task.local
Password: TestReporter123!@#

// VERIFICATION POINTS
✅ Login successful
✅ Redirected to reporter dashboard
✅ Dashboard loads
✅ Only own tasks visible
❌ Other users' tasks not visible
❌ User management not accessible
```

#### Test 3B: Reporter Cannot Approve Tasks
```dart
// PRECONDITION
- Current user is Reporter
- One pending task exists

// EXECUTE
1. Navigate to Tasks view
2. Find a pending task (assigned to them or any task)
3. Try to approve it

// VERIFICATION POINTS
❌ Approve button not visible OR disabled
✅ Clicking it shows permission error
✅ Request fails with "Admin only" error
❌ No audit log created
```

#### Test 3C: Reporter Cannot Access Admin Functions
```dart
// PRECONDITION
- Current user is Reporter
- App is running

// EXECUTE
1. Try to navigate to admin URL directly: /admin
2. Try to navigate to manage users: /manage-users
3. Try to access admin features

// VERIFICATION POINTS
❌ Access denied
❌ Redirected to appropriate screen
✅ No sensitive data leaked
```

---

## 📊 Audit Log Verification

After running tests, verify audit logs were created correctly:

### Firestore Console Verification

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Go to **Firestore Database**
3. Check **Collections** → **audit_logs**

### Verify Each Entry:
```json
{
  "id": "[AUTO_GENERATED]",
  "operationType": "task_approved|task_rejected|task_assigned|...",
  "userId": "[UID_OF_PERFORMER]",
  "resourceId": "[TASK_ID]",
  "resourceType": "task",
  "details": {
    // Operation-specific details
  },
  "timestamp": "[SERVER_TIMESTAMP]",
  "ipAddress": "[OPTIONAL]"
}
```

### Verify Immutability:

```dart
// Try to update an audit log (should fail)
try {
  await firestore
    .collection('audit_logs')
    .doc('[AUDIT_LOG_ID]')
    .update({'operationType': 'hacked'});
} catch (e) {
  // Expected: Permission denied
  print('✅ Audit log is immutable: $e');
}

// Try to delete an audit log (should fail)
try {
  await firestore
    .collection('audit_logs')
    .doc('[AUDIT_LOG_ID]')
    .delete();
} catch (e) {
  // Expected: Permission denied
  print('✅ Audit log cannot be deleted: $e');
}
```

---

## 🔍 Verification Checklist

### Authentication & Authorization ✅

- [ ] Admin user can login
- [ ] Manager user can login
- [ ] Reporter user can login
- [ ] Each user sees appropriate dashboard
- [ ] Each user sees only authorized data
- [ ] Sensitive screens not accessible to unauthorized users

### Admin Operations ✅

- [ ] Admin can approve tasks
- [ ] Admin can reject tasks
- [ ] Admin can assign tasks
- [ ] Admin can manage users
- [ ] All operations create audit logs

### Permission Guards ✅

- [ ] Non-admin users cannot approve tasks
- [ ] Non-admins cannot access user management
- [ ] Non-admins cannot see admin statistics
- [ ] Operations are blocked at multiple levels:
  - [ ] Frontend (button disabled)
  - [ ] Backend (Firestore rules)
  - [ ] Cloud Functions (if applicable)

### Audit Logging ✅

- [ ] Audit logs created for all privileged operations
- [ ] Audit logs cannot be modified
- [ ] Audit logs cannot be deleted
- [ ] All required fields present in logs
- [ ] Timestamps are accurate
- [ ] User IDs are correct

### Data Integrity ✅

- [ ] No data leakage to unauthorized users
- [ ] No data loss on operations
- [ ] Timestamps are server-side
- [ ] No stale data cached
- [ ] Rollback works correctly

---

## 📱 Debug: Checking Logs During Testing

### In VS Code Terminal:

```bash
# Capture device logs in real-time
adb logcat | grep -E "(flutter|task|audit|error|permission)" | head -200

# Save logs to file
adb logcat > /tmp/test_logs.txt &

# Check specific app logs
adb logcat | grep "flutter" | tail -50
```

### In Flutter Debug Console:

Look for these key patterns:

```
✅ GOOD SIGNS
I/flutter: Admin verification: role=Admin, isAdmin=true
I/flutter: Loading dashboard data successfully
I/flutter: Firestore query completed: tasks=5
I/flutter: Audit log created successfully

❌ BAD SIGNS (but expected for non-admin)
W/Firestore: Listen for Query(...) failed: Status{code=PERMISSION_DENIED
I/flutter: Permission denied: User role 'Reporter' cannot approve
E/firebase_database: DatabaseError: Permission denied
```

---

## 🎯 Success Criteria

All tests pass when:

1. **Authentication Works** - All 3 test users can login
2. **Authorization Enforced** - Only authorized users can perform operations
3. **Audit Trail Complete** - All privileged operations logged
4. **No Data Leaks** - Unauthorized users cannot access sensitive data
5. **Immutable Records** - Audit logs cannot be tampered with
6. **Graceful Errors** - Permission errors handled without crashes

---

## 📝 Test Report Template

After completing all tests, document findings:

```markdown
# Test Execution Report

**Date**: [TODAY'S DATE]
**Tester**: [YOUR_NAME]
**Device**: [DEVICE_INFO]
**Build**: [APP_VERSION]

## Phase 1: Admin Testing
- [ ] Admin login: ✅/❌
- [ ] Dashboard access: ✅/❌
- [ ] Task approval: ✅/❌
- [ ] Task rejection: ✅/❌
- [ ] Task assignment: ✅/❌
- [ ] Audit logs created: ✅/❌

## Phase 2: Manager Testing
- [ ] Manager login: ✅/❌
- [ ] Dashboard access: ✅/❌
- [ ] Approval blocked: ✅/❌
- [ ] Assignment allowed: ✅/❌

## Phase 3: Reporter Testing
- [ ] Reporter login: ✅/❌
- [ ] Dashboard access: ✅/❌
- [ ] Approval blocked: ✅/❌
- [ ] Admin access blocked: ✅/❌

## Audit Log Verification
- [ ] Logs created correctly: ✅/❌
- [ ] Logs immutable: ✅/❌
- [ ] No unauthorized access: ✅/❌

## Issues Found
- [List any failures here]

## Conclusion
All tests: ✅ PASSED / ❌ FAILED
```

---

## 🔧 Troubleshooting

### Issue: Login fails for test user
**Solution**:
- Verify user exists in Firebase Auth
- Check user password is correct
- Verify user profile exists in Firestore
- Check Firestore rules allow user profile read

### Issue: Approval succeeds but no audit log created
**Solution**:
- Check Firestore has audit_logs collection
- Verify user has write permission to audit_logs
- Check cloud_firestore dependency is updated
- Look for errors in Firebase console logs

### Issue: Permission denied for admin operations
**Solution**:
- Verify admin user has admin custom claim set
- Check Firestore rules are deployed correctly
- Verify user role in Firestore is "Admin"
- Clear app cache and re-login

### Issue: Task assignment doesn't notify user
**Solution**:
- Check assigned user has FCM token
- Verify notification service initialized
- Check Firebase Cloud Messaging configured
- Look for errors in FCM service logs

---

## ✅ Next Steps After Testing

1. **Document Results** - Fill out test report
2. **Fix Any Issues** - Address failures
3. **Repeat Failed Tests** - Verify fixes work
4. **Load Testing** - Test with multiple concurrent users
5. **Edge Cases** - Test unusual scenarios
6. **Production Deployment** - Ready for release

---

**Testing Status**: READY  
**Last Updated**: 2025-11-16
