class GrowthSnapshot {
  const GrowthSnapshot({
    required this.energyBalance,
    required this.todayEnergy,
    required this.streakDays,
    required this.streakBroken,
    required this.canRecover,
    required this.missedDays,
    required this.recoverCost,
    required this.recoverUsesLeft,
    required this.recoverMaxPerWeek,
    required this.recoverCooldownMinutes,
    required this.badges,
    required this.rewardItems,
    required this.redeemHistory,
    required this.rewardOptions,
    required this.weeklyBehaviorScore,
    required this.interventionMode,
    required this.interventionNote,
    required this.interventionActive,
    required this.interventionRemainingMinutes,
    required this.interventionCooldownMinutes,
    required this.interventionEffectAvailable,
    required this.interventionEffectDelta,
    required this.interventionBaselineCompletion,
    required this.interventionCurrentCompletion,
    required this.interventionEffectTrend,
    required this.interventionFollowup2hDone,
    required this.interventionFollowup6hDone,
    required this.interventionFollowup2hReached,
    required this.interventionFollowup6hReached,
    required this.interventionNextFollowupMinutes,
    required this.interventionFollowupOverdue,
    required this.interventionFollowupOverdueMinutes,
    required this.interventionFollowupOverdueStage,
    required this.interventionBoostTotal,
    required this.interventionBoostSuccess,
    required this.interventionLightTotal,
    required this.interventionLightSuccess,
    required this.interventionHistory,
  });

  final int energyBalance;
  final int todayEnergy;
  final int streakDays;
  final bool streakBroken;
  final bool canRecover;
  final int missedDays;
  final int recoverCost;
  final int recoverUsesLeft;
  final int recoverMaxPerWeek;
  final int recoverCooldownMinutes;
  final List<String> badges;
  final List<String> rewardItems;
  final List<RedeemRecord> redeemHistory;
  final List<RewardOption> rewardOptions;
  final int weeklyBehaviorScore;
  final String interventionMode;
  final String interventionNote;
  final bool interventionActive;
  final int interventionRemainingMinutes;
  final int interventionCooldownMinutes;
  final bool interventionEffectAvailable;
  final double interventionEffectDelta;
  final double interventionBaselineCompletion;
  final double interventionCurrentCompletion;
  final List<double> interventionEffectTrend;
  final bool interventionFollowup2hDone;
  final bool interventionFollowup6hDone;
  final bool interventionFollowup2hReached;
  final bool interventionFollowup6hReached;
  final int interventionNextFollowupMinutes;
  final bool interventionFollowupOverdue;
  final int interventionFollowupOverdueMinutes;
  final String interventionFollowupOverdueStage;
  final int interventionBoostTotal;
  final int interventionBoostSuccess;
  final int interventionLightTotal;
  final int interventionLightSuccess;
  final List<InterventionRecord> interventionHistory;
}

class RedeemRecord {
  const RedeemRecord({
    required this.rewardName,
    required this.cost,
    required this.createdAt,
  });

  final String rewardName;
  final int cost;
  final String createdAt;
}

class RewardOption {
  const RewardOption({
    required this.name,
    required this.basePrice,
    required this.dynamicPrice,
    required this.discountTag,
  });

  final String name;
  final int basePrice;
  final int dynamicPrice;
  final String? discountTag;
}

class InterventionRecord {
  const InterventionRecord({
    required this.mode,
    required this.note,
    required this.actionType,
    required this.actionSubType,
    required this.actionSource,
    required this.riskReduceScore,
    required this.effectDelta,
    required this.createdAt,
  });

  final String mode;
  final String note;
  final String actionType;
  final String actionSubType;
  final String actionSource;
  final int riskReduceScore;
  final double effectDelta;
  final String createdAt;
}
