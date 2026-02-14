import 'dart:math';

class MotivationService {
  static final List<String> _quotes = [
    "Quality is not an act, it is a habit. — Aristotle",
    "We are what we repeatedly do. Excellence, then, is not an act, but a habit. — Will Durant",
    "The secret of your future is hidden in your daily routine.",
    "Small habits, big results.",
    "Don't wait for inspiration. Become the inspiration through your consistency.",
    "Your habits define your future. Make them count.",
    "The journey of a thousand miles begins with a single step... and a consistent one.",
    "Discipline is choosing between what you want now and what you want most.",
    "Motivation is what gets you started. Habit is what keeps you going. — Jim Ryun",
    "Success is the sum of small efforts, repeated day in and day out.",
    "First we make our habits, then our habits make us.",
    "The best time to plant a tree was 20 years ago. The second best time is now.",
    "Atomic habits: 1% better every day adds up to massive change.",
    "Focus on the process, and the result will take care of itself.",
    "Consistency is the playground of the dull... and the path of the successful.",
  ];

  String getRandomQuote() {
    final random = Random();
    return _quotes[random.nextInt(_quotes.length)];
  }
}
