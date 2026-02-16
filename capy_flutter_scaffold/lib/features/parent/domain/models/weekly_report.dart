class WeeklyReport {
  const WeeklyReport({
    required this.childProfileId,
    required this.weekStart,
    required this.completionRate,
    required this.totalSessions,
    required this.totalMinutes,
    this.aiSummary,
  });

  final String childProfileId;
  final DateTime weekStart;
  final double completionRate;
  final int totalSessions;
  final int totalMinutes;
  final String? aiSummary;
}
