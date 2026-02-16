import '../../../core/api/api_client.dart';
import '../../../core/api/api_result.dart';
import '../domain/models/growth_snapshot.dart';
import '../domain/repositories/growth_repository.dart';

class GrowthRepositoryImpl implements GrowthRepository {
  GrowthRepositoryImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<ApiResult<GrowthSnapshot>> fetchGrowth({
    required String childProfileId,
  }) async {
    try {
      final json = await _apiClient.get('/children/$childProfileId/growth');
      final data = json['data'] as Map<String, dynamic>;
      return ApiSuccess(
        GrowthSnapshot(
          energyBalance: (data['energy_balance'] as num).toInt(),
          todayEnergy: (data['today_energy'] as num).toInt(),
          streakDays: (data['streak_days'] as num?)?.toInt() ?? 0,
          streakBroken: data['streak_broken'] == true,
          canRecover: data['can_recover'] == true,
          missedDays: (data['missed_days'] as num?)?.toInt() ?? 0,
          recoverCost: (data['recover_cost'] as num?)?.toInt() ?? 0,
          recoverUsesLeft: (data['recover_uses_left'] as num?)?.toInt() ?? 0,
          recoverMaxPerWeek: (data['recover_max_per_week'] as num?)?.toInt() ?? 0,
          recoverCooldownMinutes: (data['recover_cooldown_minutes'] as num?)?.toInt() ?? 0,
          badges: ((data['badges'] as List<dynamic>? ?? const <dynamic>[]).cast<String>()),
          rewardItems: ((data['reward_items'] as List<dynamic>? ?? const <dynamic>[]).cast<String>()),
          redeemHistory: (data['redeem_history'] as List<dynamic>? ?? const <dynamic>[])
              .map((e) {
                final row = e as Map<String, dynamic>;
                return RedeemRecord(
                  rewardName: row['reward_name'] as String? ?? '奖励',
                  cost: (row['cost'] as num?)?.toInt() ?? 0,
                  createdAt: row['created_at'] as String? ?? '',
                );
              })
              .toList(),
          rewardOptions: (data['reward_options'] as List<dynamic>? ?? const <dynamic>[])
              .map((e) {
                final row = e as Map<String, dynamic>;
                return RewardOption(
                  name: row['name'] as String? ?? '奖励',
                  basePrice: (row['base_price'] as num?)?.toInt() ?? 0,
                  dynamicPrice: (row['dynamic_price'] as num?)?.toInt() ?? 0,
                  discountTag: row['discount_tag'] as String?,
                );
              })
              .toList(),
          weeklyBehaviorScore: (data['weekly_behavior_score'] as num?)?.toInt() ?? 0,
          interventionMode: data['intervention_mode'] as String? ?? 'normal',
          interventionNote: data['intervention_note'] as String? ?? '',
          interventionActive: data['intervention_active'] == true,
          interventionRemainingMinutes: (data['intervention_remaining_minutes'] as num?)?.toInt() ?? 0,
          interventionCooldownMinutes: (data['intervention_cooldown_minutes'] as num?)?.toInt() ?? 0,
          interventionEffectAvailable: data['intervention_effect_available'] == true,
          interventionEffectDelta: (data['intervention_effect_delta'] as num?)?.toDouble() ?? 0.0,
          interventionBaselineCompletion: (data['intervention_baseline_completion'] as num?)?.toDouble() ?? 0.0,
          interventionCurrentCompletion: (data['intervention_current_completion'] as num?)?.toDouble() ?? 0.0,
          interventionEffectTrend: (data['intervention_effect_trend'] as List<dynamic>? ?? const <dynamic>[])
              .map((e) => (e as num).toDouble())
              .toList(),
          interventionFollowup2hDone: data['intervention_followup_2h_done'] == true,
          interventionFollowup6hDone: data['intervention_followup_6h_done'] == true,
          interventionFollowup2hReached: data['intervention_followup_2h_reached'] == true,
          interventionFollowup6hReached: data['intervention_followup_6h_reached'] == true,
          interventionNextFollowupMinutes: (data['intervention_next_followup_minutes'] as num?)?.toInt() ?? 0,
          interventionFollowupOverdue: data['intervention_followup_overdue'] == true,
          interventionFollowupOverdueMinutes: (data['intervention_followup_overdue_minutes'] as num?)?.toInt() ?? 0,
          interventionFollowupOverdueStage: data['intervention_followup_overdue_stage'] as String? ?? '',
          interventionBoostTotal: (data['intervention_boost_total'] as num?)?.toInt() ?? 0,
          interventionBoostSuccess: (data['intervention_boost_success'] as num?)?.toInt() ?? 0,
          interventionLightTotal: (data['intervention_light_total'] as num?)?.toInt() ?? 0,
          interventionLightSuccess: (data['intervention_light_success'] as num?)?.toInt() ?? 0,
          interventionHistory: (data['intervention_history'] as List<dynamic>? ?? const <dynamic>[])
              .map((e) {
                final row = e as Map<String, dynamic>;
                return InterventionRecord(
                  mode: row['mode'] as String? ?? 'normal',
                  note: row['note'] as String? ?? '',
                  actionType: row['action_type'] as String? ?? 'manual',
                  actionSubType: row['action_sub_type'] as String? ?? '',
                  actionSource: row['action_source'] as String? ?? '',
                  riskReduceScore: (row['risk_reduce_score'] as num?)?.toInt() ?? 0,
                  effectDelta: (row['effect_delta'] as num?)?.toDouble() ?? 0.0,
                  createdAt: row['created_at'] as String? ?? '',
                );
              })
              .toList(),
        ),
      );
    } catch (e) {
      return ApiFailure('Failed to fetch growth snapshot: $e');
    }
  }

  @override
  Future<ApiResult<int>> recoverStreak({
    required String childProfileId,
  }) async {
    try {
      final json = await _apiClient.post('/children/$childProfileId/streak-recover');
      final data = json['data'] as Map<String, dynamic>?;
      final ok = data?['ok'] == true;
      if (!ok) {
        final message = data?['message'] as String? ?? '恢复失败，稍后再试';
        return ApiFailure(message);
      }
      final streak = (data?['streak_days'] as num?)?.toInt();
      if (streak == null) {
        return const ApiFailure('恢复失败，返回数据异常');
      }
      return ApiSuccess(streak);
    } catch (e) {
      return ApiFailure('Failed to recover streak: $e');
    }
  }

  @override
  Future<ApiResult<int>> redeemReward({
    required String childProfileId,
    required String rewardName,
    required int cost,
  }) async {
    try {
      final json = await _apiClient.post(
        '/children/$childProfileId/redeem-reward',
        body: {
          'reward_name': rewardName,
          'cost': cost,
        },
      );
      final data = json['data'] as Map<String, dynamic>?;
      final ok = data?['ok'] == true;
      if (!ok) {
        final message = data?['message'] as String? ?? '兑换失败，稍后再试';
        return ApiFailure(message);
      }

      final balance = (data?['energy_balance'] as num?)?.toInt();
      if (balance == null) {
        return const ApiFailure('兑换失败，返回数据异常');
      }
      return ApiSuccess(balance);
    } catch (e) {
      return ApiFailure('Failed to redeem reward: $e');
    }
  }

  @override
  Future<ApiResult<void>> addRewardOption({
    required String childProfileId,
    required String rewardName,
    required int basePrice,
  }) async {
    try {
      final json = await _apiClient.post(
        '/children/$childProfileId/reward-options',
        body: {
          'reward_name': rewardName,
          'base_price': basePrice,
        },
      );
      final data = json['data'] as Map<String, dynamic>?;
      if (data?['ok'] == false) {
        return ApiFailure(data?['message'] as String? ?? '新增奖励失败，请稍后重试');
      }
      return const ApiSuccess(null);
    } catch (e) {
      return ApiFailure('Failed to add reward option: $e');
    }
  }

  @override
  Future<ApiResult<void>> deleteRewardOption({
    required String childProfileId,
    required String rewardName,
  }) async {
    try {
      final json = await _apiClient.post(
        '/children/$childProfileId/reward-options-delete',
        body: {
          'reward_name': rewardName,
        },
      );
      final data = json['data'] as Map<String, dynamic>?;
      if (data?['ok'] == false) {
        return ApiFailure(data?['message'] as String? ?? '删除奖励失败，请稍后重试');
      }
      return const ApiSuccess(null);
    } catch (e) {
      return ApiFailure('Failed to delete reward option: $e');
    }
  }
}
