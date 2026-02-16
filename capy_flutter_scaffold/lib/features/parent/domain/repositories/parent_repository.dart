import '../../../../core/api/api_result.dart';
import '../models/weekly_report.dart';

class ParentDashboard {
  const ParentDashboard({
    required this.completionRate,
    required this.pendingCount,
    required this.totalMinutesToday,
  });

  final double completionRate;
  final int pendingCount;
  final int totalMinutesToday;
}

abstract class ParentRepository {
  Future<ApiResult<ParentDashboard>> fetchDashboard({
    required String childProfileId,
  });

  Future<ApiResult<WeeklyReport>> fetchWeeklyReport({
    required String childProfileId,
  });

  Future<ApiResult<List<double>>> fetchWeeklyTrend({
    required String childProfileId,
  });

  Future<ApiResult<void>> sendEncourage({
    required String childProfileId,
    String? message,
    String? actionType,
    String? actionSubType,
    String? actionSource,
    int? riskReduceScore,
  });

  Future<ApiResult<void>> clearIntervention({
    required String childProfileId,
  });
}
