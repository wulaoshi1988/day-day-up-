import '../../../../core/api/api_result.dart';
import '../models/exam_record.dart';

abstract class ScoreRepository {
  Future<ApiResult<List<ExamRecord>>> fetchExamRecords({
    required String childProfileId,
    String? subject,
  });

  Future<ApiResult<ExamSummary>> fetchExamSummary({
    required String childProfileId,
    String? subject,
  });

  Future<ApiResult<AddExamResult>> addExamRecord({
    required String childProfileId,
    required String examName,
    required String subject,
    required double score,
    required double fullScore,
    required String examDate,
    int? rank,
  });
}
