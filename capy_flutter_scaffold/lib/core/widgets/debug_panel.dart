import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_env.dart';
import '../di/app_providers.dart';

class DebugPanelButton extends ConsumerWidget {
  const DebugPanelButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    return IconButton(
      icon: const Icon(Icons.tune),
      onPressed: () {
        showModalBottomSheet<void>(
          context: context,
          builder: (_) => const _DebugPanelSheet(),
        );
      },
    );
  }
}

class _DebugPanelSheet extends ConsumerWidget {
  const _DebugPanelSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childId = ref.watch(activeChildProfileIdProvider);
    final grade = ref.watch(activeGradeProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('开发调试面板', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            const Text('USE_MOCK_API: ${AppEnv.useMockApi}'),
            Text('当前 child_profile_id: $childId'),
            Text('当前年级: $grade 年级'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => ref.read(activeChildProfileIdProvider.notifier).state = 'demo-child-id',
                  child: const Text('Demo 孩子A'),
                ),
                OutlinedButton(
                  onPressed: () => ref.read(activeChildProfileIdProvider.notifier).state = 'demo-child-b',
                  child: const Text('Demo 孩子B'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('年级'),
                Expanded(
                  child: Slider(
                    min: 1,
                    max: 6,
                    divisions: 5,
                    value: grade.toDouble(),
                    label: '$grade',
                    onChanged: (v) => ref.read(activeGradeProvider.notifier).state = v.round(),
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
