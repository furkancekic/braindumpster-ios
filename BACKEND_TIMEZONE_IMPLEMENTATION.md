# 🌍 BACKEND TIMEZONE İMPLEMENTASYONU

## Backend Klasörü: `/Users/furkancekic/projects/reminder_app_new/braindumpster_python`

---

## ✅ iOS TARAFINDA YAPILDI

1. ✅ **TimezoneService.swift** oluşturuldu - Kullanıcının timezone bilgisini toplar
2. ✅ **AuthService.swift** güncellendi - Sign in/sign up sonrası timezone gönderir
3. ✅ **BraindumpsterAPI.swift** güncellendi - `/auth/update-timezone` endpoint'i eklen di

---

## 🔧 BACKEND'DE YAPILACAKLAR

### 1️⃣ ÖNCE: Timezone Validation Ekle

**Dosya:** `/services/validation.py` (yoksa oluştur) veya mevcut validation dosyasında

```python
# Timezone validation function
def validate_timezone(timezone_str):
    """Validate timezone identifier"""
    import pytz
    try:
        pytz.timezone(timezone_str)
        return True
    except pytz.exceptions.UnknownTimeZoneError:
        return False
```

---

### 2️⃣ AUTH ROUTE: User Timezone Update Endpoint

**Dosya:** `/routes/auth.py` (veya auth ile ilgili route dosyası)

**Eklenecek Endpoint:**

```python
@auth_bp.route('/update-timezone', methods=['POST'])
@require_auth  # Firebase auth decorator
def update_user_timezone():
    """Update user's timezone information"""
    logger = get_logger()

    try:
        data = request.get_json()
        user_id = request.user_id  # From require_auth decorator

        # Get timezone info from request
        user_timezone = data.get('userTimezone')  # "Europe/Brussels"
        timezone_offset = data.get('timezoneOffset')  # 3600 (seconds)
        timezone_abbrev = data.get('timezoneAbbreviation')  # "CET"
        current_local_time = data.get('currentLocalTime')  # "2025-10-16T15:30:00+01:00"

        # Validate
        if not user_timezone:
            return jsonify({"error": "userTimezone is required"}), 400

        # Validate timezone
        import pytz
        try:
            pytz.timezone(user_timezone)
        except pytz.exceptions.UnknownTimeZoneError:
            return jsonify({"error": f"Invalid timezone: {user_timezone}"}), 400

        logger.info(f"🌍 Updating timezone for user {user_id}")
        logger.info(f"   Timezone: {user_timezone}")
        logger.info(f"   Offset: {timezone_offset / 3600 if timezone_offset else 'N/A'} hours")
        logger.info(f"   Local time: {current_local_time}")

        # Update Firestore user document
        firebase_service = current_app.firebase_service
        db = firebase_service.db

        user_ref = db.collection('users').document(user_id)
        user_ref.update({
            'timezone': user_timezone,
            'timezoneOffset': timezone_offset,
            'timezoneAbbreviation': timezone_abbrev,
            'lastTimezoneUpdate': firestore.SERVER_TIMESTAMP
        })

        logger.info(f"✅ Timezone updated successfully for user {user_id}")

        return jsonify({
            "success": True,
            "message": "Timezone updated successfully",
            "timezone": user_timezone
        }), 200

    except Exception as e:
        logger.error(f"❌ Error updating timezone: {e}")
        return jsonify({"error": str(e)}), 500
```

---

### 3️⃣ TASK CREATION: Timezone Context Ekle

**Dosya:** `/routes/tasks.py`

**Satır 161-260 arası `create_tasks()` fonksiyonunda değişiklik:**

**Mevcut kod:** Satır 170 civarı
```python
data = request.get_json()
```

**Sonrasına ekle:**

```python
# Get user's timezone from Firestore
firebase_service = current_app.firebase_service
db = firebase_service.db
user_ref = db.collection('users').document(user_id).get()

if user_ref.exists:
    user_data = user_ref.to_dict()
    user_timezone = user_data.get('timezone', 'UTC')
    logger.info(f"🌍 User timezone: {user_timezone}")
else:
    user_timezone = 'UTC'
    logger.warning(f"⚠️ User timezone not found, defaulting to UTC")

# Add timezone to data for Gemini processing
data['userTimezone'] = user_timezone
```

---

### 4️⃣ GEMINI SERVICE: Timezone Context

**Dosya:** `/services/gemini_service.py`

Gemini'ye gönderi len prompt'a timezone ekle:

**Fonksiyon bulun** (muhtemelen `generate_tasks()` veya `process_audio()`)

**Prompt'a eklenecek:**

```python
def build_gemini_prompt(user_input, user_timezone='UTC'):
    """Build Gemini prompt with timezone context"""

    # Get current time in user's timezone
    from datetime import datetime
    import pytz

    user_tz = pytz.timezone(user_timezone)
    current_time_user = datetime.now(user_tz)

    prompt = f"""
You are a task management assistant.

IMPORTANT CONTEXT:
- User's timezone: {user_timezone}
- User's current local time: {current_time_user.strftime('%Y-%m-%d %H:%M %A')}
- Current day for user: {current_time_user.strftime('%A')}

USER INPUT: "{user_input}"

TASK:
1. Extract task title, description, and reminder time
2. If user mentions time (e.g., "tomorrow at 9am", "tonight", "next Monday 3pm"):
   - Calculate the exact date/time in USER'S timezone ({user_timezone})
   - Return in format: "YYYY-MM-DD HH:MM"
3. If no time mentioned, set reminderTime to null

EXAMPLES:
- "Remind me tomorrow at 9am" → reminderTime: "{(current_time_user + timedelta(days=1)).strftime('%Y-%m-%d')} 09:00"
- "Call mom tonight at 8" → reminderTime: "{current_time_user.strftime('%Y-%m-%d')} 20:00"

Return JSON:
{{
  "title": "Task title",
  "description": "Task description",
  "reminderTime": "YYYY-MM-DD HH:MM" or null,
  "timezone": "{user_timezone}"
}}
"""

    return prompt
```

---

### 5️⃣ TASK STORAGE: UTC'ye Çevir

**Dosya:** `/routes/tasks.py`

**Satır 250-260 civarı reminder işleme kısmında:**

**Mevcut kod:**
```python
reminder_time_str = reminder_data['reminder_time']
if isinstance(reminder_time_str, str):
    if reminder_time_str.endswith('Z'):
        reminder_time_str = reminder_time_str[:-1] + '+00:00'
    reminder_time = datetime.fromisoformat(reminder_time_str)
```

**Değiştir:**

```python
from datetime import datetime, timezone
import pytz

reminder_time_str = reminder_data['reminder_time']

# Get user's timezone (from earlier in function)
user_timezone = data.get('userTimezone', 'UTC')

if isinstance(reminder_time_str, str):
    # Parse reminder time
    if reminder_time_str.endswith('Z'):
        reminder_time_str = reminder_time_str[:-1] + '+00:00'

    # If time has timezone info, use it
    if '+' in reminder_time_str or reminder_time_str.endswith('Z'):
        reminder_time = datetime.fromisoformat(reminder_time_str)
    else:
        # No timezone info - assume user's timezone
        reminder_naive = datetime.fromisoformat(reminder_time_str)
        user_tz = pytz.timezone(user_timezone)
        reminder_time = user_tz.localize(reminder_naive)

    # Convert to UTC for storage
    reminder_time_utc = reminder_time.astimezone(timezone.utc)

    logger.info(f"⏰ Reminder time:")
    logger.info(f"   Original: {reminder_time_str}")
    logger.info(f"   User local: {reminder_time.isoformat()}")
    logger.info(f"   UTC (stored): {reminder_time_utc.isoformat()}")

    # Use UTC time for storage
    reminder_time = reminder_time_utc
```

---

### 6️⃣ SCHEDULER: UTC'de Çalıştır

**Dosya:** `/services/scheduler_service.py` veya `/services/reminder_scheduler.py`

**UYARI:** Scheduler HER ZAMAN UTC kullanmalı!

**Mevcut kod değiştir:**

```python
# ❌ YANLIŞ
def check_reminders():
    now = datetime.now()  # Server local time
```

**DOĞRU:**

```python
# ✅ DOĞRU
from datetime import datetime, timezone

def check_reminders():
    """Check for reminders to send (ALWAYS use UTC)"""

    # ALWAYS use UTC for scheduler
    now_utc = datetime.now(timezone.utc)

    logger.info(f"🕐 Checking reminders at UTC: {now_utc.isoformat()}")
    logger.debug(f"   Server local time: {datetime.now().isoformat()} (IGNORED)")

    # Query tasks with reminder <= now_utc
    # (Database'deki tüm zamanlar zaten UTC)
    tasks_to_remind = db.collection('tasks').where(
        'reminder_time', '<=', now_utc
    ).where(
        'reminder_sent', '==', False
    ).get()

    for task_doc in tasks_to_remind:
        task = task_doc.to_dict()

        # Get user's timezone
        user_id = task.get('user_id')
        user_doc = db.collection('users').document(user_id).get()
        user_timezone = 'UTC'

        if user_doc.exists:
            user_data = user_doc.to_dict()
            user_timezone = user_data.get('timezone', 'UTC')

        # Convert UTC time to user's local time (for display only)
        import pytz
        reminder_utc = task['reminder_time']
        user_tz = pytz.timezone(user_timezone)
        reminder_local = reminder_utc.astimezone(user_tz)

        # Send notification
        send_notification(
            user_id=user_id,
            title=task['title'],
            body=f"Reminder at {reminder_local.strftime('%H:%M')}"
        )

        # Mark as sent
        task_doc.reference.update({'reminder_sent': True})

        logger.info(f"✅ Sent reminder:")
        logger.info(f"   Task: {task['title']}")
        logger.info(f"   UTC time: {reminder_utc.isoformat()}")
        logger.info(f"   User local time: {reminder_local.strftime('%Y-%m-%d %H:%M %Z')}")
        logger.info(f"   User timezone: {user_timezone}")
```

---

### 7️⃣ APP BAŞLANGIÇTA TIMEZONE KONTROLÜ

**Dosya:** `/app.py` veya `start_production.py`

**create_app() fonksiyonunun başında ekle:**

```python
def create_app(config_name=None):
    # ... existing code ...

    # Validate timezone setup
    validate_timezone_setup()

    # ... rest of code ...

def validate_timezone_setup():
    """Validate server and application timezone configuration"""
    import time
    from datetime import datetime, timezone

    logger = logging.getLogger('braindumpster.timezone')

    logger.info("\n" + "="*60)
    logger.info("🌍 TIMEZONE VALIDATION")
    logger.info("="*60)

    # Server timezone
    logger.info(f"🖥️  Server timezone: {time.tzname}")
    logger.info(f"🖥️  Server local time: {datetime.now().isoformat()}")

    # UTC time
    utc_now = datetime.now(timezone.utc)
    logger.info(f"🌍 UTC time: {utc_now.isoformat()}")

    # Calculate offset
    local_now = datetime.now()
    offset = (local_now - utc_now.replace(tzinfo=None)).total_seconds() / 3600
    logger.info(f"⚠️  Server UTC offset: {offset:+.1f} hours")

    # Warn if not UTC
    if abs(offset) > 0:
        logger.warning(f"\n⚠️  WARNING: Server is NOT in UTC timezone!")
        logger.warning(f"   This is OK - scheduler uses UTC internally.")
        logger.warning(f"   All database times are stored in UTC.")
        logger.warning(f"   Server offset will be IGNORED in all operations.")
    else:
        logger.info(f"\n✅ Server is in UTC timezone (ideal)")

    logger.info("="*60 + "\n")
```

---

## 📊 DATABASE SCHEMA

### Firestore Users Collection

```json
{
  "users": {
    "<user_id>": {
      "email": "user@example.com",
      "displayName": "User Name",
      "timezone": "Europe/Brussels",
      "timezoneOffset": 3600,
      "timezoneAbbreviation": "CET",
      "lastTimezoneUpdate": "2025-10-16T14:30:00Z",
      "createdAt": "2025-01-01T00:00:00Z"
    }
  }
}
```

### Firestore Tasks Collection

```json
{
  "tasks": {
    "<task_id>": {
      "title": "Meeting",
      "user_id": "<user_id>",
      "reminder_time": "2025-10-17T08:00:00Z",  // ← ALWAYS UTC!
      "user_timezone": "Europe/Brussels",        // ← Reference only
      "reminder_sent": false,
      "createdAt": "2025-10-16T14:00:00Z"       // ← ALWAYS UTC!
    }
  }
}
```

---

## ✅ KONTROL LİSTESİ

Backend developer şunları yapmalı:

```
☐ 1. /routes/auth.py → /update-timezone endpoint ekle
☐ 2. /routes/tasks.py → Task oluştururken user timezone al
☐ 3. /services/gemini_service.py → Prompt'a timezone context ekle
☐ 4. /routes/tasks.py → Reminder time'ı UTC'ye çevir
☐ 5. /services/scheduler_service.py → datetime.now(timezone.utc) kullan
☐ 6. /app.py → validate_timezone_setup() ekle ve çağır
☐ 7. Test: iOS'tan timezone gönder, backend'de UTC'ye çevirildiğini kontrol et
☐ 8. Test: Scheduler'ın UTC'de çalıştığını kontrol et
```

---

## 🧪 TEST SENARYOSU

### Test 1: Timezone Update

```bash
# iOS'tan gönderilecek
POST /api/auth/update-timezone
Authorization: Bearer <firebase_token>
Content-Type: application/json

{
  "userTimezone": "Europe/Brussels",
  "timezoneOffset": 3600,
  "timezoneAbbreviation": "CET",
  "currentLocalTime": "2025-10-16T15:30:00+01:00"
}

# Beklenen response:
{
  "success": true,
  "message": "Timezone updated successfully",
  "timezone": "Europe/Brussels"
}
```

### Test 2: Task Creation

```python
# Senaryo: Belçikalı kullanıcı "Yarın saat 9'da toplantı"
# User timezone: Europe/Brussels (UTC+1)
# Gemini return: "2025-10-17 09:00"
# Backend convert: "2025-10-17 09:00" (Brussels) → "2025-10-17 08:00Z" (UTC)
# Database store: "2025-10-17T08:00:00Z"
```

### Test 3: Scheduler

```python
# Scheduler çalışır: UTC 08:00 olduğunda
# Database'den al: "2025-10-17T08:00:00Z"
# User timezone: Europe/Brussels
# Convert to local: "2025-10-17 09:00" (Brussels)
# Bildirim gönder: "Reminder at 09:00"
```

---

## 🚨 ÖNEMLİ UYARILAR

1. **HER ZAMAN UTC KULLAN**
   - Database'de: UTC
   - Scheduler'da: UTC
   - API response'da: UTC (veya ISO 8601 with timezone)

2. **ASLA SERVER LOCAL TIME KULLANMA**
   ```python
   datetime.now()  # ❌ ASLA!
   datetime.now(timezone.utc)  # ✅ HER ZAMAN
   ```

3. **TIMEZONE ÇEVİRME KURALI**
   - iOS → Backend: ISO 8601 with timezone
   - Backend → Database: UTC
   - Database → Scheduler: UTC
   - Scheduler → Notification: User's timezone (display only)

---

## 📞 İLETİŞİM

Sorular veya sorunlar için:
- iOS değişiklikleri: `/Users/furkancekic/projects/last_tasks/`
- Backend klasörü: `/Users/furkancekic/projects/reminder_app_new/braindumpster_python/`

---

**SON:** Bu implementasyon ile Belçika, Amerika, Türkiye veya dünyanın herhangi bir yerinden kullanıcı doğru zamanda bildirim alacak! 🌍⏰
