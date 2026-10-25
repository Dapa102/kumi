import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';

class TaskRepository {
  TaskRepository(this._api);

  final ApiClient _api;

  Future<List<TaskItem>> fetchTasks({
    DateTime? date,
    String status = 'all',
  }) async {
    final query = <String, String>{'status': status, 'limit': '100'};
    if (date != null) {
      final iso = date.toIso8601String().split('T').first;
      query['date'] = iso;
    }

    final response = await _api.get('/api/v1/tasks', query: query);
    final items = (response as Map<String, dynamic>)['items'] as List<dynamic>;
    return items
        .map((item) => TaskItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<TaskItem> createTask({
    required String title,
    String? description,
    required DateTime dueTime,
  }) async {
    final response = await _api.post(
      '/api/v1/tasks',
      body: {
        'title': title,
        'description': description,
        'due_time': dueTime.toUtc().toIso8601String(),
      },
    );
    return TaskItem.fromJson(response as Map<String, dynamic>);
  }

  Future<TaskItem> updateTask({
    required int id,
    required String title,
    String? description,
    required DateTime dueTime,
  }) async {
    final response = await _api.put(
      '/api/v1/tasks/$id',
      body: {
        'title': title,
        'description': description,
        'due_time': dueTime.toUtc().toIso8601String(),
      },
    );
    return TaskItem.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteTask(int id) => _api.delete('/api/v1/tasks/$id');

  Future<CompleteTaskResult> toggleComplete(int id) async {
    final response = await _api.patch('/api/v1/tasks/$id/complete');
    return CompleteTaskResult.fromJson(response as Map<String, dynamic>);
  }

  Future<UserProfile> fetchProfile() async {
    final response = await _api.get('/api/v1/user/profile');
    return UserProfile.fromJson(response as Map<String, dynamic>);
  }

  Future<UserProfile> updateName(String name) async {
    final response = await _api.put(
      '/api/v1/user/profile',
      body: {'name': name},
    );
    return UserProfile.fromJson(response as Map<String, dynamic>);
  }

  Future<List<Achievement>> fetchAchievements() async {
    final response = await _api.get('/api/v1/achievements');
    final items = (response as Map<String, dynamic>)['items'] as List<dynamic>;
    return items
        .map((item) => Achievement.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<KumiDialog> fetchDialog({
    required String context,
    int? excludeId,
  }) async {
    final response = await _api.get(
      '/api/v1/kumi/dialog',
      query: {
        'context': context,
        if (excludeId != null) 'exclude_id': '$excludeId',
      },
    );
    return KumiDialog.fromJson(response as Map<String, dynamic>);
  }
}
