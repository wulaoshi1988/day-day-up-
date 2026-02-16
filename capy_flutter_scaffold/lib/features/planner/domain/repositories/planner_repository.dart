import '../../../../core/api/api_result.dart';
import '../models/task_item.dart';

abstract class PlannerRepository {
  Future<ApiResult<List<TaskItem>>> fetchTasks({
    required String childProfileId,
    required String range,
  });

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
  });

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
  });

  Future<ApiResult<void>> completeTask({
    required String taskId,
  });

  Future<ApiResult<void>> deleteTask({
    required String taskId,
  });
}
