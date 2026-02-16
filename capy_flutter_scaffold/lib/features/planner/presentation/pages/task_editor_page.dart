import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_result.dart';
import '../../../../core/di/app_providers.dart';
import '../../domain/models/task_item.dart';
import '../providers/planner_provider.dart';

class TaskEditorPage extends ConsumerStatefulWidget {
  const TaskEditorPage({super.key});

  @override
  ConsumerState<TaskEditorPage> createState() => _TaskEditorPageState();
}

class _TaskEditorPageState extends ConsumerState<TaskEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _minutesController = TextEditingController(text: '10');
  final _targetScoreController = TextEditingController();
  final _notesController = TextEditingController();

  String _subject = '语文';
  int _difficulty = 1;
  String _status = 'todo';
  String _originalStatus = 'todo';
  String _priority = 'medium';
  DateTime? _startDate;
  DateTime? _dueDate;
  bool _saving = false;
  String? _taskId;
  bool _prefilled = false;

  static const List<_QuickTemplate> _templates = [
    _QuickTemplate(gradeMin: 1, gradeMax: 2, subject: '语文', title: '大声朗读课文 10 分钟', minutes: 10, difficulty: 1),
    _QuickTemplate(gradeMin: 1, gradeMax: 2, subject: '数学', title: '口算练习 20 题', minutes: 12, difficulty: 1),
    _QuickTemplate(gradeMin: 3, gradeMax: 4, subject: '语文', title: '古诗背诵 1 首', minutes: 12, difficulty: 2),
    _QuickTemplate(gradeMin: 3, gradeMax: 4, subject: '英语', title: '句型仿写 5 句', minutes: 15, difficulty: 2),
    _QuickTemplate(gradeMin: 5, gradeMax: 6, subject: '数学', title: '分数计算 12 题', minutes: 25, difficulty: 3),
    _QuickTemplate(gradeMin: 1, gradeMax: 6, subject: '综合', title: '番茄专注 15 分钟', minutes: 15, difficulty: 1),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _minutesController.dispose();
    _targetScoreController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart ? (_startDate ?? now) : (_dueDate ?? _startDate ?? now);
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (selected == null) return;
    setState(() {
      if (isStart) {
        _startDate = selected;
      } else {
        _dueDate = selected;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate != null && _dueDate != null && _dueDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('截止日期不能早于开始日期'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    if (_taskId != null && _originalStatus == 'done' && _status == 'todo') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('确认改回未开始'),
          content: const Text('该计划已完成，确定改回“待完成”吗？'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('取消')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('确认')),
          ],
        ),
      );
      if (confirmed != true) {
        return;
      }
    }

    setState(() => _saving = true);
    final repo = ref.read(plannerRepositoryProvider);
    final childId = ref.read(activeChildProfileIdProvider);
    final targetScoreText = _targetScoreController.text.trim();
    final targetScore = targetScoreText.isEmpty ? null : double.tryParse(targetScoreText);

    final result = _taskId == null
        ? await repo.createTask(
            childProfileId: childId,
            subject: _subject,
            title: _titleController.text.trim(),
            difficulty: _difficulty,
            estMinutes: int.parse(_minutesController.text.trim()),
            priority: _priority,
            targetScore: targetScore,
            startDate: _startDate,
            dueDate: _dueDate,
            notes: _notesController.text.trim(),
          )
        : await repo.updateTask(
            taskId: _taskId!,
            subject: _subject,
            title: _titleController.text.trim(),
            difficulty: _difficulty,
            estMinutes: int.parse(_minutesController.text.trim()),
            priority: _priority,
            targetScore: targetScore,
            startDate: _startDate,
            status: _status,
            dueDate: _dueDate,
            notes: _notesController.text.trim(),
          );

    if (!mounted) return;
    setState(() => _saving = false);

    switch (result) {
      case ApiSuccess():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_taskId == null ? '任务已添加，卡皮很开心！' : '计划已更新')),
        );
        Navigator.pop(context, true);
      case ApiFailure(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：$message')),
        );
    }
  }

  void _applyTemplate(_QuickTemplate template) {
    setState(() {
      _subject = template.subject;
      _titleController.text = template.title;
      _minutesController.text = template.minutes.toString();
      _difficulty = template.difficulty;
    });
  }

  @override
  Widget build(BuildContext context) {
    final grade = ref.watch(activeGradeProvider);
    final childId = ref.watch(activeChildProfileIdProvider);
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['taskId'] is String && _taskId == null) {
      _taskId = args['taskId'] as String;
    }
    final editing = _taskId != null;
    final tasksAsync = editing ? ref.watch(plannerTasksProvider(childId)) : null;

    if (editing && !_prefilled && tasksAsync is AsyncData<List<TaskItem>>) {
      TaskItem? task;
      for (final row in tasksAsync.value) {
        if (row.id == _taskId) {
          task = row;
          break;
        }
      }
      if (task != null) {
        final selectedTask = task;
        _prefilled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _subject = selectedTask.subject;
            _titleController.text = selectedTask.title;
            _minutesController.text = selectedTask.estMinutes.toString();
            _difficulty = selectedTask.difficulty;
            _status = selectedTask.status;
            _originalStatus = selectedTask.status;
            _priority = selectedTask.priority;
            _startDate = selectedTask.startDate;
            _dueDate = selectedTask.dueDate;
            _targetScoreController.text = selectedTask.targetScore?.toStringAsFixed(0) ?? '';
            _notesController.text = selectedTask.notes ?? '';
          });
        });
      }
    }

    final filteredTemplates = _templates
        .where((t) => grade >= t.gradeMin && grade <= t.gradeMax)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(editing ? '编辑计划' : '添加任务')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('快速模板（${grade}年级）', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: filteredTemplates
                  .map(
                    (t) => ActionChip(
                      label: Text(t.title),
                      onPressed: () => _applyTemplate(t),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _subject,
              decoration: const InputDecoration(labelText: '学科'),
              items: const [
                DropdownMenuItem(value: '语文', child: Text('语文')),
                DropdownMenuItem(value: '数学', child: Text('数学')),
                DropdownMenuItem(value: '英语', child: Text('英语')),
                DropdownMenuItem(value: '综合', child: Text('综合')),
              ],
              onChanged: (v) => setState(() => _subject = v ?? '语文'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: '计划名称'),
              validator: (v) => (v == null || v.trim().isEmpty) ? '请输入任务名称' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _minutesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '预计时长（分钟）'),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 1 || n > 240) return '请输入 1-240 的数字';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _targetScoreController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '目标分数（可选）'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final n = double.tryParse(v.trim());
                if (n == null || n < 0 || n > 1000) return '请输入合理目标分数';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _difficulty,
              decoration: const InputDecoration(labelText: '难度'),
              items: const [
                DropdownMenuItem(value: 1, child: Text('1 星（简单）')),
                DropdownMenuItem(value: 2, child: Text('2 星（中等）')),
                DropdownMenuItem(value: 3, child: Text('3 星（挑战）')),
              ],
              onChanged: (v) => setState(() => _difficulty = v ?? 1),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _priority,
              decoration: const InputDecoration(labelText: '优先级'),
              items: const [
                DropdownMenuItem(value: 'low', child: Text('低')),
                DropdownMenuItem(value: 'medium', child: Text('中')),
                DropdownMenuItem(value: 'high', child: Text('高')),
              ],
              onChanged: (v) => setState(() => _priority = v ?? 'medium'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(isStart: true),
                    icon: const Icon(Icons.play_circle_outline),
                    label: Text(_startDate == null ? '开始日期' : _startDate!.toIso8601String().split('T').first),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(isStart: false),
                    icon: const Icon(Icons.event),
                    label: Text(_dueDate == null ? '截止日期' : _dueDate!.toIso8601String().split('T').first),
                  ),
                ),
              ],
            ),
            if (editing) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: '状态'),
                items: const [
                  DropdownMenuItem(value: 'todo', child: Text('待完成')),
                  DropdownMenuItem(value: 'doing', child: Text('进行中')),
                  DropdownMenuItem(value: 'done', child: Text('已完成')),
                ],
                onChanged: (v) => setState(() => _status = v ?? 'todo'),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: '备注'),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(editing ? Icons.save : Icons.add_task),
              label: Text(_saving ? '保存中...' : (editing ? '保存修改' : '保存任务')),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickTemplate {
  const _QuickTemplate({
    required this.gradeMin,
    required this.gradeMax,
    required this.subject,
    required this.title,
    required this.minutes,
    required this.difficulty,
  });

  final int gradeMin;
  final int gradeMax;
  final String subject;
  final String title;
  final int minutes;
  final int difficulty;
}
