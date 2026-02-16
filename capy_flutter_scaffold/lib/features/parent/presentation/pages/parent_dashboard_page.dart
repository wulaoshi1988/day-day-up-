import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_result.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../growth/domain/models/growth_snapshot.dart';
import '../../../growth/presentation/providers/growth_provider.dart';
import '../../../planner/presentation/providers/planner_provider.dart';
import '../providers/parent_provider.dart';

class ParentDashboardPage extends ConsumerStatefulWidget {
  const ParentDashboardPage({super.key});

  @override
  ConsumerState<ParentDashboardPage> createState() => _ParentDashboardPageState();
}

class _ParentDashboardPageState extends ConsumerState<ParentDashboardPage> {
  bool _sendingIntervention = false;

  Future<void> _clearIntervention({required String childId}) async {
    if (_sendingIntervention) {
      return;
    }

    setState(() {
      _sendingIntervention = true;
    });

    final repo = ref.read(parentRepositoryProvider);
    final result = await repo.clearIntervention(childProfileId: childId);

    if (!mounted) {
      return;
    }

    switch (result) {
      case ApiSuccess<void>():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已撤销干预，恢复默认策略'), behavior: SnackBarBehavior.floating),
        );
        ref.invalidate(parentDashboardProvider(childId));
        ref.invalidate(growthSnapshotProvider(childId));
        ref.invalidate(plannerTasksProvider(childId));
      case ApiFailure<void>(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('撤销失败：$message'), behavior: SnackBarBehavior.floating),
        );
    }

    if (mounted) {
      setState(() {
        _sendingIntervention = false;
      });
    }
  }

  Future<void> _sendIntervention({
    required String childId,
    required String message,
    required String successText,
    String actionType = 'manual',
    String? actionSubType,
    String? actionSource,
    int? riskReduceScore,
  }) async {
    if (_sendingIntervention) {
      return;
    }

    setState(() {
      _sendingIntervention = true;
    });

    final repo = ref.read(parentRepositoryProvider);
    final result = await repo.sendEncourage(
      childProfileId: childId,
      message: message,
      actionType: actionType,
      actionSubType: actionSubType,
      actionSource: actionSource,
      riskReduceScore: riskReduceScore,
    );

    if (!mounted) {
      return;
    }

    switch (result) {
      case ApiSuccess<void>():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successText), behavior: SnackBarBehavior.floating),
        );
        ref.invalidate(parentDashboardProvider(childId));
        ref.invalidate(growthSnapshotProvider(childId));
        ref.invalidate(plannerTasksProvider(childId));
      case ApiFailure<void>(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发送失败：$message'), behavior: SnackBarBehavior.floating),
        );
    }

    if (mounted) {
      setState(() {
        _sendingIntervention = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final childId = ref.watch(activeChildProfileIdProvider);
    final grade = ref.watch(activeGradeProvider);
    final dashboardAsync = ref.watch(parentDashboardProvider(childId));
    final trendAsync = ref.watch(weeklyTrendProvider(childId));
    final growthAsync = ref.watch(growthSnapshotProvider(childId));

    return Scaffold(
      appBar: AppBar(title: const Text('家长看板')),
      body: dashboardAsync.when(
        data: (data) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  title: const Text('今日完成率'),
                  trailing: Text('${data.completionRate.toStringAsFixed(1)}%'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('待完成任务'),
                  trailing: Text('${data.pendingCount} 项'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('今日专注时长'),
                  trailing: Text('${data.totalMinutesToday} 分钟'),
                ),
              ),
              Card(
                child: growthAsync.when(
                  data: (g) {
                    final cooldownLeft = g.interventionCooldownMinutes;
                    final onCooldown = cooldownLeft > 0;
                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '家长干预建议',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 10),
                          if (onCooldown)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                '干预冷却中：$cooldownLeft 分钟后可再次发送',
                                style: const TextStyle(
                                  color: Color(0xFFD9480F),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: (_sendingIntervention || onCooldown)
                                      ? null
                                      : () {
                                          _sendIntervention(
                                            childId: childId,
                                            message: '今天表现很好，继续保持主线任务节奏，卡皮会一直陪你。',
                                            successText: '鼓励消息已发送',
                                          );
                                        },
                                  icon: const Icon(Icons.favorite),
                                  label: const Text('发送鼓励'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: (_sendingIntervention || onCooldown)
                                      ? null
                                      : () {
                                          _sendIntervention(
                                            childId: childId,
                                            message: '今天适度减负，优先完成1个主线任务与1个轻任务。',
                                            successText: '减负建议已发送',
                                          );
                                        },
                                  icon: const Icon(Icons.self_improvement),
                                  label: const Text('建议减负'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: _sendingIntervention
                                  ? null
                                  : () {
                                      _clearIntervention(childId: childId);
                                    },
                              icon: const Icon(Icons.restart_alt),
                              label: const Text('撤销干预'),
                            ),
                          ),
                          if (g.interventionHistory.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 6),
                            const Text('最近干预记录', style: TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            ...g.interventionHistory.take(3).map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  '• [${item.mode}] ${item.note} (${item.createdAt})',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF495057)),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                  loading: () => const ListTile(
                    title: Text('家长干预建议'),
                    subtitle: Text('加载中...'),
                  ),
                  error: (_, __) => const ListTile(
                    title: Text('家长干预建议'),
                    subtitle: Text('加载失败'),
                  ),
                ),
              ),
              Card(
                child: growthAsync.when(
                  data: (g) {
                    final followups = g.interventionHistory.where((e) => e.actionType == 'followup').toList();
                    final todayCount = followups.where((e) => _isSameDay(_parseRecordTime(e.createdAt), DateTime.now())).length;
                    final weekCount = followups.where((e) => _isInCurrentWeek(_parseRecordTime(e.createdAt), DateTime.now())).length;
                    final recent = followups.take(4).toList();

                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('回访完成清单', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _FollowupCountChip(label: '今日已完成', value: '$todayCount'),
                              _FollowupCountChip(label: '本周已完成', value: '$weekCount'),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (recent.isEmpty)
                            const Text('暂无回访动作记录')
                          else
                            ...recent.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  '• ${item.note}  (${item.createdAt})',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF495057)),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                  loading: () => const ListTile(
                    title: Text('回访完成清单'),
                    subtitle: Text('加载中...'),
                  ),
                  error: (_, __) => const ListTile(
                    title: Text('回访完成清单'),
                    subtitle: Text('加载失败'),
                  ),
                ),
              ),
              Card(
                child: growthAsync.when(
                  data: (g) {
                    final stats = _calcSuggestionHitStats(g.interventionHistory, sampleSize: 8);
                    final boostRate = g.interventionBoostTotal == 0
                        ? 0.0
                        : (g.interventionBoostSuccess / g.interventionBoostTotal) * 100;
                    final lightRate = g.interventionLightTotal == 0
                        ? 0.0
                        : (g.interventionLightSuccess / g.interventionLightTotal) * 100;
                    final plan = _buildInterventionPlan(
                      grade: grade,
                      behaviorScore: g.weeklyBehaviorScore,
                      boostRate: boostRate,
                      lightRate: lightRate,
                      hasStreakRisk: g.streakBroken,
                    );
                    final confidence = _calcPlanConfidence(
                      stats: stats,
                      grade: grade,
                      hasStreakRisk: g.streakBroken,
                    );
                    final fallbackPlan = confidence.level == 'low'
                        ? _buildAlternativePlan(primary: plan, grade: grade)
                        : null;

                    final onCooldown = g.interventionCooldownMinutes > 0;

                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('智能干预建议', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text(
                            '年级 G$grade · 推荐动作：${plan.title}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            plan.reason,
                            style: const TextStyle(color: Color(0xFF495057)),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: confidence.color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '置信度：${confidence.label}',
                                  style: TextStyle(color: confidence.color, fontWeight: FontWeight.w700, fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '样本 ${stats.sampleCount}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF868E96)),
                              ),
                            ],
                          ),
                          if (confidence.level == 'low') ...[
                            const SizedBox(height: 6),
                            const Text(
                              '当前样本较少或波动较大，建议同时参考备选方案。',
                              style: TextStyle(fontSize: 12, color: Color(0xFF6C757D)),
                            ),
                          ],
                          const SizedBox(height: 8),
                          ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: const Text(
                              '查看推荐依据',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                            childrenPadding: const EdgeInsets.only(bottom: 8),
                            children: [
                              _FactorRow(label: '年级分层', value: 'G$grade'),
                              _FactorRow(label: '行为评分', value: '${g.weeklyBehaviorScore}'),
                              _FactorRow(label: '鼓励有效率', value: '${boostRate.toStringAsFixed(0)}%'),
                              _FactorRow(label: '减负有效率', value: '${lightRate.toStringAsFixed(0)}%'),
                              _FactorRow(label: '连击风险', value: g.streakBroken ? '有' : '无'),
                              _FactorRow(label: '命中样本', value: '${stats.sampleCount} 次'),
                              _FactorRow(label: '命中率', value: '${stats.hitRate.toStringAsFixed(0)}%'),
                              _FactorRow(label: '置信度', value: confidence.label),
                            ],
                          ),
                          const SizedBox(height: 10),
                          FilledButton.icon(
                            onPressed: (_sendingIntervention || onCooldown)
                                ? null
                                : () {
                                    _sendIntervention(
                                      childId: childId,
                                      message: plan.message,
                                      successText: '已按智能建议发送',
                                    );
                                  },
                            icon: Icon(plan.icon),
                            label: Text('应用建议：${plan.shortAction}'),
                          ),
                          if (fallbackPlan != null) ...[
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: (_sendingIntervention || onCooldown)
                                  ? null
                                  : () {
                                      _sendIntervention(
                                        childId: childId,
                                        message: fallbackPlan.message,
                                        successText: '已应用备选建议',
                                      );
                                    },
                              icon: Icon(fallbackPlan.icon),
                              label: Text('备选方案：${fallbackPlan.shortAction}'),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                  loading: () => const ListTile(
                    title: Text('智能干预建议'),
                    subtitle: Text('加载中...'),
                  ),
                  error: (_, __) => const ListTile(
                    title: Text('智能干预建议'),
                    subtitle: Text('加载失败'),
                  ),
                ),
              ),
              Card(
                child: growthAsync.when(
                  data: (g) {
                    final stats = _calcSuggestionHitStats(g.interventionHistory, sampleSize: 8);
                    final hitColor = stats.hitRate >= 70
                        ? const Color(0xFF2F9E44)
                        : stats.hitRate >= 50
                            ? const Color(0xFF1971C2)
                            : const Color(0xFFD9480F);

                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('智能建议命中率', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '最近 ${stats.sampleCount} 次建议中命中 ${stats.hitCount} 次',
                                  style: const TextStyle(color: Color(0xFF495057)),
                                ),
                              ),
                              Text(
                                '${stats.hitRate.toStringAsFixed(0)}%',
                                style: TextStyle(color: hitColor, fontWeight: FontWeight.w800, fontSize: 18),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: (stats.hitRate / 100).clamp(0.0, 1.0),
                              minHeight: 8,
                              backgroundColor: const Color(0xFFE9ECEF),
                              valueColor: AlwaysStoppedAnimation<Color>(hitColor),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const ListTile(
                    title: Text('智能建议命中率'),
                    subtitle: Text('加载中...'),
                  ),
                  error: (_, __) => const ListTile(
                    title: Text('智能建议命中率'),
                    subtitle: Text('加载失败'),
                  ),
                ),
              ),
              Card(
                child: growthAsync.when(
                  data: (g) {
                    if (!g.interventionEffectAvailable) {
                      return const ListTile(
                        title: Text('干预效果评估（24h）'),
                        subtitle: Text('当前没有生效中的干预，无法计算短期效果'),
                      );
                    }

                    final delta = g.interventionEffectDelta;
                    final sign = delta >= 0 ? '+' : '';
                    final color = delta >= 0 ? const Color(0xFF2F9E44) : const Color(0xFFD9480F);
                    final boostRate = g.interventionBoostTotal == 0
                        ? 0.0
                        : (g.interventionBoostSuccess / g.interventionBoostTotal) * 100;
                    final lightRate = g.interventionLightTotal == 0
                        ? 0.0
                        : (g.interventionLightSuccess / g.interventionLightTotal) * 100;
                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(child: Text('干预效果评估（24h）', style: TextStyle(fontWeight: FontWeight.w700))),
                              Text(
                                '$sign${delta.toStringAsFixed(1)}%',
                                style: TextStyle(color: color, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '基线 ${g.interventionBaselineCompletion.toStringAsFixed(1)}% -> 当前 ${g.interventionCurrentCompletion.toStringAsFixed(1)}%',
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '鼓励有效率 ${boostRate.toStringAsFixed(0)}% · 减负有效率 ${lightRate.toStringAsFixed(0)}%',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF6C757D)),
                          ),
                          const SizedBox(height: 10),
                          _MiniEffectTrend(values: g.interventionEffectTrend),
                        ],
                      ),
                    );
                  },
                  loading: () => const ListTile(
                    title: Text('干预效果评估（24h）'),
                    subtitle: Text('加载中...'),
                  ),
                  error: (_, __) => const ListTile(
                    title: Text('干预效果评估（24h）'),
                    subtitle: Text('加载失败'),
                  ),
                ),
              ),
              Card(
                child: growthAsync.when(
                  data: (g) {
                    final nextMinutes = g.interventionNextFollowupMinutes;
                    final priority = _calcFollowupPriority(
                      effectAvailable: g.interventionEffectAvailable,
                      nextFollowupMinutes: nextMinutes,
                      effectDelta: g.interventionEffectDelta,
                    );
                    final onCooldown = g.interventionCooldownMinutes > 0;
                    final pending2h = g.interventionFollowup2hReached && !g.interventionFollowup2hDone;
                    final pending6h = g.interventionFollowup6hReached && !g.interventionFollowup6hDone;
                    final hasPending = pending2h || pending6h;
                    final nextText = nextMinutes > 0
                        ? '下个回访节点：$nextMinutes 分钟后'
                        : g.interventionEffectAvailable
                            ? '今日回访节点已完成，可进行复盘'
                            : '当前无生效干预，无需回访';
                    final reviewHint = g.interventionEffectAvailable
                        ? (g.interventionEffectDelta >= 3
                            ? '建议：保持当前干预策略，并在晚间做一次简短鼓励复盘。'
                            : '建议：优先关注任务拆分与减负节奏，必要时切换备选方案。')
                        : '建议：下次干预后在 2h 与 6h 进行回访观察。';
                    final actionLabel = pending2h
                        ? '补做 2h 回访'
                        : pending6h
                            ? '补做 6h 回访'
                            : '执行复盘动作';
                    final actionSubType = pending2h
                        ? '2h_makeup'
                        : pending6h
                            ? '6h_makeup'
                            : 'review';
                    final followupMessage = pending2h
                        ? '2h回访补做：请确认孩子已进入学习状态，优先完成1个主线任务。'
                        : pending6h
                            ? '6h回访补做：请复盘完成率变化，必要时切换减负策略。'
                            : (g.interventionEffectDelta < 1
                                ? '复盘建议：当前提升有限，建议减负并优先完成1个轻任务。'
                                : '复盘建议：状态稳定，继续鼓励并保持主线节奏。');
                    final followupSuccess = pending2h
                        ? '已补做 2h 回访'
                        : pending6h
                            ? '已补做 6h 回访'
                            : '已执行复盘动作';

                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(child: Text('干预回访与复盘', style: TextStyle(fontWeight: FontWeight.w700))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: priority.color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${priority.label}优先级',
                                  style: TextStyle(color: priority.color, fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _FollowupNodeRow(
                            done: g.interventionFollowup2hDone,
                            pending: pending2h,
                            label: '2h 回访节点',
                          ),
                          const SizedBox(height: 6),
                          _FollowupNodeRow(
                            done: g.interventionFollowup6hDone,
                            pending: pending6h,
                            label: '6h 回访节点',
                          ),
                          const SizedBox(height: 8),
                          Text(nextText, style: const TextStyle(fontSize: 12, color: Color(0xFF495057))),
                          const SizedBox(height: 6),
                          Text(reviewHint, style: const TextStyle(fontSize: 12, color: Color(0xFF6C757D))),
                          if (g.interventionFollowupOverdue) ...[
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF5F5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFFC9C9)),
                              ),
                              child: Text(
                                '回访逾期预警：${g.interventionFollowupOverdueStage} 节点已逾期 ${g.interventionFollowupOverdueMinutes} 分钟',
                                style: const TextStyle(color: Color(0xFFD9480F), fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          FilledButton.tonalIcon(
                            onPressed: (_sendingIntervention || onCooldown || !g.interventionEffectAvailable)
                                ? null
                                : () {
                                    _sendIntervention(
                                      childId: childId,
                                      message: followupMessage,
                                      successText: followupSuccess,
                                      actionType: 'followup',
                                      actionSubType: actionSubType,
                                    );
                                  },
                            icon: Icon(g.interventionEffectDelta < 1 ? Icons.self_improvement : Icons.favorite),
                            label: Text(hasPending ? actionLabel : '执行复盘动作'),
                          ),
                          if (onCooldown)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                '操作冷却中：${g.interventionCooldownMinutes} 分钟后可再次执行',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF868E96)),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                  loading: () => const ListTile(
                    title: Text('干预回访与复盘'),
                    subtitle: Text('加载中...'),
                  ),
                  error: (_, __) => const ListTile(
                    title: Text('干预回访与复盘'),
                    subtitle: Text('加载失败'),
                  ),
                ),
              ),
              Card(
                child: growthAsync.when(
                  data: (g) {
                    final used = (g.recoverMaxPerWeek - g.recoverUsesLeft).clamp(0, g.recoverMaxPerWeek);
                    final h = g.interventionRemainingMinutes ~/ 60;
                    final m = g.interventionRemainingMinutes % 60;
                    final interventionText = g.interventionActive
                        ? '干预生效中 ${h}h${m}m'
                        : '干预未生效';
                    return ListTile(
                      title: const Text('恢复卡使用监控'),
                      subtitle: Text('本周已使用 $used/${g.recoverMaxPerWeek} 次 · 连击 ${g.streakDays} 天 · $interventionText'),
                      trailing: Text('剩余 ${g.recoverUsesLeft} 次'),
                    );
                  },
                  loading: () => const ListTile(
                    title: Text('恢复卡使用监控'),
                    subtitle: Text('加载中...'),
                  ),
                  error: (_, __) => const ListTile(
                    title: Text('恢复卡使用监控'),
                    subtitle: Text('加载失败'),
                  ),
                ),
              ),
              growthAsync.when(
                data: (g) {
                  final now = DateTime.now();
                  final repairTrendForRisk = _buildRepairAchievementTrend(g.interventionHistory, now: now);
                  final repairAcceptanceForRisk = _calcRepairAcceptance(repairTrendForRisk);
                  final risks = <String>[];
                  var riskScore = 0;
                  if (g.streakBroken) {
                    risks.add('学习连击已中断 ${g.missedDays} 天');
                    riskScore += 35;
                  }
                  if (g.recoverUsesLeft == 0) {
                    risks.add('恢复卡本周额度已用完');
                    riskScore += 22;
                  }
                  if (g.streakBroken && g.energyBalance < g.recoverCost) {
                    risks.add('当前能量不足，无法恢复连击');
                    riskScore += 18;
                  }
                  if (g.interventionFollowupOverdue) {
                    risks.add('回访节点 ${g.interventionFollowupOverdueStage} 已逾期 ${g.interventionFollowupOverdueMinutes} 分钟');
                    riskScore += g.interventionFollowupOverdueStage == '6h' ? 30 : 20;
                  }
                  if (g.interventionEffectAvailable && g.interventionEffectDelta < 0) {
                    risks.add('干预短期效果为负，建议调整干预策略');
                    riskScore += 16;
                  }
                  if (!repairAcceptanceForRisk.passed) {
                    risks.add('修复验收未达标：${repairAcceptanceForRisk.detail}');
                    riskScore += 14;
                  }

                  if (risks.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final level = _calcWeeklyRiskLevel(riskScore);
                  final actionQueue = _buildRiskActionQueue(g);
                  final queueToday = g.interventionHistory
                      .where((e) => e.actionSource == 'risk_queue')
                      .where((e) => _isSameDay(_parseRecordTime(e.createdAt), now))
                      .toList();
                  final queueWeek = g.interventionHistory
                      .where((e) => e.actionSource == 'risk_queue')
                      .where((e) => _isInCurrentWeek(_parseRecordTime(e.createdAt), now))
                      .toList();
                  final queuePrevWeek = g.interventionHistory
                      .where((e) => e.actionSource == 'risk_queue')
                      .where((e) => _isInPreviousWeek(_parseRecordTime(e.createdAt), now))
                      .toList();
                  final queueTodayReduce = queueToday.fold<int>(0, (sum, e) => sum + e.riskReduceScore);
                  final queueWeekReduce = queueWeek.fold<int>(0, (sum, e) => sum + e.riskReduceScore);
                  final normalQuality = _calcDashboardBucketQuality(queueWeek, bucket: _DashboardQualityBucket.normal);
                  final makeupQuality = _calcDashboardBucketQuality(queueWeek, bucket: _DashboardQualityBucket.makeup);
                  final reviewQuality = _calcDashboardBucketQuality(queueWeek, bucket: _DashboardQualityBucket.review);
                  final prevNormalQuality = _calcDashboardBucketQuality(queuePrevWeek, bucket: _DashboardQualityBucket.normal);
                  final prevMakeupQuality = _calcDashboardBucketQuality(queuePrevWeek, bucket: _DashboardQualityBucket.makeup);
                  final prevReviewQuality = _calcDashboardBucketQuality(queuePrevWeek, bucket: _DashboardQualityBucket.review);
                  final deltaRepairQueue = _buildDeltaRepairQueue(
                    normal: normalQuality,
                    prevNormal: prevNormalQuality,
                    makeup: makeupQuality,
                    prevMakeup: prevMakeupQuality,
                    review: reviewQuality,
                    prevReview: prevReviewQuality,
                    now: now,
                  );
                  final repairTrend = _buildRepairAchievementTrend(g.interventionHistory, now: now);
                  final repairAcceptance = _calcRepairAcceptance(repairTrend);

                  return Column(
                    children: [
                      Card(
                        color: level.bg,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: level.color),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text('本周风险提示', style: TextStyle(fontWeight: FontWeight.w700, color: level.color)),
                                  ),
                                  Text(
                                    '${level.label}风险  ${riskScore.clamp(0, 100)}分',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: level.color),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...risks.map(
                                (risk) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text('• $risk'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('建议动作优先队列', style: TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              ...actionQueue.take(3).map((item) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(top: 2),
                                        child: Icon(item.icon, size: 16, color: const Color(0xFF495057)),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${item.reason}（预计降风险 ${item.reduceScore} 分）',
                                              style: const TextStyle(fontSize: 12, color: Color(0xFF6C757D)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      FilledButton.tonal(
                                        onPressed: _sendingIntervention
                                            ? null
                                            : () {
                                                if (item.kind == _RiskActionKind.navigateGrowth) {
                                                  Navigator.pushNamed(context, '/growth');
                                                  return;
                                                }
                                                _sendIntervention(
                                                  childId: childId,
                                                  message: item.message,
                                                  successText: item.successText,
                                                  actionType: item.actionType,
                                                  actionSubType: item.actionSubType,
                                                  actionSource: 'risk_queue',
                                                  riskReduceScore: item.reduceScore,
                                                );
                                              },
                                        child: const Text('执行'),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('队列执行历史（今日/本周）', style: TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _FollowupCountChip(label: '今日执行', value: '${queueToday.length}'),
                                  _FollowupCountChip(label: '今日降分', value: '$queueTodayReduce'),
                                  _FollowupCountChip(label: '本周执行', value: '${queueWeek.length}'),
                                  _FollowupCountChip(label: '本周降分', value: '$queueWeekReduce'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (queueToday.isEmpty)
                                const Text('今日暂无队列执行记录')
                              else
                                ...queueToday.take(3).map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      '• ${item.note}（-${item.riskReduceScore} 分）',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF495057)),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('队列质量预览（本周）', style: TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              _DashboardBucketRow(label: '普通干预', quality: normalQuality, previous: prevNormalQuality),
                              const SizedBox(height: 6),
                              _DashboardBucketRow(label: '补做回访', quality: makeupQuality, previous: prevMakeupQuality),
                              const SizedBox(height: 6),
                              _DashboardBucketRow(label: '复盘动作', quality: reviewQuality, previous: prevReviewQuality),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () => Navigator.pushNamed(context, '/weekly-report'),
                                  icon: const Icon(Icons.open_in_new),
                                  label: const Text('查看周报详版'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (deltaRepairQueue.isNotEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text('环比下降修复建议', style: TextStyle(fontWeight: FontWeight.w700)),
                                    ),
                                    if (deltaRepairQueue.any((e) => e.isOverdue == true))
                                      FilledButton.tonal(
                                        onPressed: _sendingIntervention
                                            ? null
                                            : () {
                                                final urgent = deltaRepairQueue.firstWhere((e) => e.isOverdue == true);
                                                _sendIntervention(
                                                  childId: childId,
                                                  message: urgent.message,
                                                  successText: '已执行紧急修复',
                                                  actionType: urgent.actionType,
                                                  actionSubType: urgent.actionSubType,
                                                  actionSource: 'risk_queue',
                                                  riskReduceScore: urgent.reduceScore,
                                                );
                                              },
                                        child: const Text('紧急修复'),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ...deltaRepairQueue.take(3).map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(item.icon, size: 16, color: const Color(0xFF495057)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                            Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${item.reason}（建议修复 ${item.reduceScore} 分）',
                                              style: const TextStyle(fontSize: 12, color: Color(0xFF6C757D)),
                                            ),
                                            if (item.targetScore != null && item.currentScore != null) ...[
                                              const SizedBox(height: 4),
                                              _RepairProgressRow(
                                                currentScore: item.currentScore!,
                                                targetScore: item.targetScore!,
                                                daysLeft: item.deadlineDaysLeft,
                                                isOverdue: item.isOverdue,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                        FilledButton.tonal(
                                          onPressed: _sendingIntervention
                                              ? null
                                              : () {
                                                  _sendIntervention(
                                                    childId: childId,
                                                    message: item.message,
                                                    successText: item.successText,
                                                    actionType: item.actionType,
                                                    actionSubType: item.actionSubType,
                                                    actionSource: 'risk_queue',
                                                    riskReduceScore: item.reduceScore,
                                                  );
                                                },
                                          child: const Text('修复'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Divider(),
                                const SizedBox(height: 6),
                                const Text('修复达成趋势（本周）', style: TextStyle(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 8),
                                _RepairTrendBars(values: repairTrend),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _FollowupCountChip(
                                      label: '达标天数',
                                      value: '${repairAcceptance.hitDays}/7',
                                    ),
                                    const SizedBox(width: 8),
                                    _FollowupCountChip(
                                      label: '最新得分',
                                      value: '${repairAcceptance.latestScore.toStringAsFixed(0)}',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  repairAcceptance.detail,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: repairAcceptance.color,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: trendAsync.when(
                    data: (trend) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('近7日完成趋势'),
                        const SizedBox(height: 12),
                        _MiniTrendBars(values: trend),
                      ],
                    ),
                    error: (error, _) => Text('趋势加载失败: $error'),
                    loading: () => const SizedBox(
                      height: 80,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/weekly-report'),
                icon: const Icon(Icons.auto_graph),
                label: const Text('查看成长周报'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/intervention-history'),
                icon: const Icon(Icons.history),
                label: const Text('查看干预历史详情'),
              ),
            ],
          );
        },
        error: (error, _) => Center(child: Text('加载失败: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      bottomNavigationBar: const AppBottomNav(currentRoute: '/parent-dashboard'),
    );
  }
}

class _MiniTrendBars extends StatelessWidget {
  const _MiniTrendBars({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final labels = const ['一', '二', '三', '四', '五', '六', '日'];
    return SizedBox(
      height: 130,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (index) {
          final value = values[index].clamp(0.0, 100.0).toDouble();
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('${value.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 10)),
                  const SizedBox(height: 4),
                  Container(
                    height: value,
                    decoration: BoxDecoration(
                      color: Colors.brown.shade300,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(labels[index], style: const TextStyle(fontSize: 11)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _FollowupCountChip extends StatelessWidget {
  const _FollowupCountChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F5FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF1971C2))),
          const SizedBox(width: 6),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1971C2))),
        ],
      ),
    );
  }
}

class _RepairProgressRow extends StatelessWidget {
  const _RepairProgressRow({
    required this.currentScore,
    required this.targetScore,
    required this.daysLeft,
    required this.isOverdue,
  });

  final int currentScore;
  final int targetScore;
  final int? daysLeft;
  final bool? isOverdue;

  @override
  Widget build(BuildContext context) {
    final progress = targetScore <= 0 ? 0.0 : (currentScore / targetScore).clamp(0.0, 1.0);
    final gap = (targetScore - currentScore).clamp(0, 100);
    final overdue = isOverdue == true;
    final deadlineText = overdue
        ? '已逾期'
        : daysLeft == null
            ? ''
            : '距截止 ${daysLeft} 天';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '修复目标 $targetScore 分（当前 $currentScore，差 $gap）',
                style: TextStyle(
                  fontSize: 11,
                  color: overdue ? const Color(0xFFD9480F) : const Color(0xFF495057),
                  fontWeight: overdue ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (deadlineText.isNotEmpty)
              Text(
                deadlineText,
                style: TextStyle(
                  fontSize: 11,
                  color: overdue ? const Color(0xFFD9480F) : const Color(0xFF868E96),
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: const Color(0xFFE9ECEF),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1971C2)),
          ),
        ),
      ],
    );
  }
}

class _FollowupNodeRow extends StatelessWidget {
  const _FollowupNodeRow({
    required this.done,
    required this.pending,
    required this.label,
  });

  final bool done;
  final bool pending;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = done
        ? const Color(0xFF2F9E44)
        : pending
            ? const Color(0xFFD9480F)
            : const Color(0xFF868E96);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: pending ? const Color(0xFFFFF5F5) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, size: 18, color: color),
          const SizedBox(width: 8),
          Text(label),
          if (pending) ...[
            const SizedBox(width: 8),
            const Text('待补做', style: TextStyle(fontSize: 12, color: Color(0xFFD9480F), fontWeight: FontWeight.w700)),
          ],
        ],
      ),
    );
  }
}

enum _DashboardQualityBucket { normal, makeup, review }

_DashboardBucketQuality _calcDashboardBucketQuality(
  List<InterventionRecord> items, {
  required _DashboardQualityBucket bucket,
}) {
  bool match(InterventionRecord e) {
    switch (bucket) {
      case _DashboardQualityBucket.normal:
        return e.actionType == 'manual';
      case _DashboardQualityBucket.makeup:
        return e.actionSubType == '2h_makeup' || e.actionSubType == '6h_makeup';
      case _DashboardQualityBucket.review:
        return e.actionSubType == 'review';
    }
  }

  final selected = items.where(match).toList();
  final expected = selected.fold<int>(0, (sum, e) => sum + e.riskReduceScore);
  final actual = selected.fold<double>(0.0, (sum, e) {
    final delta = e.effectDelta;
    return sum + (delta > 0 ? delta * 4.0 : 0.0);
  });
  final score = expected <= 0 ? 0 : ((actual / expected) * 100).round().clamp(0, 100);
  return _DashboardBucketQuality(count: selected.length, score: score);
}

class _DashboardBucketQuality {
  const _DashboardBucketQuality({required this.count, required this.score});

  final int count;
  final int score;
}

class _DashboardBucketRow extends StatelessWidget {
  const _DashboardBucketRow({
    required this.label,
    required this.quality,
    required this.previous,
  });

  final String label;
  final _DashboardBucketQuality quality;
  final _DashboardBucketQuality previous;

  @override
  Widget build(BuildContext context) {
    final color = quality.score >= 80
        ? const Color(0xFF2F9E44)
        : quality.score >= 55
            ? const Color(0xFFF08C00)
            : const Color(0xFFD9480F);
    final delta = quality.score - previous.score;
    final hasPrevious = previous.count > 0;
    final deltaText = delta > 0
        ? '↑ +$delta'
        : delta < 0
            ? '↓ $delta'
            : '→ 0';
    final deltaColor = delta > 0
        ? const Color(0xFF2F9E44)
        : delta < 0
            ? const Color(0xFFD9480F)
            : const Color(0xFF868E96);

    return Row(
      children: [
        Expanded(child: Text('$label（${quality.count}次）', style: const TextStyle(fontSize: 12))),
        SizedBox(
          width: 120,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (quality.score / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFFE9ECEF),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${quality.score}', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700)),
            Text(
              hasPrevious ? deltaText : '新',
              style: TextStyle(fontSize: 10, color: hasPrevious ? deltaColor : const Color(0xFF868E96), fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ],
    );
  }
}

DateTime? _parseRecordTime(String value) {
  if (value.isEmpty) {
    return null;
  }
  final normalized = value.replaceFirst(' ', 'T');
  return DateTime.tryParse(normalized);
}

bool _isSameDay(DateTime? a, DateTime b) {
  if (a == null) {
    return false;
  }
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

bool _isInCurrentWeek(DateTime? date, DateTime now) {
  if (date == null) {
    return false;
  }
  final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
  final end = start.add(const Duration(days: 7));
  return !date.isBefore(start) && date.isBefore(end);
}

bool _isInPreviousWeek(DateTime? date, DateTime now) {
  if (date == null) {
    return false;
  }
  final currentStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
  final prevStart = currentStart.subtract(const Duration(days: 7));
  return !date.isBefore(prevStart) && date.isBefore(currentStart);
}

_InterventionPlan _buildInterventionPlan({
  required int grade,
  required int behaviorScore,
  required double boostRate,
  required double lightRate,
  required bool hasStreakRisk,
}) {
  if (hasStreakRisk) {
    return const _InterventionPlan(
      title: '减负稳节奏',
      shortAction: '建议减负',
      reason: '检测到连击风险，先保证主线保底更稳。',
      message: '今天优先减负：先完成1个主线和1个轻任务，保证连续学习。',
      icon: Icons.self_improvement,
    );
  }

  if (grade <= 2) {
    if (behaviorScore < 70 || lightRate >= boostRate) {
      return const _InterventionPlan(
        title: '低年级减负优先',
        shortAction: '建议减负',
        reason: '低年级更适合短任务和高频正反馈，避免挫败。',
        message: '今天采用低年级减负方案：短任务优先，主线保底完成即可。',
        icon: Icons.self_improvement,
      );
    }
    return const _InterventionPlan(
      title: '低年级鼓励推进',
      shortAction: '发送鼓励',
      reason: '当前状态良好，可用鼓励提升主动性。',
      message: '你做得很棒！按计划完成主线后再做一个轻挑战任务。',
      icon: Icons.favorite,
    );
  }

  if (grade <= 4) {
    if (behaviorScore >= 78 && boostRate >= 55) {
      return const _InterventionPlan(
        title: '均衡年级冲刺',
        shortAction: '发送鼓励',
        reason: '行为评分与鼓励效果均较好，可适度冲刺。',
        message: '今天状态很好，继续保持主线节奏，完成后挑战一个进阶任务。',
        icon: Icons.favorite,
      );
    }
    return const _InterventionPlan(
      title: '均衡年级稳态',
      shortAction: '建议减负',
      reason: '先保证完成率，再逐步增加难度更稳妥。',
      message: '今天建议减负：主线任务优先，支线按精力完成。',
      icon: Icons.self_improvement,
    );
  }

  if (behaviorScore >= 82 && boostRate >= lightRate) {
    return const _InterventionPlan(
      title: '高年级目标冲刺',
      shortAction: '发送鼓励',
      reason: '高年级可承受更高挑战，鼓励策略更匹配当前状态。',
      message: '高年级冲刺日：保持主线节奏，建议加做1个中高难度任务。',
      icon: Icons.favorite,
    );
  }

  return const _InterventionPlan(
    title: '高年级压力管理',
    shortAction: '建议减负',
    reason: '先稳住节奏与完成率，再恢复挑战强度。',
    message: '今天优先减负，保底主线，减少额外挑战，关注学习稳定性。',
    icon: Icons.self_improvement,
  );
}

class _InterventionPlan {
  const _InterventionPlan({
    required this.title,
    required this.shortAction,
    required this.reason,
    required this.message,
    required this.icon,
  });

  final String title;
  final String shortAction;
  final String reason;
  final String message;
  final IconData icon;
}

_InterventionPlan _buildAlternativePlan({
  required _InterventionPlan primary,
  required int grade,
}) {
  if (primary.shortAction == '发送鼓励') {
    return const _InterventionPlan(
      title: '备选：稳态减负',
      shortAction: '建议减负',
      reason: '当冲刺效果不稳定时，先提升完成率再加压。',
      message: '备选方案：今天先减负，优先主线与轻任务，稳定节奏。',
      icon: Icons.self_improvement,
    );
  }

  if (grade <= 2) {
    return const _InterventionPlan(
      title: '备选：轻鼓励推进',
      shortAction: '发送鼓励',
      reason: '低年级可用轻鼓励提升兴趣，不额外加压。',
      message: '备选方案：做得很棒，完成主线后可再做一个轻挑战任务。',
      icon: Icons.favorite,
    );
  }

  return const _InterventionPlan(
    title: '备选：鼓励冲刺',
    shortAction: '发送鼓励',
    reason: '在完成率稳定时，用鼓励提升挑战意愿。',
    message: '备选方案：保持节奏，完成主线后挑战一个进阶任务。',
    icon: Icons.favorite,
  );
}

_PlanConfidence _calcPlanConfidence({
  required _SuggestionHitStats stats,
  required int grade,
  required bool hasStreakRisk,
}) {
  if (hasStreakRisk) {
    return const _PlanConfidence(level: 'high', label: '高', color: Color(0xFF2F9E44));
  }

  if (stats.sampleCount < 3) {
    return const _PlanConfidence(level: 'low', label: '低', color: Color(0xFFD9480F));
  }

  final adjusted = stats.hitRate + (grade <= 2 ? 4 : 0) - (grade >= 5 ? 3 : 0);
  if (adjusted >= 72) {
    return const _PlanConfidence(level: 'high', label: '高', color: Color(0xFF2F9E44));
  }
  if (adjusted >= 52) {
    return const _PlanConfidence(level: 'medium', label: '中', color: Color(0xFF1971C2));
  }
  return const _PlanConfidence(level: 'low', label: '低', color: Color(0xFFD9480F));
}

class _PlanConfidence {
  const _PlanConfidence({
    required this.level,
    required this.label,
    required this.color,
  });

  final String level;
  final String label;
  final Color color;
}

_FollowupPriority _calcFollowupPriority({
  required bool effectAvailable,
  required int nextFollowupMinutes,
  required double effectDelta,
}) {
  if (!effectAvailable) {
    return const _FollowupPriority(label: '低', color: Color(0xFF2F9E44));
  }

  if (nextFollowupMinutes <= 15 || effectDelta < 0) {
    return const _FollowupPriority(label: '高', color: Color(0xFFD9480F));
  }
  if (nextFollowupMinutes <= 60 || effectDelta < 2) {
    return const _FollowupPriority(label: '中', color: Color(0xFFF08C00));
  }
  return const _FollowupPriority(label: '低', color: Color(0xFF2F9E44));
}

class _FollowupPriority {
  const _FollowupPriority({required this.label, required this.color});

  final String label;
  final Color color;
}

List<_RiskActionItem> _buildRiskActionQueue(GrowthSnapshot g) {
  final actions = <_RiskActionItem>[];
  final now = DateTime.now();
  final repairTrend = _buildRepairAchievementTrend(g.interventionHistory, now: now);
  final repairAcceptance = _calcRepairAcceptance(repairTrend);

  if (!repairAcceptance.passed) {
    actions.add(
      const _RiskActionItem(
        title: '优先执行修复动作',
        reason: '修复验收未达标，需先提升近3日修复质量',
        reduceScore: 26,
        kind: _RiskActionKind.sendIntervention,
        message: '修复优先：先完成1次高质量回访并对比基线完成率，再决定下一步策略。',
        successText: '已执行修复优先动作',
        actionType: 'followup',
        actionSubType: 'review',
        icon: Icons.trending_up,
      ),
    );
  }

  if (g.interventionFollowupOverdue) {
    final is6h = g.interventionFollowupOverdueStage == '6h';
    actions.add(
      _RiskActionItem(
        title: is6h ? '补做 6h 回访' : '补做 2h 回访',
        reason: '回访节点逾期 ${g.interventionFollowupOverdueMinutes} 分钟',
        reduceScore: is6h ? 30 : 22,
        kind: _RiskActionKind.sendIntervention,
        message: is6h
            ? '6h回访补做：请复盘完成率变化，必要时切换减负策略。'
            : '2h回访补做：请确认孩子已进入学习状态，优先完成1个主线任务。',
        successText: is6h ? '已补做 6h 回访' : '已补做 2h 回访',
        actionType: 'followup',
        actionSubType: is6h ? '6h_makeup' : '2h_makeup',
        icon: Icons.alarm,
      ),
    );
  }

  if (g.streakBroken && g.canRecover) {
    actions.add(
      const _RiskActionItem(
        title: '恢复连击',
        reason: '连击中断且可恢复',
        reduceScore: 24,
        kind: _RiskActionKind.navigateGrowth,
        message: '',
        successText: '',
        actionType: 'manual',
        actionSubType: '',
        icon: Icons.local_fire_department,
      ),
    );
  }

  if (g.interventionEffectAvailable && g.interventionEffectDelta < 0) {
    actions.add(
      const _RiskActionItem(
        title: '切换减负策略',
        reason: '干预短期效果为负',
        reduceScore: 16,
        kind: _RiskActionKind.sendIntervention,
        message: '风险干预：当前策略效果不佳，建议减负并优先轻任务。',
        successText: '已切换为减负策略',
        actionType: 'manual',
        actionSubType: '',
        icon: Icons.self_improvement,
      ),
    );
  }

  if (g.recoverUsesLeft == 0) {
    actions.add(
      const _RiskActionItem(
        title: '发送鼓励干预',
        reason: '恢复卡额度耗尽，需要行为引导',
        reduceScore: 10,
        kind: _RiskActionKind.sendIntervention,
        message: '恢复卡已用尽，今天请优先完成主线任务，保持稳定节奏。',
        successText: '已发送鼓励干预',
        actionType: 'manual',
        actionSubType: '',
        icon: Icons.favorite,
      ),
    );
  }

  actions.sort((a, b) {
    final aOverdue = a.isOverdue == true ? 1 : 0;
    final bOverdue = b.isOverdue == true ? 1 : 0;
    if (aOverdue != bOverdue) {
      return bOverdue.compareTo(aOverdue);
    }
    return b.reduceScore.compareTo(a.reduceScore);
  });
  return actions;
}

List<_RiskActionItem> _buildDeltaRepairQueue({
  required _DashboardBucketQuality normal,
  required _DashboardBucketQuality prevNormal,
  required _DashboardBucketQuality makeup,
  required _DashboardBucketQuality prevMakeup,
  required _DashboardBucketQuality review,
  required _DashboardBucketQuality prevReview,
  required DateTime now,
}) {
  final actions = <_RiskActionItem>[];
  final daysLeft = (7 - now.weekday).clamp(0, 7);

  final normalDelta = normal.score - prevNormal.score;
  final makeupDelta = makeup.score - prevMakeup.score;
  final reviewDelta = review.score - prevReview.score;

  if (prevNormal.count > 0 && normalDelta < 0) {
    actions.add(
      _RiskActionItem(
        title: '修复普通干预质量',
        reason: '普通干预环比下降 ${normalDelta.abs()} 分',
        reduceScore: normalDelta.abs().clamp(6, 20),
        kind: _RiskActionKind.sendIntervention,
        message: '质量修复：普通干预先聚焦主线任务，减少一次性目标数量。',
        successText: '已发送普通干预修复动作',
        actionType: 'manual',
        actionSubType: '',
        currentScore: normal.score,
        targetScore: prevNormal.score,
        deadlineDaysLeft: daysLeft,
        isOverdue: daysLeft == 0 && normal.score < prevNormal.score,
        icon: Icons.tune,
      ),
    );
  }

  if (prevMakeup.count > 0 && makeupDelta < 0) {
    actions.add(
      _RiskActionItem(
        title: '修复补做回访质量',
        reason: '补做回访环比下降 ${makeupDelta.abs()} 分',
        reduceScore: makeupDelta.abs().clamp(8, 24),
        kind: _RiskActionKind.sendIntervention,
        message: '质量修复：回访补做时先确认任务拆分，再执行减负策略。',
        successText: '已发送补做回访修复动作',
        actionType: 'followup',
        actionSubType: '2h_makeup',
        currentScore: makeup.score,
        targetScore: prevMakeup.score,
        deadlineDaysLeft: daysLeft,
        isOverdue: daysLeft == 0 && makeup.score < prevMakeup.score,
        icon: Icons.build_circle,
      ),
    );
  }

  if (prevReview.count > 0 && reviewDelta < 0) {
    actions.add(
      _RiskActionItem(
        title: '修复复盘动作质量',
        reason: '复盘动作环比下降 ${reviewDelta.abs()} 分',
        reduceScore: reviewDelta.abs().clamp(6, 18),
        kind: _RiskActionKind.sendIntervention,
        message: '质量修复：复盘时请对比基线与当前完成率，再决定下一动作。',
        successText: '已发送复盘质量修复动作',
        actionType: 'followup',
        actionSubType: 'review',
        currentScore: review.score,
        targetScore: prevReview.score,
        deadlineDaysLeft: daysLeft,
        isOverdue: daysLeft == 0 && review.score < prevReview.score,
        icon: Icons.rule,
      ),
    );
  }

  actions.sort((a, b) => b.reduceScore.compareTo(a.reduceScore));
  return actions;
}

enum _RiskActionKind { sendIntervention, navigateGrowth }

class _RiskActionItem {
  const _RiskActionItem({
    required this.title,
    required this.reason,
    required this.reduceScore,
    required this.kind,
    required this.message,
    required this.successText,
    required this.actionType,
    required this.actionSubType,
    required this.icon,
    this.currentScore,
    this.targetScore,
    this.deadlineDaysLeft,
    this.isOverdue,
  });

  final String title;
  final String reason;
  final int reduceScore;
  final _RiskActionKind kind;
  final String message;
  final String successText;
  final String actionType;
  final String actionSubType;
  final IconData icon;
  final int? currentScore;
  final int? targetScore;
  final int? deadlineDaysLeft;
  final bool? isOverdue;
}

_RiskLevel _calcWeeklyRiskLevel(int score) {
  final safe = score.clamp(0, 100);
  if (safe >= 70) {
    return const _RiskLevel(
      label: '高',
      color: Color(0xFFD9480F),
      bg: Color(0xFFFFF4E6),
    );
  }
  if (safe >= 40) {
    return const _RiskLevel(
      label: '中',
      color: Color(0xFFF08C00),
      bg: Color(0xFFFFF9DB),
    );
  }
  return const _RiskLevel(
    label: '低',
    color: Color(0xFF2F9E44),
    bg: Color(0xFFEBFBEE),
  );
}

class _RiskLevel {
  const _RiskLevel({required this.label, required this.color, required this.bg});

  final String label;
  final Color color;
  final Color bg;
}

_SuggestionHitStats _calcSuggestionHitStats(
  List<InterventionRecord> history, {
  required int sampleSize,
}) {
  final filtered = history.where((e) {
    final mode = e.mode;
    return (mode == 'boost' || mode == 'light') && e.actionType == 'manual';
  }).take(sampleSize).toList();

  if (filtered.isEmpty) {
    return const _SuggestionHitStats(hitCount: 0, sampleCount: 0, hitRate: 0);
  }

  final hitCount = filtered.where((e) => e.effectDelta > 0).length;
  final hitRate = (hitCount / filtered.length) * 100;
  return _SuggestionHitStats(
    hitCount: hitCount,
    sampleCount: filtered.length,
    hitRate: hitRate,
  );
}

class _SuggestionHitStats {
  const _SuggestionHitStats({
    required this.hitCount,
    required this.sampleCount,
    required this.hitRate,
  });

  final int hitCount;
  final int sampleCount;
  final double hitRate;
}

class _FactorRow extends StatelessWidget {
  const _FactorRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF868E96)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, color: Color(0xFF343A40), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniEffectTrend extends StatelessWidget {
  const _MiniEffectTrend({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const SizedBox.shrink();
    }

    final labels = const ['-20h', '-16h', '-12h', '-8h', '-4h', 'Now'];
    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (index) {
          final value = values[index].clamp(0.0, 100.0).toDouble();
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: value,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C5CE7).withOpacity(0.75),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    labels[index < labels.length ? index : labels.length - 1],
                    style: const TextStyle(fontSize: 10, color: Color(0xFF868E96)),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

List<double> _buildRepairAchievementTrend(List<InterventionRecord> history, {required DateTime now}) {
  final sums = List<double>.filled(7, 0);
  final counts = List<int>.filled(7, 0);

  for (final item in history) {
    if (item.actionSource != 'risk_queue') {
      continue;
    }
    final isRepair = item.note.contains('质量修复') ||
        item.actionSubType == '2h_makeup' ||
        item.actionSubType == '6h_makeup' ||
        item.actionSubType == 'review';
    if (!isRepair) {
      continue;
    }

    final date = _parseRecordTime(item.createdAt);
    if (!_isInCurrentWeek(date, now) || date == null) {
      continue;
    }

    final expected = item.riskReduceScore <= 0 ? 1 : item.riskReduceScore;
    final actual = item.effectDelta > 0 ? item.effectDelta * 4.0 : 0.0;
    final quality = ((actual / expected) * 100).clamp(0.0, 100.0);
    final index = date.weekday - 1;
    sums[index] += quality;
    counts[index] += 1;
  }

  return List<double>.generate(7, (index) {
    final count = counts[index];
    if (count <= 0) {
      return 0;
    }
    return sums[index] / count;
  });
}

_RepairAcceptance _calcRepairAcceptance(List<double> trend) {
  if (trend.isEmpty) {
    return const _RepairAcceptance(
      hitDays: 0,
      latestScore: 0,
      passed: false,
      detail: '暂无修复执行记录，验收目标：近3日均值>=65 且最近1日>=70。',
      color: Color(0xFF868E96),
    );
  }

  final hitDays = trend.where((value) => value >= 70).length;
  final latest = trend.last;
  final tail = trend.length >= 3 ? trend.sublist(trend.length - 3) : trend;
  final tailAvg = tail.isEmpty ? 0.0 : tail.reduce((a, b) => a + b) / tail.length;
  final passed = latest >= 70 && tailAvg >= 65 && hitDays >= 2;
  final detail = passed
      ? '已达到修复验收线（近3日均值 ${tailAvg.toStringAsFixed(0)}，最新 ${latest.toStringAsFixed(0)}）。'
      : '未达修复验收线（近3日均值 ${tailAvg.toStringAsFixed(0)}，最新 ${latest.toStringAsFixed(0)}；目标为近3日>=65 且最新>=70）。';

  return _RepairAcceptance(
    hitDays: hitDays,
    latestScore: latest,
    passed: passed,
    detail: detail,
    color: passed ? const Color(0xFF2F9E44) : const Color(0xFFD9480F),
  );
}

class _RepairAcceptance {
  const _RepairAcceptance({
    required this.hitDays,
    required this.latestScore,
    required this.passed,
    required this.detail,
    required this.color,
  });

  final int hitDays;
  final double latestScore;
  final bool passed;
  final String detail;
  final Color color;
}

class _RepairTrendBars extends StatelessWidget {
  const _RepairTrendBars({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const SizedBox.shrink();
    }

    final labels = const ['一', '二', '三', '四', '五', '六', '日'];
    return SizedBox(
      height: 90,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (index) {
          final value = values[index].clamp(0.0, 100.0).toDouble();
          final color = value >= 70
              ? const Color(0xFF2F9E44)
              : value >= 50
                  ? const Color(0xFFF08C00)
                  : const Color(0xFFD9480F);

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${value.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF495057)),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    height: (value * 0.6).clamp(4.0, 60.0),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(labels[index], style: const TextStyle(fontSize: 10, color: Color(0xFF868E96))),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
