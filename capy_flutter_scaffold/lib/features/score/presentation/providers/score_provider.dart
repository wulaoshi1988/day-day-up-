import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_result.dart';
import '../../../../core/di/app_providers.dart';
import '../../domain/models/exam_record.dart';

typedef ScoreQuery = ({
  String childProfileId,
  String subject,
});

final examRecordsProvider = FutureProvider.autoDispose.family<List<ExamRecord>, ScoreQuery>((ref, query) async {
  final repo = ref.watch(scoreRepositoryProvider);
  final result = await repo.fetchExamRecords(
    childProfileId: query.childProfileId,
    subject: query.subject == '全部' ? null : query.subject,
  );

  return switch (result) {
    ApiSuccess<List<ExamRecord>>(:final data) => data,
    ApiFailure<List<ExamRecord>>(:final message) => throw Exception(message),
  };
});

final examSummaryProvider = FutureProvider.autoDispose.family<ExamSummary, ScoreQuery>((ref, query) async {
  final repo = ref.watch(scoreRepositoryProvider);
  final result = await repo.fetchExamSummary(
    childProfileId: query.childProfileId,
    subject: query.subject == '全部' ? null : query.subject,
  );

  return switch (result) {
    ApiSuccess<ExamSummary>(:final data) => data,
    ApiFailure<ExamSummary>(:final message) => throw Exception(message),
  };
});
