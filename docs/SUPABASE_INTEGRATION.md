# DiaCare Supabase Integration Documentation

## Overview

This document describes the complete Supabase integration for the DiaCare diabetes management application. The integration replaces the local SQLite database with Supabase's PostgreSQL backend while maintaining offline preferences via SharedPreferences.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Database Schema](#database-schema)
3. [Authentication Model](#authentication-model)
4. [Row Level Security (RLS)](#row-level-security-rls)
5. [Integration Points](#integration-points)
6. [Migration Guide](#migration-guide)
7. [Environment Setup](#environment-setup)

---

## Architecture Overview

### Before (SQLite)

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter App                               │
├─────────────────────────────────────────────────────────────┤
│                    DataService                               │
├─────────────────────────────────────────────────────────────┤
│     DatabaseHelper (SQLite)    │    PreferencesService      │
│     - Users                    │    - Theme                  │
│     - Glucose readings         │    - Locale                 │
│     - Health cards             │    - Units                  │
│     - Reminders                │    - Session                │
│     - Diabetic profiles        │                             │
└─────────────────────────────────────────────────────────────┘
```

### After (Supabase)

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter App                               │
├─────────────────────────────────────────────────────────────┤
│                    DataService                               │
├─────────────────────────────────────────────────────────────┤
│     SupabaseService            │    PreferencesService      │
│     (PostgreSQL + Auth)        │    (Local Cache)           │
├─────────────────────────────────────────────────────────────┤
│                    Supabase Cloud                            │
│     ┌─────────────────────────────────────────────────────┐ │
│     │  auth.users (Supabase Auth)                          │ │
│     │  ↓                                                    │ │
│     │  profiles ← diabetic_profiles                        │ │
│     │  ↓                                                    │ │
│     │  glucose_readings                                     │ │
│     │  health_cards                                         │ │
│     │  reminders                                            │ │
│     │  user_preferences                                     │ │
│     └─────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## Database Schema

### Entity Relationship Diagram

```
┌─────────────────┐
│   auth.users    │  (Supabase managed)
│─────────────────│
│ id (UUID) PK    │
│ email           │
│ encrypted_pass  │
└────────┬────────┘
         │ 1:1
         ▼
┌─────────────────┐
│    profiles     │
│─────────────────│
│ id (UUID) PK/FK │──────────────────────────────────────────┐
│ email           │                                          │
│ username        │                                          │
│ full_name       │                                          │
│ date_of_birth   │                                          │
│ gender          │                                          │
│ height          │                                          │
│ weight          │                                          │
│ created_at      │                                          │
│ updated_at      │                                          │
└────────┬────────┘                                          │
         │ 1:1                                               │
         ▼                                                   │
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│diabetic_profiles│    │ glucose_readings│    │  health_cards   │
│─────────────────│    │─────────────────│    │─────────────────│
│ id (UUID) PK    │    │ id (UUID) PK    │    │ id (UUID) PK    │
│ user_id FK      │←───│ user_id FK      │←───│ user_id FK      │
│ diabetic_type   │    │ value           │    │ card_type       │
│ treatment_type  │    │ unit            │    │ value           │
│ min_glucose     │    │ reading_type    │    │ unit            │
│ max_glucose     │    │ notes           │    │ recorded_date   │
│ diagnosis_date  │    │ recorded_at     │    │ created_at      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │
         │ 1:N
         ▼
┌─────────────────┐    ┌─────────────────┐
│    reminders    │    │user_preferences │
│─────────────────│    │─────────────────│
│ id (UUID) PK    │    │ id (UUID) PK    │
│ user_id FK      │    │ user_id FK      │
│ title           │    │ theme           │
│ reminder_type   │    │ locale          │
│ scheduled_time  │    │ units           │
│ is_enabled      │    │ notifications   │
│ is_recurring    │    │ biometric       │
│ status          │    │ onboarding      │
└─────────────────┘    └─────────────────┘
```

### Table Specifications

#### profiles

| Column            | Type         | Constraints                                |
| ----------------- | ------------ | ------------------------------------------ |
| id                | UUID         | PK, FK → auth.users, CASCADE DELETE        |
| email             | TEXT         | UNIQUE, NOT NULL                           |
| username          | TEXT         | NOT NULL                                   |
| full_name         | TEXT         | DEFAULT ''                                 |
| profile_image_url | TEXT         | NULLABLE                                   |
| date_of_birth     | DATE         | NULLABLE                                   |
| gender            | TEXT         | CHECK IN ('Male', 'Female', 'Other', NULL) |
| height            | DECIMAL(5,2) | NULLABLE                                   |
| weight            | DECIMAL(5,2) | NULLABLE                                   |
| created_at        | TIMESTAMPTZ  | DEFAULT NOW()                              |
| updated_at        | TIMESTAMPTZ  | DEFAULT NOW()                              |

#### diabetic_profiles

| Column         | Type        | Constraints                                                           |
| -------------- | ----------- | --------------------------------------------------------------------- |
| id             | UUID        | PK, DEFAULT uuid_generate_v4()                                        |
| user_id        | UUID        | FK → profiles, CASCADE DELETE, UNIQUE                                 |
| diabetic_type  | TEXT        | CHECK IN ('Type 1', 'Type 2', 'Gestational', 'Prediabetes', 'Other')  |
| treatment_type | TEXT        | CHECK IN ('Insulin', 'Medication', 'Diet', 'Exercise', 'Combination') |
| min_glucose    | INTEGER     | CHECK 0-500, DEFAULT 70                                               |
| max_glucose    | INTEGER     | CHECK 0-500, DEFAULT 180                                              |
| diagnosis_date | DATE        | NULLABLE                                                              |
| created_at     | TIMESTAMPTZ | DEFAULT NOW()                                                         |
| updated_at     | TIMESTAMPTZ | DEFAULT NOW()                                                         |

#### glucose_readings

| Column       | Type         | Constraints                                                            |
| ------------ | ------------ | ---------------------------------------------------------------------- |
| id           | UUID         | PK, DEFAULT uuid_generate_v4()                                         |
| user_id      | UUID         | FK → profiles, CASCADE DELETE                                          |
| value        | DECIMAL(6,2) | NOT NULL, CHECK 0-1000                                                 |
| unit         | TEXT         | CHECK IN ('mg/dL', 'mmol/L'), DEFAULT 'mg/dL'                          |
| reading_type | TEXT         | CHECK IN ('fasting', 'before_meal', 'after_meal', 'bedtime', 'random') |
| notes        | TEXT         | NULLABLE                                                               |
| recorded_at  | TIMESTAMPTZ  | NOT NULL, DEFAULT NOW()                                                |
| created_at   | TIMESTAMPTZ  | DEFAULT NOW()                                                          |

#### health_cards

| Column        | Type                                | Constraints                                                 |
| ------------- | ----------------------------------- | ----------------------------------------------------------- |
| id            | UUID                                | PK, DEFAULT uuid_generate_v4()                              |
| user_id       | UUID                                | FK → profiles, CASCADE DELETE                               |
| card_type     | TEXT                                | CHECK IN ('water', 'pills', 'activity', 'carbs', 'insulin') |
| value         | DECIMAL(10,2)                       | NOT NULL, CHECK >= 0                                        |
| unit          | TEXT                                | NOT NULL                                                    |
| recorded_date | DATE                                | NOT NULL, DEFAULT CURRENT_DATE                              |
| created_at    | TIMESTAMPTZ                         | DEFAULT NOW()                                               |
| **UNIQUE**    | (user_id, card_type, recorded_date) |                                                             |

#### reminders

| Column             | Type        | Constraints                                                               |
| ------------------ | ----------- | ------------------------------------------------------------------------- |
| id                 | UUID        | PK, DEFAULT uuid_generate_v4()                                            |
| user_id            | UUID        | FK → profiles, CASCADE DELETE                                             |
| title              | TEXT        | NOT NULL                                                                  |
| description        | TEXT        | NULLABLE                                                                  |
| reminder_type      | TEXT        | CHECK IN ('medication', 'glucose', 'water', 'exercise', 'meal', 'custom') |
| scheduled_time     | TIME        | NOT NULL                                                                  |
| is_enabled         | BOOLEAN     | DEFAULT TRUE                                                              |
| is_recurring       | BOOLEAN     | DEFAULT FALSE                                                             |
| recurrence_pattern | TEXT        | CHECK IN ('hourly', 'daily', 'weekly', 'monthly', NULL)                   |
| status             | TEXT        | CHECK IN ('pending', 'done', 'not_done', 'skipped', 'completed')          |
| completed_at       | TIMESTAMPTZ | NULLABLE                                                                  |
| created_at         | TIMESTAMPTZ | DEFAULT NOW()                                                             |
| updated_at         | TIMESTAMPTZ | DEFAULT NOW()                                                             |

#### user_preferences

| Column                | Type        | Constraints                                           |
| --------------------- | ----------- | ----------------------------------------------------- |
| id                    | UUID        | PK, DEFAULT uuid_generate_v4()                        |
| user_id               | UUID        | FK → profiles, CASCADE DELETE, UNIQUE                 |
| theme                 | TEXT        | CHECK IN ('light', 'dark', 'system'), DEFAULT 'light' |
| locale                | TEXT        | CHECK IN ('en', 'fr', 'ar'), DEFAULT 'en'             |
| units                 | TEXT        | CHECK IN ('mg/dL', 'mmol/L'), DEFAULT 'mg/dL'         |
| notifications_enabled | BOOLEAN     | DEFAULT TRUE                                          |
| biometric_enabled     | BOOLEAN     | DEFAULT FALSE                                         |
| onboarding_complete   | BOOLEAN     | DEFAULT FALSE                                         |
| created_at            | TIMESTAMPTZ | DEFAULT NOW()                                         |
| updated_at            | TIMESTAMPTZ | DEFAULT NOW()                                         |

---

## Authentication Model

### Supabase Auth Flow

```
┌─────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   App       │     │  Supabase Auth  │     │  PostgreSQL     │
│   (Flutter) │     │  (JWT-based)    │     │  (Database)     │
└──────┬──────┘     └────────┬────────┘     └────────┬────────┘
       │                     │                       │
       │ 1. signUp()         │                       │
       │────────────────────►│                       │
       │                     │ 2. Create auth.users  │
       │                     │──────────────────────►│
       │                     │                       │
       │                     │ 3. Trigger: create    │
       │                     │    profiles, prefs    │
       │                     │──────────────────────►│
       │                     │                       │
       │ 4. Return JWT       │                       │
       │◄────────────────────│                       │
       │                     │                       │
       │ 5. API requests     │                       │
       │ (with JWT)          │                       │
       │─────────────────────────────────────────────│
       │                     │                       │
       │                     │ 6. RLS validates      │
       │                     │    auth.uid() = user  │
       │                     │                       │
       │ 7. Return data      │                       │
       │◄────────────────────────────────────────────│
```

### Auth Methods

| Method             | Description                                               |
| ------------------ | --------------------------------------------------------- |
| `signUp()`         | Creates new user in auth.users, triggers profile creation |
| `signIn()`         | Authenticates and returns JWT                             |
| `signOut()`        | Clears session and JWT                                    |
| `resetPassword()`  | Sends password reset email                                |
| `updatePassword()` | Changes user password                                     |
| `deleteAccount()`  | Removes user and all data (CASCADE)                       |

### Session Persistence

- JWT tokens are automatically persisted by `supabase_flutter`
- Sessions survive app restarts
- Token refresh is handled automatically

---

## Row Level Security (RLS)

### Policy Summary

All tables have RLS enabled. Users can only access their own data.

| Table             | SELECT   | INSERT   | UPDATE   | DELETE   |
| ----------------- | -------- | -------- | -------- | -------- |
| profiles          | Own only | Trigger  | Own only | Cascade  |
| diabetic_profiles | Own only | Trigger  | Own only | Cascade  |
| glucose_readings  | Own only | Own only | Own only | Own only |
| health_cards      | Own only | Own only | Own only | Own only |
| reminders         | Own only | Own only | Own only | Own only |
| user_preferences  | Own only | Trigger  | Own only | Cascade  |

### Policy Definitions

#### SELECT Policies

```sql
-- All tables follow this pattern
CREATE POLICY "Users can view own [table]"
    ON public.[table]
    FOR SELECT
    USING (auth.uid() = user_id);  -- or 'id' for profiles
```

#### INSERT Policies

```sql
-- For user-created content (glucose, health_cards, reminders)
CREATE POLICY "Users can insert own [table]"
    ON public.[table]
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);
```

#### UPDATE Policies

```sql
CREATE POLICY "Users can update own [table]"
    ON public.[table]
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
```

#### DELETE Policies

```sql
CREATE POLICY "Users can delete own [table]"
    ON public.[table]
    FOR DELETE
    USING (auth.uid() = user_id);
```

### Security Considerations

1. **No TRUE policies** - All policies require authentication
2. **No service_role on client** - Only anon key is used
3. **Trigger-based inserts** - Profiles created via secure trigger
4. **CASCADE deletes** - User deletion removes all related data
5. **Constraint validation** - Database enforces data integrity

---

## Integration Points

### Files Modified/Created

| File                                         | Change                                     |
| -------------------------------------------- | ------------------------------------------ |
| `pubspec.yaml`                               | Added `supabase_flutter`, `flutter_dotenv` |
| `.env`                                       | Supabase credentials (gitignored)          |
| `.env.example`                               | Template for credentials                   |
| `lib/services/supabase_service.dart`         | **NEW** - Supabase client wrapper          |
| `lib/services/data_service_supabase.dart`    | **NEW** - DataService using Supabase       |
| `supabase/migrations/001_initial_schema.sql` | **NEW** - Database schema                  |

### Service Architecture

```dart
// GetIt Service Locator
final getIt = GetIt.instance;

// Registration
await SupabaseService.initialize();
getIt.registerSingleton<SupabaseService>(SupabaseService.instance);
getIt.registerSingleton<PreferencesService>(prefs);
getIt.registerSingleton<DataService>(DataService(supabase, prefs));

// Usage
final dataService = getIt<DataService>();
await dataService.login(email, password);
```

### API Mapping

| Old (SQLite)                         | New (Supabase)                        |
| ------------------------------------ | ------------------------------------- |
| `DatabaseHelper.createUser()`        | `SupabaseService.signUp()`            |
| `DatabaseHelper.authenticateUser()`  | `SupabaseService.signIn()`            |
| `DatabaseHelper.getUserById()`       | `SupabaseService.getProfile()`        |
| `DatabaseHelper.addGlucoseReading()` | `SupabaseService.addGlucoseReading()` |
| `DatabaseHelper.getReminders()`      | `SupabaseService.getReminders()`      |
| All `int userId` parameters          | Changed to `auth.uid()` (automatic)   |

---

## Migration Guide

### For Existing SQLite Users

If you have existing users with SQLite data, here's the migration approach:

1. **Export SQLite Data**

   ```dart
   // In old app version
   final db = await database;
   final users = await db.query('users');
   final glucoseReadings = await db.query('glucose_readings');
   // ... export to JSON
   ```

2. **Transform IDs**

   - Old: INTEGER auto-increment IDs
   - New: UUID linked to auth.users
   - Create mapping table during migration

3. **Import to Supabase**

   ```sql
   -- Admin script (run with service_role)
   INSERT INTO profiles (id, email, ...) VALUES (...);
   INSERT INTO glucose_readings (user_id, ...) VALUES (...);
   ```

4. **Password Migration**
   - Old passwords use SHA-256 hash
   - Supabase uses bcrypt
   - Users must reset passwords OR use custom verification

### Switching DataService

To switch from SQLite to Supabase:

```dart
// In main.dart

// OLD (SQLite)
import 'services/data_service_new.dart';

// NEW (Supabase)
import 'services/data_service_supabase.dart';
```

Both files export the same `DataService` class with identical API.

---

## Environment Setup

### 1. Create Supabase Project

1. Go to [supabase.com](https://supabase.com)
2. Create new project
3. Copy URL and anon key from Settings → API

### 2. Configure Environment

```bash
# Copy example file
cp .env.example .env

# Edit .env with your values
SUPABASE_URL=https://YOUR_PROJECT.supabase.co
SUPABASE_ANON_KEY=your_anon_key
```

### 3. Run Migrations

1. Open Supabase SQL Editor
2. Paste contents of `supabase/migrations/001_initial_schema.sql`
3. Execute

### 4. Update main.dart

```dart
import 'services/data_service_supabase.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDataServiceLocator();
  runApp(const MyApp());
}
```

### 5. Test Authentication

```dart
// Register
await dataService.registerUser(
  email: 'test@example.com',
  password: 'password123',
  username: 'testuser',
);

// Login
await dataService.login('test@example.com', 'password123');

// Check status
print(dataService.isLoggedIn); // true
print(dataService.currentUserId); // UUID string
```

---

## Assumptions & Improvements

### Assumptions Made

1. **Single device usage** - No offline-first sync implemented
2. **Email verification optional** - Can enable in Supabase settings
3. **No file storage needed** - Profile images stored as URLs
4. **UTC timestamps** - All times stored in UTC, converted locally

### Improvements from SQLite

1. **Proper constraints** - CHECK constraints for enums and ranges
2. **UUID primary keys** - Better for distributed systems
3. **Automatic timestamps** - Triggers handle `updated_at`
4. **Normalized schema** - `user_preferences` separated from profile
5. **Type safety** - PostgreSQL type system vs SQLite's loose typing
6. **Security** - RLS policies prevent unauthorized access
7. **Scalability** - Cloud database scales automatically

### Future Enhancements

1. **Offline mode** - Queue operations when offline
2. **Real-time sync** - Subscribe to data changes
3. **File storage** - Profile images in Supabase Storage
4. **Push notifications** - Supabase Edge Functions for reminders
5. **Data analytics** - Aggregate queries for insights

---

## Troubleshooting

### Common Issues

| Issue                          | Solution                                      |
| ------------------------------ | --------------------------------------------- |
| "Missing Supabase credentials" | Check `.env` file exists and is in assets     |
| "Email already registered"     | User exists, use login instead                |
| "RLS policy violation"         | Check `auth.uid()` matches `user_id`          |
| "JWT expired"                  | Session auto-refreshes, restart app if issues |
| "Network error"                | Check internet connection, Supabase status    |

### Debug Mode

```dart
// Enable Supabase logging
Supabase.initialize(
  ...
  realtimeClientOptions: const RealtimeClientOptions(
    logLevel: RealtimeLogLevel.debug,
  ),
);
```

---

## Contact

For issues with this integration, check:

- [Supabase Documentation](https://supabase.com/docs)
- [supabase_flutter Package](https://pub.dev/packages/supabase_flutter)
- Project Issues on GitHub
