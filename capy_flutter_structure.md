# Capybara Study MVP - Flutter Structure and Routes

## 1) Recommended Folder Structure

```text
lib/
  main.dart
  app.dart
  core/
    constants/
      app_colors.dart
      app_copy.dart
      app_spacing.dart
    theme/
      app_theme.dart
    network/
      api_client.dart
      api_result.dart
    storage/
      secure_storage.dart
    analytics/
      analytics_service.dart
  shared/
    widgets/
      capy_card.dart
      capy_button.dart
      empty_state.dart
      loading_view.dart
    models/
      user_model.dart
      child_profile_model.dart
      task_model.dart
      timer_session_model.dart
      reward_model.dart
      weekly_report_model.dart
  features/
    auth/
      data/
        auth_repository.dart
      presentation/
        pages/
          sign_in_page.dart
          sign_up_page.dart
        providers/
          auth_provider.dart
    home/
      presentation/
        pages/
          child_home_page.dart
          parent_home_page.dart
        widgets/
          today_task_card.dart
          capy_mood_banner.dart
    planner/
      data/
        planner_repository.dart
      presentation/
        pages/
          planner_page.dart
          task_editor_page.dart
        providers/
          planner_provider.dart
    timer/
      data/
        timer_repository.dart
      presentation/
        pages/
          timer_page.dart
        providers/
          timer_provider.dart
    growth/
      data/
        growth_repository.dart
      presentation/
        pages/
          growth_page.dart
          rewards_page.dart
        providers/
          growth_provider.dart
    parent/
      data/
        parent_repository.dart
      presentation/
        pages/
          parent_dashboard_page.dart
          weekly_report_page.dart
        providers/
          parent_provider.dart
  router/
    app_router.dart
```

## 2) Route Map (MVP)

| Route | Screen | Role | Purpose |
|---|---|---|---|
| `/sign-in` | SignInPage | parent/child | Login |
| `/sign-up` | SignUpPage | parent | Register family owner |
| `/home` | ChildHomePage or ParentHomePage | both | Role-based entry |
| `/planner` | PlannerPage | child/parent | Today/week tasks |
| `/task-editor` | TaskEditorPage | parent/child | Add/edit task |
| `/timer` | TimerPage | child | Focus timer |
| `/growth` | GrowthPage | child | Energy + badges |
| `/rewards` | RewardsPage | child/parent | Rewards and exchange |
| `/parent-dashboard` | ParentDashboardPage | parent | Progress dashboard |
| `/weekly-report` | WeeklyReportPage | parent | Weekly summary |

## 3) State Management Recommendation

- Use `Riverpod` for MVP speed and testability.
- Keep providers feature-scoped:
  - `AuthProvider`
  - `PlannerProvider`
  - `TimerProvider`
  - `GrowthProvider`
  - `ParentProvider`

## 4) API Integration Boundaries

- Repositories only call API/storage. UI does not touch network directly.
- Each feature has one repository and one provider.
- Suggested repository methods:
  - `AuthRepository`: signIn, signOut, signUp
  - `PlannerRepository`: listTasks, createTask, updateTask, completeTask
  - `TimerRepository`: startSession, stopSession
  - `GrowthRepository`: fetchEnergy, fetchRewards, exchangeReward
  - `ParentRepository`: fetchDashboard, fetchWeeklyReport

## 5) MVP Navigation Flow

1. Sign in
2. Role check (`parent` or `child`)
3. Home
   - Child: Planner -> Timer -> Growth
   - Parent: Parent Dashboard -> Weekly Report -> Planner

## 6) Event Tracking (must-have)

- `task_created`
- `timer_started`
- `timer_completed`
- `checkin_completed`
- `reward_redeemed`
- `weekly_report_viewed`
- `parent_nudge_sent`

## 7) Copy and Visual Notes

- Tone: warm, encouraging, pressure-free.
- Keep capybara motif in all success/empty states.
- Avoid punitive red-heavy UI for children.
