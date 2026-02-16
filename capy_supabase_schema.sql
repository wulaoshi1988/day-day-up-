-- Capybara Study MVP - Supabase PostgreSQL Schema
-- Target: Supabase (auth.users as identity source)

create extension if not exists pgcrypto;

do $$
begin
  if not exists (select 1 from pg_type where typname = 'app_role') then
    create type app_role as enum ('parent', 'child');
  end if;

  if not exists (select 1 from pg_type where typname = 'task_status') then
    create type task_status as enum ('todo', 'doing', 'done');
  end if;

  if not exists (select 1 from pg_type where typname = 'task_source') then
    create type task_source as enum ('manual', 'template', 'ai');
  end if;

  if not exists (select 1 from pg_type where typname = 'timer_mode') then
    create type timer_mode as enum ('stopwatch', 'pomodoro');
  end if;

  if not exists (select 1 from pg_type where typname = 'reward_log_status') then
    create type reward_log_status as enum ('pending', 'approved', 'rejected');
  end if;
end $$;

create table if not exists public.app_users (
  id uuid primary key references auth.users(id) on delete cascade,
  role app_role not null,
  nickname text not null,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.families (
  id uuid primary key default gen_random_uuid(),
  family_name text not null,
  owner_user_id uuid not null references public.app_users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.child_profiles (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  name text not null,
  grade int not null check (grade between 1 and 6),
  birthday date,
  avatar_theme text not null default 'capybara-default',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.family_members (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  user_id uuid not null references public.app_users(id) on delete cascade,
  child_profile_id uuid references public.child_profiles(id) on delete cascade,
  relation text not null default 'guardian',
  created_at timestamptz not null default now(),
  unique (family_id, user_id, child_profile_id)
);

create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  child_profile_id uuid not null references public.child_profiles(id) on delete cascade,
  subject text not null,
  title text not null,
  difficulty smallint not null default 1 check (difficulty between 1 and 3),
  est_minutes int not null default 10 check (est_minutes between 1 and 240),
  due_date date,
  status task_status not null default 'todo',
  source task_source not null default 'manual',
  created_by uuid not null references public.app_users(id) on delete restrict,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.timer_sessions (
  id uuid primary key default gen_random_uuid(),
  task_id uuid references public.tasks(id) on delete set null,
  child_profile_id uuid not null references public.child_profiles(id) on delete cascade,
  mode timer_mode not null,
  planned_minutes int not null default 10 check (planned_minutes between 1 and 180),
  actual_seconds int check (actual_seconds >= 0),
  started_at timestamptz not null,
  ended_at timestamptz,
  completed boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.checkins (
  id uuid primary key default gen_random_uuid(),
  child_profile_id uuid not null references public.child_profiles(id) on delete cascade,
  task_id uuid references public.tasks(id) on delete set null,
  checkin_date date not null,
  energy_delta int not null,
  note text,
  by_user_id uuid not null references public.app_users(id) on delete restrict,
  created_at timestamptz not null default now(),
  unique (child_profile_id, task_id, checkin_date)
);

create table if not exists public.rewards (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  title text not null,
  cost_energy int not null check (cost_energy > 0),
  stock int,
  enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.reward_logs (
  id uuid primary key default gen_random_uuid(),
  reward_id uuid not null references public.rewards(id) on delete cascade,
  child_profile_id uuid not null references public.child_profiles(id) on delete cascade,
  exchanged_at timestamptz not null default now(),
  status reward_log_status not null default 'pending',
  approved_by uuid references public.app_users(id) on delete set null,
  approved_at timestamptz,
  reason text
);

create table if not exists public.weekly_reports (
  id uuid primary key default gen_random_uuid(),
  child_profile_id uuid not null references public.child_profiles(id) on delete cascade,
  week_start date not null,
  completion_rate numeric(5,2) not null default 0 check (completion_rate between 0 and 100),
  total_sessions int not null default 0,
  total_minutes int not null default 0,
  ai_summary text,
  generated_at timestamptz not null default now(),
  unique (child_profile_id, week_start)
);

create index if not exists idx_child_profiles_family_id on public.child_profiles(family_id);
create index if not exists idx_family_members_family_id on public.family_members(family_id);
create index if not exists idx_tasks_child_profile_id on public.tasks(child_profile_id);
create index if not exists idx_tasks_status_due_date on public.tasks(status, due_date);
create index if not exists idx_timer_sessions_child_profile_id on public.timer_sessions(child_profile_id);
create index if not exists idx_checkins_child_profile_id_date on public.checkins(child_profile_id, checkin_date);
create index if not exists idx_rewards_family_id on public.rewards(family_id);
create index if not exists idx_reward_logs_child_profile_id on public.reward_logs(child_profile_id);
create index if not exists idx_weekly_reports_child_week on public.weekly_reports(child_profile_id, week_start);

create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_app_users_updated_at on public.app_users;
create trigger trg_app_users_updated_at
before update on public.app_users
for each row execute function public.set_updated_at();

drop trigger if exists trg_families_updated_at on public.families;
create trigger trg_families_updated_at
before update on public.families
for each row execute function public.set_updated_at();

drop trigger if exists trg_child_profiles_updated_at on public.child_profiles;
create trigger trg_child_profiles_updated_at
before update on public.child_profiles
for each row execute function public.set_updated_at();

drop trigger if exists trg_tasks_updated_at on public.tasks;
create trigger trg_tasks_updated_at
before update on public.tasks
for each row execute function public.set_updated_at();

drop trigger if exists trg_rewards_updated_at on public.rewards;
create trigger trg_rewards_updated_at
before update on public.rewards
for each row execute function public.set_updated_at();

-- Optional RLS baseline (recommended for production)
alter table public.app_users enable row level security;
alter table public.families enable row level security;
alter table public.child_profiles enable row level security;
alter table public.family_members enable row level security;
alter table public.tasks enable row level security;
alter table public.timer_sessions enable row level security;
alter table public.checkins enable row level security;
alter table public.rewards enable row level security;
alter table public.reward_logs enable row level security;
alter table public.weekly_reports enable row level security;

-- Minimal ownership policy examples (expand before production)
drop policy if exists app_users_self_access on public.app_users;
create policy app_users_self_access on public.app_users
for all using (auth.uid() = id) with check (auth.uid() = id);

drop policy if exists families_owner_access on public.families;
create policy families_owner_access on public.families
for all using (owner_user_id = auth.uid()) with check (owner_user_id = auth.uid());
