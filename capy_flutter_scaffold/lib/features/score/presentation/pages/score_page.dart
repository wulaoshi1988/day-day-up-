import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_result.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../domain/models/exam_record.dart';
import '../providers/score_provider.dart';

class ScorePage extends ConsumerStatefulWidget {
  const ScorePage({super.key});

  @override
  ConsumerState<ScorePage> createState() => _ScorePageState();
}

class _ScorePageState extends ConsumerState<ScorePage> {
  String _subject = '全部';
  static const _subjects = ['全部', '语文', '数学', '英语', '物理', '化学', '生物'];

  Future<void> _addExamRecord(String childId) async {
    final examName = TextEditingController();
    final subject = TextEditingController(text: '数学');
    final score = TextEditingController();
    final fullScore = TextEditingController(text: '100');
    final date = TextEditingController(text: DateTime.now().toIso8601String().split('T').first);

    final payload = await showDialog<(String, String, double, double, String)?>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('录入成绩'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: examName,
                  decoration: const InputDecoration(labelText: '考试名称'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: subject,
                  decoration: const InputDecoration(labelText: '学科'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: score,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '分数'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: fullScore,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '满分'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: date,
                  decoration: const InputDecoration(labelText: '考试日期 (YYYY-MM-DD)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final exam = examName.text.trim();
                final sub = subject.text.trim();
                final s = double.tryParse(score.text.trim());
                final f = double.tryParse(fullScore.text.trim());
                final d = date.text.trim();
                if (exam.isEmpty || sub.isEmpty || s == null || f == null || f <= 0 || s < 0 || s > f || d.isEmpty) {
                  return;
                }
                Navigator.pop(dialogContext, (exam, sub, s, f, d));
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );

    examName.dispose();
    subject.dispose();
    score.dispose();
    fullScore.dispose();
    date.dispose();

    if (payload == null || !mounted) {
      return;
    }

    final repo = ref.read(scoreRepositoryProvider);
    final result = await repo.addExamRecord(
      childProfileId: childId,
      examName: payload.$1,
      subject: payload.$2,
      score: payload.$3,
      fullScore: payload.$4,
      examDate: payload.$5,
    );

    if (!mounted) return;
    switch (result) {
                    case ApiSuccess<AddExamResult>(:final data):
                      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data.duplicateHint ? (data.duplicateMessage ?? '录入成功（含重复提醒）') : '成绩录入成功'),
            behavior: SnackBarBehavior.floating,
                        ),
                      );
                      ref.invalidate(examRecordsProvider);
                      ref.invalidate(examSummaryProvider);
      case ApiFailure<AddExamResult>(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('录入失败：$message'), behavior: SnackBarBehavior.floating),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final childId = ref.watch(activeChildProfileIdProvider);
    final recordAsync = ref.watch(examRecordsProvider((childProfileId: childId, subject: _subject)));
    final summaryAsync = ref.watch(examSummaryProvider((childProfileId: childId, subject: _subject)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('成绩追踪'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.tonalIcon(
              onPressed: () => _addExamRecord(childId),
              icon: const Icon(Icons.add),
              label: const Text('录入'),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentRoute: '/scores'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _subjects
                .map(
                  (item) => ChoiceChip(
                    label: Text(item),
                    selected: _subject == item,
                    onSelected: (_) {
                      setState(() {
                        _subject = item;
                      });
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          summaryAsync.when(
            data: (s) => _SummaryCard(summary: s),
            loading: () => const Card(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
            error: (e, _) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('汇总加载失败：$e'))),
          ),
          const SizedBox(height: 12),
          recordAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('暂无成绩记录，先点击右上角“录入”添加一次考试成绩。'),
                  ),
                );
              }
              return Column(
                children: items
                    .map(
                      (item) => Card(
                        child: ListTile(
                          title: Text('${item.examName} · ${item.subject}'),
                          subtitle: Text('${item.examDate}  ${item.score.toStringAsFixed(0)}/${item.fullScore.toStringAsFixed(0)}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${item.scoreRate.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.w700)),
                              if (item.rank != null)
                                Text('排名 ${item.rank}', style: const TextStyle(fontSize: 12, color: Color(0xFF6C757D))),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const Card(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
            error: (e, _) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('成绩列表加载失败：$e'))),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final ExamSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _Metric(label: '考试次数', value: '${summary.examCount}')),
                Expanded(child: _Metric(label: '平均得分率', value: '${summary.averageRate.toStringAsFixed(1)}%')),
                Expanded(child: _Metric(label: '最近总分', value: summary.latestTotalScore <= 0 ? '--' : summary.latestTotalScore.toStringAsFixed(0))),
              ],
            ),
            const SizedBox(height: 10),
            Text('最近考试：${summary.latestExamName}', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _MiniTrend(values: summary.recentTrend),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: summary.subjectStats
                  .take(4)
                  .map((s) => Chip(label: Text('${s.subject} ${s.averageRate.toStringAsFixed(0)}% (${s.examCount})')))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6C757D))),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _MiniTrend extends StatelessWidget {
  const _MiniTrend({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const Text('暂无趋势数据', style: TextStyle(color: Color(0xFF868E96), fontSize: 12));
    }

    return SizedBox(
      height: 64,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: values.map((v) {
          final h = (v * 0.5).clamp(4.0, 54.0).toDouble();
          final color = v >= 80
              ? const Color(0xFF2F9E44)
              : v >= 60
                  ? const Color(0xFF1971C2)
                  : const Color(0xFFF08C00);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Container(
                height: h,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
