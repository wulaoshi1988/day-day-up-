import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_result.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/debug_panel.dart';
import '../../../growth/presentation/providers/growth_provider.dart';
import '../../domain/models/task_item.dart';
import '../providers/planner_provider.dart';

class PlannerPage extends ConsumerWidget {
  const PlannerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childProfileId = ref.watch(activeChildProfileIdProvider);
    final tasksAsync = ref.watch(plannerTasksProvider(childProfileId));
    final growthAsync = ref.watch(growthSnapshotProvider(childProfileId));
    final quoteAsync = ref.watch(capyQuoteProvider);
    final selectedFilter = ref.watch(plannerStatusFilterProvider);
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompactHeader = screenWidth < 430;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final extraHeader = ((textScale - 1) * 24).clamp(0.0, 20.0);
    final quotePreview = quoteAsync.maybeWhen(
      data: (quote) => quote,
      orElse: () => '卡皮巴拉名言：今天比昨天更专注一点点。',
    );

    Future<void> completeTask(TaskItem task, int currentDoneCount) async {
      final repo = ref.read(plannerRepositoryProvider);
      final result = await repo.completeTask(taskId: task.id);
      switch (result) {
        case ApiSuccess<void>():
          ref.invalidate(plannerTasksProvider(childProfileId));
          ref.invalidate(growthSnapshotProvider(childProfileId));
          if (context.mounted) {
            showDialog<void>(
              context: context,
              barrierDismissible: true,
              builder: (_) => _TaskRewardDialog(
                score: task.difficulty * 10,
                streak: currentDoneCount + 1,
              ),
            );
          }
        case ApiFailure<void>(:final message):
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('操作失败：$message'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
      }
    }

    Future<void> updateTaskStatus(TaskItem task, String status) async {
      if (task.status == 'done' && status == 'todo') {
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

      final repo = ref.read(plannerRepositoryProvider);
      final result = await repo.updateTask(taskId: task.id, status: status);
      switch (result) {
        case ApiSuccess<TaskItem>():
          ref.invalidate(plannerTasksProvider(childProfileId));
          ref.invalidate(growthSnapshotProvider(childProfileId));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('已更新为${_statusText(status)}'), behavior: SnackBarBehavior.floating),
            );
          }
        case ApiFailure<TaskItem>(:final message):
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('状态更新失败：$message'), behavior: SnackBarBehavior.floating),
            );
          }
      }
    }

    Future<void> deleteTask(TaskItem task) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('删除计划'),
          content: Text('确认删除“${task.title}”？删除后不可恢复。'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('取消')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('删除')),
          ],
        ),
      );
      if (confirmed != true) {
        return;
      }

      final repo = ref.read(plannerRepositoryProvider);
      final result = await repo.deleteTask(taskId: task.id);
      switch (result) {
        case ApiSuccess<void>():
          ref.invalidate(plannerTasksProvider(childProfileId));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('计划已删除'), behavior: SnackBarBehavior.floating),
            );
          }
        case ApiFailure<void>(:final message):
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('删除失败：$message'), behavior: SnackBarBehavior.floating),
            );
          }
      }
    }

    Future<void> postponeTask(TaskItem task, int days) async {
      final next = (task.dueDate ?? DateTime.now()).add(Duration(days: days));
      final repo = ref.read(plannerRepositoryProvider);
      final result = await repo.updateTask(taskId: task.id, dueDate: next);
      switch (result) {
        case ApiSuccess<TaskItem>():
          ref.invalidate(plannerTasksProvider(childProfileId));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('已延期 $days 天'), behavior: SnackBarBehavior.floating),
            );
          }
        case ApiFailure<TaskItem>(:final message):
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('延期失败：$message'), behavior: SnackBarBehavior.floating),
            );
          }
      }
    }

    Future<void> addPlanTask() async {
      final created = await Navigator.pushNamed(context, '/task-editor');
      if (created == true) {
        ref.invalidate(plannerTasksProvider(childProfileId));
        ref.invalidate(growthSnapshotProvider(childProfileId));
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: (isCompactHeader ? 262 : 248) + extraHeader,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: const Color(0xFFFF8C42),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFF8C42), Color(0xFFFF6B35)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 38, 20, 20),
                    child: tasksAsync.when(
                      data: (tasks) {
                        final quoteText = quotePreview;
                        final completed = tasks.where((t) => t.status == 'done').length;
                        final total = tasks.length;
                        final progress = total > 0 ? completed / total : 0.0;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Image.asset(
                                    'assets/icons/app/capy_hero_meditation.png',
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.pets,
                                      size: 32,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '今日冒险',
                                        style: theme.textTheme.headlineSmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '继续前进，卡皮巴拉为你加油！',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                            color: Colors.white.withValues(alpha: 0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '今日进度',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  SizedBox(
                                    width: 100,
                                    height: 8,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '$completed/$total',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              constraints: BoxConstraints(minHeight: isCompactHeader ? 44 : 46),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Icon(Icons.format_quote, size: 16, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      quoteText,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.white.withValues(alpha: 0.95),
                                        fontWeight: FontWeight.w600,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                        ),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
            actions: const [
              DebugPanelButton(),
            ],
          ),
          SliverToBoxAdapter(
            child: tasksAsync.when(
              data: (tasks) => _GamificationStrip(tasks: tasks),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
          SliverToBoxAdapter(
            child: tasksAsync.when(
              data: (tasks) => _PlannerContent(
                tasks: tasks,
                behaviorScore: growthAsync.asData?.value.weeklyBehaviorScore ?? 72,
                interventionMode: growthAsync.asData?.value.interventionMode ?? 'normal',
                interventionNote: growthAsync.asData?.value.interventionNote ?? '',
                interventionActive: growthAsync.asData?.value.interventionActive ?? false,
                interventionRemainingMinutes: growthAsync.asData?.value.interventionRemainingMinutes ?? 0,
                onCompleteTask: completeTask,
                onUpdateStatus: updateTaskStatus,
                onDeleteTask: deleteTask,
                onPostponeTask: postponeTask,
                selectedFilter: selectedFilter,
                onFilterChanged: (value) => ref.read(plannerStatusFilterProvider.notifier).state = value,
                onAddPlanTask: addPlanTask,
              ),
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
              loading: () => const SizedBox(height: 400, child: Center(child: CircularProgressIndicator())),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentRoute: '/planner'),
    );
  }
}

class _PlannerContent extends StatelessWidget {
  const _PlannerContent({
    required this.tasks,
    required this.behaviorScore,
    required this.interventionMode,
    required this.interventionNote,
    required this.interventionActive,
    required this.interventionRemainingMinutes,
    required this.onCompleteTask,
    required this.onUpdateStatus,
    required this.onDeleteTask,
    required this.onPostponeTask,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.onAddPlanTask,
  });

  final List<TaskItem> tasks;
  final int behaviorScore;
  final String interventionMode;
  final String interventionNote;
  final bool interventionActive;
  final int interventionRemainingMinutes;
  final Future<void> Function(TaskItem, int) onCompleteTask;
  final Future<void> Function(TaskItem, String) onUpdateStatus;
  final Future<void> Function(TaskItem) onDeleteTask;
  final Future<void> Function(TaskItem, int days) onPostponeTask;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;
  final Future<void> Function() onAddPlanTask;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (tasks.isEmpty) {
      return SizedBox(
        height: 400,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
          color: const Color(0xFFFF8C42).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pets, size: 64, color: Color(0xFFFF8C42)),
              ),
              const SizedBox(height: 20),
              Text(
                '今天还没有任务',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF2D3748),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '点击下方按钮开始你的冒险吧！',
                style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF718096)),
              ),
            ],
          ),
        ),
      );
    }

    final todoTasks = tasks.where((t) => t.status == 'todo').toList();
    final doingTasks = tasks.where((t) => t.status == 'doing').toList();
    final doneTasks = tasks.where((t) => t.status == 'done').toList();
    final overdueTasks = tasks.where((t) => _isOverdueTask(t)).toList();

    final nextTask = _pickAdaptiveTask(
      doingTasks: doingTasks,
      todoTasks: todoTasks,
      behaviorScore: behaviorScore,
      interventionMode: interventionActive ? interventionMode : 'normal',
    );
    final allCompleted = todoTasks.isEmpty && doingTasks.isEmpty && tasks.isNotEmpty;
    final mainTaskId = nextTask?.id;
    final studiedMinutes = doneTasks.fold<int>(0, (sum, task) => sum + task.estMinutes);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WeekDateStrip(tasks: tasks),
          const SizedBox(height: 14),
          if (allCompleted)
            const _MainQuestCelebration()
          else if (nextTask != null)
            _MainQuestCard(
              task: nextTask,
              onTap: () async {
                if (nextTask.status != 'doing') {
                  await onUpdateStatus(nextTask, 'doing');
                }
                if (!context.mounted) {
                  return;
                }
                Navigator.pushNamed(context, '/timer');
              },
            ),
          const SizedBox(height: 10),
          _AdaptiveHintCard(
            behaviorScore: behaviorScore,
            interventionMode: interventionActive ? interventionMode : 'normal',
            interventionNote: interventionNote,
            interventionActive: interventionActive,
            interventionRemainingMinutes: interventionRemainingMinutes,
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FilterChip(label: '全部', value: 'all', selected: selectedFilter, onTap: onFilterChanged),
                    _FilterChip(label: '进行中', value: 'doing', selected: selectedFilter, onTap: onFilterChanged),
                    _FilterChip(label: '已完成', value: 'done', selected: selectedFilter, onTap: onFilterChanged),
                    _FilterChip(label: '逾期', value: 'overdue', selected: selectedFilter, onTap: onFilterChanged),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: () async => onAddPlanTask(),
                icon: const Icon(Icons.add_task),
                label: const Text('添加计划'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _StudyTimeline(studiedMinutes: studiedMinutes),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWideScreen = constraints.maxWidth > 600;
              if (isWideScreen && selectedFilter == 'all') {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _TaskSection(
                        title: '待完成',
                        icon: Icons.radio_button_unchecked,
                        iconColor: const Color(0xFFFF6B6B),
                        tasks: todoTasks,
                        onCompleteTask: onCompleteTask,
                        onUpdateStatus: onUpdateStatus,
                        onDeleteTask: onDeleteTask,
                        onPostponeTask: onPostponeTask,
                        currentDoneCount: doneTasks.length,
                        mainTaskId: mainTaskId,
                        emptyMessage: '太棒了，没有待完成的任务！',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _TaskSection(
                        title: '进行中',
                        icon: Icons.pending,
                        iconColor: const Color(0xFF4ECDC4),
                        tasks: doingTasks,
                        onCompleteTask: onCompleteTask,
                        onUpdateStatus: onUpdateStatus,
                        onDeleteTask: onDeleteTask,
                        onPostponeTask: onPostponeTask,
                        currentDoneCount: doneTasks.length,
                        mainTaskId: mainTaskId,
                        emptyMessage: '暂无进行中的任务',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _TaskSection(
                        title: '已完成',
                        icon: Icons.check_circle,
                        iconColor: const Color(0xFF95E1D3),
                        tasks: doneTasks,
                        onCompleteTask: onCompleteTask,
                        onUpdateStatus: onUpdateStatus,
                        onDeleteTask: onDeleteTask,
                        onPostponeTask: onPostponeTask,
                        currentDoneCount: doneTasks.length,
                        mainTaskId: mainTaskId,
                        isCompletedSection: true,
                        emptyMessage: '还没有完成任何任务',
                      ),
                    ),
                  ],
                );
              }

              if (selectedFilter != 'all') {
                final filtered = selectedFilter == 'doing'
                    ? doingTasks
                    : selectedFilter == 'done'
                        ? doneTasks
                        : selectedFilter == 'overdue'
                            ? overdueTasks
                            : tasks;
                final title = selectedFilter == 'doing'
                    ? '进行中'
                    : selectedFilter == 'done'
                        ? '已完成'
                        : selectedFilter == 'overdue'
                            ? '逾期'
                            : '全部';
                final color = selectedFilter == 'doing'
                    ? const Color(0xFF4ECDC4)
                    : selectedFilter == 'done'
                        ? const Color(0xFF95E1D3)
                        : selectedFilter == 'overdue'
                            ? const Color(0xFFE03131)
                            : const Color(0xFFFF8C42);

                return _TaskSection(
                  title: title,
                  icon: selectedFilter == 'done'
                      ? Icons.check_circle
                      : selectedFilter == 'overdue'
                          ? Icons.warning_amber_rounded
                          : Icons.pending,
                  iconColor: color,
                  tasks: filtered,
                  onCompleteTask: onCompleteTask,
                  onUpdateStatus: onUpdateStatus,
                  onDeleteTask: onDeleteTask,
                  onPostponeTask: onPostponeTask,
                  currentDoneCount: doneTasks.length,
                  mainTaskId: mainTaskId,
                  emptyMessage: '暂无$title计划',
                  isCompletedSection: selectedFilter == 'done',
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (todoTasks.isNotEmpty) ...[
                    _TaskSection(
                      title: '待完成',
                      icon: Icons.radio_button_unchecked,
                      iconColor: const Color(0xFFFF6B6B),
                      tasks: todoTasks,
                      onCompleteTask: onCompleteTask,
                      onUpdateStatus: onUpdateStatus,
                      onDeleteTask: onDeleteTask,
                      onPostponeTask: onPostponeTask,
                      currentDoneCount: doneTasks.length,
                      mainTaskId: mainTaskId,
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (doingTasks.isNotEmpty) ...[
                    _TaskSection(
                      title: '进行中',
                      icon: Icons.pending,
                      iconColor: const Color(0xFF4ECDC4),
                      tasks: doingTasks,
                      onCompleteTask: onCompleteTask,
                      onUpdateStatus: onUpdateStatus,
                      onDeleteTask: onDeleteTask,
                      onPostponeTask: onPostponeTask,
                      currentDoneCount: doneTasks.length,
                      mainTaskId: mainTaskId,
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (doneTasks.isNotEmpty)
                    _TaskSection(
                      title: '已完成',
                      icon: Icons.check_circle,
                      iconColor: const Color(0xFF95E1D3),
                      tasks: doneTasks,
                      onCompleteTask: onCompleteTask,
                      onUpdateStatus: onUpdateStatus,
                      onDeleteTask: onDeleteTask,
                      onPostponeTask: onPostponeTask,
                      currentDoneCount: doneTasks.length,
                      mainTaskId: mainTaskId,
                      isCompletedSection: true,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  TaskItem? _pickAdaptiveTask({
    required List<TaskItem> doingTasks,
    required List<TaskItem> todoTasks,
    required int behaviorScore,
    required String interventionMode,
  }) {
    if (doingTasks.isNotEmpty) {
      return doingTasks.first;
    }
    if (todoTasks.isEmpty) {
      return null;
    }

    final baseDifficulty = behaviorScore <= 65
        ? 2
        : behaviorScore <= 80
            ? 3
            : 4;

    final targetDifficulty = interventionMode == 'light'
        ? 2
        : interventionMode == 'boost'
            ? (baseDifficulty + 1).clamp(2, 5)
            : baseDifficulty;

    final sorted = [...todoTasks]
      ..sort((a, b) {
        final da = (a.difficulty - targetDifficulty).abs();
        final db = (b.difficulty - targetDifficulty).abs();
        if (da != db) return da.compareTo(db);
        return a.estMinutes.compareTo(b.estMinutes);
      });
    return sorted.first;
  }
}

class _AdaptiveHintCard extends StatelessWidget {
  const _AdaptiveHintCard({
    required this.behaviorScore,
    required this.interventionMode,
    required this.interventionNote,
    required this.interventionActive,
    required this.interventionRemainingMinutes,
  });

  final int behaviorScore;
  final String interventionMode;
  final String interventionNote;
  final bool interventionActive;
  final int interventionRemainingMinutes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fromParent = interventionActive && (interventionMode == 'light' || interventionMode == 'boost');
    final remainHours = interventionRemainingMinutes ~/ 60;
    final remainMinutes = interventionRemainingMinutes % 60;
    final remainText = interventionActive
        ? '（家长干预生效中，剩余 ${remainHours}h${remainMinutes}m）'
        : '';

    final text = interventionMode == 'light'
        ? '家长建议减负：优先轻任务和主线保底，稳定节奏。'
        : interventionMode == 'boost'
            ? '家长鼓励冲刺：可先做主线，再挑战进阶任务。'
            : behaviorScore <= 65
                ? '建议先从轻任务热身，再进入主线任务。'
                : behaviorScore <= 80
                    ? '节奏稳定，建议主线+支线均衡推进。'
                    : '状态很好，可优先挑战较高难度任务。';

    final color = interventionMode == 'light'
        ? const Color(0xFFE67700)
        : interventionMode == 'boost'
            ? const Color(0xFF2B8A3E)
            : behaviorScore <= 65
                ? const Color(0xFFF08C00)
                : behaviorScore <= 80
                    ? const Color(0xFF1971C2)
                    : const Color(0xFF2F9E44);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.psychology, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '策略推荐（评分 $behaviorScore）$remainText：$text${fromParent && interventionNote.isNotEmpty ? '\n家长提示：$interventionNote' : ''}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF2D3748),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskSection extends StatelessWidget {
  const _TaskSection({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.tasks,
    required this.onCompleteTask,
    required this.onUpdateStatus,
    required this.onDeleteTask,
    required this.onPostponeTask,
    required this.currentDoneCount,
    required this.mainTaskId,
    this.emptyMessage,
    this.isCompletedSection = false,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final List<TaskItem> tasks;
  final Future<void> Function(TaskItem, int) onCompleteTask;
  final Future<void> Function(TaskItem, String) onUpdateStatus;
  final Future<void> Function(TaskItem) onDeleteTask;
  final Future<void> Function(TaskItem, int days) onPostponeTask;
  final int currentDoneCount;
  final String? mainTaskId;
  final String? emptyMessage;
  final bool isCompletedSection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2D3748),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEDF2F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${tasks.length}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF718096),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (tasks.isEmpty && emptyMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Center(
              child: Text(
                emptyMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFFA0AEC0)),
              ),
            ),
          )
        else
          ...tasks.map(
            (task) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TaskCard(
                task: task,
                onCompleteTask: onCompleteTask,
                onUpdateStatus: onUpdateStatus,
                onDeleteTask: onDeleteTask,
                onPostponeTask: onPostponeTask,
                isCompleted: isCompletedSection,
                isMainTask: task.id == mainTaskId,
                currentDoneCount: currentDoneCount,
              ),
            ),
          ),
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.onCompleteTask,
    required this.onUpdateStatus,
    required this.onDeleteTask,
    required this.onPostponeTask,
    required this.isCompleted,
    required this.isMainTask,
    required this.currentDoneCount,
  });

  final TaskItem task;
  final Future<void> Function(TaskItem, int) onCompleteTask;
  final Future<void> Function(TaskItem, String) onUpdateStatus;
  final Future<void> Function(TaskItem) onDeleteTask;
  final Future<void> Function(TaskItem, int days) onPostponeTask;
  final bool isCompleted;
  final bool isMainTask;
  final int currentDoneCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final difficultyColor = task.difficulty <= 2
        ? const Color(0xFF68D391)
        : task.difficulty <= 4
            ? const Color(0xFFF6AD55)
            : const Color(0xFFFC8181);

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/task-editor', arguments: {'taskId': task.id}),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCompleted ? const Color(0xFFF7FAFC) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
            color: Colors.black.withValues(alpha: isCompleted ? 0.03 : 0.06),
              blurRadius: isCompleted ? 8 : 16,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: isCompleted ? const Color(0xFFE2E8F0) : Colors.transparent),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isCompleted ? const Color(0xFFA0AEC0) : const Color(0xFF2D3748),
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                      decorationThickness: 2,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        Navigator.pushNamed(context, '/task-editor', arguments: {'taskId': task.id});
                        return;
                      }
                      if (value == 'delete') {
                        await onDeleteTask(task);
                        return;
                      }
                      if (value == 'postpone_1') {
                        await onPostponeTask(task, 1);
                        return;
                      }
                      if (value == 'postpone_3') {
                        await onPostponeTask(task, 3);
                        return;
                      }
                      await onUpdateStatus(task, value);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem<String>(value: 'edit', child: Text('编辑计划')),
                      const PopupMenuItem<String>(value: 'todo', child: Text('标记为待完成')),
                      const PopupMenuItem<String>(value: 'doing', child: Text('标记为进行中')),
                      if (!isCompleted) const PopupMenuItem<String>(value: 'done', child: Text('标记为已完成')),
                      const PopupMenuItem<String>(value: 'postpone_1', child: Text('延期 1 天')),
                      const PopupMenuItem<String>(value: 'postpone_3', child: Text('延期 3 天')),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(value: 'delete', child: Text('删除计划')),
                    ],
                    icon: const Icon(Icons.more_vert, color: Color(0xFF718096)),
                  ),
                if (!isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                    color: difficultyColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '难度${task.difficulty}',
                      style: theme.textTheme.labelSmall?.copyWith(color: difficultyColor, fontWeight: FontWeight.w700),
                    ),
                  ),
                if (isMainTask && !isCompleted) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                    color: const Color(0xFFFF8C42).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '主线',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: const Color(0xFFFF8C42),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ] else if (!isCompleted) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                    color: const Color(0xFF718096).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '支线',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF718096),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _Pill(icon: Icons.book_outlined, text: task.subject),
                const SizedBox(width: 8),
                _Pill(icon: Icons.schedule, text: '${task.estMinutes}分钟'),
                const Spacer(),
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF95E1D3).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check, size: 14, color: Color(0xFF38A169)),
                        const SizedBox(width: 4),
                        Text(
                          '已完成',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: const Color(0xFF38A169),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  InkWell(
                    onTap: () => onCompleteTask(task, currentDoneCount),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFF8C42), Color(0xFFFF6B35)]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                      color: const Color(0xFFFF8C42).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline, size: 18, color: Colors.white),
                          SizedBox(width: 6),
                          Text('完成', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFEDF2F7), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF718096)),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(color: const Color(0xFF4A5568), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _MainQuestCard extends StatelessWidget {
  const _MainQuestCard({required this.task, required this.onTap});

  final TaskItem task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDoing = task.status == 'doing';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFF8C42), Color(0xFFFF6B35)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFFF8C42).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '今日主线',
            style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            isDoing ? '继续进行中的任务' : '开始下一个任务',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.95)),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _MainQuestPill(text: task.subject),
                          const SizedBox(width: 8),
                          _MainQuestPill(text: '${task.estMinutes}分钟'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFFF8C42),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: Icon(isDoing ? Icons.timer : Icons.play_arrow),
                  label: Text(isDoing ? '专注' : '开始'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MainQuestPill extends StatelessWidget {
  const _MainQuestPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _MainQuestCelebration extends StatelessWidget {
  const _MainQuestCelebration();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF95E1D3), Color(0xFF38A169)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.celebration, size: 48, color: Colors.white),
          const SizedBox(height: 10),
          Text(
            '太棒了！今日主线任务全部完成',
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '继续保持，卡皮为你骄傲！',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.95)),
          ),
        ],
      ),
    );
  }
}

class _GamificationStrip extends StatelessWidget {
  const _GamificationStrip({required this.tasks});

  final List<TaskItem> tasks;

  @override
  Widget build(BuildContext context) {
    final completedToday = tasks.where((t) => t.status == 'done').length;
    final questScore = tasks.fold<int>(
      0,
      (sum, task) => sum + (task.status == 'done' ? task.difficulty * 10 : 0),
    );
    final streakDays = _calculateStreak(tasks);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFA29BFE), Color(0xFF6C5CE7)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _GamificationStat(
              icon: Icons.local_fire_department,
              label: '连续天数',
              value: '$streakDays',
              iconColor: const Color(0xFFFFB74D),
            ),
          ),
          Container(
            width: 1,
            height: 40,
                    color: Colors.white.withValues(alpha: 0.2),
          ),
          Expanded(
            child: _GamificationStat(
              icon: Icons.check_circle,
              label: '今日完成',
              value: '$completedToday',
              iconColor: const Color(0xFF69F0AE),
            ),
          ),
          Container(
            width: 1,
            height: 40,
                    color: Colors.white.withValues(alpha: 0.2),
          ),
          Expanded(
            child: _GamificationStat(
              icon: Icons.military_tech,
              label: '任务积分',
              value: '$questScore',
              iconColor: const Color(0xFFFFD54F),
            ),
          ),
        ],
      ),
    );
  }

  int _calculateStreak(List<TaskItem> tasks) {
    final completedToday = tasks.where((t) => t.status == 'done').length;
    if (completedToday > 0) {
      return 3 + (completedToday % 5);
    }
    return 2;
  }
}

class _GamificationStat extends StatelessWidget {
  const _GamificationStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 24, color: iconColor),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StudyTimeline extends StatelessWidget {
  const _StudyTimeline({required this.studiedMinutes});

  final int studiedMinutes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (studiedMinutes / 60).clamp(0.0, 1.0);
    final milestones = <int>[0, 20, 40, 60];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline, color: Color(0xFF4ECDC4), size: 20),
              const SizedBox(width: 8),
              Text(
                '今日已学 $studiedMinutes 分钟',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF2D3748),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: const Color(0xFFEDF2F7),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: milestones
                .map(
                  (m) => Text(
                    '${m}m',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: studiedMinutes >= m ? const Color(0xFF4ECDC4) : const Color(0xFFA0AEC0),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _TaskRewardDialog extends StatelessWidget {
  const _TaskRewardDialog({required this.score, required this.streak});

  final int score;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF8C42), Color(0xFFFF6B35)],
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.celebration, size: 44, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              '完成得漂亮！',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department, color: Colors.white),
                  const SizedBox(width: 6),
                  Text('连击 $streak', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 12),
                  const Icon(Icons.military_tech, color: Colors.white),
                  const SizedBox(width: 6),
                  Text('+$score 积分', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFFF8C42),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('继续冒险'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekDateStrip extends StatelessWidget {
  const _WeekDateStrip({required this.tasks});

  final List<TaskItem> tasks;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final center = DateTime(today.year, today.month, today.day);
    final dates = List<DateTime>.generate(7, (index) => center.add(Duration(days: index - 3)));
    final weekOfMonth = _weekOfMonth(center);
    final dateTitle = '${center.year}年${center.month}月${center.day}日  第${center.month}月第$weekOfMonth周';

    final completedByDate = <String, int>{};
    for (final task in tasks) {
      if (task.status != 'done' || task.completedAt == null) {
        continue;
      }
      final done = task.completedAt!;
      final key = '${done.year}-${done.month}-${done.day}';
      completedByDate[key] = (completedByDate[key] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateTitle,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF495057),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: dates.map((date) {
          final isToday = _isSameDay(date, center);
          final key = '${date.year}-${date.month}-${date.day}';
          final doneCount = completedByDate[key] ?? 0;
          final isGreen = doneCount > 0;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isGreen
                      ? const Color(0xFFE6FCF5)
                      : isToday
                          ? const Color(0xFFFFF3BF)
                          : const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isGreen
                        ? const Color(0xFF2F9E44)
                        : isToday
                            ? const Color(0xFFF08C00)
                            : const Color(0xFFE9ECEF),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      const ['一', '二', '三', '四', '五', '六', '日'][date.weekday - 1],
                      style: const TextStyle(fontSize: 11, color: Color(0xFF868E96), fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isGreen
                            ? const Color(0xFF2F9E44)
                            : isToday
                                ? const Color(0xFFE67700)
                                : const Color(0xFF343A40),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

int _weekOfMonth(DateTime date) {
  return ((date.day - 1) ~/ 7) + 1;
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

bool _isOverdueTask(TaskItem task) {
  if (task.status == 'done' || task.dueDate == null) {
    return false;
  }
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final due = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
  return due.isBefore(today);
}

String _statusText(String status) {
  switch (status) {
    case 'todo':
      return '待完成';
    case 'doing':
      return '进行中';
    case 'done':
      return '已完成';
    default:
      return status;
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected == value,
      onSelected: (_) => onTap(value),
    );
  }
}
