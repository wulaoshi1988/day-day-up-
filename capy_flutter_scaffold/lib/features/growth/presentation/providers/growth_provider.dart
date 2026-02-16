import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_result.dart';
import '../../../../core/di/app_providers.dart';
import '../../domain/models/growth_snapshot.dart';

final growthSnapshotProvider = FutureProvider.family<GrowthSnapshot, String>((ref, childProfileId) async {
  final repo = ref.watch(growthRepositoryProvider);
  final result = await repo.fetchGrowth(childProfileId: childProfileId);

  switch (result) {
    case ApiSuccess<GrowthSnapshot>(:final data):
      return data;
    case ApiFailure<GrowthSnapshot>(:final message):
      throw Exception(message);
  }
});
