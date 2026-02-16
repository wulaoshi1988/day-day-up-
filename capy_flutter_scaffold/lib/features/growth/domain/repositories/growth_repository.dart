import '../../../../core/api/api_result.dart';
import '../models/growth_snapshot.dart';

abstract class GrowthRepository {
  Future<ApiResult<GrowthSnapshot>> fetchGrowth({
    required String childProfileId,
  });

  Future<ApiResult<int>> recoverStreak({
    required String childProfileId,
  });

  Future<ApiResult<int>> redeemReward({
    required String childProfileId,
    required String rewardName,
    required int cost,
  });

  Future<ApiResult<void>> addRewardOption({
    required String childProfileId,
    required String rewardName,
    required int basePrice,
  });

  Future<ApiResult<void>> deleteRewardOption({
    required String childProfileId,
    required String rewardName,
  });
}
