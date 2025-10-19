# Backend Implementation Guide for iOS UX/UI Updates

## Overview
This guide outlines the backend changes needed to support the new iOS features implemented in the Braindumpster app.

---

## ✅ Already Working (No Backend Changes Needed)

These features work entirely on the iOS side:
- ✅ Confetti animations
- ✅ Toast notifications
- ✅ Color palette/design system
- ✅ Empty states
- ✅ Error handling improvements
- ✅ Accessibility labels
- ✅ Haptic feedback

---

## 🔧 Backend Changes Required

### 1. **Update Task Endpoint (REQUIRED for Snooze Feature)**

The snooze feature needs the ability to update a task's `due_date` and `time` fields.

#### Current Endpoint:
```python
PUT /tasks/{task_id}
```

#### Currently Only Supports:
- `status` field updates

#### Needs to Support:
```json
{
  "due_date": "2025-10-12",  // Optional
  "time": "3:00 PM",          // Optional
  "title": "Updated title",   // Optional
  "description": "Updated",   // Optional
  "priority": "high"          // Optional
}
```

#### Python Implementation Example:

```python
# In your Flask/FastAPI backend

@app.route('/tasks/<task_id>', methods=['PUT'])
@require_auth  # Your auth decorator
def update_task(task_id):
    """Update task fields"""
    user_id = get_current_user_id()  # From auth token
    data = request.get_json()

    # Get the task
    task = db.tasks.find_one({
        '_id': ObjectId(task_id),
        'user_id': user_id
    })

    if not task:
        return jsonify({'error': 'Task not found'}), 404

    # Build update dict with only provided fields
    update_fields = {}

    if 'due_date' in data:
        update_fields['due_date'] = data['due_date']

    if 'time' in data:
        update_fields['time'] = data['time']

    if 'title' in data:
        update_fields['title'] = data['title']

    if 'description' in data:
        update_fields['description'] = data['description']

    if 'priority' in data:
        update_fields['priority'] = data['priority']

    if 'status' in data:  # Keep existing status update
        update_fields['status'] = data['status']

    # Update in database
    db.tasks.update_one(
        {'_id': ObjectId(task_id)},
        {'$set': update_fields}
    )

    return jsonify({
        'success': True,
        'task_id': task_id,
        'updated_fields': list(update_fields.keys())
    }), 200
```

---

### 2. **Friendly Notification Messages (RECOMMENDED)**

Update your notification sending code to use the friendly messages from `NotificationCopyGuide.swift`.

#### Current Notifications (Example):
```python
# ❌ Old technical style
notification = {
    'title': 'Task Reminder',
    'body': f'Task {task_title} is due at {time}'
}
```

#### New Friendly Notifications:
```python
# ✅ New friendly style
notification_templates = {
    'task_due_soon': {
        'title': 'Heads up! 👋',
        'body': '{task_title} is due in 15 minutes'
    },
    'task_due_now': {
        'title': 'Time to act! ⏰',
        'body': '{task_title} is due now'
    },
    'task_overdue': {
        'title': 'Hey, don\'t forget! 🔔',
        'body': '{task_title} needs your attention'
    },
    'daily_morning': {
        'title': 'Good morning! ☀️',
        'body': 'You have {count} tasks today. Let\'s crush them!'
    },
    'streak_at_risk': {
        'title': 'Don\'t break the streak! 🔥',
        'body': 'Complete one task to keep your {streak_days} day streak alive'
    },
    'all_complete': {
        'title': 'All done! Time to chill 😎',
        'body': 'Every task is checked off. You earned a break!'
    }
}

def send_notification(user_id, template_name, **kwargs):
    """Send notification with friendly message"""
    template = notification_templates.get(template_name)
    if not template:
        return

    # Format template with provided values
    title = template['title'].format(**kwargs)
    body = template['body'].format(**kwargs)

    # Send via Firebase
    message = messaging.Message(
        notification=messaging.Notification(
            title=title,
            body=body
        ),
        data={
            'action': kwargs.get('action', 'open_dashboard'),
            'task_id': kwargs.get('task_id', '')
        },
        token=get_fcm_token(user_id)
    )

    messaging.send(message)
```

#### Usage Examples:
```python
# Task due soon
send_notification(
    user_id='123',
    template_name='task_due_soon',
    task_title='Buy groceries',
    action='open_task',
    task_id='task_456'
)

# Daily morning summary
send_notification(
    user_id='123',
    template_name='daily_morning',
    count=5,
    action='open_dashboard'
)

# Streak at risk
send_notification(
    user_id='123',
    template_name='streak_at_risk',
    streak_days=7,
    action='open_dashboard'
)
```

---

### 3. **Streak Tracking (OPTIONAL - Currently Client-Side Only)**

The iOS app tracks streaks locally using UserDefaults. For a better experience, you can optionally track this on the backend.

#### Benefits of Backend Tracking:
- Sync across devices
- More accurate tracking
- Analytics and insights
- Milestone notifications

#### Implementation (Optional):
```python
# Add to your User model
class User:
    current_streak: int = 0
    longest_streak: int = 0
    last_completion_date: date = None

@app.route('/tasks/<task_id>/complete', methods=['POST'])
@require_auth
def complete_task(task_id):
    user_id = get_current_user_id()

    # Mark task complete
    update_task_status(task_id, 'completed')

    # Update streak
    user = get_user(user_id)
    today = date.today()

    if user.last_completion_date == today:
        # Already completed a task today
        pass
    elif user.last_completion_date == today - timedelta(days=1):
        # Consecutive day - increase streak
        user.current_streak += 1
        user.last_completion_date = today

        # Check for milestone
        if user.current_streak in [3, 7, 14, 30, 60, 100]:
            send_notification(
                user_id=user_id,
                template_name='streak_milestone',
                streak_days=user.current_streak
            )
    else:
        # Streak broken - reset
        user.current_streak = 1
        user.last_completion_date = today

    # Update longest streak
    if user.current_streak > user.longest_streak:
        user.longest_streak = user.current_streak

    save_user(user)

    return jsonify({
        'success': True,
        'streak': user.current_streak
    })
```

---

## 📋 Quick Checklist

### Required (for full functionality):
- [ ] **Update Task Endpoint** - Modify `PUT /tasks/{task_id}` to accept `due_date`, `time`, `title`, `description`, `priority`

### Recommended (for better UX):
- [ ] **Friendly Notifications** - Update notification messages to use friendly copy
- [ ] **Notification Frequency Limits** - Max 1 motivation notification per week, 1 come-back nudge per 3 days
- [ ] **Quiet Hours** - Respect quiet hours (default 10 PM - 8 AM), only send urgent during quiet time

### Optional (for enhanced features):
- [ ] **Backend Streak Tracking** - Track streaks server-side for cross-device sync
- [ ] **Streak Milestones** - Send notifications when milestones are reached
- [ ] **Weekly Summary** - Send weekly progress notifications

---

## 🧪 Testing the Changes

### Test Update Task Endpoint:
```bash
# Test snooze functionality
curl -X PUT https://your-api.com/tasks/TASK_ID \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "due_date": "2025-10-12",
    "time": "3:00 PM"
  }'

# Expected response:
# {
#   "success": true,
#   "task_id": "TASK_ID",
#   "updated_fields": ["due_date", "time"]
# }
```

### Test Notification Messages:
1. Trigger a task reminder
2. Verify the message is friendly (e.g., "Heads up! 👋" not "Task Reminder")
3. Check that emojis render correctly
4. Verify deep linking works (tapping opens correct screen)

---

## 📊 Monitoring

### Key Metrics to Track:
- **Notification open rates** - Did friendly copy improve engagement?
- **Snooze usage** - How often do users snooze tasks?
- **Streak retention** - What % of users maintain streaks?
- **Error rates** - Monitor 400/500 errors on update endpoint

### Logging Recommendations:
```python
# Log important events
logger.info(f"Task {task_id} snoozed by user {user_id} to {due_date} {time}")
logger.info(f"User {user_id} reached {streak_days} day streak milestone")
logger.info(f"Notification sent: {template_name} to user {user_id}")
```

---

## 🐛 Troubleshooting

### Common Issues:

**Issue**: Snooze not working
- **Check**: Is `PUT /tasks/{task_id}` accepting `due_date` and `time` fields?
- **Fix**: Update backend to accept these optional fields

**Issue**: Notifications still technical
- **Check**: Are you using the new templates?
- **Fix**: Update notification sending code to use friendly messages

**Issue**: Streak not syncing across devices
- **Check**: Is streak tracked server-side?
- **Fix**: Implement backend streak tracking (optional section above)

---

## 📞 Support

If you need help implementing any of these changes:
1. Check the inline code examples above
2. Review the NotificationCopyGuide.swift file for all message templates
3. Test each endpoint individually before full integration

---

## Summary

**✅ iOS Side: Complete** - All UI/UX features implemented
**🔧 Backend Side: 1 Required Change** - Update task endpoint to support snooze
**💡 Backend Side: Recommended** - Update notification messages to be friendly
**🌟 Backend Side: Optional** - Add server-side streak tracking
