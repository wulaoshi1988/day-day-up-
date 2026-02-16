import 'package:flutter/material.dart';

import 'features/growth/presentation/pages/growth_page.dart';
import 'features/parent/presentation/pages/intervention_history_page.dart';
import 'features/parent/presentation/pages/parent_dashboard_page.dart';
import 'features/parent/presentation/pages/weekly_report_page.dart';
import 'features/planner/presentation/pages/planner_page.dart';
import 'features/planner/presentation/pages/task_editor_page.dart';
import 'features/timer/presentation/pages/timer_page.dart';
import 'features/score/presentation/pages/score_page.dart';

class CapyStudyApp extends StatelessWidget {
  const CapyStudyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '卡皮学习岛',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFC98F65),
      ),
      initialRoute: '/planner',
      routes: {
        '/planner': (_) => const PlannerPage(),
        '/': (_) => const PlannerPage(),
        '/task-editor': (_) => const TaskEditorPage(),
        '/timer': (_) => const TimerPage(),
        '/growth': (_) => const GrowthPage(),
        '/scores': (_) => const ScorePage(),
        '/parent-dashboard': (_) => const ParentDashboardPage(),
        '/weekly-report': (_) => const WeeklyReportPage(),
        '/intervention-history': (_) => const InterventionHistoryPage(),
      },
    );
  }
}
