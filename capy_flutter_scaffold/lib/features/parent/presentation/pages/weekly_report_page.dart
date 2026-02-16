import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../growth/domain/models/growth_snapshot.dart';
import '../../../growth/presentation/providers/growth_provider.dart';
import '../providers/parent_provider.dart';

class WeeklyReportPage extends ConsumerWidget {
  const WeeklyReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childId = ref.watch(activeChildProfileIdProvider);
    final reportAsync = ref.watch(weeklyReportProvider(childId));
    final growthAsync = ref.watch(growthSnapshotProvider(childId));

    return Scaffold(
      appBar: AppBar(title: const Text('本周成长报告')),
      body: reportAsync.when(
        data: (report) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                title: const Text('完成率'),
                trailing: Text('${report.completionRate.toStringAsFixed(1)}%'),
              ),
              ListTile(
                title: const Text('专注次数'),
                trailing: Text('${report.totalSessions} 次'),
              ),
              ListTile(
                title: const Text('专注总时长'),
                trailing: Text('${report.totalMinutes} 分钟'),
              ),
              Card(
                child: growthAsync.when(
                  data: (g) {
                    final used = (g.recoverMaxPerWeek - g.recoverUsesLeft).clamp(0, g.recoverMaxPerWeek);
                    return ListTile(
                      title: const Text('连击与恢复卡'),
                      subtitle: Text('当前连击 ${g.streakDays} 天 · 本周恢复卡使用 $used/${g.recoverMaxPerWeek} 次'),
                      trailing: Text('剩余 ${g.recoverUsesLeft} 次'),
                    );
                  },
                  loading: () => const ListTile(
                    title: Text('连击与恢复卡'),
                    subtitle: Text('加载中...'),
                  ),
                  error: (_, __) => const ListTile(
                    title: Text('连击与恢复卡'),
                    subtitle: Text('加载失败'),
                  ),
                ),
              ),
              growthAsync.when(
                data: (g) {
                  final now = DateTime.now();
                  final queueWeek = g.interventionHistory
                      .where((e) => e.actionSource == 'risk_queue')
                      .where((e) => _isInCurrentWeek(_parseRecordTime(e.createdAt), now))
                      .toList();
                  final queuePrevWeek = g.interventionHistory
                      .where((e) => e.actionSource == 'risk_queue')
                      .where((e) => _isInPreviousWeek(_parseRecordTime(e.createdAt), now))
                      .toList();
                  final repairTrend = _buildRepairAchievementTrend(g.interventionHistory, now: now);
                  final repairAcceptance = _calcRepairAcceptance(repairTrend);
                  final queueWeekCount = queueWeek.length;
                  final queueWeekReduce = queueWeek.fold<int>(0, (sum, e) => sum + e.riskReduceScore);
                  final queueWeekActualReduce = queueWeek
                      .fold<double>(0.0, (sum, e) => sum + (e.effectDelta > 0 ? e.effectDelta * 4.0 : 0.0));
                  final queueQualityScore = queueWeekReduce <= 0
                      ? 0
                      : ((queueWeekActualReduce / queueWeekReduce) * 100).round().clamp(0, 100);
                  final normalQuality = _calcBucketQuality(queueWeek, bucket: _QualityBucket.normal);
                  final makeupQuality = _calcBucketQuality(queueWeek, bucket: _QualityBucket.makeup);
                  final reviewQuality = _calcBucketQuality(queueWeek, bucket: _QualityBucket.review);
                  final prevNormalQuality = _calcBucketQuality(queuePrevWeek, bucket: _QualityBucket.normal);
                  final prevMakeupQuality = _calcBucketQuality(queuePrevWeek, bucket: _QualityBucket.makeup);
                  final prevReviewQuality = _calcBucketQuality(queuePrevWeek, bucket: _QualityBucket.review);

                  final notes = <String>[];
                  if (g.streakBroken) {
                    notes.add('连击已中断 ${g.missedDays} 天，建议本周先恢复学习节奏。');
                  } else if (g.streakDays >= 7) {
                    notes.add('连击已达 ${g.streakDays} 天，建议家长给予阶段性奖励强化正反馈。');
                  } else {
                    notes.add('连击 ${g.streakDays} 天，建议每天固定时段学习避免断签。');
                  }

                  if (g.recoverUsesLeft == 0) {
                    notes.add('恢复卡本周次数已用尽，请优先保障连续学习。');
                  }

                  if (g.redeemHistory.isNotEmpty) {
                    final recent = g.redeemHistory.first;
                    notes.add('最近兑换：${recent.rewardName}（-${recent.cost} 能量），可关注奖励频率与学习产出平衡。');
                  }

                  notes.add('本周行为评分 ${g.weeklyBehaviorScore} 分，可结合完成率与连击趋势做下周计划。');

                  if (g.interventionEffectAvailable) {
                    final delta = g.interventionEffectDelta;
                    if (delta >= 5) {
                      notes.add('干预有效：24小时完成率提升 ${delta.toStringAsFixed(1)}%，建议保持当前策略。');
                    } else if (delta >= 0) {
                      notes.add('干预轻度有效：24小时完成率变化 ${delta.toStringAsFixed(1)}%，可继续观察。');
                    } else {
                      notes.add('干预待优化：24小时完成率下降 ${delta.abs().toStringAsFixed(1)}%，建议调整为减负+短任务。');
                    }
                  } else {
                    notes.add('当前无生效中的干预，建议在关键阶段按需使用干预功能。');
                  }

                  final boostRate = g.interventionBoostTotal == 0
                      ? 0.0
                      : (g.interventionBoostSuccess / g.interventionBoostTotal) * 100;
                  final lightRate = g.interventionLightTotal == 0
                      ? 0.0
                      : (g.interventionLightSuccess / g.interventionLightTotal) * 100;
                  notes.add('分模式有效率：鼓励 ${boostRate.toStringAsFixed(0)}%，减负 ${lightRate.toStringAsFixed(0)}%。');

                  var riskScore = 0;
                  if (g.streakBroken) riskScore += 35;
                  if (g.recoverUsesLeft == 0) riskScore += 22;
                  if (g.streakBroken && g.energyBalance < g.recoverCost) riskScore += 18;
                  if (g.interventionFollowupOverdue) {
                    riskScore += g.interventionFollowupOverdueStage == '6h' ? 30 : 20;
                  }
                  if (g.interventionEffectAvailable && g.interventionEffectDelta < 0) riskScore += 16;
                  if (!repairAcceptance.passed) riskScore += 14;
                  final riskLabel = riskScore >= 70
                      ? '高'
                      : riskScore >= 40
                          ? '中'
                          : '低';
                  notes.add('综合风险等级：$riskLabel（${riskScore.clamp(0, 100)}分）。');
                  if (!repairAcceptance.passed) {
                    notes.add('修复风险提醒：建议先完成修复验收线，再扩大干预强度。');
                  }

                  if (queueWeekCount > 0) {
                    notes.add('本周风险队列执行 $queueWeekCount 次，累计预计降风险 $queueWeekReduce 分。');
                    final qualityLabel = queueQualityScore >= 80
                        ? '高'
                        : queueQualityScore >= 55
                            ? '中'
                            : '低';
                    notes.add('队列执行质量：$qualityLabel（${queueQualityScore}分），建议持续跟踪动作后的实际变化。');
                    final lowBuckets = <String>[];
                    if (normalQuality.score > 0 && normalQuality.score < 50) {
                      lowBuckets.add('普通干预');
                    }
                    if (makeupQuality.score > 0 && makeupQuality.score < 50) {
                      lowBuckets.add('补做回访');
                    }
                    if (reviewQuality.score > 0 && reviewQuality.score < 50) {
                      lowBuckets.add('复盘动作');
                    }
                    if (lowBuckets.isNotEmpty) {
                      notes.add('低质量环节：${lowBuckets.join('、')}，建议优先优化这些动作模板。');
                    }

                    final bucketDeltaNotes = <String>[];
                    final normalDelta = normalQuality.score - prevNormalQuality.score;
                    final makeupDelta = makeupQuality.score - prevMakeupQuality.score;
                    final reviewDelta = reviewQuality.score - prevReviewQuality.score;
                    if (prevNormalQuality.count > 0) {
                      bucketDeltaNotes.add('普通干预${_deltaText(normalDelta)}');
                    }
                    if (prevMakeupQuality.count > 0) {
                      bucketDeltaNotes.add('补做回访${_deltaText(makeupDelta)}');
                    }
                    if (prevReviewQuality.count > 0) {
                      bucketDeltaNotes.add('复盘动作${_deltaText(reviewDelta)}');
                    }
                    if (bucketDeltaNotes.isNotEmpty) {
                      notes.add('环比上周：${bucketDeltaNotes.join('，')}。');
                    }
                    notes.add(
                      '修复验收：本周达标 ${repairAcceptance.hitDays}/7 天，最新 ${repairAcceptance.latestScore.toStringAsFixed(0)} 分，'
                      '${repairAcceptance.passed ? '已达验收线' : '未达验收线'}。',
                    );
                  } else {
                    notes.add('本周暂无风险队列执行记录，建议至少完成1次高优先级动作。');
                  }

                  final priorities = _buildPriorityRecommendations(
                    growth: g,
                    riskScore: riskScore,
                    queueWeekCount: queueWeekCount,
                    normalQuality: normalQuality,
                    makeupQuality: makeupQuality,
                    reviewQuality: reviewQuality,
                    repairAcceptance: repairAcceptance,
                  );

                  return Column(
                    children: [
                      Card(
                        color: const Color(0xFFFFF9DB),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.tips_and_updates, color: Color(0xFFB08900)),
                                  SizedBox(width: 8),
                                  Text('风险与建议', style: TextStyle(fontWeight: FontWeight.w700)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...notes.map(
                                (note) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text('• $note'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('下周优先行动（按优先级）', style: TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              ...priorities.take(3).map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(item.icon, size: 16, color: item.color),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                                            const SizedBox(height: 2),
                                            Text(item.reason, style: const TextStyle(fontSize: 12, color: Color(0xFF6C757D))),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'P${item.priority}',
                                        style: TextStyle(fontSize: 12, color: item.color, fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
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
              const Divider(),
              growthAsync.when(
                data: (g) {
                  final now = DateTime.now();
                  final queueWeek = g.interventionHistory
                      .where((e) => e.actionSource == 'risk_queue')
                      .where((e) => _isInCurrentWeek(_parseRecordTime(e.createdAt), now))
                      .toList();
                  final queuePrevWeek = g.interventionHistory
                      .where((e) => e.actionSource == 'risk_queue')
                      .where((e) => _isInPreviousWeek(_parseRecordTime(e.createdAt), now))
                      .toList();
                  final repairTrend = _buildRepairAchievementTrend(g.interventionHistory, now: now);
                  final repairAcceptance = _calcRepairAcceptance(repairTrend);
                  final queueWeekReduce = queueWeek.fold<int>(0, (sum, e) => sum + e.riskReduceScore);
                  final queueWeekActualReduce = queueWeek
                      .fold<double>(0.0, (sum, e) => sum + (e.effectDelta > 0 ? e.effectDelta * 4.0 : 0.0));
                  final queueQualityScore = queueWeekReduce <= 0
                      ? 0
                      : ((queueWeekActualReduce / queueWeekReduce) * 100).round().clamp(0, 100);
                  final normalQuality = _calcBucketQuality(queueWeek, bucket: _QualityBucket.normal);
                  final makeupQuality = _calcBucketQuality(queueWeek, bucket: _QualityBucket.makeup);
                  final reviewQuality = _calcBucketQuality(queueWeek, bucket: _QualityBucket.review);
                  final prevNormalQuality = _calcBucketQuality(queuePrevWeek, bucket: _QualityBucket.normal);
                  final prevMakeupQuality = _calcBucketQuality(queuePrevWeek, bucket: _QualityBucket.makeup);
                  final prevReviewQuality = _calcBucketQuality(queuePrevWeek, bucket: _QualityBucket.review);
                  final qualityColor = queueQualityScore >= 80
                      ? const Color(0xFF2F9E44)
                      : queueQualityScore >= 55
                          ? const Color(0xFFF08C00)
                          : const Color(0xFFD9480F);

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('风险队列执行复盘（本周）', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text('执行 ${queueWeek.length} 次 · 累计预计降风险 $queueWeekReduce 分'),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: Text('估算实际降风险 ${queueWeekActualReduce.toStringAsFixed(1)} 分'),
                              ),
                              Text(
                                '质量 ${queueQualityScore}分',
                                style: TextStyle(color: qualityColor, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: (queueQualityScore / 100).clamp(0.0, 1.0),
                              minHeight: 8,
                              backgroundColor: const Color(0xFFE9ECEF),
                              valueColor: AlwaysStoppedAnimation<Color>(qualityColor),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _BucketQualityRow(label: '普通干预', quality: normalQuality, previous: prevNormalQuality),
                          const SizedBox(height: 6),
                          _BucketQualityRow(label: '补做回访', quality: makeupQuality, previous: prevMakeupQuality),
                          const SizedBox(height: 6),
                          _BucketQualityRow(label: '复盘动作', quality: reviewQuality, previous: prevReviewQuality),
                          const SizedBox(height: 10),
                          const Text('修复达成趋势（本周）', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          _RepairTrendBars(values: repairTrend),
                          const SizedBox(height: 6),
                          Text(
                            repairAcceptance.detail,
                            style: TextStyle(
                              fontSize: 12,
                              color: repairAcceptance.color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (queueWeek.isEmpty)
                            const Text('暂无执行明细')
                          else
                            ...queueWeek.take(5).map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  '• ${item.note}（-${item.riskReduceScore} 分，${item.createdAt}）',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF495057)),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const Divider(),
              Text(report.aiSummary ?? '本周继续保持小步前进。'),
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

DateTime? _parseRecordTime(String value) {
  if (value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value.replaceFirst(' ', 'T'));
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

enum _QualityBucket { normal, makeup, review }

_BucketQuality _calcBucketQuality(
  List<InterventionRecord> items, {
  required _QualityBucket bucket,
}) {
  bool match(InterventionRecord e) {
    switch (bucket) {
      case _QualityBucket.normal:
        return e.actionType == 'manual';
      case _QualityBucket.makeup:
        return e.actionSubType == '2h_makeup' || e.actionSubType == '6h_makeup';
      case _QualityBucket.review:
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
  return _BucketQuality(
    count: selected.length,
    score: score,
    expected: expected,
    actual: actual,
  );
}

class _BucketQuality {
  const _BucketQuality({
    required this.count,
    required this.score,
    required this.expected,
    required this.actual,
  });

  final int count;
  final int score;
  final int expected;
  final double actual;
}

class _BucketQualityRow extends StatelessWidget {
  const _BucketQualityRow({required this.label, required this.quality, required this.previous});

  final String label;
  final _BucketQuality quality;
  final _BucketQuality previous;

  @override
  Widget build(BuildContext context) {
    final color = quality.score >= 80
        ? const Color(0xFF2F9E44)
        : quality.score >= 55
            ? const Color(0xFFF08C00)
            : const Color(0xFFD9480F);
    final hasPrevious = previous.count > 0;
    final delta = quality.score - previous.score;
    final deltaColor = delta > 0
        ? const Color(0xFF2F9E44)
        : delta < 0
            ? const Color(0xFFD9480F)
            : const Color(0xFF868E96);
    final deltaText = delta > 0
        ? '↑ +$delta'
        : delta < 0
            ? '↓ $delta'
            : '→ 0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('$label（${quality.count}次）', style: const TextStyle(fontSize: 12))),
            Text(
              '${quality.score}分',
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700),
            ),
            Text(
              hasPrevious ? deltaText : '新',
              style: TextStyle(fontSize: 10, color: hasPrevious ? deltaColor : const Color(0xFF868E96), fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (quality.score / 100).clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: const Color(0xFFE9ECEF),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '预计 ${quality.expected} / 实际 ${quality.actual.toStringAsFixed(1)}',
          style: const TextStyle(fontSize: 11, color: Color(0xFF868E96)),
        ),
      ],
    );
  }
}

String _deltaText(int delta) {
  if (delta > 0) return '上升$delta分';
  if (delta < 0) return '下降${delta.abs()}分';
  return '持平';
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
      height: 84,
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
                  Text('${value.toStringAsFixed(0)}', style: const TextStyle(fontSize: 10)),
                  const SizedBox(height: 2),
                  Container(
                    height: (value * 0.56).clamp(4.0, 56.0),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(height: 3),
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

List<_PriorityRecommendation> _buildPriorityRecommendations({
  required GrowthSnapshot growth,
  required int riskScore,
  required int queueWeekCount,
  required _BucketQuality normalQuality,
  required _BucketQuality makeupQuality,
  required _BucketQuality reviewQuality,
  required _RepairAcceptance repairAcceptance,
}) {
  final items = <_PriorityRecommendation>[];

  if (!repairAcceptance.passed) {
    items.add(
      _PriorityRecommendation(
        priority: 1,
        title: '先完成修复验收线',
        reason: '修复趋势未达标，优先提升近3日质量均值与最新一天达标率。',
        icon: Icons.trending_up,
        color: const Color(0xFFD9480F),
      ),
    );
  }

  if (growth.interventionFollowupOverdue) {
    final overdueStage = growth.interventionFollowupOverdueStage;
    items.add(
      _PriorityRecommendation(
        priority: 1,
        title: overdueStage == '6h' ? '补做6h回访' : '补做2h回访',
        reason: '当前存在回访逾期，先补齐回访可最快降低短期风险。',
        icon: Icons.alarm,
        color: const Color(0xFFD9480F),
      ),
    );
  }

  if (riskScore >= 70) {
    items.add(
      _PriorityRecommendation(
        priority: 1,
        title: '执行高风险动作1次',
        reason: '综合风险处于高位，建议优先执行1个高收益减风险动作。',
        icon: Icons.priority_high,
        color: const Color(0xFFD9480F),
      ),
    );
  }

  if (normalQuality.count > 0 && normalQuality.score < 55) {
    items.add(
      _PriorityRecommendation(
        priority: 2,
        title: '优化普通干预模板',
        reason: '普通干预质量偏低，建议减少一次性目标并聚焦主线任务。',
        icon: Icons.tune,
        color: const Color(0xFFF08C00),
      ),
    );
  }

  if (makeupQuality.count > 0 && makeupQuality.score < 55) {
    items.add(
      _PriorityRecommendation(
        priority: 2,
        title: '优化补做回访脚本',
        reason: '补做回访质量偏低，建议先拆任务再执行减负方案。',
        icon: Icons.build_circle,
        color: const Color(0xFFF08C00),
      ),
    );
  }

  if (reviewQuality.count > 0 && reviewQuality.score < 55) {
    items.add(
      _PriorityRecommendation(
        priority: 2,
        title: '强化复盘动作闭环',
        reason: '复盘动作质量不足，建议基于基线与当日完成率做复盘。',
        icon: Icons.rule,
        color: const Color(0xFFF08C00),
      ),
    );
  }

  if (queueWeekCount == 0) {
    items.add(
      _PriorityRecommendation(
        priority: 3,
        title: '至少执行1次风险队列动作',
        reason: '本周无队列执行记录，建议先完成一个可验证动作建立数据闭环。',
        icon: Icons.playlist_add_check,
        color: const Color(0xFF1971C2),
      ),
    );
  }

  if (items.isEmpty) {
    items.add(
      const _PriorityRecommendation(
        priority: 3,
        title: '维持当前节奏并持续观察',
        reason: '当前指标稳定，建议保持动作频率并关注趋势变化。',
        icon: Icons.verified,
        color: Color(0xFF2F9E44),
      ),
    );
  }

  items.sort((a, b) => a.priority.compareTo(b.priority));
  return items;
}

class _PriorityRecommendation {
  const _PriorityRecommendation({
    required this.priority,
    required this.title,
    required this.reason,
    required this.icon,
    required this.color,
  });

  final int priority;
  final String title;
  final String reason;
  final IconData icon;
  final Color color;
}
