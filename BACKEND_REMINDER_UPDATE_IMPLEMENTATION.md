# Backend Implementation: Reminder Update Feature

## Overview
This document describes the backend changes needed to support the reminder update feature in the iOS app. The iOS app now allows users to edit existing reminders (change the reminder time and message).

## Required Backend Changes

### 1. New API Endpoint

**Endpoint:** `PUT /api/tasks/{task_id}/reminders/{reminder_id}`

**Purpose:** Update an existing reminder's time and message

**Authentication:** Requires Firebase JWT token in Authorization header

**Request Headers:**
```
Authorization: Bearer {firebase_jwt_token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "reminder_time": "2025-10-17T15:30:00+00:00",
  "message": "Updated reminder message"
}
```

**Request Body Parameters:**
- `reminder_time` (string, required): The new reminder time in ISO 8601 format with timezone (e.g., "2025-10-17T15:30:00+00:00")
- `message` (string, required): The updated reminder message

**Success Response (200 OK):**
```json
{
  "message": "Reminder updated successfully",
  "reminder": {
    "id": "reminder_123",
    "task_id": "task_456",
    "reminder_time": "2025-10-17T15:30:00+00:00",
    "message": "Updated reminder message",
    "sent": false
  }
}
```

**Error Responses:**

**400 Bad Request** - Invalid input:
```json
{
  "error": "reminder_time and message are required"
}
```

**401 Unauthorized** - Missing or invalid authentication:
```json
{
  "error": "Unauthorized"
}
```

**403 Forbidden** - User doesn't own the task:
```json
{
  "error": "You don't have permission to update this reminder"
}
```

**404 Not Found** - Task or reminder doesn't exist:
```json
{
  "error": "Task not found"
}
```
or
```json
{
  "error": "Reminder not found"
}
```

### 2. Implementation Details

#### Database Schema
No schema changes required. The existing reminder structure should already have:
- `id` (string) - Unique reminder identifier
- `task_id` (string) - Reference to parent task
- `reminder_time` (datetime/timestamp) - When the reminder should trigger
- `message` (string) - The reminder message
- `sent` (boolean) - Whether the reminder has been sent

#### Business Logic Requirements

1. **Authentication & Authorization:**
   - Verify Firebase JWT token is valid
   - Extract user_id from the token
   - Verify the task belongs to the authenticated user
   - Only allow updates if `sent` is `false` (cannot edit already-sent reminders)

2. **Input Validation:**
   - Both `reminder_time` and `message` must be provided
   - `reminder_time` must be a valid ISO 8601 datetime string
   - `reminder_time` must be in the future (cannot set reminder for past time)
   - `message` must not be empty

3. **Update Process:**
   - Find the task by `task_id` in the database
   - Verify the task belongs to the authenticated user
   - Find the reminder by `reminder_id` within the task's reminders
   - Verify reminder exists and `sent` is `false`
   - Parse the `reminder_time` string to a datetime object
   - Convert to UTC if not already (iOS sends in user's timezone)
   - Update the reminder's `reminder_time` and `message` fields
   - Save changes to database
   - Return updated reminder data

4. **Scheduler Integration:**
   - If you have a scheduled job/task for this reminder, it needs to be rescheduled
   - Cancel the old scheduled job (if exists)
   - Create a new scheduled job with the updated `reminder_time`
   - Update any in-memory scheduler references

### 3. Example Python/Flask Implementation

```python
from flask import Blueprint, request, jsonify
from datetime import datetime, timezone
import pytz

reminders_bp = Blueprint('reminders', __name__)

@reminders_bp.route('/api/tasks/<task_id>/reminders/<reminder_id>', methods=['PUT'])
@require_auth  # Your Firebase auth decorator
def update_reminder(task_id, reminder_id):
    """Update a reminder's time and message"""

    # Get authenticated user
    user_id = get_user_id_from_token()

    # Get request data
    data = request.get_json()
    reminder_time_str = data.get('reminder_time')
    message = data.get('message')

    # Validate input
    if not reminder_time_str or not message:
        return jsonify({'error': 'reminder_time and message are required'}), 400

    if not message.strip():
        return jsonify({'error': 'message cannot be empty'}), 400

    # Parse reminder time
    try:
        # iOS sends ISO 8601 with timezone: "2025-10-17T15:30:00+02:00"
        reminder_time = datetime.fromisoformat(reminder_time_str.replace('Z', '+00:00'))

        # Convert to UTC for storage
        if reminder_time.tzinfo is None:
            # If no timezone info, assume UTC
            reminder_time = reminder_time.replace(tzinfo=timezone.utc)
        else:
            # Convert to UTC
            reminder_time = reminder_time.astimezone(timezone.utc)
    except ValueError:
        return jsonify({'error': 'Invalid reminder_time format. Use ISO 8601 format'}), 400

    # Validate reminder is in the future
    if reminder_time <= datetime.now(timezone.utc):
        return jsonify({'error': 'reminder_time must be in the future'}), 400

    # Get task from database
    task = db.collection('tasks').document(task_id).get()

    if not task.exists:
        return jsonify({'error': 'Task not found'}), 404

    task_data = task.to_dict()

    # Verify ownership
    if task_data.get('user_id') != user_id:
        return jsonify({'error': 'You don\'t have permission to update this reminder'}), 403

    # Find reminder in task's reminders
    reminders = task_data.get('reminders', [])
    reminder_index = None
    old_reminder = None

    for idx, rem in enumerate(reminders):
        if rem.get('id') == reminder_id:
            reminder_index = idx
            old_reminder = rem
            break

    if reminder_index is None:
        return jsonify({'error': 'Reminder not found'}), 404

    # Check if reminder was already sent
    if old_reminder.get('sent', False):
        return jsonify({'error': 'Cannot update a reminder that has already been sent'}), 400

    # Update reminder
    reminders[reminder_index]['reminder_time'] = reminder_time.isoformat()
    reminders[reminder_index]['message'] = message.strip()

    # Update in database
    db.collection('tasks').document(task_id).update({
        'reminders': reminders,
        'updated_at': datetime.now(timezone.utc)
    })

    # Reschedule the reminder job
    try:
        # Cancel old scheduled job
        scheduler.cancel_job(f"reminder_{task_id}_{reminder_id}")

        # Schedule new job
        scheduler.schedule_job(
            send_reminder,
            trigger='date',
            run_date=reminder_time,
            args=[task_id, reminder_id, user_id, message],
            id=f"reminder_{task_id}_{reminder_id}"
        )
    except Exception as e:
        print(f"Warning: Failed to reschedule reminder: {e}")
        # Continue anyway - reminder is updated in DB

    # Return updated reminder
    return jsonify({
        'message': 'Reminder updated successfully',
        'reminder': {
            'id': reminder_id,
            'task_id': task_id,
            'reminder_time': reminder_time.isoformat(),
            'message': message.strip(),
            'sent': False
        }
    }), 200
```

### 4. Testing Checklist

#### Unit Tests
- [ ] Test successful reminder update
- [ ] Test update with missing `reminder_time`
- [ ] Test update with missing `message`
- [ ] Test update with empty `message`
- [ ] Test update with invalid datetime format
- [ ] Test update with past datetime
- [ ] Test update for non-existent task
- [ ] Test update for non-existent reminder
- [ ] Test update without authentication
- [ ] Test update for task not owned by user
- [ ] Test update for already-sent reminder

#### Integration Tests
- [ ] Test full update flow from iOS app
- [ ] Test timezone conversion (user timezone to UTC)
- [ ] Test scheduler job rescheduling
- [ ] Test concurrent updates to same reminder
- [ ] Test database transaction rollback on error

#### Manual Testing
1. Create a task with a reminder via iOS app
2. Edit the reminder time to 5 minutes from now
3. Wait and verify reminder is sent at new time
4. Create another reminder and edit the message
5. Verify the new message appears when reminder is sent
6. Try to edit a sent reminder - should fail
7. Try to edit another user's reminder - should fail

### 5. Deployment Notes

1. **Database Migration:** No migration needed, existing schema supports this

2. **API Versioning:** This is a new endpoint, no breaking changes

3. **Backwards Compatibility:**
   - Existing delete reminder endpoint remains unchanged
   - iOS app will gracefully handle 404 if endpoint doesn't exist yet
   - Users on older app versions won't have the edit button

4. **Monitoring:**
   - Add logging for reminder update operations
   - Monitor error rates for 400/403/404 responses
   - Track scheduler job reschedule success rate
   - Alert if reminder update latency exceeds threshold

5. **Rate Limiting:**
   - Consider rate limiting: max 100 reminder updates per user per hour
   - Prevents abuse and excessive scheduler load

### 6. Security Considerations

1. **Authorization:**
   - Always verify task ownership before allowing updates
   - Never allow users to update other users' reminders

2. **Input Sanitization:**
   - Sanitize reminder message to prevent XSS (if messages are displayed in web UI)
   - Validate datetime format strictly
   - Limit message length (e.g., max 500 characters)

3. **Time Validation:**
   - Reject reminders more than 1 year in the future
   - Reject reminders in the past
   - Handle timezone attacks (malicious timezone data)

4. **Rate Limiting:**
   - Prevent spam by limiting update frequency
   - Use exponential backoff for repeated failed attempts

### 7. iOS App Integration

The iOS app has already been updated with:

1. **UI Changes:**
   - Edit button (pencil icon) appears next to delete button for unsent reminders
   - Edit sheet with DatePicker and TextField for reminder time and message
   - Success toast notification after successful update

2. **API Call:**
   - Endpoint: `PUT /api/tasks/{task_id}/reminders/{reminder_id}`
   - Headers: `Authorization: Bearer {token}`, `Content-Type: application/json`
   - Body: `{"reminder_time": "ISO8601 string", "message": "string"}`

3. **Files Modified:**
   - `TaskDetailView.swift`: Added EditReminderView and edit button
   - `BraindumpsterAPI.swift`: Added `updateReminder()` method
   - `Models.swift`: No changes needed

### 8. Additional Notes

- **Timezone Handling:** iOS sends reminder times in ISO 8601 format with timezone offset. Backend should store all times in UTC and convert when needed.

- **Sent Reminders:** Do not allow editing reminders where `sent = true`. This prevents confusion and maintains audit trail.

- **Future Enhancements:**
  - Add bulk update (update multiple reminders at once)
  - Add recurrence patterns (daily/weekly reminders)
  - Add snooze functionality for sent reminders
  - Add reminder templates

- **Performance:**
  - For tasks with many reminders (>50), consider pagination
  - Index task_id and reminder_id fields for faster lookups
  - Cache frequently accessed tasks in Redis

## Summary

This feature allows users to update existing reminders through the iOS app. The backend needs to:
1. Implement the `PUT /api/tasks/{task_id}/reminders/{reminder_id}` endpoint
2. Validate inputs (auth, ownership, reminder state, datetime format)
3. Update the reminder in the database
4. Reschedule the reminder job in the scheduler
5. Return the updated reminder data

The iOS implementation is complete and ready to integrate once the backend endpoint is available.
