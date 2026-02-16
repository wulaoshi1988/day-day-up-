import '../../../core/api/api_client.dart';
import '../../../core/api/api_result.dart';
import '../domain/repositories/timer_repository.dart';

class TimerRepositoryImpl implements TimerRepository {
  TimerRepositoryImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<ApiResult<int>> submitFocusSession({
    required String childProfileId,
    required int focusedMinutes,
    String? note,
  }) async {
    try {
      final energyDelta = focusedMinutes >= 15 ? 6 : 4;
      final json = await _apiClient.post(
        '/checkins',
        body: {
          'child_profile_id': childProfileId,
          'task_id': null,
          'checkin_date': DateTime.now().toIso8601String().split('T').first,
          'energy_delta': energyDelta,
          'note': note ?? '番茄专注完成',
        },
      );

      final data = json['data'] as Map<String, dynamic>?;
      final gain = (data?['energy_delta'] as num?)?.toInt() ?? energyDelta;
      return ApiSuccess(gain);
    } catch (e) {
      return ApiFailure('Failed to submit focus session: $e');
    }
  }
}
