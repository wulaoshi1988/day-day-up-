import '../../../core/api/api_client.dart';
import '../../../core/api/api_result.dart';
import '../domain/models/task_item.dart';
import '../domain/repositories/planner_repository.dart';
import 'dto/task_dto.dart';

class PlannerRepositoryImpl implements PlannerRepository {
  PlannerRepositoryImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<ApiResult<List<TaskItem>>> fetchTasks({
    required String childProfileId,
    required String range,
  }) async {
    try {
      final json = await _apiClient.get(
        '/children/$childProfileId/tasks',
        query: {'range': range},
      );

      final rows = (json['data'] as List<dynamic>? ?? <dynamic>[])
          .cast<Map<String, dynamic>>();
      final items = rows.map((e) => TaskDto.fromJson(e).toDomain()).toList();
      return ApiSuccess(items);
    } catch (e) {
      return ApiFailure('Failed to fetch tasks: $e');
    }
  }

  @override
  Future<ApiResult<TaskItem>> createTask({
    required String childProfileId,
    required String subject,
    required String title,
    required int difficulty,
    required int estMinutes,
    required String priority,
    double? targetScore,
    DateTime? startDate,
    DateTime? dueDate,
    String? notes,
  }) async {
    try {
      final json = await _apiClient.post(
        '/children/$childProfileId/tasks',
        body: {
          'subject': subject,
          'title': title,
          'difficulty': difficulty,
          'est_minutes': estMinutes,
          'priority': priority,
          if (targetScore != null) 'target_score': targetScore,
          if (startDate != null) 'start_date': startDate.toIso8601String(),
          'due_date': dueDate?.toIso8601String(),
          if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        },
      );
      final data = json['data'] as Map<String, dynamic>?;
      if (data?['ok'] == false) {
        return ApiFailure(data?['message'] as String? ?? '创建计划失败');
      }
      if (data == null) {
        return const ApiFailure('创建计划失败，返回数据异常');
      }
      return ApiSuccess(TaskDto.fromJson(data).toDomain());
    } catch (e) {
      return ApiFailure('Failed to create task: $e');
    }
  }

  @override
  Future<ApiResult<TaskItem>> updateTask({
    required String taskId,
    String? subject,
    String? title,
    int? difficulty,
    int? estMinutes,
    String? priority,
    double? targetScore,
    DateTime? startDate,
    String? status,
    DateTime? dueDate,
    String? notes,
  }) async {
    try {
      final body = <String, dynamic>{
        if (subject != null) 'subject': subject,
        if (title != null) 'title': title,
        if (difficulty != null) 'difficulty': difficulty,
        if (estMinutes != null) 'est_minutes': estMinutes,
        if (priority != null) 'priority': priority,
        if (targetScore != null) 'target_score': targetScore,
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (status != null) 'status': status,
        if (dueDate != null) 'due_date': dueDate.toIso8601String(),
        if (notes != null) 'notes': notes,
      };

      final json = await _apiClient.patch('/tasks/$taskId', body: body);
      final data = json['data'] as Map<String, dynamic>?;
      if (data?['ok'] == false) {
        return ApiFailure(data?['message'] as String? ?? '更新计划失败');
      }
      if (data == null) {
        return const ApiFailure('更新计划失败，返回数据异常');
      }
      return ApiSuccess(TaskDto.fromJson(data).toDomain());
    } catch (e) {
      return ApiFailure('Failed to update task: $e');
    }
  }

  @override
  Future<ApiResult<void>> completeTask({required String taskId}) async {
    try {
      await _apiClient.post('/tasks/$taskId/complete');
      return const ApiSuccess(null);
    } catch (e) {
      return ApiFailure('Failed to complete task: $e');
    }
  }

  @override
  Future<ApiResult<void>> deleteTask({required String taskId}) async {
    try {
      final json = await _apiClient.post('/tasks/$taskId/delete');
      final data = json['data'] as Map<String, dynamic>?;
      if (data?['ok'] != true) {
        return ApiFailure(data?['message'] as String? ?? '删除失败，稍后再试');
      }
      return const ApiSuccess(null);
    } catch (e) {
      return ApiFailure('Failed to delete task: $e');
    }
  }
}
