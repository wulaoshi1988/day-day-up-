// Supabase Edge Function (Deno) - Weekly trend data from weekly_reports
// Endpoint: /weekly-trend

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

Deno.serve(async (req) => {
  try {
    if (req.method !== 'GET') {
      return new Response(JSON.stringify({ error: 'Method Not Allowed' }), { status: 405 });
    }

    const url = new URL(req.url);
    const childProfileId = url.searchParams.get('child_profile_id');
    if (!childProfileId) {
      return new Response(JSON.stringify({ error: 'child_profile_id required' }), { status: 400 });
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, serviceRoleKey);

    const { data, error } = await supabase
      .from('weekly_reports')
      .select('completion_rate,week_start')
      .eq('child_profile_id', childProfileId)
      .order('week_start', { ascending: false })
      .limit(7);

    if (error) throw error;

    const trend = (data ?? [])
      .reverse()
      .map((r) => Number(r.completion_rate ?? 0));

    while (trend.length < 7) {
      trend.unshift(0);
    }

    return new Response(JSON.stringify({ data: trend }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: String(error) }), { status: 500 });
  }
});
