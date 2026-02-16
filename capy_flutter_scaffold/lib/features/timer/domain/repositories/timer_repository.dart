import '../../../../core/api/api_result.dart';

abstract class TimerRepository {
  Future<ApiResult<int>> submitFocusSession({
    required String childProfileId,
    required int focusedMinutes,
    String? note,
  });
}
