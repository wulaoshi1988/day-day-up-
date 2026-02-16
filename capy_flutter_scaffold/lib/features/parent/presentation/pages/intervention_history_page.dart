import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/app_providers.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../growth/presentation/providers/growth_provider.dart';

class InterventionHistoryPage extends ConsumerStatefulWidget {
  const InterventionHistoryPage({super.key});

  @override
  ConsumerState<InterventionHistoryPage> createState() => _InterventionHistoryPageState();
}

class _InterventionHistoryPageState extends ConsumerState<InterventionHistoryPage> {
  String _filter = 'all';
  String _subFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final childId = ref.watch(activeChildProfileIdProvider);
    final growthAsync = ref.watch(growthSnapshotProvider(childId));

    return Scaffold(
      appBar: AppBar(title: const Text('干预历史详情')),
      body: growthAsync.when(
        data: (g) {
          final history = g.interventionHistory;
          final typeFiltered = _filter == 'all'
              ? history
              : history.where((e) => e.actionType == _filter).toList();
          final filteredHistory = _subFilter == 'all'
              ? typeFiltered
              : typeFiltered.where((e) => e.actionSubType == _subFilter).toList();
          final boostCount = history.where((e) => e.mode == 'boost').length;
          final lightCount = history.where((e) => e.mode == 'light').length;
          final resetCount = history.where((e) => e.mode == 'normal').length;
          final boostRate = g.interventionBoostTotal == 0
              ? 0.0
              : (g.interventionBoostSuccess / g.interventionBoostTotal) * 100;
          final lightRate = g.interventionLightTotal == 0
              ? 0.0
              : (g.interventionLightSuccess / g.interventionLightTotal) * 100;
          final recent = history.where((e) => e.mode == 'boost' || e.mode == 'light').take(8).toList();
          final hitCount = recent.where((e) => e.effectDelta > 0).length;
          final hitRate = recent.isEmpty ? 0.0 : (hitCount / recent.length) * 100;
          final followups = history.where((e) => e.actionType == 'followup').toList();
          final followupToday = followups.where((e) => _isSameDay(_parseRecordTime(e.createdAt), DateTime.now())).length;
          final followupWeek = followups.where((e) => _isInCurrentWeek(_parseRecordTime(e.createdAt), DateTime.now())).length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          label: '鼓励次数',
                          value: '$boostCount',
                          color: const Color(0xFF2F9E44),
                        ),
                      ),
                      Expanded(
                        child: _StatTile(
                          label: '减负次数',
                          value: '$lightCount',
                          color: const Color(0xFFF08C00),
                        ),
                      ),
                      Expanded(
                        child: _StatTile(
                          label: '撤销次数',
                          value: '$resetCount',
                          color: const Color(0xFF495057),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('全部'),
                    selected: _filter == 'all',
                    onSelected: (_) => setState(() => _filter = 'all'),
                  ),
                  ChoiceChip(
                    label: const Text('普通干预'),
                    selected: _filter == 'manual',
                    onSelected: (_) => setState(() => _filter = 'manual'),
                  ),
                  ChoiceChip(
                    label: const Text('回访干预'),
                    selected: _filter == 'followup',
                    onSelected: (_) => setState(() => _filter = 'followup'),
                  ),
                  ChoiceChip(
                    label: const Text('撤销记录'),
                    selected: _filter == 'clear',
                    onSelected: (_) => setState(() => _filter = 'clear'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('全部子类型'),
                    selected: _subFilter == 'all',
                    onSelected: (_) => setState(() => _subFilter = 'all'),
                  ),
                  ChoiceChip(
                    label: const Text('2h补做'),
                    selected: _subFilter == '2h_makeup',
                    onSelected: (_) => setState(() => _subFilter = '2h_makeup'),
                  ),
                  ChoiceChip(
                    label: const Text('6h补做'),
                    selected: _subFilter == '6h_makeup',
                    onSelected: (_) => setState(() => _subFilter = '6h_makeup'),
                  ),
                  ChoiceChip(
                    label: const Text('复盘'),
                    selected: _subFilter == 'review',
                    onSelected: (_) => setState(() => _subFilter = 'review'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  title: const Text('回访完成统计'),
                  subtitle: Text('今日 $followupToday 次 · 本周 $followupWeek 次'),
                  trailing: Text('总计 ${followups.length} 次'),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('分模式有效率', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      _RateRow(
                        label: '鼓励模式',
                        detail: '${g.interventionBoostSuccess}/${g.interventionBoostTotal}',
                        percent: boostRate,
                        color: const Color(0xFF2F9E44),
                      ),
                      const SizedBox(height: 8),
                      _RateRow(
                        label: '减负模式',
                        detail: '${g.interventionLightSuccess}/${g.interventionLightTotal}',
                        percent: lightRate,
                        color: const Color(0xFFF08C00),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  title: const Text('智能建议命中率（最近8次）'),
                  subtitle: Text('命中 $hitCount/${recent.length} 次'),
                  trailing: Text(
                    '${hitRate.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: hitRate >= 70
                          ? const Color(0xFF2F9E44)
                          : hitRate >= 50
                              ? const Color(0xFF1971C2)
                              : const Color(0xFFD9480F),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('时间线', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      if (filteredHistory.isEmpty)
                        const Text('暂无干预记录')
                      else
                        ...filteredHistory.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  item.mode == 'boost'
                                      ? Icons.favorite
                                      : item.mode == 'light'
                                          ? Icons.self_improvement
                                          : Icons.restart_alt,
                                  size: 18,
                                  color: item.mode == 'boost'
                                      ? const Color(0xFF2F9E44)
                                      : item.mode == 'light'
                                          ? const Color(0xFFF08C00)
                                          : const Color(0xFF495057),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '[${item.mode}] ${item.note}',
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 2),
                                      _ActionTypeBadge(actionType: item.actionType),
                                      const SizedBox(height: 2),
                                      _ActionSubTypeBadge(actionSubType: item.actionSubType),
                                      const SizedBox(height: 2),
                                      Text(
                                        '效果变化 ${item.effectDelta >= 0 ? '+' : ''}${item.effectDelta.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: item.effectDelta >= 0 ? const Color(0xFF2F9E44) : const Color(0xFFD9480F),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.createdAt,
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF868E96)),
                                      ),
                                    ],
                                  ),
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('加载失败: $error')),
      ),
      bottomNavigationBar: const AppBottomNav(currentRoute: '/parent-dashboard'),
    );
  }
}

class _ActionTypeBadge extends StatelessWidget {
  const _ActionTypeBadge({required this.actionType});

  final String actionType;

  @override
  Widget build(BuildContext context) {
    final label = actionType == 'followup'
        ? '回访'
        : actionType == 'clear'
            ? '撤销'
            : '普通';
    final color = actionType == 'followup'
        ? const Color(0xFF1971C2)
        : actionType == 'clear'
            ? const Color(0xFF495057)
            : const Color(0xFF2F9E44);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _ActionSubTypeBadge extends StatelessWidget {
  const _ActionSubTypeBadge({required this.actionSubType});

  final String actionSubType;

  @override
  Widget build(BuildContext context) {
    if (actionSubType.isEmpty || actionSubType == 'clear') {
      return const SizedBox.shrink();
    }

    final label = actionSubType == '2h_makeup'
        ? '2h补做'
        : actionSubType == '6h_makeup'
            ? '6h补做'
            : actionSubType == 'review'
                ? '复盘'
                : actionSubType;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE7F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF5F3DC4)),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 20)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Color(0xFF6C757D), fontSize: 12)),
      ],
    );
  }
}

class _RateRow extends StatelessWidget {
  const _RateRow({
    required this.label,
    required this.detail,
    required this.percent,
    required this.color,
  });

  final String label;
  final String detail;
  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
            Text('$detail  (${percent.toStringAsFixed(0)}%)', style: const TextStyle(color: Color(0xFF6C757D), fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (percent / 100).clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: const Color(0xFFE9ECEF),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

DateTime? _parseRecordTime(String value) {
  if (value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value.replaceFirst(' ', 'T'));
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
