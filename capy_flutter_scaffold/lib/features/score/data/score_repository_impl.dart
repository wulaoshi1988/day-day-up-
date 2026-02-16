import '../../../core/api/api_client.dart';
import '../../../core/api/api_result.dart';
import '../domain/models/exam_record.dart';
import '../domain/repositories/score_repository.dart';

class ScoreRepositoryImpl implements ScoreRepository {
  ScoreRepositoryImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<ApiResult<List<ExamRecord>>> fetchExamRecords({
    required String childProfileId,
    String? subject,
  }) async {
    try {
      final json = await _apiClient.get(
        '/children/$childProfileId/exam-records',
        query: {
          if (subject != null && subject.trim().isNotEmpty) 'subject': subject.trim(),
        },
      );

      final rows = (json['data'] as List<dynamic>? ?? const <dynamic>[]).cast<Map<String, dynamic>>();
      final records = rows.map(_toExamRecord).toList();
      return ApiSuccess(records);
    } catch (e) {
      return ApiFailure('Failed to fetch exam records: $e');
    }
  }

  @override
  Future<ApiResult<ExamSummary>> fetchExamSummary({
    required String childProfileId,
    String? subject,
  }) async {
    try {
      final json = await _apiClient.get(
        '/children/$childProfileId/exam-summary',
        query: {
          if (subject != null && subject.trim().isNotEmpty) 'subject': subject.trim(),
        },
      );
      final data = json['data'] as Map<String, dynamic>? ?? const <String, dynamic>{};

      final stats = (data['subject_stats'] as List<dynamic>? ?? const <dynamic>[])
          .cast<Map<String, dynamic>>()
          .map(
            (row) => SubjectScoreStat(
              subject: row['subject'] as String? ?? '综合',
              averageRate: (row['average_rate'] as num?)?.toDouble() ?? 0,
              examCount: (row['exam_count'] as num?)?.toInt() ?? 0,
            ),
          )
          .toList();

      final summary = ExamSummary(
        examCount: (data['exam_count'] as num?)?.toInt() ?? 0,
        averageRate: (data['average_rate'] as num?)?.toDouble() ?? 0,
        latestTotalScore: (data['latest_total_score'] as num?)?.toDouble() ?? 0,
        latestExamName: data['latest_exam_name'] as String? ?? '--',
        recentTrend: (data['recent_trend'] as List<dynamic>? ?? const <dynamic>[])
            .map((e) => (e as num).toDouble())
            .toList(),
        subjectStats: stats,
      );
      return ApiSuccess(summary);
    } catch (e) {
      return ApiFailure('Failed to fetch exam summary: $e');
    }
  }

  @override
  Future<ApiResult<AddExamResult>> addExamRecord({
    required String childProfileId,
    required String examName,
    required String subject,
    required double score,
    required double fullScore,
    required String examDate,
    int? rank,
  }) async {
    try {
      final json = await _apiClient.post(
        '/children/$childProfileId/exam-records',
        body: {
          'exam_name': examName,
          'subject': subject,
          'score': score,
          'full_score': fullScore,
          'exam_date': examDate,
          if (rank != null) 'rank': rank,
        },
      );

      final data = json['data'] as Map<String, dynamic>?;
      if (data?['ok'] == false) {
        return ApiFailure(data?['message'] as String? ?? '成绩录入失败，请稍后再试');
      }

      final row = data?['record'] as Map<String, dynamic>?;
      if (row == null) {
        return const ApiFailure('成绩录入失败，返回数据异常');
      }

      return ApiSuccess(
        AddExamResult(
          record: _toExamRecord(row),
          duplicateHint: data?['duplicate_hint'] == true,
          duplicateMessage: data?['duplicate_message'] as String?,
        ),
      );
    } catch (e) {
      return ApiFailure('Failed to add exam record: $e');
    }
  }

  ExamRecord _toExamRecord(Map<String, dynamic> row) {
    return ExamRecord(
      id: row['id'] as String? ?? '',
      examName: row['exam_name'] as String? ?? '考试',
      subject: row['subject'] as String? ?? '综合',
      score: (row['score'] as num?)?.toDouble() ?? 0,
      fullScore: (row['full_score'] as num?)?.toDouble() ?? 0,
      examDate: row['exam_date'] as String? ?? '',
      rank: (row['rank'] as num?)?.toInt(),
    );
  }
}
