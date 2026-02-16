class ExamRecord {
  const ExamRecord({
    required this.id,
    required this.examName,
    required this.subject,
    required this.score,
    required this.fullScore,
    required this.examDate,
    this.rank,
  });

  final String id;
  final String examName;
  final String subject;
  final double score;
  final double fullScore;
  final String examDate;
  final int? rank;

  double get scoreRate {
    if (fullScore <= 0) return 0;
    return (score / fullScore) * 100;
  }
}

class SubjectScoreStat {
  const SubjectScoreStat({
    required this.subject,
    required this.averageRate,
    required this.examCount,
  });

  final String subject;
  final double averageRate;
  final int examCount;
}

class ExamSummary {
  const ExamSummary({
    required this.examCount,
    required this.averageRate,
    required this.latestTotalScore,
    required this.latestExamName,
    required this.recentTrend,
    required this.subjectStats,
  });

  final int examCount;
  final double averageRate;
  final double latestTotalScore;
  final String latestExamName;
  final List<double> recentTrend;
  final List<SubjectScoreStat> subjectStats;
}

class AddExamResult {
  const AddExamResult({
    required this.record,
    required this.duplicateHint,
    this.duplicateMessage,
  });

  final ExamRecord record;
  final bool duplicateHint;
  final String? duplicateMessage;
}
