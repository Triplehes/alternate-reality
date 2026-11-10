/// Original, offline messages. Stable for a local calendar day; cycles after 60 days.
abstract final class DailyMotivation {
  static const messages = <String>[
    'You do not need to finish everything today. Choose one useful step and begin.',
    'Progress can be quiet. The effort you make today still counts.',
    'A difficult morning does not have to decide the rest of your day.',
    'Start with what you have, where you are, and learn as you move.',
    'Rest is part of moving forward. Give yourself room to recover.',
    'You can be uncertain and still take a thoughtful next step.',
    'Focus on the next action you can control, not every possible outcome.',
    'Small habits become meaningful when you return to them.',
    'You are allowed to learn slowly and ask for help along the way.',
    'One setback is information, not a final verdict on your ability.',
    'Make room for one thing today that matters to you.',
    'You do not have to feel ready to try something manageable.',
    'Notice what is working, even while you work on what is not.',
    'Your pace can be different from someone else\'s and still be worthwhile.',
    'A kind word to yourself can make the next step easier.',
    'Consistency includes starting again after a pause.',
    'Choose a goal small enough to act on today.',
    'You can change your approach without giving up your purpose.',
    'Celebrate the effort you can repeat, not only the result you hope for.',
    'Leave some space in your day for curiosity.',
    'You have permission to set boundaries around your time and energy.',
    'A thoughtful question can open a path you did not see before.',
    'Begin with the task that makes the next task easier.',
    'Asking for support is a practical step forward.',
    'You can acknowledge a hard day without judging your whole life by it.',
    'Something imperfect and useful can be a good place to start.',
    'Give your attention to the person and the work in front of you.',
    'There is value in practicing, even before the improvement is visible.',
    'Try to make today a little more honest, kind or intentional.',
    'You can learn from yesterday without living there.',
    'A short break may help you return with more clarity.',
    'Make the next decision with the information you have, then stay open to learning.',
    'You do not have to solve the entire problem to improve one part of it.',
    'Protect a little time for the things that give you energy.',
    'Your first attempt is allowed to be a first attempt.',
    'Take a moment to recognise something you have already handled.',
    'You can be proud of showing up while still wanting to improve.',
    'A slower step in a useful direction is still movement.',
    'Choose patience with yourself while you build a new skill.',
    'Not every opportunity is yours to take. Choose what fits your priorities.',
    'Listening carefully can be a meaningful contribution today.',
    'A plan can change. Your willingness to adapt is useful.',
    'Try one practical thing before deciding that nothing will help.',
    'You are allowed to begin again without having every answer.',
    'Put a little care into the ordinary parts of your day.',
    'Your worth does not depend on how productive you are today.',
    'Notice the small choices that make your day more manageable.',
    'Make space for progress that does not need an audience.',
    'It is possible to take responsibility without being cruel to yourself.',
    'A clear, achievable priority can be more useful than a long list.',
    'Let one small success remind you that effort can make a difference.',
    'You can respect your limits and still explore your possibilities.',
    'Look for the part of the challenge that you can learn from.',
    'A conversation with someone you trust may help you see another option.',
    'Treat your attention as something worth protecting.',
    'You do not need to compare every chapter of your life with someone else\'s.',
    'Try to leave one situation a little better than you found it.',
    'There is strength in making a careful choice instead of a hurried one.',
    'Give yourself credit for the things that took courage, even if they looked small.',
    'Tomorrow is not a task you must complete today. Take care of this next step.',
  ];

  static int dayIndex(DateTime date) => DateTime.utc(
    date.year,
    date.month,
    date.day,
  ).difference(DateTime.utc(1970)).inDays;
  static String forDate(DateTime date) =>
      messages[dayIndex(date) % messages.length];

  static List<DateTime> upcoming(
    DateTime now,
    int hour,
    int minute, {
    int count = 30,
  }) {
    final first = DateTime(now.year, now.month, now.day, hour, minute);
    final offset = first.isAfter(now) ? 0 : 1;
    return List.generate(
      count,
      (i) => DateTime(now.year, now.month, now.day + offset + i, hour, minute),
    );
  }
}
