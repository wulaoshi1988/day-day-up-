import '../../../core/api/api_client.dart';
import '../../../core/api/api_result.dart';
import '../domain/models/weekly_report.dart';
import '../domain/repositories/parent_repository.dart';
import 'dto/weekly_report_dto.dart';

class ParentRepositoryImpl implements ParentRepository {
  ParentRepositoryImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<ApiResult<ParentDashboard>> fetchDashboard({
    required String childProfileId,
  }) async {
    try {
      final json = await _apiClient.get('/children/$childProfileId/dashboard');
      final data = json['data'] as Map<String, dynamic>;

      return ApiSuccess(
        ParentDashboard(
          completionRate: (data['completion_rate'] as num).toDouble(),
          pendingCount: (data['pending_count'] as num).toInt(),
          totalMinutesToday: (data['total_minutes_today'] as num).toInt(),
        ),
      );
    } catch (e) {
      return ApiFailure('Failed to fetch parent dashboard: $e');
    }
  }

  @override
  Future<ApiResult<WeeklyReport>> fetchWeeklyReport({
    required String childProfileId,
  }) async {
    try {
      final json = await _apiClient.get('/children/$childProfileId/weekly-report');
      final report = WeeklyReportDto.fromJson(json['data'] as Map<String, dynamic>).toDomain();
      return ApiSuccess(report);
    } catch (e) {
      return ApiFailure('Failed to fetch weekly report: $e');
    }
  }

  @override
  Future<ApiResult<List<double>>> fetchWeeklyTrend({
    required String childProfileId,
  }) async {
    try {
      final json = await _apiClient.get('/children/$childProfileId/weekly-trend');
      final data = (json['data'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => (e as num).toDouble())
          .toList();
      return ApiSuccess(data);
    } catch (e) {
      return ApiFailure('Failed to fetch weekly trend: $e');
    }
  }

  @override
  Future<ApiResult<void>> sendEncourage({
    required String childProfileId,
    String? message,
    String? actionType,
    String? actionSubType,
    String? actionSource,
    int? riskReduceScore,
  }) async {
    try {
      final json = await _apiClient.post(
        '/children/$childProfileId/encourage',
        body: {
          if (message != null && message.trim().isNotEmpty) 'message': message.trim(),
          if (actionType != null && actionType.trim().isNotEmpty) 'action_type': actionType.trim(),
          if (actionSubType != null && actionSubType.trim().isNotEmpty) 'action_sub_type': actionSubType.trim(),
          if (actionSource != null && actionSource.trim().isNotEmpty) 'action_source': actionSource.trim(),
          if (riskReduceScore != null) 'risk_reduce_score': riskReduceScore,
        },
      );

      final data = json['data'] as Map<String, dynamic>?;
      final ok = data?['ok'];
      if (ok == false) {
        return ApiFailure(data?['message'] as String? ?? '发送失败，请稍后重试');
      }

      return const ApiSuccess(null);
    } catch (e) {
      return ApiFailure('Failed to send encourage message: $e');
    }
  }

  @override
  Future<ApiResult<void>> clearIntervention({
    required String childProfileId,
  }) async {
    try {
      final json = await _apiClient.post('/children/$childProfileId/intervention-clear');
      final data = json['data'] as Map<String, dynamic>?;
      final ok = data?['ok'];
      if (ok == false) {
        return ApiFailure(data?['message'] as String? ?? '撤销失败，请稍后重试');
      }
      return const ApiSuccess(null);
    } catch (e) {
      return ApiFailure('Failed to clear intervention: $e');
    }
  }

}
