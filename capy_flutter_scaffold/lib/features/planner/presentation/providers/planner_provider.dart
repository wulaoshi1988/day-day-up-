import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../../core/api/api_result.dart';
import '../../../../core/di/app_providers.dart';
import '../../domain/models/task_item.dart';

final plannerTasksProvider = FutureProvider.family<List<TaskItem>, String>((ref, childProfileId) async {
  final repo = ref.watch(plannerRepositoryProvider);
  final result = await repo.fetchTasks(childProfileId: childProfileId, range: 'today');

  switch (result) {
    case ApiSuccess<List<TaskItem>>(:final data):
      return data;
    case ApiFailure<List<TaskItem>>(:final message):
      throw Exception(message);
  }
});

final plannerStatusFilterProvider = StateProvider<String>((_) => 'all');

String? _extractQuoteFromPayload(dynamic payload) {
  if (payload is Map<String, dynamic>) {
    final candidates = [
      payload['hitokoto'],
      payload['mingrenmingyan'],
      payload['msg'],
      payload['text'],
      payload['content'],
    ];
    for (final raw in candidates) {
      final text = (raw as String? ?? '').replaceAll('\n', ' ').trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
  }

  if (payload is List && payload.isNotEmpty) {
    for (final item in payload) {
      final text = _extractQuoteFromPayload(item);
      if (text != null && text.isNotEmpty) {
        return text;
      }
    }
  }

  return null;
}

final capyQuoteProvider = FutureProvider<String>((_) async {
  const fallbackQuotes = [
    '努力是把普通的一天，变成闪闪发光的一天。',
    '优秀不是天赋，而是把好习惯坚持到底。',
    '每天进步一点点，习惯会把你送到更远的地方。',
    '先把小事做好，长期坚持就是优秀。',
    '自律像种子，习惯像土壤，努力会开花。',
    '把今天完成好，就是明天优秀的起点。',
  ];

  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 4),
      receiveTimeout: const Duration(seconds: 4),
    ),
  );

  final quoteApis = <Uri>[
    Uri.parse('https://v1.hitokoto.cn/?encode=json'),
    Uri.parse('https://v.api.aa1.cn/api/api-wenan-mingrenmingyan/index.php?aa1=json'),
  ];

  final start = DateTime.now().millisecond % quoteApis.length;
  final rotated = [
    ...quoteApis.skip(start),
    ...quoteApis.take(start),
  ];

  for (final uri in rotated) {
    try {
      final resp = await dio.getUri<dynamic>(uri);
      final text = _extractQuoteFromPayload(resp.data);
      if (text != null && text.isNotEmpty) {
        return '卡皮巴拉名言：$text';
      }
    } catch (_) {
      continue;
    }
  }

  final index = DateTime.now().millisecond % fallbackQuotes.length;
  return '卡皮巴拉名言：${fallbackQuotes[index]}';
});
