import '../../domain/models/weekly_report.dart';

class WeeklyReportDto {
  const WeeklyReportDto({
    required this.childProfileId,
    required this.weekStart,
    required this.completionRate,
    required this.totalSessions,
    required this.totalMinutes,
    this.aiSummary,
  });

  final String childProfileId;
  final String weekStart;
  final double completionRate;
  final int totalSessions;
  final int totalMinutes;
  final String? aiSummary;

  factory WeeklyReportDto.fromJson(Map<String, dynamic> json) {
    return WeeklyReportDto(
      childProfileId: json['child_profile_id'] as String,
      weekStart: json['week_start'] as String,
      completionRate: (json['completion_rate'] as num).toDouble(),
      totalSessions: (json['total_sessions'] as num).toInt(),
      totalMinutes: (json['total_minutes'] as num).toInt(),
      aiSummary: json['ai_summary'] as String?,
    );
  }

  WeeklyReport toDomain() {
    return WeeklyReport(
      childProfileId: childProfileId,
      weekStart: DateTime.parse(weekStart),
      completionRate: completionRate,
      totalSessions: totalSessions,
      totalMinutes: totalMinutes,
      aiSummary: aiSummary,
    );
  }
}
