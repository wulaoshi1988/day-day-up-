# Capy Study App Scaffold

Capybara-themed MVP scaffold for grades 1-6 with child + parent flows.

## 1) Install

```bash
flutter pub get
```

## 1.1) Web test (Windows BAT)

From `C:/scripts/capy_flutter_scaffold`:

```bat
run_web_mock.bat
```

Real API mode:

```bat
run_web_real.bat "https://YOUR_PROJECT.supabase.co/functions/v1" "YOUR_JWT"
```

Notes:
- Scripts will auto-run `flutter config --enable-web`.
- Scripts will auto-run `flutter create --platforms=web .` to generate missing web files.

## 2) Run with mock data (recommended first)

```bash
flutter run --dart-define=USE_MOCK_API=true
```

## 3) Run with real API

```bash
flutter run \
  --dart-define=USE_MOCK_API=false \
  --dart-define=API_BASE_URL=https://YOUR_PROJECT.supabase.co/functions/v1 \
  --dart-define=ACCESS_TOKEN=YOUR_JWT
```

## 4) Expected endpoints

- `GET /children/:id/tasks?range=today|week`
- `POST /children/:id/tasks`
- `PATCH /tasks/:id`
- `POST /tasks/:id/complete`
- `GET /children/:id/dashboard`
- `GET /children/:id/weekly-trend`
- `GET /children/:id/weekly-report`
- `GET /children/:id/growth`
- `POST /children/:id/streak-recover`
- `POST /children/:id/redeem-reward`
- `POST /children/:id/encourage`
- `POST /children/:id/intervention-clear`
- `POST /checkins`

## 4.1) Streak & recover rules (mock mode)

- Daily streak settlement: same day multiple checkins/completions only count once.
- Gap of 1 day: streak +1.
- Gap >1 day: streak resets and enters `streak_broken` state.
- Recover card:
  - costs `12` energy each use
  - weekly quota `2` uses (auto reset each week)
  - cooldown `180` minutes after each successful recover
  - only available when streak is broken and quota/energy are sufficient

## 4.2) Reward redeem (mock mode)

- Endpoint: `POST /children/:id/redeem-reward`
- Request body: `{ reward_name, cost }`
- Rule: deducts energy if balance is sufficient, otherwise returns failure message
- Growth payload includes `redeem_history` for latest redeem records.
- Parent dashboard/weekly report now surface streak risks and recover/redeem monitoring.

## 4.3) Dynamic reward pricing (mock mode)

- Reward price is dynamically calculated by child grade and streak state.
- Higher grade may increase base cost slightly.
- Continuous streak can trigger discount tags (shown in Growth page).
- Server-side (mock) validates final dynamic price during redeem.

## 4.4) Weekly behavior score (mock mode)

- `growth` payload includes `weekly_behavior_score` (0-100).
- Weekly report uses it to produce parent-facing risk/explanation hints.

## 4.5) Adaptive task strategy (mock mode)

- Planner uses `weekly_behavior_score` to adjust next-task recommendation difficulty.
- Score <= 65: recommend lighter tasks first.
- Score 66-80: balanced recommendation.
- Score > 80: can recommend higher-difficulty tasks.

## 4.6) Parent intervention actions (mock mode)

- Parent dashboard provides quick actions:
  - send encouragement
  - suggest workload reduction
- Both actions call `sendEncourage` endpoint with different message templates.
- Intervention result is synced to child planner via growth payload fields:
  - `intervention_mode`: `normal | light | boost`
  - `intervention_note`: latest parent note
- `intervention_mode` is active for 24 hours, then auto-falls back to `normal`.
- Growth payload also provides:
  - `intervention_active` (bool)
  - `intervention_remaining_minutes` (countdown)
- Intervention actions have a cooldown (30 minutes) to avoid frequent switching.
- Growth payload provides:
  - `intervention_cooldown_minutes`
  - `intervention_history` (latest intervention logs)
- Growth payload also includes 24h effect metrics:
  - `intervention_effect_available`
  - `intervention_effect_delta`
  - `intervention_baseline_completion`
  - `intervention_current_completion`
  - `intervention_effect_trend` (multi-point 24h trend samples)
  - `intervention_followup_2h_done`
  - `intervention_followup_6h_done`
  - `intervention_followup_2h_reached`
  - `intervention_followup_6h_reached`
  - `intervention_next_followup_minutes`
  - `intervention_followup_overdue`
  - `intervention_followup_overdue_minutes`
  - `intervention_followup_overdue_stage`
- Growth payload also includes mode-level effectiveness stats:
  - `intervention_boost_total` / `intervention_boost_success`
  - `intervention_light_total` / `intervention_light_success`
- `intervention_history` entries include:
  - `effect_delta`
  - `action_type` (`manual` / `followup` / `clear`)
  - `action_sub_type` (`2h_makeup` / `6h_makeup` / `review`)
  - `action_source` (`risk_queue` etc.)
  - `risk_reduce_score` (estimated reduced risk points)
- Parent dashboard and intervention history page show smart recommendation hit-rate based on recent intervention outcomes.
- Parent dashboard includes a follow-up and review card for 2h/6h checkpoints and next review hint.
- Follow-up card adds urgency level (high/medium/low) and a one-click follow-up action entry.
- Follow-up card highlights pending checkpoints (2h/6h) and supports one-click makeup actions.
- Follow-up card shows overdue warning with overdue minutes and stage.
- Weekly risk scoring now includes follow-up overdue and intervention effectiveness signals.
- Parent dashboard and weekly report display unified risk level (high/medium/low).
- Parent dashboard includes a prioritized risk-action queue with estimated risk reduction score.
- Parent dashboard includes queue execution history (today/week count and cumulative reduced-risk points).
- Weekly report includes risk-queue execution retrospective (weekly count, cumulative reduced-risk points, recent action lines).
- Weekly report also computes queue execution quality score by comparing estimated vs effect-derived reduced-risk points.
- Weekly report now breaks quality into three action buckets: normal intervention / follow-up makeup / review.
- Weekly report bucket quality rows include week-over-week deltas (up/down/flat) when last-week samples exist.
- Parent dashboard now provides a lightweight preview of the same three quality buckets, aligned with weekly report calculation.
- Dashboard quality preview shows week-over-week deltas (up/down arrows) for each bucket.
- When a bucket declines week-over-week, dashboard generates one-click repair actions and writes them as risk-queue executions.
- Repair actions now include target score and progress-to-target display on dashboard.
- Repair actions now also show week deadline countdown and overdue state when target is unmet at week end.
- Overdue repair actions are prioritized at the top and support a one-click emergency repair entry.
- Intervention history page supports filters: all / manual / followup / clear.
- Intervention history page also supports sub-type filters for follow-up makeup/review actions.
- Parent dashboard and history page include follow-up completion checklist stats (today/week/total).
- Planner adaptive recommendation will prioritize easier or harder tasks accordingly.
- Parent dashboard now provides grade-aware smart intervention recommendation:
  - combines grade tier + behavior score + mode effectiveness (boost/light)
  - outputs recommended action and one-click apply template
- Recommendation priority: streak risk handling first, then grade-tier strategy.
- Smart recommendation includes confidence level (high/medium/low).
- When confidence is low, dashboard provides an alternative one-click intervention option.
- Smart recommendation card includes an explainable factor panel (grade/score/mode rates/risk/sample/hit-rate/confidence).

Weekly report now includes an intervention effectiveness conclusion based on 24h delta.
- `intervention-clear` can reset to default strategy immediately (no cooldown required).
- Parent side now includes a dedicated intervention history detail page (`/intervention-history`) with timeline and mode counts.

## 5) Seed and schema SQL

- Main schema: `C:/scripts/capy_supabase_schema.sql`
- Task template seed: `C:/scripts/capy_seed_task_templates.sql`

## 6) Edge function sample

- Rule-based weekly report: `C:/scripts/capy_weekly_report_function.ts`
- Weekly trend endpoint: `C:/scripts/capy_weekly_trend_function.ts`
