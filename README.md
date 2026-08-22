# REPcommit ⚡

A high-performance, minimal, and disciplined push-up tracking app built with **Flutter**, **Riverpod**, and **Firebase**.

Designed for speed, clarity, and habit building with a stark, dark-mode terminal aesthetic.

---

## Key Features

- **Today Screen (Primary Dashboard)**
  - Header displaying date, day, and lowercase `@username`.
  - Classic side-by-side **Push Instrument** panel featuring a centered push-up counter, progress bar with progress status and percentage displayed below, and vertical side stats panel (**Day Streak**, **Best Streak**, and **Consistency**) on the right.
  - Interactive **Commit Heatmap Field** tracking daily push-up activity.
  - **Momentum** section showing 7-day average volume and trend comparisons.
  - **Crew Pulse** displaying live friend activity.

- **Signal Screen (Activity History)**
  - Full-year commit heatmap field.
  - Weekly volume distribution bar charts.
  - Personal record highlights (Best Set, Best Day, Best Week, Longest Line).
  - Interactive **Monthly Replay** modal.
  - Detailed recent push timeline logs.

- **Crew Screen (Social & Squads)**
  - Static structured summary cards for **Friends**, **Squads**, and **Requests** with uniform colors.
  - User search functional by **username** or **email** with verified result cards displaying avatar, display name, username, and email metadata.
  - Real-time friend request system (send, accept, decline, remove).
  - Populated friend profiles with live online status, current streaks, and daily push totals.
  - **Squads** feature to create or join group push-up commitments.
  - Side-by-side **Compare Panel** to challenge friends.

- **Profile Screen**
  - Structured card grid layout for key performance metrics (Current Streak, Consistency, Active Days, Daily Average).
  - Personal Records grid.
  - Editable Goals & Commitments (Daily Target, Weekly Goal, Long-Term Goal).
  - Synchronized **Milestones & Achievements** gallery.
  - Danger Zone (Sign out, Data Wipe, Account Deletion).

---

## Tech Stack & Architecture

- **Framework**: Flutter (Dart)
- **State Management**: Riverpod (`StateNotifierProvider`, `StreamProvider`)
- **Backend / Database**: Firebase Cloud Firestore
- **Authentication**: Firebase Auth (Google Sign-In & Anonymous Auth)
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
  │     └── timestamp: timestamp
  │
  └── dailyStats/{YYYY-MM-DD}
        ├── date: string
        ├── totalPushUps: number
        ├── sessionCount: number
        └── targetReached: boolean

friendships/{friendshipId}
  ├── fromUid: string
  ├── toUid: string
  ├── status: "pending" | "accepted"
  ├── createdAt: timestamp
  └── acceptedAt: timestamp

squads/{squadId}
  ├── id: string
  ├── name: string
  ├── description: string
  ├── target: number
  ├── members: array<string>
  └── createdBy: string
```

---

## Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK
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
