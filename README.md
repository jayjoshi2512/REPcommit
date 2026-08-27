# REPcommit ⚡

A high-performance, minimal, and disciplined exercise & habit tracking app built with **Flutter**, **Riverpod**, and **Firebase**.

Designed for speed, clarity, and habit building with a stark, dark-mode terminal aesthetic.

---

## Key Features

- **Multi-Exercise & Tab Management**
  - Track **Push-ups**, **Pull-ups**, **Squats**, and **Custom Exercises** seamlessly.
  - **Today Screen**: Defaults to Push-ups tab with an interactive `+ ADD EXERCISE` tab management modal to dynamically add/remove active exercise tabs.
  - **Signal Screen**: Automatically scopes history charts, heatmap fields, and records to user-specific enabled exercises.
  - **Crew Screen**: Dynamically generates Leaderboard filter tabs from user-enabled exercises and actual logged crew exercise totals (no static unlogged tabs).

- **High-Performance Animated Infinity Loader (`InfiniteSymbolLoader`)**
  - Custom `CustomPainter` vector animation powered by the lemniscate curve (\(x(t), y(t)\)).
  - Features a multi-point neon laser sweep comet trail with breathing focal pulse halos.

- **Today Screen (Primary Dashboard)**
  - Header displaying date, day, lowercase `@username`, and interactive **Notification Bell**.
  - Dynamic **Push Instrument** panel with exercise-specific readouts, progress bars, and vertical stats panel (**Day Streak**, **Best Streak**, and **Consistency**).
  - Interactive **Commit Heatmap Field** tracking daily activity.
  - **Momentum** section showing 7-day average volume and trend comparisons.
  - **Crew Pulse** displaying live friend activity.

- **Signal Screen (Activity History)**
  - Filterable by user-specific exercise disciplines.
  - Full-year commit heatmap field.
  - Weekly volume distribution bar charts per exercise.
  - Personal record highlights (Best Set, Best Day, Best Week, Longest Line).
  - Interactive **Monthly Replay** modal.
  - Detailed exercise timeline logs.

- **Crew Screen (Social & Leaderboard)**
  - Static structured summary cards for **Friends** and **Incoming Requests**.
  - User search functional by **username** or **email** with verified result cards displaying avatar, display name, username, and email metadata.
  - Real-time friend request system (send, accept, decline, remove).
  - Populated friend profiles with live online status, current streaks, and daily push totals.
  - **Detailed Leaderboard Breakdown**: Tap any friend card to open a side-by-side comparison modal with an exercise-by-exercise breakdown table, bounded number badge cards, and a `VS` pill separator.
  - **Instant Nudges**: Send real-time nudge notifications directly to workout partners.

- **Notifications & Automated Reminders**
  - Custom notification alert sound (`climb.mp3`) with automatic system fallback.
  - Local push notification system with automated **10 PM daily workout reminders**.
  - Instant nudge notification alerts between workout partners.
  - Interactive **Notification Sheet** accessible via top bell icon with instant system notification testing.

- **Profile Screen & Milestones**
  - Structured card grid layout for key performance metrics (Current Streak, Consistency, Active Days, Daily Average).
  - Personal Records grid.
  - Editable Goals & Commitments (Daily Target, Weekly Goal, Long-Term Goal).
  - Expanded **Milestones & Achievements** gallery including multi-discipline achievements (**First Push**, **First Pull-up**, **First Squat**, **Triple Threat**, **Century Club**, etc.).
  - Danger Zone (Sign out, Data Wipe, Account Deletion).

---

## Tech Stack & Architecture

- **Framework**: Flutter (Dart)
- **State Management**: Riverpod (`StateNotifierProvider`, `StreamProvider`)
- **Backend / Database**: Firebase Cloud Firestore
- **Authentication**: Firebase Auth (Google Sign-In & Anonymous Auth)
- **Local Notifications**: `flutter_local_notifications` with Core Library Desugaring enabled
- **Design System**: Monospaced typography (`Courier Prime` / `Roboto Mono`), custom HSL color palette, dark mode panel styling

---

## Firestore Database Schema

```
usernames/{username}
  ├── uid: string
  └── createdAt: timestamp

users/{uid}
  ├── uid: string
  ├── username: string
  ├── displayName: string
  ├── email: string
  ├── photoUrl: string
  ├── dailyTarget: number
  ├── weeklyGoal: number
  ├── longTermGoal: number
  ├── lastActiveAt: timestamp
  │
  ├── pushLogs/{logId}
  │     ├── count: number
  │     ├── exerciseId: string
  │     └── timestamp: timestamp
  │
  ├── dailyStats/{YYYY-MM-DD}
  │     ├── date: string
  │     ├── totalPushUps: number
  │     ├── exerciseTotals: map<string, number>
  │     ├── sessionCount: number
  │     └── targetReached: boolean
  │
  └── notifications/{notificationId}
        ├── id: string
        ├── type: "nudge" | "reminder"
        ├── fromUsername: string
        ├── message: string
        └── timestamp: timestamp

friendships/{friendshipId}
  ├── fromUid: string
  ├── toUid: string
  ├── status: "pending" | "accepted"
  ├── createdAt: timestamp
  └── acceptedAt: timestamp
```

---

## Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK
- Android Studio / VS Code with Java 17 support
- Firebase account with Firestore & Auth enabled

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/jayjoshi2512/REPcommit.git
   cd RAPcommit
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run static code analysis:
   ```bash
   flutter analyze
   ```

4. Start the application:
   ```bash
   flutter run
   ```
