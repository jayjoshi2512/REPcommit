/// Daily content drop model.
///
/// Content types: thought, micro_challenge, signal, crew_cue,
/// recovery_note, daily_question, commit_prompt.
class DailyDrop {
  final String date;
  final String type;
  final String title;
  final String body;
  final bool active;
  final DateTime createdAt;

  const DailyDrop({
    required this.date,
    required this.type,
    required this.title,
    required this.body,
    this.active = true,
    required this.createdAt,
  });

  factory DailyDrop.fromMap(Map<String, dynamic> map) {
    return DailyDrop(
      date: map['date'] as String? ?? '',
      type: map['type'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      active: map['active'] as bool? ?? true,
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt'] as DateTime
          : DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'type': type,
      'title': title,
      'body': body,
      'active': active,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Human-readable type label (e.g., "THOUGHT OF THE DAY").
  String get typeLabel {
    return switch (type) {
      'thought' => 'THOUGHT OF THE DAY',
      'micro_challenge' => 'MICRO CHALLENGE',
      'signal' => 'SIGNAL',
      'crew_cue' => 'CREW CUE',
      'recovery_note' => 'RECOVERY NOTE',
      'daily_question' => 'DAILY QUESTION',
      'commit_prompt' => 'COMMIT PROMPT',
      _ => 'FIELD NOTE',
    };
  }

  /// Short tag for display (e.g., "Thought of the day").
  String get tag {
    return switch (type) {
      'thought' => 'Thought of the day',
      'micro_challenge' => 'Micro challenge',
      'signal' => 'Signal',
      'crew_cue' => 'Crew cue',
      'recovery_note' => 'Recovery note',
      'daily_question' => 'Daily question',
      'commit_prompt' => 'Commit prompt',
      _ => 'Field note',
    };
  }

  /// Get today's drop deterministically cycled day-by-day.
  static DailyDrop get todayDrop {
    final now = DateTime.now();
    final dayIndex = now.difference(DateTime(2025, 1, 1)).inDays.abs();
    return fallbacks[dayIndex % fallbacks.length];
  }

  /// 30 curated daily drops cycling sequentially day by day.
  static List<DailyDrop> get fallbacks {
    final now = DateTime.now();
    return [
      DailyDrop(date: '', type: 'thought', title: 'Your best sessions are the ones you repeat.', body: 'A tiny dose of consistency beats a dramatic reset. Keep the next set small enough to start.', createdAt: now),
      DailyDrop(date: '', type: 'micro_challenge', title: 'Make today the day you leave a clean square.', body: 'Log any real set before midnight. Small counts still count.', createdAt: now),
      DailyDrop(date: '', type: 'signal', title: 'Your recent average is a floor, not a ceiling.', body: 'A little more volume is available today, but consistency still wins.', createdAt: now),
      DailyDrop(date: '', type: 'crew_cue', title: 'Someone in your crew is already moving.', body: 'Check the crew tab, see who is active, and log your next set.', createdAt: now),
      DailyDrop(date: '', type: 'recovery_note', title: 'Progress is not only made by adding more.', body: 'If the last few days were heavy, protect tomorrow by keeping today controlled.', createdAt: now),
      DailyDrop(date: '', type: 'daily_question', title: 'What would make tonight feel complete?', body: 'Pick one measurable answer, then log it before the day closes.', createdAt: now),
      DailyDrop(date: '', type: 'commit_prompt', title: 'Leave evidence that you were here.', body: 'The calendar remembers every square. Give today a reason to light up.', createdAt: now),
      DailyDrop(date: '', type: 'thought', title: 'Discipline is choosing between what you want now and what you want most.', body: '5 minutes of push-ups right now builds a habit that lasts years.', createdAt: now),
      DailyDrop(date: '', type: 'micro_challenge', title: 'Complete 25 push-ups in 2 clean sets.', body: 'Break it up: 15 now, 10 after a short rest. Perfect form.', createdAt: now),
      DailyDrop(date: '', type: 'signal', title: 'The secret of getting ahead is getting started.', body: 'Do not overthink the total volume. Just get the first rep done.', createdAt: now),
      DailyDrop(date: '', type: 'thought', title: 'Show up on the hard days.', body: 'Logging 10 reps on a tired day builds more mental muscle than 50 reps on an easy day.', createdAt: now),
      DailyDrop(date: '', type: 'daily_question', title: 'What is your baseline target today?', body: 'Set a clear goal and push until you hit it.', createdAt: now),
      DailyDrop(date: '', type: 'thought', title: 'Small habits compound into unstoppable momentum.', body: 'Every push-up logged is a vote for the person you want to become.', createdAt: now),
      DailyDrop(date: '', type: 'commit_prompt', title: 'Light up your heatmap.', body: 'A single set keeps your streak alive and your board green.', createdAt: now),
      DailyDrop(date: '', type: 'micro_challenge', title: 'Try a slow tempo set.', body: '3 seconds down, 1 second up. Focus on tension over speed.', createdAt: now),
      DailyDrop(date: '', type: 'recovery_note', title: 'Listen to your shoulders and elbows.', body: 'Warm up properly before pushing hard. Longevity is king.', createdAt: now),
      DailyDrop(date: '', type: 'thought', title: 'Action creates motivation, not the other way around.', body: 'Do not wait to feel like working out. Start the set and feelings will follow.', createdAt: now),
      DailyDrop(date: '', type: 'signal', title: 'Your history is proof of what you are capable of.', body: 'Look back at your active days when you need inspiration.', createdAt: now),
      DailyDrop(date: '', type: 'crew_cue', title: 'Encourage a teammate today.', body: 'Send a quick nudge or salute to a crew member hitting their target.', createdAt: now),
      DailyDrop(date: '', type: 'daily_question', title: 'What set can you do right now?', body: 'Drop and give yourself 15 reps before moving to the next task.', createdAt: now),
      DailyDrop(date: '', type: 'thought', title: 'Consistency beats intensity every single time.', body: 'Doing 30 reps every day beats doing 200 reps once a week.', createdAt: now),
      DailyDrop(date: '', type: 'commit_prompt', title: 'Own your evening routine.', body: 'Log a quick set before 9 PM to lock in your day\'s progress.', createdAt: now),
      DailyDrop(date: '', type: 'micro_challenge', title: 'Beat yesterday\'s total by just 2 push-ups.', body: 'Incremental progress is the fastest way to double your numbers.', createdAt: now),
      DailyDrop(date: '', type: 'thought', title: 'Focus on the process, the results will take care of themselves.', body: 'Count your sets, trust the system, and watch your strength grow.', createdAt: now),
      DailyDrop(date: '', type: 'recovery_note', title: 'Stretch your chest and shoulders tonight.', body: 'Proper recovery ensures you can push hard again tomorrow.', createdAt: now),
      DailyDrop(date: '', type: 'thought', title: 'You are one set away from feeling accomplished.', body: 'Finish the day strong with a focused set of push-ups.', createdAt: now),
      DailyDrop(date: '', type: 'signal', title: 'Track every rep, honour every effort.', body: 'Your personal log is your private trophy wall.', createdAt: now),
      DailyDrop(date: '', type: 'daily_question', title: 'How many reps remain to reach your daily goal?', body: 'Close the gap now before the clock strikes midnight.', createdAt: now),
      DailyDrop(date: '', type: 'commit_prompt', title: 'Make today count.', body: 'No excuses. No delays. Log your push-ups now.', createdAt: now),
      DailyDrop(date: '', type: 'thought', title: 'Strength is built one rep at a time.', body: 'Celebrate every single set you complete.', createdAt: now),
    ];
  }
}
