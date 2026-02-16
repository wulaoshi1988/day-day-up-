// Supabase Edge Function (Deno) - Rule-based weekly report
// Endpoint: /weekly-report

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

type WeeklySummary = {
  completion_rate: number;
  total_sessions: number;
  total_minutes: number;
  ai_summary: string;
};

function buildSummary(input: {
  completed: number;
  total: number;
  minutes: number;
}): WeeklySummary {
  const completion = input.total > 0 ? (input.completed / input.total) * 100 : 0;
  const rounded = Number(completion.toFixed(2));

  let advice = '本周保持稳定节奏，下周继续每日小步推进。';
  if (rounded < 40) advice = '建议下周先降低任务难度，优先建立连续打卡。';
  if (rounded >= 80) advice = '完成率很高，可以逐步增加 1-2 个进阶任务。';

  return {
    completion_rate: rounded,
    total_sessions: input.completed,
    total_minutes: input.minutes,
    ai_summary: `本周完成率 ${rounded}%，共专注 ${input.minutes} 分钟。${advice}`,
  };
}

Deno.serve(async (req) => {
  try {
    if (req.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method Not Allowed' }), { status: 405 });
    }

    const { child_profile_id, week_start } = await req.json();
    if (!child_profile_id || !week_start) {
      return new Response(JSON.stringify({ error: 'child_profile_id and week_start required' }), { status: 400 });
    }

    const url = Deno.env.get('SUPABASE_URL')!;
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(url, serviceRoleKey);

    const weekStart = new Date(week_start);
    const weekEnd = new Date(weekStart);
    weekEnd.setDate(weekEnd.getDate() + 7);

    const { data: tasks, error: taskError } = await supabase
      .from('tasks')
      .select('id,status')
      .eq('child_profile_id', child_profile_id)
      .gte('created_at', weekStart.toISOString())
      .lt('created_at', weekEnd.toISOString());

    if (taskError) throw taskError;

    const { data: sessions, error: sessionError } = await supabase
      .from('timer_sessions')
      .select('actual_seconds,completed')
      .eq('child_profile_id', child_profile_id)
      .gte('started_at', weekStart.toISOString())
      .lt('started_at', weekEnd.toISOString());

    if (sessionError) throw sessionError;

    const total = tasks?.length ?? 0;
    const completed = (tasks ?? []).filter((t) => t.status === 'done').length;
    const minutes = Math.round(
      (sessions ?? [])
        .filter((s) => s.completed)
        .reduce((acc, s) => acc + (s.actual_seconds ?? 0), 0) / 60,
    );

    const summary = buildSummary({ completed, total, minutes });

    const { error: upsertError } = await supabase
      .from('weekly_reports')
      .upsert(
        {
          child_profile_id,
          week_start,
          completion_rate: summary.completion_rate,
          total_sessions: summary.total_sessions,
          total_minutes: summary.total_minutes,
          ai_summary: summary.ai_summary,
          generated_at: new Date().toISOString(),
        },
        { onConflict: 'child_profile_id,week_start' },
      );

    if (upsertError) throw upsertError;

    return new Response(JSON.stringify({ data: summary }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: String(error) }), { status: 500 });
  }
});
