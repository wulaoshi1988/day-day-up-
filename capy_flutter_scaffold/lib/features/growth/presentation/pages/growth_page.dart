import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_result.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../domain/models/growth_snapshot.dart';
import '../providers/growth_provider.dart';

class GrowthPage extends ConsumerWidget {
  const GrowthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childId = ref.watch(activeChildProfileIdProvider);
    final growthAsync = ref.watch(growthSnapshotProvider(childId));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFFFD79A8),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFD79A8), Color(0xFFE84393)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.spa, size: 32, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '卡皮成长页',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '查看你的成长和收获',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: growthAsync.when(
              data: (g) {
                Future<void> redeemReward(String rewardName, int cost) async {
                  final repo = ref.read(growthRepositoryProvider);
                  final result = await repo.redeemReward(
                    childProfileId: childId,
                    rewardName: rewardName,
                    cost: cost,
                  );
                  if (!context.mounted) return;

                  switch (result) {
                    case ApiSuccess<int>(:final data):
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('兑换成功：$rewardName（剩余能量 $data）'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      ref.invalidate(growthSnapshotProvider(childId));
                    case ApiFailure<int>(:final message):
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('兑换失败：$message'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                  }
                }

                Future<void> addRewardOption() async {
                  final nameController = TextEditingController();
                  final priceController = TextEditingController(text: '18');

                  final payload = await showDialog<(String, int)>(
                    context: context,
                    builder: (dialogContext) {
                      return AlertDialog(
                        title: const Text('新增兑换奖励'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                labelText: '奖励名称',
                                hintText: '例如：周末电影时间',
                              ),
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: priceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: '基础能量值',
                                hintText: '例如：18',
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('取消'),
                          ),
                          FilledButton(
                            onPressed: () {
                              final name = nameController.text.trim();
                              final price = int.tryParse(priceController.text.trim());
                              if (name.isEmpty || price == null || price <= 0) {
                                return;
                              }
                              Navigator.pop(dialogContext, (name, price));
                            },
                            child: const Text('保存'),
                          ),
                        ],
                      );
                    },
                  );

                  nameController.dispose();
                  priceController.dispose();

                  if (!context.mounted || payload == null) {
                    return;
                  }

                  final repo = ref.read(growthRepositoryProvider);
                  final result = await repo.addRewardOption(
                    childProfileId: childId,
                    rewardName: payload.$1,
                    basePrice: payload.$2,
                  );
                  if (!context.mounted) return;

                  switch (result) {
                    case ApiSuccess<void>():
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('奖励已新增，已出现在兑换列表'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      ref.invalidate(growthSnapshotProvider(childId));
                    case ApiFailure<void>(:final message):
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('新增失败：$message'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                  }
                }

                Future<void> deleteRewardOption(String rewardName) async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('删除奖励'),
                      content: Text('确认删除“$rewardName”？删除后将不再显示在兑换列表。'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('取消'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('删除'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed != true || !context.mounted) {
                    return;
                  }

                  final repo = ref.read(growthRepositoryProvider);
                  final result = await repo.deleteRewardOption(
                    childProfileId: childId,
                    rewardName: rewardName,
                  );
                  if (!context.mounted) return;

                  switch (result) {
                    case ApiSuccess<void>():
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('奖励已删除'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      ref.invalidate(growthSnapshotProvider(childId));
                    case ApiFailure<void>(:final message):
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('删除失败：$message'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                  }
                }

                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeroEnergyCard(
                        energyBalance: g.energyBalance,
                        todayEnergy: g.todayEnergy,
                        streakDays: g.streakDays,
                      ),
                      const SizedBox(height: 24),
                      _LevelProgressModule(
                        energyBalance: g.energyBalance,
                        todayEnergy: g.todayEnergy,
                      ),
                      const SizedBox(height: 14),
                      _BehaviorScoreCard(score: g.weeklyBehaviorScore),
                      const SizedBox(height: 16),
                      if (g.streakBroken)
                        _StreakRecoverCard(
                          canRecover: g.canRecover,
                          missedDays: g.missedDays,
                          recoverCost: g.recoverCost,
                          recoverUsesLeft: g.recoverUsesLeft,
                          recoverMaxPerWeek: g.recoverMaxPerWeek,
                          recoverCooldownMinutes: g.recoverCooldownMinutes,
                          energyBalance: g.energyBalance,
                          onRecover: () async {
                            final repo = ref.read(growthRepositoryProvider);
                            final result = await repo.recoverStreak(childProfileId: childId);
                            if (!context.mounted) return;
                            switch (result) {
                              case ApiSuccess<int>(:final data):
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('恢复成功！当前连击 $data 天'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                ref.invalidate(growthSnapshotProvider(childId));
                              case ApiFailure<int>(:final message):
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('恢复失败：$message'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                            }
                          },
                        ),
                      const SizedBox(height: 28),
                      _SectionHeader(
                        icon: Icons.military_tech,
                        iconColor: const Color(0xFFA29BFE),
                        title: '已解锁徽章',
                        trailing: '${g.badges.length}',
                      ),
                      const SizedBox(height: 14),
                      if (g.badges.isEmpty)
                        _EmptyBadgeCard(theme: theme)
                      else
                        _BadgesCard(badges: g.badges),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          const Expanded(
                            child: _SectionHeader(
                              icon: Icons.redeem,
                              iconColor: Color(0xFFFD79A8),
                              title: '可兑换奖励',
                            ),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () => addRewardOption(),
                            icon: const Icon(Icons.add),
                            label: const Text('新增奖励'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ...g.rewardOptions.map((option) {
                        return _RewardCard(
                          reward: option.name,
                          basePrice: option.basePrice,
                          dynamicPrice: option.dynamicPrice,
                          discountTag: option.discountTag,
                          enabled: g.energyBalance >= option.dynamicPrice,
                          onRedeem: () => redeemReward(option.name, option.dynamicPrice),
                          onDelete: () => deleteRewardOption(option.name),
                        );
                      }),
                      const SizedBox(height: 18),
                      _RedeemHistoryCard(history: g.redeemHistory),
                      const SizedBox(height: 100),
                    ],
                  ),
                );
              },
              error: (error, _) => SizedBox(
                height: 400,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Color(0xFFFF6B6B)),
                      const SizedBox(height: 16),
                      Text('加载失败: $error', style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
              loading: () => const SizedBox(
                height: 400,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentRoute: '/growth'),
    );
  }
}

class _HeroEnergyCard extends StatelessWidget {
  const _HeroEnergyCard({
    required this.energyBalance,
    required this.todayEnergy,
    required this.streakDays,
  });

  final int energyBalance;
  final int todayEnergy;
  final int streakDays;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF8C42), Color(0xFFFF6B35)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8C42).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.energy_savings_leaf, size: 36, color: Colors.white),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '胡萝卜能量余额',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$energyBalance',
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '今日新增 +$todayEnergy 能量',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '连续连击 $streakDays',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelProgressModule extends StatelessWidget {
  const _LevelProgressModule({required this.energyBalance, required this.todayEnergy});

  final int energyBalance;
  final int todayEnergy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = _calculateLevel(energyBalance);
    final level = info.level;
    final nextLevel = level + 1;
    final need = (info.nextLevelThreshold - energyBalance).clamp(0, 999999);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFA29BFE), Color(0xFF6C5CE7)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.workspace_premium, size: 28, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '当前等级',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF718096),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFA29BFE), Color(0xFF6C5CE7)]),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'LV.$level',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '能量值：$energyBalance',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF2D3748),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  '距离 LV.$nextLevel 还差 $need 能量',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF718096),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '今日 +$todayEnergy',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFFF8C42),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: info.progress,
              minHeight: 10,
              backgroundColor: const Color(0xFFEDF2F7),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF4ECDC4).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '再获得 $need 能量就能升级到 LV.$nextLevel！',
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF2D3748),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _LevelInfo _calculateLevel(int energy) {
    const thresholds = [0, 100, 250, 500, 1000, 1600];

    int level = 1;
    int from = 0;
    int to = 100;

    for (var i = 0; i < thresholds.length - 1; i++) {
      final start = thresholds[i];
      final end = thresholds[i + 1];
      if (energy >= start && energy < end) {
        level = i + 1;
        from = start;
        to = end;
        break;
      }
      if (energy >= thresholds.last) {
        level = thresholds.length;
        from = thresholds[thresholds.length - 2];
        to = thresholds.last + 600;
      }
    }

    final range = (to - from).toDouble();
    final progress = ((energy - from) / range).clamp(0.0, 1.0);
    return _LevelInfo(level: level, nextLevelThreshold: to, progress: progress);
  }
}

class _LevelInfo {
  const _LevelInfo({required this.level, required this.nextLevelThreshold, required this.progress});

  final int level;
  final int nextLevelThreshold;
  final double progress;
}

class _StreakRecoverCard extends StatelessWidget {
  const _StreakRecoverCard({
    required this.canRecover,
    required this.missedDays,
    required this.recoverCost,
    required this.recoverUsesLeft,
    required this.recoverMaxPerWeek,
    required this.recoverCooldownMinutes,
    required this.energyBalance,
    required this.onRecover,
  });

  final bool canRecover;
  final int missedDays;
  final int recoverCost;
  final int recoverUsesLeft;
  final int recoverMaxPerWeek;
  final int recoverCooldownMinutes;
  final int energyBalance;
  final Future<void> Function() onRecover;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFC078)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department, color: Color(0xFFFF8C42)),
              const SizedBox(width: 8),
              Text(
                '连击中断提醒',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF2D3748),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '你已中断 $missedDays 天，使用断签恢复卡可补回连击。',
            style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF5C6773)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _RecoverInfoPill(icon: Icons.bolt, text: '消耗 $recoverCost 能量'),
              _RecoverInfoPill(icon: Icons.calendar_today, text: '本周剩余 $recoverUsesLeft/$recoverMaxPerWeek 次'),
              _RecoverInfoPill(icon: Icons.energy_savings_leaf, text: '当前能量 $energyBalance'),
              if (recoverCooldownMinutes > 0)
                _RecoverInfoPill(icon: Icons.hourglass_bottom, text: '冷却 $recoverCooldownMinutes 分钟'),
            ],
          ),
          const SizedBox(height: 12),
          if (!canRecover)
            Text(
              recoverUsesLeft <= 0
                  ? '本周恢复次数已用完'
                  : energyBalance < recoverCost
                      ? '能量不足，先完成任务再来恢复'
                      : recoverCooldownMinutes > 0
                          ? '恢复卡冷却中，$recoverCooldownMinutes 分钟后可使用'
                          : '当前没有可恢复的连击',
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFFD9480F),
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: canRecover ? () async => onRecover() : null,
              icon: const Icon(Icons.restore),
              label: const Text('使用恢复卡'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecoverInfoPill extends StatelessWidget {
  const _RecoverInfoPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF9A3412)),
          const SizedBox(width: 6),
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: const Color(0xFF7C2D12),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BehaviorScoreCard extends StatelessWidget {
  const _BehaviorScoreCard({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = score >= 85
        ? '稳定优秀'
        : score >= 70
            ? '表现良好'
            : '需要关注';

    final color = score >= 85
        ? const Color(0xFF2F9E44)
        : score >= 70
            ? const Color(0xFF1C7ED6)
            : const Color(0xFFD9480F);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.insights, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '本周行为评分 $score（$level）',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF2D3748),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.iconColor, required this.title, this.trailing});

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 24, color: iconColor),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            color: const Color(0xFF2D3748),
            fontWeight: FontWeight.w700,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              trailing!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: iconColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _EmptyBadgeCard extends StatelessWidget {
  const _EmptyBadgeCard({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFA29BFE).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline, size: 40, color: Color(0xFFA29BFE)),
          ),
          const SizedBox(height: 16),
          Text(
            '还没有解锁徽章',
            style: theme.textTheme.titleMedium?.copyWith(
              color: const Color(0xFF2D3748),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '完成任务专注学习，解锁你的第一个徽章吧！',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF718096)),
          ),
        ],
      ),
    );
  }
}

class _BadgesCard extends StatefulWidget {
  const _BadgesCard({required this.badges});

  final List<String> badges;

  @override
  State<_BadgesCard> createState() => _BadgesCardState();
}

class _BadgesCardState extends State<_BadgesCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badges = widget.badges;
    final showCollapsed = badges.length > 5;
    final visibleBadges = (!_expanded && showCollapsed) ? badges.take(5).toList() : badges;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: visibleBadges.map((badge) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFA29BFE), Color(0xFF6C5CE7)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFA29BFE).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      badge,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          if (showCollapsed) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _expanded = !_expanded;
                  });
                },
                icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                label: Text(_expanded ? '收起' : '更多（${badges.length - 5}）'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.reward,
    required this.basePrice,
    required this.dynamicPrice,
    required this.discountTag,
    required this.enabled,
    required this.onRedeem,
    this.onDelete,
  });

  final String reward;
  final int basePrice;
  final int dynamicPrice;
  final String? discountTag;
  final bool enabled;
  final Future<void> Function() onRedeem;
  final Future<void> Function()? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFD79A8).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.card_giftcard, size: 24, color: Color(0xFFFD79A8)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF2D3748),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '使用胡萝卜能量兑换',
                  style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF718096)),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '$dynamicPrice 能量',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: const Color(0xFFFF8C42),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (dynamicPrice < basePrice) ...[
                      const SizedBox(width: 8),
                      Text(
                        '$basePrice',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: const Color(0xFFA0AEC0),
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                    if (discountTag != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6FCF5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          discountTag!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: const Color(0xFF0CA678),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (onDelete != null)
            IconButton(
              onPressed: () async => onDelete!(),
              icon: const Icon(Icons.delete_outline, color: Color(0xFFD9480F)),
              tooltip: '删除奖励',
            ),
          FilledButton(
            onPressed: enabled ? () async => onRedeem() : null,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFD79A8),
              disabledBackgroundColor: const Color(0xFFCBD5E0),
            ),
            child: const Text('兑换'),
          ),
        ],
      ),
    );
  }
}

class _RedeemHistoryCard extends StatelessWidget {
  const _RedeemHistoryCard({required this.history});

  final List<RedeemRecord> history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE7F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, color: Color(0xFF6C5CE7)),
              const SizedBox(width: 8),
              Text(
                '最近兑换记录',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF2D3748),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (history.isEmpty)
            Text(
              '暂无兑换记录，完成任务积累能量后来兑换吧。',
              style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF718096)),
            )
          else
            ...history.take(4).map(
              (record) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: Color(0xFF38A169)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${record.rewardName}  -${record.cost} 能量',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF2D3748),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      record.createdAt,
                      style: theme.textTheme.labelSmall?.copyWith(color: const Color(0xFFA0AEC0)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
