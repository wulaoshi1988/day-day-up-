-- Seed script for Capybara task templates (20 rows)
-- Run after capy_supabase_schema.sql

create table if not exists public.task_templates (
  id uuid primary key default gen_random_uuid(),
  template_id text not null unique,
  grade_start int not null check (grade_start between 1 and 6),
  grade_end int not null check (grade_end between 1 and 6),
  subject text not null,
  title text not null,
  est_minutes int not null check (est_minutes between 1 and 240),
  difficulty smallint not null check (difficulty between 1 and 3),
  energy_reward int not null check (energy_reward > 0),
  tags text[] not null default '{}',
  capy_hint text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_task_templates_updated_at on public.task_templates;
create trigger trg_task_templates_updated_at
before update on public.task_templates
for each row execute function public.set_updated_at();

insert into public.task_templates (
  template_id, grade_start, grade_end, subject, title,
  est_minutes, difficulty, energy_reward, tags, capy_hint, is_active
)
values
('capy_g1_cn_read_01',1,2,'语文','大声朗读课文 10 分钟',10,1,5,array['朗读','基础'],'卡皮在温泉边听你读书啦',true),
('capy_g1_math_calc_01',1,2,'数学','口算练习 20 题',12,1,6,array['口算','基础'],'做完这组口算，卡皮请你晒太阳',true),
('capy_g1_en_word_01',1,2,'英语','跟读单词 15 个',10,1,5,array['跟读','单词'],'卡皮跟你一起念单词',true),
('capy_g2_cn_copy_01',2,3,'语文','生字词抄写 2 行',15,1,6,array['生字','书写'],'字写整齐，卡皮给你一颗胡萝卜星',true),
('capy_g2_math_wordproblem_01',2,3,'数学','应用题 3 道',18,2,8,array['应用题','思维'],'慢慢想，卡皮最喜欢认真思考',true),
('capy_g3_en_sentence_01',3,4,'英语','句型仿写 5 句',15,2,8,array['句型','写作'],'句子写得好，卡皮开心打滚',true),
('capy_g3_cn_recite_01',3,4,'语文','古诗背诵 1 首',12,2,7,array['背诵','古诗'],'背完古诗，和卡皮一起泡温泉',true),
('capy_g3_math_mixed_01',3,4,'数学','混合运算 15 题',20,2,9,array['混合运算','训练'],'一步一步算，卡皮陪你到完成',true),
('capy_g4_en_read_01',4,5,'英语','课文朗读+翻译 1 段',18,2,9,array['阅读','翻译'],'你读一句，卡皮点点头',true),
('capy_g4_cn_readnote_01',4,5,'语文','阅读摘抄 5 句好词好句',15,2,8,array['阅读','摘抄'],'卡皮收藏了你的好句子',true),
('capy_g4_math_geometry_01',4,5,'数学','几何基础题 8 题',20,2,9,array['几何','基础'],'图形也能很可爱，和卡皮一起做',true),
('capy_g5_cn_composition_01',5,6,'语文','作文提纲 1 份',25,3,12,array['作文','提纲'],'先写提纲，写作就不慌啦',true),
('capy_g5_math_fraction_01',5,6,'数学','分数计算 12 题',25,3,12,array['分数','计算'],'分数有点难，卡皮给你加油',true),
('capy_g5_en_grammar_01',5,6,'英语','语法专项 10 题',22,3,11,array['语法','专项'],'做完语法题，卡皮给你点赞',true),
('capy_all_review_01',1,6,'综合','错题回顾 10 分钟',10,2,7,array['错题','复盘'],'复盘一下，明天会更轻松',true),
('capy_all_focus_01',1,6,'综合','番茄专注 15 分钟',15,1,6,array['专注','番茄钟'],'专注一会儿，卡皮在旁边安静陪你',true),
('capy_all_preview_01',1,6,'综合','明日预习 1 科',12,1,6,array['预习','规划'],'先预习一点点，课堂更轻松',true),
('capy_all_read_01',1,6,'综合','课外阅读 20 分钟',20,1,8,array['阅读','习惯'],'卡皮最喜欢安静阅读时光',true),
('capy_all_sport_01',1,6,'习惯','运动打卡 15 分钟',15,1,6,array['运动','健康'],'动一动更有精神，卡皮一起伸懒腰',true),
('capy_all_pack_01',1,6,'习惯','整理书包和书桌',8,1,5,array['整理','自理'],'整整齐齐，卡皮心情也会变好',true)
on conflict (template_id) do update set
  grade_start = excluded.grade_start,
  grade_end = excluded.grade_end,
  subject = excluded.subject,
  title = excluded.title,
  est_minutes = excluded.est_minutes,
  difficulty = excluded.difficulty,
  energy_reward = excluded.energy_reward,
  tags = excluded.tags,
  capy_hint = excluded.capy_hint,
  is_active = excluded.is_active,
  updated_at = now();
