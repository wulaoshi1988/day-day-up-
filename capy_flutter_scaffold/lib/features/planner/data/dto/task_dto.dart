import '../../domain/models/task_item.dart';

class TaskDto {
  const TaskDto({
    required this.id,
    required this.childProfileId,
    required this.subject,
    required this.title,
    required this.difficulty,
    required this.estMinutes,
    required this.status,
    required this.priority,
    this.targetScore,
    this.startDate,
    this.dueDate,
    this.notes,
    this.completedAt,
  });

  final String id;
  final String childProfileId;
  final String subject;
  final String title;
  final int difficulty;
  final int estMinutes;
  final String status;
  final String priority;
  final num? targetScore;
  final String? startDate;
  final String? dueDate;
  final String? notes;
  final String? completedAt;

  factory TaskDto.fromJson(Map<String, dynamic> json) {
    return TaskDto(
      id: json['id'] as String,
      childProfileId: json['child_profile_id'] as String,
      subject: json['subject'] as String,
      title: json['title'] as String,
      difficulty: (json['difficulty'] as num).toInt(),
      estMinutes: (json['est_minutes'] as num).toInt(),
      status: json['status'] as String,
      priority: json['priority'] as String? ?? 'medium',
      targetScore: json['target_score'] as num?,
      startDate: json['start_date'] as String?,
      dueDate: json['due_date'] as String?,
      notes: json['notes'] as String?,
      completedAt: json['completed_at'] as String?,
    );
  }

  TaskItem toDomain() {
    return TaskItem(
      id: id,
      childProfileId: childProfileId,
      subject: subject,
      title: title,
      difficulty: difficulty,
      estMinutes: estMinutes,
      status: status,
      priority: priority,
      targetScore: targetScore?.toDouble(),
      startDate: startDate == null ? null : DateTime.parse(startDate!),
      dueDate: dueDate == null ? null : DateTime.parse(dueDate!),
      notes: notes,
      completedAt: completedAt == null ? null : DateTime.parse(completedAt!),
    );
  }
}
