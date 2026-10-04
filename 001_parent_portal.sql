-- EduCore Parent Portal migration. Run this in the SAME Supabase project used by EduCore.
-- Safe additions: it does not delete or rename existing EduCore tables.

create table if not exists public.parent_student_links (
  id uuid primary key default uuid_generate_v4(),
  parent_id uuid not null references public.parents(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  relationship_type varchar(50) default 'Parent',
  is_primary boolean default false,
  is_active boolean default true,
  created_at timestamptz default now(),
  unique(parent_id, student_id)
);

create index if not exists idx_parent_student_links_parent on public.parent_student_links(parent_id) where is_active=true;
create index if not exists idx_parent_student_links_student on public.parent_student_links(student_id) where is_active=true;

-- Existing EduCore has students.parent_id for legacy single-parent records.
-- This backfills those links without removing the old field.
insert into public.parent_student_links(parent_id, student_id, relationship_type, is_primary)
select s.parent_id, s.id, coalesce(s.parent_relationship,'Parent'), true
from public.students s
where s.parent_id is not null
on conflict(parent_id, student_id) do nothing;

alter table public.parent_student_links enable row level security;

create or replace function public.current_parent_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select p.id from public.parents p where p.user_id = auth.uid() limit 1;
$$;

create or replace function public.current_parent_student_ids()
returns setof uuid
language sql
stable
security definer
set search_path = public
as $$
  select l.student_id from public.parent_student_links l
  where l.parent_id = public.current_parent_id() and l.is_active = true;
$$;

grant execute on function public.current_parent_id() to authenticated;
grant execute on function public.current_parent_student_ids() to authenticated;

-- Parent profile
 drop policy if exists "Parents can read own parent profile" on public.parents;
create policy "Parents can read own parent profile" on public.parents
for select to authenticated using (user_id = auth.uid());

-- Link table
 drop policy if exists "Parents can read their student links" on public.parent_student_links;
create policy "Parents can read their student links" on public.parent_student_links
for select to authenticated using (parent_id = public.current_parent_id());

-- Child records
 drop policy if exists "Parents can read linked students" on public.students;
create policy "Parents can read linked students" on public.students
for select to authenticated using (id in (select public.current_parent_student_ids()));

-- Linked attendance
 drop policy if exists "Parents can read linked attendance" on public.attendance;
create policy "Parents can read linked attendance" on public.attendance
for select to authenticated using (student_id in (select public.current_parent_student_ids()));

-- Linked payments
 drop policy if exists "Parents can read linked payments" on public.payments;
create policy "Parents can read linked payments" on public.payments
for select to authenticated using (student_id in (select public.current_parent_student_ids()));

-- Published results only
 drop policy if exists "Parents can read linked published results" on public.results;
create policy "Parents can read linked published results" on public.results
for select to authenticated using (student_id in (select public.current_parent_student_ids()) and is_published = true);

-- Published report cards only
 drop policy if exists "Parents can read linked published report cards" on public.report_cards;
create policy "Parents can read linked published report cards" on public.report_cards
for select to authenticated using (student_id in (select public.current_parent_student_ids()) and is_published = true);

-- Fee structures needed to show class fee context
 drop policy if exists "Parents can read active fee structures for linked children" on public.fee_structures;
create policy "Parents can read active fee structures for linked children" on public.fee_structures
for select to authenticated using (
  is_active = true and is_archived = false and class_id in (select s.class_id from public.students s where s.id in (select public.current_parent_student_ids()))
);

-- Classes/streams/subjects/exams/school metadata used by the portal.
 drop policy if exists "Parents can read linked school classes" on public.classes;
create policy "Parents can read linked school classes" on public.classes
for select to authenticated using (id in (select s.class_id from public.students s where s.id in (select public.current_parent_student_ids())));

 drop policy if exists "Parents can read linked streams" on public.streams;
create policy "Parents can read linked streams" on public.streams
for select to authenticated using (id in (select s.stream_id from public.students s where s.id in (select public.current_parent_student_ids())));

 drop policy if exists "Parents can read linked subjects" on public.subjects;
create policy "Parents can read linked subjects" on public.subjects
for select to authenticated using (school_id in (select s.school_id from public.students s where s.id in (select public.current_parent_student_ids())));

 drop policy if exists "Parents can read linked exams" on public.exams;
create policy "Parents can read linked exams" on public.exams
for select to authenticated using (is_published = true and school_id in (select s.school_id from public.students s where s.id in (select public.current_parent_student_ids())));

-- School profile
 drop policy if exists "Parents can read own school" on public.schools;
create policy "Parents can read own school" on public.schools
for select to authenticated using (id in (select p.school_id from public.parents p where p.user_id = auth.uid()));

-- School announcements. Existing notification table has role targeting.
 drop policy if exists "Parents can read parent announcements" on public.notifications;
create policy "Parents can read parent announcements" on public.notifications
for select to authenticated using (
  school_id in (select p.school_id from public.parents p where p.user_id = auth.uid())
  and target_role in ('All','Parents')
);

-- Profiles are needed only for basic parent identity in the wider EduCore system; do not expose other profiles here.
 drop policy if exists "Parents can read own profile" on public.profiles;
create policy "Parents can read own profile" on public.profiles
for select to authenticated using (id = auth.uid());

-- IMPORTANT: keep parent portal read-only. No INSERT/UPDATE/DELETE policies are created for parents.
