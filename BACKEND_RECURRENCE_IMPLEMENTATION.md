# Backend Recurrence Implementation Guide

This document outlines the changes needed in the Python backend to support reminder recurrence and priority features.

## Overview

The iOS app now sends `recurrence` and `priority` fields when updating reminders. The backend needs to:
1. Accept these new fields in the reminder update endpoint
2. Store them in the database
3. Use them in the reminder scheduling system

## API Endpoint Changes

### Update Reminder Endpoint
**Endpoint:** `PUT /api/tasks/{task_id}/reminders/{reminder_id}`

#### Current Request Body:
```json
{
  "reminder_time": "2025-10-17T18:00:00+0300",
  "message": "Don't forget to review"
}
```

#### New Request Body (with optional fields):
```json
{
  "reminder_time": "2025-10-17T18:00:00+0300",
  "message": "Don't forget to review",
  "recurrence": "daily",  // Optional: "none", "daily", "weekly", "monthly"
  "priority": "high"      // Optional: "low", "normal", "high"
}
```

## Database Schema Changes

### Reminders Table
Add two new columns to the `reminders` table:

```sql
ALTER TABLE reminders
ADD COLUMN recurrence VARCHAR(20) DEFAULT 'none',
ADD COLUMN priority VARCHAR(20) DEFAULT 'normal';
```

**Field Details:**
- `recurrence`: VARCHAR(20), DEFAULT 'none'
  - Valid values: `'none'`, `'daily'`, `'weekly'`, `'monthly'`
  - Indicates if and how often the reminder should repeat

- `priority`: VARCHAR(20), DEFAULT 'normal'
  - Valid values: `'low'`, `'normal'`, `'high'`
  - Used for sorting and notification styling

## Python Backend Code Changes

### 1. Update the Reminder Model
Location: `models.py` or equivalent

```python
class Reminder:
    def __init__(self, ...):
        # Existing fields...
        self.recurrence = 'none'  # New field
        self.priority = 'normal'   # New field
```

### 2. Update the Update Reminder Endpoint
Location: `routes/tasks.py` or equivalent

```python
@app.route('/api/tasks/<task_id>/reminders/<reminder_id>', methods=['PUT'])
def update_reminder(task_id, reminder_id):
    # Get existing fields
    data = request.get_json()
    reminder_time = data.get('reminder_time')
    message = data.get('message')

    # Get new optional fields with defaults
    recurrence = data.get('recurrence', 'none')
    priority = data.get('priority', 'normal')

    # Validate recurrence
    valid_recurrence = ['none', 'daily', 'weekly', 'monthly']
    if recurrence not in valid_recurrence:
        return jsonify({'error': f'Invalid recurrence. Must be one of: {valid_recurrence}'}), 400

    # Validate priority
    valid_priority = ['low', 'normal', 'high']
    if priority not in valid_priority:
        return jsonify({'error': f'Invalid priority. Must be one of: {valid_priority}'}), 400

    # Update reminder in database
    cursor.execute('''
        UPDATE reminders
        SET reminder_time = ?,
            message = ?,
            recurrence = ?,
            priority = ?
        WHERE id = ? AND task_id = ?
    ''', (reminder_time, message, recurrence, priority, reminder_id, task_id))

    # If recurrence is set, schedule recurring reminders
    if recurrence != 'none':
        schedule_recurring_reminder(reminder_id, reminder_time, recurrence)

    return jsonify({'message': 'Reminder updated successfully'}), 200
```

### 3. Update the Create Reminder Endpoint
Don't forget to also update the create reminder endpoint to accept these fields:

```python
@app.route('/api/tasks/<task_id>/reminders', methods=['POST'])
def create_reminder(task_id):
    data = request.get_json()
    reminder_time = data.get('reminder_time')
    message = data.get('message')
    recurrence = data.get('recurrence', 'none')
    priority = data.get('priority', 'normal')

    # ... validation and creation logic
```

### 4. Implement Recurring Reminder Scheduler
Location: Create new file `scheduler.py` or add to existing scheduler

```python
def schedule_recurring_reminder(reminder_id, base_time, recurrence_type):
    """
    Schedule the next occurrence of a recurring reminder.
    This should be called after a reminder is sent.
    """
    from datetime import datetime, timedelta

    base_dt = datetime.fromisoformat(base_time)

    if recurrence_type == 'daily':
        next_time = base_dt + timedelta(days=1)
    elif recurrence_type == 'weekly':
        next_time = base_dt + timedelta(weeks=1)
    elif recurrence_type == 'monthly':
        # Handle month boundaries carefully
        next_time = base_dt + timedelta(days=30)  # Approximate, refine as needed
    else:
        return  # No recurrence

    # Update reminder_time in database for next occurrence
    cursor.execute('''
        UPDATE reminders
        SET reminder_time = ?,
            sent = FALSE
        WHERE id = ?
    ''', (next_time.isoformat(), reminder_id))

    return next_time
```

### 5. Update the Reminder Notification System
Location: Your notification/scheduler service

After sending a reminder notification, check if it's recurring:

```python
def send_reminder_notification(reminder_id):
    # Send the notification...

    # Get reminder details
    cursor.execute('SELECT recurrence, reminder_time FROM reminders WHERE id = ?', (reminder_id,))
    reminder = cursor.fetchone()

    if reminder['recurrence'] != 'none':
        # Schedule next occurrence
        schedule_recurring_reminder(reminder_id, reminder['reminder_time'], reminder['recurrence'])
    else:
        # Mark as sent for non-recurring reminders
        cursor.execute('UPDATE reminders SET sent = TRUE WHERE id = ?', (reminder_id,))
```

### 6. Update GET Endpoints
Make sure reminder GET endpoints return the new fields:

```python
@app.route('/api/tasks/user/<user_id>', methods=['GET'])
def get_user_tasks(user_id):
    # ... existing code ...

    # When serializing reminders, include new fields:
    reminders_data = [{
        'id': r['id'],
        'reminder_time': r['reminder_time'],
        'message': r['message'],
        'sent': r['sent'],
        'recurrence': r.get('recurrence', 'none'),    # New field
        'priority': r.get('priority', 'normal')        # New field
    } for r in reminders]
```

## Testing

### Test Cases

1. **Create reminder with recurrence:**
```bash
curl -X POST http://57.129.81.193:5001/api/tasks/{task_id}/reminders \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "reminder_time": "2025-10-18T09:00:00+0300",
    "message": "Daily standup",
    "recurrence": "daily",
    "priority": "high"
  }'
```

2. **Update reminder with recurrence:**
```bash
curl -X PUT http://57.129.81.193:5001/api/tasks/{task_id}/reminders/{reminder_id} \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "reminder_time": "2025-10-18T18:00:00+0300",
    "message": "Evening review",
    "recurrence": "weekly",
    "priority": "normal"
  }'
```

3. **Validate error handling:**
```bash
# Invalid recurrence value
curl -X PUT http://57.129.81.193:5001/api/tasks/{task_id}/reminders/{reminder_id} \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "reminder_time": "2025-10-18T18:00:00+0300",
    "message": "Test",
    "recurrence": "invalid_value"
  }'

# Expected response: 400 Bad Request with error message
```

## Migration Steps

1. **Backup the database** before making schema changes
2. **Add new columns** with default values to existing reminders table
3. **Update Python models** to include new fields
4. **Update API endpoints** to accept and return new fields
5. **Implement scheduler logic** for recurring reminders
6. **Update notification service** to handle recurrence
7. **Test thoroughly** with curl commands
8. **Deploy** and monitor logs

## Notes

- The iOS app sends recurrence as optional parameters, so existing reminders will default to `'none'` and `'normal'`
- Consider timezone handling carefully for recurring reminders
- For monthly recurrence, handle edge cases (e.g., January 31 -> February 28/29)
- Consider adding a `recurring_parent_id` field if you want to track which reminders were generated from the same source
- Priority can be used in the future for:
  - Notification styling (different colors/sounds)
  - Sorting in the reminder queue
  - Analytics and reporting

## Future Enhancements

1. **Custom recurrence patterns**: "Every 2 weeks", "Every 3rd Monday"
2. **End conditions**: "Repeat until date X" or "Repeat N times"
3. **Pause/Resume**: Allow users to temporarily disable recurring reminders
4. **Recurrence history**: Track all occurrences of a recurring reminder
