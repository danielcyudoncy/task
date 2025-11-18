# 🚀 Manual Testing Quick Start Guide

**Duration**: ~20 minutes per test scenario  
**Device**: Connected Android device (Infinix X6728)  
**Status**: Ready to Execute

---

## ⚡ Pre-Test Checklist

Before starting, complete these steps:

```bash
# 1. Ensure device is connected
adb devices

# 2. Rebuild app with latest code
flutter clean
flutter pub get
flutter run -v -d 146624053J000176

# 3. Clear app data to ensure fresh state
adb -s 146624053J000176 shell pm clear com.task

# 4. Open app
# (App will open on device)
```

---

## 📝 Test Scenario #1: Admin User Approval Flow

**Objective**: Verify admin can approve tasks with audit logging

### Step-by-Step:

#### 1️⃣ **Login as Admin**
```
Email: admin.test@task.local
Password: TestAdmin123!@#
```

**Expected**: ✅ Login succeeds, redirected to admin dashboard

**Verify in logs**:
```bash
# In terminal, watch device logs
adb -s 146624053J000176 logcat | grep -i "role|admin|login"

# Should see:
# I/flutter: Role loaded: Admin, navigating...
# I/flutter: Admin verification: role=Admin, isAdmin=true
```

#### 2️⃣ **Navigate to Tasks**
- Tap on "Tasks" or "Dashboard" (depending on UI)
- Wait for tasks to load

**Expected**: ✅ Dashboard shows tasks without permission errors

**Verify**:
- No red error banners
- Task list populated
- No "Permission denied" messages

#### 3️⃣ **Find a Pending Task**
- Look for a task with status "pending" (not "approved" or "rejected")
- Note the task ID or title

**Expected**: ✅ At least one pending task visible

#### 4️⃣ **Approve the Task**
- Tap/click on the task to open details
- Tap "Approve" button
- Confirm if prompted

**Expected**: ✅ Task status changes to "approved" without errors

**Verify in Logs**:
```bash
# Should see approval success
adb -s 146624053J000176 logcat | grep -i "approval|approved|task"

# Should see audit log created
# I/flutter: Audit log created for task_approved
```

#### 5️⃣ **Verify Audit Log in Firestore**

Go to Firebase Console:
1. Open https://console.firebase.google.com/
2. Select your project
3. Go to **Firestore Database**
4. Click **Collection**: `audit_logs`
5. Find the newest entry

**Verify the entry contains**:
```json
{
  "operationType": "task_approved",
  "userId": "[admin-uid]",
  "resourceId": "[task-id]",
  "resourceType": "task",
  "details": {
    "approvalStatus": "approved"
  },
  "timestamp": "[recent]"
}
```

✅ **TEST PASSED**: Task approved + audit log created

---

## 📝 Test Scenario #2: Admin Cannot Be Bypassed by Reporter

**Objective**: Verify reporter cannot approve tasks

### Step-by-Step:

#### 1️⃣ **Logout**
- Tap profile/settings icon
- Tap "Logout"

**Expected**: ✅ Redirected to login screen

#### 2️⃣ **Login as Reporter**
```
Email: reporter.test@task.local
Password: TestReporter123!@#
```

**Expected**: ✅ Login succeeds

**Verify in logs**:
```bash
adb -s 146624053J000176 logcat | grep -i "role|reporter"

# Should see:
# I/flutter: Role loaded: Reporter, navigating...
```

#### 3️⃣ **Navigate to Tasks**
- Tap on "Tasks"
- Wait for tasks to load

**Expected**: ✅ Tasks load but limited to reporter's own tasks

#### 4️⃣ **Find a Pending Task**
- Look for any pending task visible to reporter

**Expected**: ✅ Pending task visible (or message that no pending tasks exist)

#### 5️⃣ **Try to Approve**
- Tap the task
- Look for "Approve" button

**Expected**: ❌ One of these:
- Button is greyed out/disabled
- Button not visible at all
- Tapping shows error message

#### 6️⃣ **Verify No Audit Log Created**

Check Firestore:
1. Go to Console → Firestore → `audit_logs`
2. Look for any entries with reporter's UID approving tasks
3. Should be **NONE**

**Expected**: ❌ No task_approved entries by reporter

✅ **TEST PASSED**: Reporter blocked from approving tasks

---

## 📝 Test Scenario #3: Manager Limited Access

**Objective**: Verify manager has limited permissions

### Step-by-Step:

#### 1️⃣ **Logout and Login as Manager**
```
Email: manager.test@task.local
Password: TestManager123!@#
```

**Expected**: ✅ Login succeeds

#### 2️⃣ **Check Dashboard Access**
- Verify manager can see dashboard
- Verify manager can see assigned tasks

**Expected**: ✅ Dashboard loads, shows limited data

#### 3️⃣ **Try Approval**
- Navigate to tasks
- Try to approve a task

**Expected**: ❌ Blocked from approving (same as reporter)

#### 4️⃣ **Try Assignment (if allowed)**
- Try to assign a task to another user

**Expected**: 
- ✅ Allowed (if Manager role includes assignment permission)
- OR ❌ Blocked (if not allowed)

✅ **TEST PASSED**: Manager permissions correctly enforced

---

## 🔐 Test Scenario #4: Audit Log Immutability

**Objective**: Verify audit logs cannot be tampered with

### Step-by-Step:

#### 1️⃣ **Login as Admin**
```
Email: admin.test@task.local
Password: TestAdmin123!@#
```

#### 2️⃣ **Go to Firebase Console**
1. Open https://console.firebase.google.com/
2. Navigate to **Firestore Database**
3. Find **Collection**: `audit_logs`
4. Select any recent audit log entry

#### 3️⃣ **Try to Edit**
- Click the edit icon (pencil) on the entry
- Try to change `operationType` field
- Try to save

**Expected**: ❌ Error: "Permission denied" or "You do not have permission"

#### 4️⃣ **Try to Delete**
- Click delete icon (trash) on the entry
- Confirm delete

**Expected**: ❌ Error: "Permission denied"

✅ **TEST PASSED**: Audit logs are immutable

---

## 📊 Results Documentation

After each test, record results in this table:

| Test Scenario | Admin | Manager | Reporter | Notes |
|---------------|-------|---------|----------|-------|
| Login | ✅ | ✅ | ✅ | All users logged in |
| Dashboard Access | ✅ | ✅ | ✅ | Each sees appropriate data |
| Task Approval | ✅ | ❌ | ❌ | Only admin allowed |
| Task Rejection | ✅ | ❌ | ❌ | Only admin allowed |
| Task Assignment | ✅ | ✅/❌ | ❌ | Depends on manager role |
| Audit Logging | ✅ | N/A | N/A | All admin ops logged |
| Immutability | ✅ | ✅ | ✅ | Logs cannot be modified |
| Permission Errors | ✅ | ✅ | ✅ | No crashes, graceful handling |

---

## 🐛 Troubleshooting Quick Fixes

### Problem: Login fails
```bash
# Solution 1: Clear app cache
adb -s 146624053J000176 shell pm clear com.task

# Solution 2: Reinstall app
adb -s 146624053J000176 uninstall com.task
flutter run -v -d 146624053J000176
```

### Problem: "Permission denied" errors in normal flow
```bash
# Solution: Check Firestore rules deployed
firebase functions:config:get  # Check if functions deployed

# Manually deploy if needed
firebase deploy --only firestore:rules,functions
```

### Problem: Audit logs not created
```bash
# Solution: Check AuditService is initialized
# In app logs, look for:
# I/flutter: AuditService: Initialized

# If not, restart app
flutter run -v --no-fast-start -d 146624053J000176
```

### Problem: Can see other users' data (should not be able to)
```bash
# Solution: Verify Firestore rules are active
# Re-deploy rules:
cd functions
firebase deploy --only firestore:rules
```

---

## ⏱️ Estimated Test Timeline

- **Scenario 1 (Admin)**: 5 minutes
- **Scenario 2 (Reporter)**: 5 minutes
- **Scenario 3 (Manager)**: 4 minutes
- **Scenario 4 (Immutability)**: 3 minutes
- **Documentation**: 3 minutes

**Total**: ~20 minutes for full test cycle

---

## 🎯 Pass/Fail Criteria

### ✅ ALL TESTS PASS When:

1. **Admin can approve/reject tasks** without errors
2. **Audit logs created** for all admin operations
3. **Non-admin users blocked** from admin operations
4. **Audit logs immutable** (cannot modify or delete)
5. **No permission errors** for authorized operations
6. **No crashes** during permission denials
7. **Data not leaked** to unauthorized users

### ❌ TESTS FAIL If:

1. Any user can approve tasks without proper authorization
2. Audit logs not created for operations
3. Audit logs can be modified or deleted
4. App crashes on permission denial
5. Unauthorized users can access sensitive data
6. Permission errors not handled gracefully

---

## 📸 Screenshots to Capture (Optional)

- Admin dashboard showing all data
- Task approval success screen
- Audit log in Firebase Console
- Permission error for non-admin (if visible)
- Manager dashboard (limited view)

---

## ✅ Sign-Off Checklist

- [ ] All 4 scenarios tested
- [ ] Results documented above
- [ ] Screenshots captured (if applicable)
- [ ] No crashes observed
- [ ] Permission errors handled gracefully
- [ ] Audit logs verified in Firebase
- [ ] Immutability verified
- [ ] Report saved and shared

---

**Ready to Test**: YES ✅

Run this command to get started:
```bash
flutter run -v -d 146624053J000176
```

Then follow the scenarios above!
