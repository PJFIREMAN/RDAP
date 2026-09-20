create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
create table public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 full_name text not null check(length(trim(full_name)) between 2 and 120),
 email text not null,
 phone text not null check(length(phone) between 8 and 25),
 username text not null check(username ~ '^[a-z0-9_]{3,32}$'),
 work_id text not null check(length(trim(work_id)) between 1 and 80),
 created_at timestamptz not null default now()
);
create unique index profiles_username_unique on public.profiles(lower(username));
create table public.tasks (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
 title text not null check(length(trim(title)) between 1 and 200),
 description text not null default '' check(length(description)<=5000),
 category text not null default 'Coordenação' check(category in ('Capacitação','Assistência técnica','Coordenação','Suporte operacional','Reporting','Outros')),
 status text not null default 'planejado' check(status in ('planejado','em_andamento','concluido')),
 priority text not null default 'media' check(priority in ('baixa','media','alta')),
 start_date date not null,
 due_date date not null check(due_date>=start_date),
 completed_at timestamptz,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create index tasks_user_due on public.tasks(user_id,due_date);
create table public.reports (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
 title text not null check(length(trim(title)) between 1 and 200),
 period_start date not null,
 period_end date not null check(period_end>=period_start),
 snapshot jsonb not null check(jsonb_typeof(snapshot)='array'),
 created_at timestamptz not null default now()
);
create index reports_user_created on public.reports(user_id,created_at desc);
alter table public.profiles enable row level security;
alter table public.tasks enable row level security;
alter table public.reports enable row level security;
revoke all on public.profiles,public.tasks,public.reports from anon,authenticated;
grant select on public.profiles to authenticated;
grant select,insert,update,delete on public.tasks to authenticated;
grant select,insert,delete on public.reports to authenticated;
create policy profiles_read_own on public.profiles for select to authenticated using (id=(select auth.uid()));
create policy tasks_read_own on public.tasks for select to authenticated using(user_id=(select auth.uid()));
create policy tasks_insert_own on public.tasks for insert to authenticated with check(user_id=(select auth.uid()));
create policy tasks_update_own on public.tasks for update to authenticated using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()));
create policy tasks_delete_own on public.tasks for delete to authenticated using(user_id=(select auth.uid()));
create policy reports_read_own on public.reports for select to authenticated using(user_id=(select auth.uid()));
create policy reports_insert_own on public.reports for insert to authenticated with check(user_id=(select auth.uid()));
create policy reports_delete_own on public.reports for delete to authenticated using(user_id=(select auth.uid()));
create function private.create_profile() returns trigger
language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is not null and auth.uid() <> new.id then
   raise exception 'Invalid identity';
 end if;
 insert into public.profiles(id,full_name,email,phone,username,work_id)
 values(new.id,trim(new.raw_user_meta_data->>'full_name'),new.email,
 trim(new.raw_user_meta_data->>'phone'),lower(trim(new.raw_user_meta_data->>'username')),
 trim(new.raw_user_meta_data->>'work_id'));
 return new;
end;
$$;
revoke all on function private.create_profile() from public,anon,authenticated;
create trigger create_user_profile after insert on auth.users for each row execute function private.create_profile();
create function private.touch_task() returns trigger
language plpgsql security invoker set search_path='' as $$
begin
 new.updated_at=now();
 if new.status='concluido' and (tg_op='INSERT' or old.status is distinct from new.status) then new.completed_at=now();
 elsif new.status<>'concluido' then new.completed_at=null;
 else new.completed_at=old.completed_at;
 end if;
 return new;
end;
$$;
revoke all on function private.touch_task() from public,anon,authenticated;
create trigger touch_task before insert or update on public.tasks for each row execute function private.touch_task();
