-- Forge's first hosted-data schema.
-- Every exposed table has explicit grants and row-level security policies.

create extension if not exists pgcrypto with schema extensions;

create type public.exercise_video_kind as enum ('ai_generated', 'team_demo');
create type public.exercise_video_status as enum ('pending', 'approved', 'rejected');

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  username text unique,
  display_name text not null default 'Athlete',
  avatar_url text,
  bio text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_username_format check (
    username is null or username ~ '^[a-zA-Z0-9_]{3,24}$'
  )
);

create table public.exercises (
  id uuid primary key default extensions.gen_random_uuid(),
  slug text not null unique,
  name text not null,
  description text,
  primary_muscle text not null,
  secondary_muscles text[] not null default '{}',
  equipment text[] not null default '{}',
  instructions text[] not null default '{}',
  is_published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.exercise_videos (
  id uuid primary key default extensions.gen_random_uuid(),
  exercise_id uuid not null references public.exercises (id) on delete cascade,
  kind public.exercise_video_kind not null,
  status public.exercise_video_status not null default 'pending',
  title text not null,
  provider text not null default 'cloudflare_stream',
  provider_video_id text,
  playback_url text,
  poster_url text,
  duration_seconds integer,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint exercise_videos_duration_positive check (
    duration_seconds is null or duration_seconds > 0
  ),
  constraint exercise_videos_provider_ref check (
    provider_video_id is not null or playback_url is not null
  ),
  unique (exercise_id, kind, provider_video_id)
);

create table public.routines (
  id uuid primary key default extensions.gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  name text not null,
  description text,
  is_public boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint routines_name_length check (char_length(name) between 1 and 80)
);

create table public.routine_exercises (
  id uuid primary key default extensions.gen_random_uuid(),
  routine_id uuid not null references public.routines (id) on delete cascade,
  exercise_id uuid not null references public.exercises (id) on delete restrict,
  position integer not null,
  target_sets integer,
  target_reps text,
  rest_seconds integer,
  notes text,
  created_at timestamptz not null default now(),
  constraint routine_exercises_position_nonnegative check (position >= 0),
  constraint routine_exercises_sets_positive check (target_sets is null or target_sets > 0),
  constraint routine_exercises_rest_nonnegative check (rest_seconds is null or rest_seconds >= 0),
  unique (routine_id, position)
);

create table public.workouts (
  id uuid primary key default extensions.gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  routine_id uuid references public.routines (id) on delete set null,
  name text not null default 'Workout',
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint workouts_end_after_start check (ended_at is null or ended_at >= started_at)
);

create table public.workout_exercises (
  id uuid primary key default extensions.gen_random_uuid(),
  workout_id uuid not null references public.workouts (id) on delete cascade,
  exercise_id uuid not null references public.exercises (id) on delete restrict,
  position integer not null,
  notes text,
  created_at timestamptz not null default now(),
  constraint workout_exercises_position_nonnegative check (position >= 0),
  unique (workout_id, position)
);

create table public.workout_sets (
  id uuid primary key default extensions.gen_random_uuid(),
  workout_exercise_id uuid not null references public.workout_exercises (id) on delete cascade,
  set_number integer not null,
  reps integer,
  weight numeric(8, 2),
  duration_seconds integer,
  distance_meters numeric(9, 2),
  rpe numeric(3, 1),
  is_warmup boolean not null default false,
  is_failure boolean not null default false,
  created_at timestamptz not null default now(),
  constraint workout_sets_number_positive check (set_number > 0),
  constraint workout_sets_reps_nonnegative check (reps is null or reps >= 0),
  constraint workout_sets_weight_nonnegative check (weight is null or weight >= 0),
  constraint workout_sets_duration_nonnegative check (duration_seconds is null or duration_seconds >= 0),
  constraint workout_sets_distance_nonnegative check (distance_meters is null or distance_meters >= 0),
  constraint workout_sets_rpe_range check (rpe is null or rpe between 0 and 10),
  unique (workout_exercise_id, set_number)
);

create table public.exercise_comments (
  id uuid primary key default extensions.gen_random_uuid(),
  exercise_id uuid not null references public.exercises (id) on delete cascade,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  parent_comment_id uuid references public.exercise_comments (id) on delete cascade,
  body text not null,
  is_hidden boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint exercise_comments_body_length check (char_length(body) between 1 and 2000)
);

create table public.exercise_reactions (
  exercise_id uuid not null references public.exercises (id) on delete cascade,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  value smallint not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint exercise_reactions_value check (value in (-1, 1)),
  primary key (exercise_id, user_id)
);

create index exercise_videos_approved_order_idx
  on public.exercise_videos (exercise_id, kind, sort_order)
  where status = 'approved';
create index routines_owner_updated_idx on public.routines (user_id, updated_at desc);
create index routines_public_updated_idx on public.routines (updated_at desc) where is_public;
create index routine_exercises_exercise_idx on public.routine_exercises (exercise_id);
create index workouts_owner_started_idx on public.workouts (user_id, started_at desc);
create index workout_exercises_exercise_idx on public.workout_exercises (exercise_id);
create index workout_sets_parent_idx on public.workout_sets (workout_exercise_id);
create index exercise_comments_feed_idx on public.exercise_comments (exercise_id, created_at desc)
  where not is_hidden;
create index exercise_comments_user_idx on public.exercise_comments (user_id, created_at desc);

create function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at before update on public.profiles
  for each row execute function public.set_updated_at();
create trigger exercises_set_updated_at before update on public.exercises
  for each row execute function public.set_updated_at();
create trigger exercise_videos_set_updated_at before update on public.exercise_videos
  for each row execute function public.set_updated_at();
create trigger routines_set_updated_at before update on public.routines
  for each row execute function public.set_updated_at();
create trigger workouts_set_updated_at before update on public.workouts
  for each row execute function public.set_updated_at();
create trigger exercise_comments_set_updated_at before update on public.exercise_comments
  for each row execute function public.set_updated_at();
create trigger exercise_reactions_set_updated_at before update on public.exercise_reactions
  for each row execute function public.set_updated_at();

create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(
      nullif(new.raw_user_meta_data ->> 'full_name', ''),
      nullif(new.raw_user_meta_data ->> 'name', ''),
      'Athlete'
    )
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Remove broad defaults, then grant only what client roles need.
revoke all on public.profiles, public.exercises, public.exercise_videos,
  public.routines, public.routine_exercises, public.workouts,
  public.workout_exercises, public.workout_sets, public.exercise_comments,
  public.exercise_reactions from anon, authenticated;

grant select on public.profiles, public.exercises, public.exercise_videos to anon, authenticated;
grant select, update on public.profiles to authenticated;
grant select, insert, update, delete on public.routines, public.routine_exercises,
  public.workouts, public.workout_exercises, public.workout_sets to authenticated;
grant select, insert, update, delete on public.exercise_comments,
  public.exercise_reactions to authenticated;

alter table public.profiles enable row level security;
alter table public.exercises enable row level security;
alter table public.exercise_videos enable row level security;
alter table public.routines enable row level security;
alter table public.routine_exercises enable row level security;
alter table public.workouts enable row level security;
alter table public.workout_exercises enable row level security;
alter table public.workout_sets enable row level security;
alter table public.exercise_comments enable row level security;
alter table public.exercise_reactions enable row level security;

create policy "Profiles are publicly readable"
  on public.profiles for select to anon, authenticated using (true);
create policy "Users update their own profile"
  on public.profiles for update to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

create policy "Published exercises are readable"
  on public.exercises for select to anon, authenticated using (is_published);
create policy "Approved videos for published exercises are readable"
  on public.exercise_videos for select to anon, authenticated
  using (
    status = 'approved'
    and exists (
      select 1 from public.exercises e
      where e.id = exercise_videos.exercise_id and e.is_published
    )
  );

create policy "Users read their own routines and public routines"
  on public.routines for select to authenticated
  using (user_id = (select auth.uid()) or is_public);
create policy "Users create their own routines"
  on public.routines for insert to authenticated
  with check (user_id = (select auth.uid()));
create policy "Users update their own routines"
  on public.routines for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
create policy "Users delete their own routines"
  on public.routines for delete to authenticated
  using (user_id = (select auth.uid()));

create policy "Routine items follow routine visibility"
  on public.routine_exercises for select to authenticated
  using (exists (
    select 1 from public.routines r
    where r.id = routine_exercises.routine_id
      and (r.user_id = (select auth.uid()) or r.is_public)
  ));
create policy "Users manage items in their routines"
  on public.routine_exercises for all to authenticated
  using (exists (
    select 1 from public.routines r
    where r.id = routine_exercises.routine_id and r.user_id = (select auth.uid())
  ))
  with check (exists (
    select 1 from public.routines r
    where r.id = routine_exercises.routine_id and r.user_id = (select auth.uid())
  ));

create policy "Users read their own workouts"
  on public.workouts for select to authenticated using (user_id = (select auth.uid()));
create policy "Users create their own workouts"
  on public.workouts for insert to authenticated with check (user_id = (select auth.uid()));
create policy "Users update their own workouts"
  on public.workouts for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "Users delete their own workouts"
  on public.workouts for delete to authenticated using (user_id = (select auth.uid()));

create policy "Workout exercises follow workout ownership"
  on public.workout_exercises for select to authenticated
  using (exists (
    select 1 from public.workouts w
    where w.id = workout_exercises.workout_id and w.user_id = (select auth.uid())
  ));
create policy "Users manage exercises in their workouts"
  on public.workout_exercises for all to authenticated
  using (exists (
    select 1 from public.workouts w
    where w.id = workout_exercises.workout_id and w.user_id = (select auth.uid())
  ))
  with check (exists (
    select 1 from public.workouts w
    where w.id = workout_exercises.workout_id and w.user_id = (select auth.uid())
  ));

create policy "Workout sets follow workout ownership"
  on public.workout_sets for select to authenticated
  using (exists (
    select 1
    from public.workout_exercises we
    join public.workouts w on w.id = we.workout_id
    where we.id = workout_sets.workout_exercise_id and w.user_id = (select auth.uid())
  ));
create policy "Users manage sets in their workouts"
  on public.workout_sets for all to authenticated
  using (exists (
    select 1
    from public.workout_exercises we
    join public.workouts w on w.id = we.workout_id
    where we.id = workout_sets.workout_exercise_id and w.user_id = (select auth.uid())
  ))
  with check (exists (
    select 1
    from public.workout_exercises we
    join public.workouts w on w.id = we.workout_id
    where we.id = workout_sets.workout_exercise_id and w.user_id = (select auth.uid())
  ));

create policy "Visible comments on published exercises are readable"
  on public.exercise_comments for select to anon, authenticated
  using (
    not is_hidden
    and exists (
      select 1 from public.exercises e
      where e.id = exercise_comments.exercise_id and e.is_published
    )
  );
create policy "Signed-in users add comments as themselves"
  on public.exercise_comments for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and exists (
      select 1 from public.exercises e
      where e.id = exercise_comments.exercise_id and e.is_published
    )
  );
create policy "Users edit their own visible comments"
  on public.exercise_comments for update to authenticated
  using (user_id = (select auth.uid()) and not is_hidden)
  with check (user_id = (select auth.uid()) and not is_hidden);
create policy "Users delete their own comments"
  on public.exercise_comments for delete to authenticated
  using (user_id = (select auth.uid()));

create policy "Users read their own reactions"
  on public.exercise_reactions for select to authenticated
  using (user_id = (select auth.uid()));
create policy "Users react as themselves"
  on public.exercise_reactions for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and exists (
      select 1 from public.exercises e
      where e.id = exercise_reactions.exercise_id and e.is_published
    )
  );
create policy "Users change their own reaction"
  on public.exercise_reactions for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
create policy "Users remove their own reaction"
  on public.exercise_reactions for delete to authenticated
  using (user_id = (select auth.uid()));

create function public.get_exercise_reaction_counts(p_exercise_ids uuid[])
returns table (exercise_id uuid, likes bigint, dislikes bigint)
language sql
stable
security definer
set search_path = ''
as $$
  select r.exercise_id,
    count(*) filter (where r.value = 1) as likes,
    count(*) filter (where r.value = -1) as dislikes
  from public.exercise_reactions r
  join public.exercises e on e.id = r.exercise_id and e.is_published
  where r.exercise_id = any(p_exercise_ids)
  group by r.exercise_id;
$$;
revoke all on function public.get_exercise_reaction_counts(uuid[]) from public;
grant execute on function public.get_exercise_reaction_counts(uuid[]) to anon, authenticated;

