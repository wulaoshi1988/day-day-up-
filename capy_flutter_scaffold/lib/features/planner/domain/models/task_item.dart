class TaskItem {
  const TaskItem({
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
  final double? targetScore;
  final DateTime? startDate;
  final DateTime? dueDate;
  final String? notes;
  final DateTime? completedAt;
}
