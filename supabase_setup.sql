-- ============================================================
--  오목 랭킹 — Supabase 스키마
--  Supabase 대시보드 → SQL Editor 에 붙여넣고 실행하세요.
-- ============================================================

-- 1) 프로필 (카카오 닉네임/프로필 이미지 캐시) -----------------
create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  nickname    text,
  avatar_url  text,
  created_at  timestamptz not null default now()
);

alter table public.profiles enable row level security;

drop policy if exists "profiles_select_all" on public.profiles;
create policy "profiles_select_all"
  on public.profiles for select using (true);

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
  on public.profiles for insert with check (auth.uid() = id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
  on public.profiles for update using (auth.uid() = id);

-- 2) 대전 기록 (AI 대전 결과) --------------------------------
create table if not exists public.match_results (
  id          bigint generated always as identity primary key,
  player_id   uuid not null references auth.users(id) on delete cascade,
  result      text not null check (result in ('win','loss')),
  mode        text not null default 'ai',
  created_at  timestamptz not null default now()
);

alter table public.match_results enable row level security;

drop policy if exists "results_select_all" on public.match_results;
create policy "results_select_all"
  on public.match_results for select using (true);

drop policy if exists "results_insert_own" on public.match_results;
create policy "results_insert_own"
  on public.match_results for insert with check (auth.uid() = player_id);

-- 3) 랭킹 뷰 -------------------------------------------------
create or replace view public.leaderboard as
select
  p.id,
  p.nickname,
  p.avatar_url,
  count(*) filter (where m.result = 'win')  as wins,
  count(*) filter (where m.result = 'loss') as losses,
  count(m.id)                               as games
from public.profiles p
left join public.match_results m on m.player_id = p.id
group by p.id, p.nickname, p.avatar_url;

grant select on public.leaderboard to anon, authenticated;
