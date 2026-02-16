import 'api_client.dart';

class MockApiClient implements ApiClient {
  static final Map<String, List<Map<String, dynamic>>> _tasksByChild = {
    'demo-child-id': [
      {
        'id': 't1',
        'child_profile_id': 'demo-child-id',
        'subject': '语文',
        'title': '朗读课文 10 分钟',
        'difficulty': 1,
        'est_minutes': 10,
        'status': 'todo',
        'priority': 'medium',
        'target_score': null,
        'start_date': null,
        'due_date': null,
        'notes': '',
        'completed_at': null,
      },
      {
        'id': 't2',
        'child_profile_id': 'demo-child-id',
        'subject': '数学',
        'title': '口算练习 20 题',
        'difficulty': 2,
        'est_minutes': 12,
        'status': 'doing',
        'priority': 'high',
        'target_score': 95,
        'start_date': null,
        'due_date': null,
        'notes': '先做基础题再做提升题',
        'completed_at': null,
      },
    ],
    'demo-child-b': [
      {
        'id': 'tb1',
        'child_profile_id': 'demo-child-b',
        'subject': '英语',
        'title': '跟读单词 15 个',
        'difficulty': 1,
        'est_minutes': 10,
        'status': 'todo',
        'priority': 'low',
        'target_score': null,
        'start_date': null,
        'due_date': null,
        'notes': '',
        'completed_at': null,
      },
    ],
  };

  static final Map<String, List<Map<String, dynamic>>> _examRecordsByChild = {
    'demo-child-id': [
      {
        'id': 'e1',
        'exam_name': '期中考试',
        'subject': '数学',
        'score': 92,
        'full_score': 100,
        'exam_date': '2026-01-15',
        'rank': 12,
      },
      {
        'id': 'e2',
        'exam_name': '期中考试',
        'subject': '英语',
        'score': 88,
        'full_score': 100,
        'exam_date': '2026-01-15',
        'rank': 18,
      },
      {
        'id': 'e3',
        'exam_name': '月考二',
        'subject': '语文',
        'score': 84,
        'full_score': 100,
        'exam_date': '2025-12-22',
        'rank': 22,
      },
      {
        'id': 'e4',
        'exam_name': '月考二',
        'subject': '数学',
        'score': 90,
        'full_score': 100,
        'exam_date': '2025-12-22',
        'rank': 15,
      },
    ],
    'demo-child-b': [
      {
        'id': 'eb1',
        'exam_name': '单元测验',
        'subject': '英语',
        'score': 76,
        'full_score': 100,
        'exam_date': '2026-01-10',
        'rank': 31,
      },
    ],
  };

  static final Map<String, int> _energyByChild = {
    'demo-child-id': 268,
    'demo-child-b': 196,
  };

  static final Map<String, int> _todayEnergyByChild = {
    'demo-child-id': 18,
    'demo-child-b': 10,
  };

  static final Map<String, List<double>> _trendByChild = {
    'demo-child-id': [60, 66, 70, 73, 78, 82, 86],
    'demo-child-b': [42, 46, 44, 55, 58, 62, 65],
  };

  static final Map<String, int> _gradeByChild = {
    'demo-child-id': 3,
    'demo-child-b': 5,
  };

  static final Map<String, String> _interventionModeByChild = {
    'demo-child-id': 'normal',
    'demo-child-b': 'normal',
  };

  static final Map<String, String> _interventionNoteByChild = {
    'demo-child-id': '',
    'demo-child-b': '',
  };

  static final Map<String, int> _interventionUpdatedAtMsByChild = {
    'demo-child-id': 0,
    'demo-child-b': 0,
  };

  static final Map<String, double> _interventionBaselineCompletionByChild = {
    'demo-child-id': 0,
    'demo-child-b': 0,
  };

  static final Map<String, List<Map<String, dynamic>>> _interventionHistoryByChild = {
    'demo-child-id': const <Map<String, dynamic>>[],
    'demo-child-b': const <Map<String, dynamic>>[],
  };

  static const int _interventionActiveMinutes = 24 * 60;
  static const int _interventionCooldownMinutes = 30;

  static final Map<String, int> _streakByChild = {
    'demo-child-id': 6,
    'demo-child-b': 3,
  };

  static final Map<String, String> _lastActiveDateByChild = {
    'demo-child-id': _dateOnly(DateTime.now().subtract(const Duration(days: 1))),
    'demo-child-b': _dateOnly(DateTime.now().subtract(const Duration(days: 4))),
  };

  static final Map<String, int> _streakBackupByChild = {
    'demo-child-id': 0,
    'demo-child-b': 3,
  };

  static final Map<String, bool> _streakBrokenByChild = {
    'demo-child-id': false,
    'demo-child-b': true,
  };

  static final Map<String, bool> _canRecoverByChild = {
    'demo-child-id': false,
    'demo-child-b': true,
  };

  static const int _recoverCost = 12;
  static const int _recoverMaxPerWeek = 2;
  static const int _recoverCooldownMinutes = 180;

  static final Map<String, int> _recoverUsedCountByChild = {
    'demo-child-id': 0,
    'demo-child-b': 0,
  };

  static final Map<String, String> _recoverWeekKeyByChild = {
    'demo-child-id': '',
    'demo-child-b': '',
  };

  static final Map<String, List<Map<String, dynamic>>> _redeemHistoryByChild = {
    'demo-child-id': [
      {
        'reward_name': '卡皮贴纸包',
        'cost': 18,
        'created_at': '2026-02-10 19:20',
      },
    ],
    'demo-child-b': const <Map<String, dynamic>>[],
  };

  static final List<Map<String, dynamic>> _rewardCatalog = [
    {'name': '卡皮贴纸包', 'base_price': 18},
    {'name': '奶茶兑换卡', 'base_price': 26},
    {'name': '周末公园卡', 'base_price': 36},
    {'name': '卡皮盲盒券', 'base_price': 48},
  ];

  static final Map<String, List<Map<String, dynamic>>> _customRewardCatalogByChild = {
    'demo-child-id': <Map<String, dynamic>>[],
    'demo-child-b': <Map<String, dynamic>>[],
  };

  static final Map<String, List<String>> _removedRewardNamesByChild = {
    'demo-child-id': <String>[],
    'demo-child-b': <String>[],
  };

  static final Map<String, int> _lastRecoverAtMsByChild = {
    'demo-child-id': 0,
    'demo-child-b': 0,
  };

  static String _dateOnly(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static int _dayDiff(String fromDate, String toDate) {
    final from = DateTime.parse(fromDate);
    final to = DateTime.parse(toDate);
    return to.difference(from).inDays;
  }

  static String _weekKey(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return _dateOnly(monday);
  }

  static void _refreshRecoverQuota(String childId) {
    final currentWeek = _weekKey(DateTime.now());
    final savedWeek = _recoverWeekKeyByChild[childId];
    if (savedWeek != currentWeek) {
      _recoverWeekKeyByChild[childId] = currentWeek;
      _recoverUsedCountByChild[childId] = 0;
    }
  }

  static int _recoverCooldownLeftMinutes(String childId) {
    final lastMs = _lastRecoverAtMsByChild[childId] ?? 0;
    if (lastMs <= 0) return 0;
    final elapsedMinutes = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(lastMs)).inMinutes;
    final left = _recoverCooldownMinutes - elapsedMinutes;
    return left > 0 ? left : 0;
  }

  static int _interventionRemainingMinutes(String childId) {
    final updatedAt = _interventionUpdatedAtMsByChild[childId] ?? 0;
    if (updatedAt <= 0) {
      return 0;
    }
    final elapsed = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(updatedAt)).inMinutes;
    final left = _interventionActiveMinutes - elapsed;
    return left > 0 ? left : 0;
  }

  static int _interventionElapsedMinutes(String childId) {
    final updatedAt = _interventionUpdatedAtMsByChild[childId] ?? 0;
    if (updatedAt <= 0) {
      return 0;
    }
    return DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(updatedAt)).inMinutes;
  }

  static int _interventionCooldownLeftMinutes(String childId) {
    final updatedAt = _interventionUpdatedAtMsByChild[childId] ?? 0;
    if (updatedAt <= 0) {
      return 0;
    }
    final elapsed = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(updatedAt)).inMinutes;
    final left = _interventionCooldownMinutes - elapsed;
    return left > 0 ? left : 0;
  }

  static double _currentCompletionRate(String childId) {
    final tasks = _tasksByChild[childId] ?? <Map<String, dynamic>>[];
    if (tasks.isEmpty) {
      return 0.0;
    }
    final done = tasks.where((t) => t['status'] == 'done').length;
    return (done / tasks.length) * 100;
  }

  static List<double> _buildInterventionEffectTrend({
    required double baseline,
    required double current,
    required bool active,
  }) {
    if (!active) {
      return [baseline, baseline, baseline, baseline, baseline, baseline]
          .map((v) => v.clamp(0.0, 100.0).toDouble())
          .toList();
    }

    final delta = current - baseline;
    final points = <double>[];
    for (var i = 0; i < 6; i++) {
      final t = i / 5;
      final curve = t * t * (3 - 2 * t);
      final value = baseline + (delta * curve);
      points.add(value.clamp(0.0, 100.0).toDouble());
    }
    return points;
  }

  static bool _hasFollowupAction(String childId, List<String> subTypes) {
    final history = _interventionHistoryByChild[childId] ?? const <Map<String, dynamic>>[];
    for (final row in history) {
      final actionType = row['action_type'] as String? ?? '';
      final actionSubType = row['action_sub_type'] as String? ?? '';
      if (actionType == 'followup' && subTypes.contains(actionSubType)) {
        return true;
      }
    }
    return false;
  }

  static double _simulateInterventionDelta(String childId, String mode) {
    final score = _weeklyBehaviorScore(childId);
    final base = mode == 'boost'
        ? (score >= 75 ? 6.0 : 3.5)
        : mode == 'light'
            ? (score <= 65 ? 4.5 : 2.0)
            : 0.0;
    final noise = ((DateTime.now().millisecond % 7) - 3) * 0.3;
    return (base + noise).clamp(-3.0, 12.0).toDouble();
  }

  static Map<String, int> _interventionModeStats(List<Map<String, dynamic>> history) {
    var boostTotal = 0;
    var boostSuccess = 0;
    var lightTotal = 0;
    var lightSuccess = 0;

    for (final row in history) {
      final mode = row['mode'] as String? ?? 'normal';
      final delta = (row['effect_delta'] as num?)?.toDouble();
      if (mode == 'boost') {
        boostTotal += 1;
        if ((delta ?? 0) > 0) {
          boostSuccess += 1;
        }
      } else if (mode == 'light') {
        lightTotal += 1;
        if ((delta ?? 0) > 0) {
          lightSuccess += 1;
        }
      }
    }

    return {
      'boost_total': boostTotal,
      'boost_success': boostSuccess,
      'light_total': lightTotal,
      'light_success': lightSuccess,
    };
  }

  static void _refreshInterventionState(String childId) {
    final mode = _interventionModeByChild[childId] ?? 'normal';
    if (mode == 'normal') {
      return;
    }

    if (_interventionRemainingMinutes(childId) > 0) {
      return;
    }

    _interventionModeByChild[childId] = 'normal';
    _interventionNoteByChild[childId] = '';
    _interventionUpdatedAtMsByChild[childId] = 0;
    _interventionBaselineCompletionByChild[childId] = 0.0;
  }

  static List<Map<String, dynamic>> _buildRewardOptions(String childId) {
    final grade = _gradeByChild[childId] ?? 3;
    final streak = _streakByChild[childId] ?? 0;

    final gradeFactor = grade >= 5 ? 1.18 : grade >= 3 ? 1.08 : 1.0;
    final streakDiscount = streak >= 10
        ? 0.82
        : streak >= 7
            ? 0.9
            : streak >= 3
                ? 0.96
                : 1.0;

    final customCatalog = _customRewardCatalogByChild[childId] ?? const <Map<String, dynamic>>[];
    final removedNames = _removedRewardNamesByChild[childId] ?? const <String>[];
    final mergedCatalog = <Map<String, dynamic>>[
      ..._rewardCatalog,
      ...customCatalog,
    ].where((item) {
      final name = (item['name'] as String? ?? '').trim();
      return !removedNames.contains(name);
    }).toList();

    return mergedCatalog.map((item) {
      final base = (item['base_price'] as num).toInt();
      final dynamicPrice = (base * gradeFactor * streakDiscount).round().clamp(8, 999);
      String? tag;
      if (streak >= 10) {
        tag = '连击特惠-18%';
      } else if (streak >= 7) {
        tag = '连击特惠-10%';
      } else if (streak >= 3) {
        tag = '连击特惠-4%';
      }

      return {
        'name': item['name'],
        'base_price': base,
        'dynamic_price': dynamicPrice,
        'discount_tag': tag,
      };
    }).toList();
  }

  static int _weeklyBehaviorScore(String childId) {
    final trend = _trendByChild[childId] ?? [55, 58, 60, 62, 63, 64, 65];
    final avg = trend.fold<double>(0.0, (sum, v) => sum + v) / trend.length;
    final streak = _streakByChild[childId] ?? 0;
    final recoverUsed = _recoverUsedCountByChild[childId] ?? 0;
    final score = (avg * 0.7) + (streak * 2.0) - (recoverUsed * 4.0);
    return score.round().clamp(35, 99);
  }

  static void _refreshBrokenState(String childId) {
    final last = _lastActiveDateByChild[childId];
    if (last == null) {
      _streakBrokenByChild[childId] = false;
      _canRecoverByChild[childId] = false;
      return;
    }

    final today = _dateOnly(DateTime.now());
    final diff = _dayDiff(last, today);
    if (diff > 1 && (_streakByChild[childId] ?? 0) > 0) {
      _streakBrokenByChild[childId] = true;
      _canRecoverByChild[childId] = true;
      _streakBackupByChild[childId] = _streakByChild[childId] ?? 0;
    }
  }

  static void _applyDailyStreakSettlement(String childId) {
    final today = _dateOnly(DateTime.now());
    final current = _streakByChild[childId] ?? 0;
    final last = _lastActiveDateByChild[childId];

    if (last == null) {
      _streakByChild[childId] = current <= 0 ? 1 : current;
      _lastActiveDateByChild[childId] = today;
      _streakBrokenByChild[childId] = false;
      _canRecoverByChild[childId] = false;
      _streakBackupByChild[childId] = 0;
      return;
    }

    final diff = _dayDiff(last, today);
    if (diff <= 0) {
      return;
    }

    if (diff == 1) {
      _streakByChild[childId] = (current <= 0 ? 1 : current) + 1;
      _streakBrokenByChild[childId] = false;
      _canRecoverByChild[childId] = false;
      _streakBackupByChild[childId] = 0;
      _lastActiveDateByChild[childId] = today;
      return;
    }

    _streakBackupByChild[childId] = current;
    _streakByChild[childId] = 1;
    _streakBrokenByChild[childId] = true;
    _canRecoverByChild[childId] = true;
    _lastActiveDateByChild[childId] = today;
  }

  static String _extractChildId(String path) {
    final parts = path.split('/');
    final idx = parts.indexOf('children');
    if (idx >= 0 && idx + 1 < parts.length) return parts[idx + 1];
    return 'demo-child-id';
  }

  static String _extractTaskId(String path) {
    final parts = path.split('/');
    final idx = parts.indexOf('tasks');
    if (idx >= 0 && idx + 1 < parts.length) return parts[idx + 1];
    return '';
  }

  static DateTime _parseYmd(String value) {
    return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  static List<Map<String, dynamic>> _sortExamRecords(List<Map<String, dynamic>> rows) {
    final copied = [...rows];
    copied.sort((a, b) {
      final ad = _parseYmd(a['exam_date'] as String? ?? '');
      final bd = _parseYmd(b['exam_date'] as String? ?? '');
      return bd.compareTo(ad);
    });
    return copied;
  }

  static List<Map<String, dynamic>> _filterExamRecords(String childId, String? subject) {
    final all = _examRecordsByChild[childId] ?? <Map<String, dynamic>>[];
    final filtered = (subject == null || subject.trim().isEmpty)
        ? all
        : all.where((row) => (row['subject'] as String? ?? '') == subject.trim()).toList();
    return _sortExamRecords(filtered);
  }

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    if (path.contains('/tasks')) {
      final childId = _extractChildId(path);
      final tasks = _tasksByChild[childId] ?? <Map<String, dynamic>>[];
      return {'data': tasks};
    }

    if (path.contains('/dashboard')) {
      final childId = _extractChildId(path);
      final tasks = _tasksByChild[childId] ?? <Map<String, dynamic>>[];
      final done = tasks.where((t) => t['status'] == 'done').length;
      final pending = tasks.where((t) => t['status'] != 'done').length;
      final completion = _currentCompletionRate(childId);

      return {
        'data': {
          'completion_rate': completion,
          'pending_count': pending,
          'total_minutes_today': (done * 12) + 12,
        }
      };
    }

    if (path.contains('/weekly-trend')) {
      final childId = _extractChildId(path);
      return {'data': _trendByChild[childId] ?? [50, 52, 55, 58, 60, 62, 64]};
    }

    if (path.contains('/weekly-report')) {
      final childId = _extractChildId(path);
      final trend = _trendByChild[childId] ?? [50, 52, 55, 58, 60, 62, 64];
      final completion = trend.last;
      return {
        'data': {
          'child_profile_id': childId,
          'week_start': DateTime.now().toIso8601String(),
          'completion_rate': completion,
          'total_sessions': (completion ~/ 6).toInt(),
          'total_minutes': (completion * 2).toInt(),
          'ai_summary': '本周完成率 ${completion.toStringAsFixed(1)}%，继续保持稳定节奏。',
        }
      };
    }

    if (path.contains('/exam-records')) {
      final childId = _extractChildId(path);
      final subject = query?['subject'] as String?;
      return {'data': _filterExamRecords(childId, subject)};
    }

    if (path.contains('/exam-summary')) {
      final childId = _extractChildId(path);
      final subject = query?['subject'] as String?;
      final rows = _filterExamRecords(childId, subject);

      if (rows.isEmpty) {
        return {
          'data': {
            'exam_count': 0,
            'average_rate': 0,
            'latest_total_score': 0,
            'latest_exam_name': '--',
            'recent_trend': const <double>[],
            'subject_stats': const <Map<String, dynamic>>[],
          }
        };
      }

      final averageRate = rows
              .map((row) {
                final s = (row['score'] as num?)?.toDouble() ?? 0;
                final f = (row['full_score'] as num?)?.toDouble() ?? 0;
                if (f <= 0) return 0.0;
                return (s / f) * 100;
              })
              .fold<double>(0.0, (sum, v) => sum + v) /
          rows.length;

      final latestDate = rows.first['exam_date'] as String? ?? '';
      final latestExamName = rows.first['exam_name'] as String? ?? '--';
      final latestTotalScore = rows
          .where((row) => (row['exam_date'] as String? ?? '') == latestDate)
          .fold<double>(0.0, (sum, row) => sum + ((row['score'] as num?)?.toDouble() ?? 0));

      final recentTrend = rows
          .take(6)
          .map((row) {
            final s = (row['score'] as num?)?.toDouble() ?? 0;
            final f = (row['full_score'] as num?)?.toDouble() ?? 0;
            if (f <= 0) return 0.0;
            return ((s / f) * 100).clamp(0.0, 100.0).toDouble();
          })
          .toList();

      final bySubject = <String, List<Map<String, dynamic>>>{};
      for (final row in rows) {
        final key = row['subject'] as String? ?? '综合';
        bySubject.putIfAbsent(key, () => <Map<String, dynamic>>[]).add(row);
      }
      final stats = bySubject.entries.map((entry) {
        final list = entry.value;
        final avg = list
                .map((row) {
                  final s = (row['score'] as num?)?.toDouble() ?? 0;
                  final f = (row['full_score'] as num?)?.toDouble() ?? 0;
                  if (f <= 0) return 0.0;
                  return (s / f) * 100;
                })
                .fold<double>(0.0, (sum, v) => sum + v) /
            list.length;
        return {
          'subject': entry.key,
          'average_rate': avg,
          'exam_count': list.length,
        };
      }).toList();

      return {
        'data': {
          'exam_count': rows.length,
          'average_rate': averageRate,
          'latest_total_score': latestTotalScore,
          'latest_exam_name': latestExamName,
          'recent_trend': recentTrend,
          'subject_stats': stats,
        }
      };
    }

    if (path.contains('/growth')) {
      final childId = _extractChildId(path);
      _refreshInterventionState(childId);
      _refreshRecoverQuota(childId);
      _refreshBrokenState(childId);
      final last = _lastActiveDateByChild[childId];
      final today = _dateOnly(DateTime.now());
      final missedDays = last == null ? 0 : (_dayDiff(last, today) - 1).clamp(0, 365);
      final used = _recoverUsedCountByChild[childId] ?? 0;
      final usesLeft = (_recoverMaxPerWeek - used).clamp(0, _recoverMaxPerWeek);
      final hasEnergy = (_energyByChild[childId] ?? 0) >= _recoverCost;
      final cooldownLeft = _recoverCooldownLeftMinutes(childId);
      final canRecover = (_canRecoverByChild[childId] ?? false) && usesLeft > 0 && hasEnergy && cooldownLeft == 0;
      final rewardOptions = _buildRewardOptions(childId);
      final interventionRemaining = _interventionRemainingMinutes(childId);
      final interventionElapsed = _interventionElapsedMinutes(childId);
      final interventionCooldown = _interventionCooldownLeftMinutes(childId);
      final baseline = _interventionBaselineCompletionByChild[childId] ?? 0.0;
      final currentCompletion = _currentCompletionRate(childId);
      final effectAvailable = interventionRemaining > 0;
      final effectDelta = effectAvailable ? (currentCompletion - baseline) : 0.0;
      final effectTrend = _buildInterventionEffectTrend(
        baseline: baseline,
        current: currentCompletion,
        active: effectAvailable,
      );
      final reached2h = effectAvailable && interventionElapsed >= 120;
      final reached6h = effectAvailable && interventionElapsed >= 360;
      final followup2hDone = reached2h && _hasFollowupAction(childId, const ['2h_makeup', '6h_makeup', 'review']);
      final followup6hDone = reached6h && _hasFollowupAction(childId, const ['6h_makeup', 'review']);

      final nextFollowupInMinutes = !effectAvailable
          ? 0
          : !reached2h
              ? (120 - interventionElapsed).clamp(0, 120)
              : !followup2hDone
                  ? 0
                  : !reached6h
                      ? (360 - interventionElapsed).clamp(0, 240)
                      : !followup6hDone
                          ? 0
                          : 0;

      final overdue2h = reached2h && !followup2hDone;
      final overdue6h = reached6h && !followup6hDone;
      final overdueStage = overdue6h
          ? '6h'
          : overdue2h
              ? '2h'
              : '';
      final overdueMinutes = overdue6h
          ? (interventionElapsed - 360).clamp(0, 24 * 60)
          : overdue2h
              ? (interventionElapsed - 120).clamp(0, 24 * 60)
              : 0;
      final interventionHistory = _interventionHistoryByChild[childId] ?? const <Map<String, dynamic>>[];
      final modeStats = _interventionModeStats(interventionHistory);
      return {
        'data': {
          'energy_balance': _energyByChild[childId] ?? 0,
          'today_energy': _todayEnergyByChild[childId] ?? 0,
          'streak_days': _streakByChild[childId] ?? 0,
          'streak_broken': _streakBrokenByChild[childId] ?? false,
          'can_recover': canRecover,
          'missed_days': missedDays,
          'recover_cost': _recoverCost,
          'recover_uses_left': usesLeft,
          'recover_max_per_week': _recoverMaxPerWeek,
          'recover_cooldown_minutes': cooldownLeft,
          'badges': [
            '温泉连击',
            '阅读小能手',
            '专注达人',
            '数学突击手',
            '英语拼读王',
            '语文朗读星',
            '番茄钟守护者',
            '连击一周',
            '连击双周',
            '早起学习家',
            '夜间复盘员',
            '错题终结者',
            '主线通关者',
            '任务清零王',
            '成长勋章大师',
          ],
          'reward_items': rewardOptions.map((e) => e['name']).toList(),
          'reward_options': rewardOptions,
          'weekly_behavior_score': _weeklyBehaviorScore(childId),
          'intervention_mode': _interventionModeByChild[childId] ?? 'normal',
          'intervention_note': _interventionNoteByChild[childId] ?? '',
          'intervention_active': interventionRemaining > 0,
          'intervention_remaining_minutes': interventionRemaining,
          'intervention_cooldown_minutes': interventionCooldown,
          'intervention_effect_available': effectAvailable,
          'intervention_effect_delta': effectDelta,
          'intervention_baseline_completion': baseline,
          'intervention_current_completion': currentCompletion,
          'intervention_effect_trend': effectTrend,
          'intervention_followup_2h_done': followup2hDone,
          'intervention_followup_6h_done': followup6hDone,
          'intervention_followup_2h_reached': reached2h,
          'intervention_followup_6h_reached': reached6h,
          'intervention_next_followup_minutes': nextFollowupInMinutes,
          'intervention_followup_overdue': overdueMinutes > 0,
          'intervention_followup_overdue_minutes': overdueMinutes,
          'intervention_followup_overdue_stage': overdueStage,
          'intervention_history': interventionHistory,
          'intervention_boost_total': modeStats['boost_total'],
          'intervention_boost_success': modeStats['boost_success'],
          'intervention_light_total': modeStats['light_total'],
          'intervention_light_success': modeStats['light_success'],
          'redeem_history': _redeemHistoryByChild[childId] ?? const <Map<String, dynamic>>[],
        }
      };
    }

    return {'data': {}};
  }

  @override
  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    if (path.contains('/tasks/')) {
      final taskId = _extractTaskId(path);
      for (final entry in _tasksByChild.entries) {
        for (final task in entry.value) {
          if (task['id'] == taskId) {
            task.addAll(<String, dynamic>{...?body});
            final incomingStatus = body?['status'] as String?;
            if (incomingStatus != null) {
              if (incomingStatus == 'done') {
                task['completed_at'] = DateTime.now().toIso8601String();
              } else if (incomingStatus == 'todo' || incomingStatus == 'doing') {
                task['completed_at'] = null;
              }
            }
            return {'data': task};
          }
        }
      }
    }
    return {'data': <String, dynamic>{...?body, 'id': _extractTaskId(path)}};
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    if (path.contains('/children/') && path.endsWith('/tasks')) {
      final childId = _extractChildId(path);
      final startDate = body?['start_date'] as String?;
      final dueDate = body?['due_date'] as String?;
      if (startDate != null && dueDate != null) {
        final s = DateTime.tryParse(startDate);
        final d = DateTime.tryParse(dueDate);
        if (s != null && d != null && d.isBefore(s)) {
          return {
            'data': {
              'ok': false,
              'message': '截止日期不能早于开始日期',
            }
          };
        }
      }
      final id = 'created-${DateTime.now().millisecondsSinceEpoch}';
      final row = {
        'id': id,
        'child_profile_id': childId,
        'subject': body?['subject'] ?? '综合',
        'title': body?['title'] ?? '新任务',
        'difficulty': body?['difficulty'] ?? 1,
        'est_minutes': body?['est_minutes'] ?? 10,
        'status': 'todo',
        'priority': body?['priority'] ?? 'medium',
        'target_score': body?['target_score'],
        'start_date': startDate,
        'due_date': body?['due_date'],
        'notes': body?['notes'] ?? '',
        'completed_at': null,
      };
      _tasksByChild.putIfAbsent(childId, () => <Map<String, dynamic>>[]).add(row);
      return {'data': row};
    }

    if (path.contains('/exam-records')) {
      final childId = _extractChildId(path);
      final examName = (body?['exam_name'] as String? ?? '').trim();
      final subject = (body?['subject'] as String? ?? '').trim();
      final score = (body?['score'] as num?)?.toDouble() ?? -1;
      final fullScore = (body?['full_score'] as num?)?.toDouble() ?? -1;
      final examDate = (body?['exam_date'] as String? ?? '').trim();
      final rank = (body?['rank'] as num?)?.toInt();

      if (examName.isEmpty || subject.isEmpty || examDate.isEmpty) {
        return {
          'data': {
            'ok': false,
            'message': '考试名称、学科、日期不能为空',
          }
        };
      }
      if (fullScore <= 0 || score < 0 || score > fullScore) {
        return {
          'data': {
            'ok': false,
            'message': '分数需在 0 到满分之间',
          }
        };
      }

      final rows = _examRecordsByChild.putIfAbsent(childId, () => <Map<String, dynamic>>[]);
      final duplicate = rows.any(
        (row) =>
            (row['exam_name'] as String? ?? '').trim() == examName &&
            (row['exam_date'] as String? ?? '').trim() == examDate,
      );

      final record = {
        'id': 'exam-${DateTime.now().millisecondsSinceEpoch}',
        'exam_name': examName,
        'subject': subject,
        'score': score,
        'full_score': fullScore,
        'exam_date': examDate,
        'rank': rank,
      };
      rows.insert(0, record);

      return {
        'data': {
          'ok': true,
          'record': record,
          'duplicate_hint': duplicate,
          if (duplicate) 'duplicate_message': '检测到同名同日考试记录，请确认是否重复录入',
        }
      };
    }

    if (path.endsWith('/complete')) {
      final taskId = _extractTaskId(path);
      for (final entry in _tasksByChild.entries) {
        for (final task in entry.value) {
          if (task['id'] == taskId) {
            task['status'] = 'done';
            task['completed_at'] = DateTime.now().toIso8601String();
            _applyDailyStreakSettlement(entry.key);
            _energyByChild[entry.key] = (_energyByChild[entry.key] ?? 0) + 5;
            _todayEnergyByChild[entry.key] = (_todayEnergyByChild[entry.key] ?? 0) + 5;
            return {'data': {'ok': true}};
          }
        }
      }
      return {'data': {'ok': false}};
    }

    if (path.endsWith('/delete')) {
      final taskId = _extractTaskId(path);
      for (final entry in _tasksByChild.entries) {
        final before = entry.value.length;
        entry.value.removeWhere((task) => task['id'] == taskId);
        if (entry.value.length != before) {
          return {
            'data': {'ok': true}
          };
        }
      }
      return {
        'data': {
          'ok': false,
          'message': '任务不存在',
        }
      };
    }

    if (path == '/checkins') {
      final childId = body?['child_profile_id'] as String? ?? 'demo-child-id';
      _applyDailyStreakSettlement(childId);
      final energyDelta = (body?['energy_delta'] as num?)?.toInt() ?? 4;
      _energyByChild[childId] = (_energyByChild[childId] ?? 0) + energyDelta;
      _todayEnergyByChild[childId] = (_todayEnergyByChild[childId] ?? 0) + energyDelta;
      return {
        'data': {
          'child_profile_id': childId,
          'energy_delta': energyDelta,
          'status': 'ok',
        }
      };
    }

    if (path.endsWith('/streak-recover')) {
      final childId = _extractChildId(path);
      _refreshRecoverQuota(childId);
      final canRecover = _canRecoverByChild[childId] ?? false;
      final backup = _streakBackupByChild[childId] ?? 0;
      final used = _recoverUsedCountByChild[childId] ?? 0;
      final usesLeft = _recoverMaxPerWeek - used;
      final energy = _energyByChild[childId] ?? 0;
      final cooldownLeft = _recoverCooldownLeftMinutes(childId);

      if (!canRecover || backup <= 0) {
        return {
          'data': {
            'ok': false,
            'message': '当前没有可恢复的连击',
            'streak_days': _streakByChild[childId] ?? 0,
          }
        };
      }

      if (usesLeft <= 0) {
        return {
          'data': {
            'ok': false,
            'message': '本周恢复次数已用完',
            'streak_days': _streakByChild[childId] ?? 0,
          }
        };
      }

      if (energy < _recoverCost) {
        return {
          'data': {
            'ok': false,
            'message': '能量不足，无法使用恢复卡',
            'streak_days': _streakByChild[childId] ?? 0,
          }
        };
      }

      if (cooldownLeft > 0) {
        return {
          'data': {
            'ok': false,
            'message': '恢复卡冷却中，$cooldownLeft 分钟后可再次使用',
            'streak_days': _streakByChild[childId] ?? 0,
          }
        };
      }

      _energyByChild[childId] = energy - _recoverCost;
      _recoverUsedCountByChild[childId] = used + 1;
      _lastRecoverAtMsByChild[childId] = DateTime.now().millisecondsSinceEpoch;
      _streakByChild[childId] = backup + 1;
      _streakBrokenByChild[childId] = false;
      _canRecoverByChild[childId] = false;
      _streakBackupByChild[childId] = 0;
      _lastActiveDateByChild[childId] = _dateOnly(DateTime.now());

      return {
        'data': {
          'ok': true,
          'streak_days': _streakByChild[childId],
        }
      };
    }

    if (path.endsWith('/redeem-reward')) {
      final childId = _extractChildId(path);
      final rewardName = (body?['reward_name'] as String? ?? '').trim();
      if (rewardName.isEmpty) {
        return {
          'data': {
            'ok': false,
            'message': '奖励名称不能为空',
            'energy_balance': _energyByChild[childId] ?? 0,
          }
        };
      }
      final options = _buildRewardOptions(childId);
      final matched = options.where((e) => e['name'] == rewardName).toList();
      if (matched.isEmpty) {
        return {
          'data': {
            'ok': false,
            'message': '奖励未配置，请联系家长先设置奖励项',
            'energy_balance': _energyByChild[childId] ?? 0,
          }
        };
      }
      final serverCost = (matched.first['dynamic_price'] as num).toInt();
      final balance = _energyByChild[childId] ?? 0;

      if (balance < serverCost) {
        return {
          'data': {
            'ok': false,
            'message': '能量不足，暂时无法兑换',
            'energy_balance': balance,
          }
        };
      }

      _energyByChild[childId] = balance - serverCost;
      final history = _redeemHistoryByChild.putIfAbsent(childId, () => <Map<String, dynamic>>[]);
      history.insert(0, {
        'reward_name': rewardName,
        'cost': serverCost,
        'created_at': '${_dateOnly(DateTime.now())} ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      });
      if (history.length > 12) {
        history.removeRange(12, history.length);
      }

      return {
        'data': {
          'ok': true,
          'reward_name': rewardName,
          'cost': serverCost,
          'energy_balance': _energyByChild[childId],
        }
      };
    }

    if (path.endsWith('/reward-options')) {
      final childId = _extractChildId(path);
      final rewardName = (body?['reward_name'] as String? ?? '').trim();
      final basePrice = (body?['base_price'] as num?)?.toInt() ?? 0;

      if (rewardName.isEmpty) {
        return {
          'data': {
            'ok': false,
            'message': '奖励名称不能为空',
          }
        };
      }
      if (basePrice < 1) {
        return {
          'data': {
            'ok': false,
            'message': '奖励能量必须大于0',
          }
        };
      }

      final custom = _customRewardCatalogByChild.putIfAbsent(childId, () => <Map<String, dynamic>>[]);
      final removed = _removedRewardNamesByChild.putIfAbsent(childId, () => <String>[]);
      final existsBuiltIn = _rewardCatalog.any((item) => (item['name'] as String? ?? '').trim() == rewardName);
      final existsCustom = custom.any((item) => (item['name'] as String? ?? '').trim() == rewardName);
      if (existsBuiltIn || existsCustom) {
        return {
          'data': {
            'ok': false,
            'message': '奖励名称已存在，请更换名称',
          }
        };
      }

      custom.insert(0, {
        'name': rewardName,
        'base_price': basePrice.clamp(1, 999),
      });
      removed.remove(rewardName);
      if (custom.length > 8) {
        custom.removeRange(8, custom.length);
      }

      return {
        'data': {
          'ok': true,
        }
      };
    }

    if (path.endsWith('/reward-options-delete')) {
      final childId = _extractChildId(path);
      final rewardName = (body?['reward_name'] as String? ?? '').trim();

      if (rewardName.isEmpty) {
        return {
          'data': {
            'ok': false,
            'message': '奖励名称不能为空',
          }
        };
      }

      final custom = _customRewardCatalogByChild.putIfAbsent(childId, () => <Map<String, dynamic>>[]);
      final removed = _removedRewardNamesByChild.putIfAbsent(childId, () => <String>[]);
      final customBefore = custom.length;
      custom.removeWhere((item) => (item['name'] as String? ?? '').trim() == rewardName);
      final removedCustom = custom.length != customBefore;

      final inBuiltIn = _rewardCatalog.any((item) => (item['name'] as String? ?? '').trim() == rewardName);
      if (!removedCustom && !inBuiltIn) {
        return {
          'data': {
            'ok': false,
            'message': '奖励不存在，无法删除',
          }
        };
      }

      if (inBuiltIn && !removed.contains(rewardName)) {
        removed.add(rewardName);
      }

      return {
        'data': {
          'ok': true,
        }
      };
    }

    if (path.endsWith('/encourage')) {
      final childId = _extractChildId(path);
      final message = (body?['message'] as String? ?? '').trim();
      final actionType = (body?['action_type'] as String? ?? '').trim().isEmpty ? 'manual' : (body?['action_type'] as String).trim();
      final actionSubType = (body?['action_sub_type'] as String? ?? '').trim();
      final actionSource = (body?['action_source'] as String? ?? '').trim();
      final riskReduceScore = (body?['risk_reduce_score'] as num?)?.toInt() ?? 0;
      final cooldownLeft = _interventionCooldownLeftMinutes(childId);

      if (cooldownLeft > 0) {
        return {
          'data': {
            'ok': false,
            'message': '干预冷却中，$cooldownLeft 分钟后可再次操作',
            'intervention_mode': _interventionModeByChild[childId] ?? 'normal',
            'intervention_note': _interventionNoteByChild[childId] ?? '',
            'intervention_active': _interventionRemainingMinutes(childId) > 0,
            'intervention_remaining_minutes': _interventionRemainingMinutes(childId),
            'intervention_cooldown_minutes': cooldownLeft,
          }
        };
      }

      final isReduceLoad = message.contains('减负') || message.contains('轻任务');
      final isBoost = message.contains('鼓励') || message.contains('继续保持');

      if (isReduceLoad) {
        _interventionModeByChild[childId] = 'light';
      } else if (isBoost) {
        _interventionModeByChild[childId] = 'boost';
      } else {
        _interventionModeByChild[childId] = 'normal';
      }

      _interventionNoteByChild[childId] = message;
      _interventionUpdatedAtMsByChild[childId] = DateTime.now().millisecondsSinceEpoch;
      _interventionBaselineCompletionByChild[childId] = _currentCompletionRate(childId);

      final mode = _interventionModeByChild[childId] ?? 'normal';
      final simulatedDelta = _simulateInterventionDelta(childId, mode);
      final history = _interventionHistoryByChild.putIfAbsent(childId, () => <Map<String, dynamic>>[]);
      history.insert(0, {
        'mode': mode,
        'note': message,
        'action_type': actionType,
        'action_sub_type': actionSubType,
        'action_source': actionSource,
        'risk_reduce_score': riskReduceScore,
        'effect_delta': simulatedDelta,
        'created_at': '${_dateOnly(DateTime.now())} ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      });
      if (history.length > 20) {
        history.removeRange(20, history.length);
      }

      return {
        'data': {
          'ok': true,
          'intervention_mode': mode,
          'intervention_note': _interventionNoteByChild[childId],
          'intervention_active': true,
          'intervention_remaining_minutes': _interventionActiveMinutes,
          'intervention_cooldown_minutes': _interventionCooldownMinutes,
        }
      };
    }

    if (path.endsWith('/intervention-clear')) {
      final childId = _extractChildId(path);
      _interventionModeByChild[childId] = 'normal';
      _interventionNoteByChild[childId] = '家长手动撤销干预';
      _interventionUpdatedAtMsByChild[childId] = 0;
      _interventionBaselineCompletionByChild[childId] = 0.0;

      final history = _interventionHistoryByChild.putIfAbsent(childId, () => <Map<String, dynamic>>[]);
      history.insert(0, {
        'mode': 'normal',
        'note': '家长手动撤销干预',
        'action_type': 'clear',
        'action_sub_type': 'clear',
        'action_source': 'manual',
        'risk_reduce_score': 0,
        'effect_delta': 0.0,
        'created_at': '${_dateOnly(DateTime.now())} ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      });
      if (history.length > 20) {
        history.removeRange(20, history.length);
      }

      return {
        'data': {
          'ok': true,
          'intervention_mode': 'normal',
          'intervention_note': _interventionNoteByChild[childId],
          'intervention_active': false,
          'intervention_remaining_minutes': 0,
          'intervention_cooldown_minutes': 0,
        }
      };
    }

    return {'data': {}};
  }
}
