import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_result.dart';
import '../../../../core/di/app_providers.dart';
import '../../domain/models/weekly_report.dart';
import '../../domain/repositories/parent_repository.dart';

final parentDashboardProvider = FutureProvider.family<ParentDashboard, String>((ref, childProfileId) async {
  final repo = ref.watch(parentRepositoryProvider);
  final result = await repo.fetchDashboard(childProfileId: childProfileId);

  switch (result) {
    case ApiSuccess<ParentDashboard>(:final data):
      return data;
    case ApiFailure<ParentDashboard>(:final message):
      throw Exception(message);
  }
});

final weeklyReportProvider = FutureProvider.family<WeeklyReport, String>((ref, childProfileId) async {
  final repo = ref.watch(parentRepositoryProvider);
  final result = await repo.fetchWeeklyReport(childProfileId: childProfileId);

  switch (result) {
    case ApiSuccess<WeeklyReport>(:final data):
      return data;
    case ApiFailure<WeeklyReport>(:final message):
      throw Exception(message);
  }
});

final weeklyTrendProvider = FutureProvider.family<List<double>, String>((ref, childProfileId) async {
  final repo = ref.watch(parentRepositoryProvider);
  final result = await repo.fetchWeeklyTrend(childProfileId: childProfileId);

  switch (result) {
    case ApiSuccess<List<double>>(:final data):
      return data;
    case ApiFailure<List<double>>(:final message):
      throw Exception(message);
  }
});
