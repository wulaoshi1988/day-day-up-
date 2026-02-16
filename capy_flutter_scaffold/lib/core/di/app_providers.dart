import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/dio_api_client.dart';
import '../api/mock_api_client.dart';
import '../config/app_env.dart';
import '../../features/growth/data/growth_repository_impl.dart';
import '../../features/growth/domain/repositories/growth_repository.dart';
import '../../features/planner/data/planner_repository_impl.dart';
import '../../features/planner/domain/repositories/planner_repository.dart';
import '../../features/parent/data/parent_repository_impl.dart';
import '../../features/parent/domain/repositories/parent_repository.dart';
import '../../features/timer/data/timer_repository_impl.dart';
import '../../features/timer/domain/repositories/timer_repository.dart';
import '../../features/score/data/score_repository_impl.dart';
import '../../features/score/domain/repositories/score_repository.dart';

final useMockApiProvider = Provider<bool>((_) => AppEnv.useMockApi);
final apiBaseUrlProvider = Provider<String>((_) => AppEnv.apiBaseUrl);
final accessTokenProvider = Provider<String>((_) => AppEnv.accessToken);

final activeChildProfileIdProvider = StateProvider<String>((_) => 'demo-child-id');
final activeGradeProvider = StateProvider<int>((_) => 3);

final apiClientProvider = Provider<ApiClient>((ref) {
  if (ref.watch(useMockApiProvider)) {
    return MockApiClient();
  }

  return DioApiClient(
    baseUrl: ref.watch(apiBaseUrlProvider),
    accessToken: ref.watch(accessTokenProvider),
  );
});

final plannerRepositoryProvider = Provider<PlannerRepository>((ref) {
  return PlannerRepositoryImpl(ref.watch(apiClientProvider));
});

final parentRepositoryProvider = Provider<ParentRepository>((ref) {
  return ParentRepositoryImpl(ref.watch(apiClientProvider));
});

final timerRepositoryProvider = Provider<TimerRepository>((ref) {
  return TimerRepositoryImpl(ref.watch(apiClientProvider));
});

final growthRepositoryProvider = Provider<GrowthRepository>((ref) {
  return GrowthRepositoryImpl(ref.watch(apiClientProvider));
});

final scoreRepositoryProvider = Provider<ScoreRepository>((ref) {
  return ScoreRepositoryImpl(ref.watch(apiClientProvider));
});
