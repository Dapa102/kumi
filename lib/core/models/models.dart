class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.name,
    this.pictureUrl,
    this.currentStreak = 0,
    this.lastCompletedDate,
    this.totalTasks = 0,
    this.completedTasks = 0,
    this.completedToday = 0,
    this.completionRate = 0,
  });

  final int id;
  final String email;
  final String name;
  final String? pictureUrl;
  final int currentStreak;
  final DateTime? lastCompletedDate;
  final int totalTasks;
  final int completedTasks;
  final int completedToday;
  final double completionRate;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? const {};
    return UserProfile(
      id: json['id'] as int,
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      pictureUrl: json['picture_url'] as String?,
      currentStreak: json['current_streak'] as int? ?? 0,
      lastCompletedDate: json['last_completed_date'] == null
          ? null
          : DateTime.tryParse(json['last_completed_date'] as String),
      totalTasks: stats['total_tasks'] as int? ?? 0,
      completedTasks: stats['completed_tasks'] as int? ?? 0,
      completedToday: stats['completed_today'] as int? ?? 0,
      completionRate: (stats['completion_rate'] as num?)?.toDouble() ?? 0,
    );
  }
}

class AuthResult {
  const AuthResult({
    required this.accessToken,
    required this.isNewUser,
    required this.user,
  });

  final String accessToken;
  final bool isNewUser;
  final UserProfile user;

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
    accessToken: json['access_token'] as String,
    isNewUser: json['is_new_user'] as bool? ?? false,
    user: UserProfile.fromJson(json['user'] as Map<String, dynamic>),
  );
}

class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    this.description,
    required this.dueTime,
    required this.isCompleted,
    this.completedAt,
  });

  final int id;
  final String title;
  final String? description;
  final DateTime dueTime;
  final bool isCompleted;
  final DateTime? completedAt;

  bool get isOverdue => !isCompleted && dueTime.isBefore(DateTime.now());

  bool get isDueSoon {
    final diff = dueTime.difference(DateTime.now());
    return !isCompleted && diff.inMinutes >= 0 && diff.inHours < 2;
  }

  factory TaskItem.fromJson(Map<String, dynamic> json) => TaskItem(
    id: json['id'] as int,
    title: json['title'] as String,
    description: json['description'] as String?,
    dueTime: DateTime.parse(json['due_time'] as String).toLocal(),
    isCompleted: json['is_completed'] as bool? ?? false,
    completedAt: json['completed_at'] == null
        ? null
        : DateTime.parse(json['completed_at'] as String).toLocal(),
  );
}

class Achievement {
  const Achievement({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.icon,
    this.earned = false,
    this.earnedAt,
  });

  final int id;
  final String code;
  final String name;
  final String description;
  final String icon;
  final bool earned;
  final DateTime? earnedAt;

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
    id: json['id'] as int,
    code: json['code'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    icon: json['icon'] as String? ?? 'badge',
    earned: json['earned'] as bool? ?? false,
    earnedAt: json['earned_at'] == null
        ? null
        : DateTime.parse(json['earned_at'] as String).toLocal(),
  );
}

class GamificationResult {
  const GamificationResult({
    required this.currentStreak,
    required this.streakIncreased,
    required this.newAchievements,
  });

  final int currentStreak;
  final bool streakIncreased;
  final List<Achievement> newAchievements;

  factory GamificationResult.fromJson(Map<String, dynamic> json) =>
      GamificationResult(
        currentStreak: json['current_streak'] as int? ?? 0,
        streakIncreased: json['streak_increased'] as bool? ?? false,
        newAchievements: (json['new_achievements'] as List<dynamic>? ?? [])
            .map(
              (item) => Achievement.fromJson({
                ...item as Map<String, dynamic>,
                'earned': true,
              }),
            )
            .toList(),
      );
}

class CompleteTaskResult {
  const CompleteTaskResult({required this.task, required this.gamification});

  final TaskItem task;
  final GamificationResult gamification;

  factory CompleteTaskResult.fromJson(Map<String, dynamic> json) =>
      CompleteTaskResult(
        task: TaskItem.fromJson(json),
        gamification: GamificationResult.fromJson(
          json['gamification'] as Map<String, dynamic>? ?? const {},
        ),
      );
}

class KumiDialog {
  const KumiDialog({
    required this.id,
    required this.context,
    required this.text,
  });

  final int id;
  final String context;
  final String text;

  factory KumiDialog.fromJson(Map<String, dynamic> json) => KumiDialog(
    id: json['id'] as int,
    context: json['context'] as String,
    text: json['text'] as String,
  );
}
