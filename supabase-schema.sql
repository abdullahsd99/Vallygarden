-- CafeOps / Zoy OS Supabase Schema
-- Run this file inside Supabase SQL Editor.

create extension if not exists "uuid-ossp";

-- =========================
-- ENUMS
-- =========================

do $$ begin
  create type app_role as enum ('general_manager', 'branch_manager', 'barista');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type item_status as enum ('active', 'inactive', 'pending', 'completed', 'missed', 'overdue');
exception when duplicate_object then null;
end $$;

-- =========================
-- CORE TABLES
-- =========================

create table if not exists public.companies (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  legal_name text,
  phone text,
  email text,
  default_language text not null default 'ar',
  created_at timestamptz not null default now()
);

create table if not exists public.branches (
  id uuid primary key default uuid_generate_v4(),
  company_id uuid not null references public.companies(id) on delete cascade,
  name text not null,
  city text,
  location text,
  opening_hours text,
  status item_status not null default 'active',
  created_at timestamptz not null default now()
);

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  company_id uuid references public.companies(id) on delete cascade,
  branch_id uuid references public.branches(id) on delete set null,
  full_name text not null,
  phone text,
  role app_role not null default 'barista',
  language text not null default 'ar',
  status item_status not null default 'active',
  created_at timestamptz not null default now()
);

-- =========================
-- RECIPES
-- =========================

create table if not exists public.recipes (
  id uuid primary key default uuid_generate_v4(),
  company_id uuid not null references public.companies(id) on delete cascade,
  name_ar text not null,
  name_en text,
  name_ne text,
  category text,
  cup_size text,
  ingredients jsonb not null default '[]'::jsonb,
  preparation_steps jsonb not null default '[]'::jsonb,
  product_cost numeric(10,2),
  selling_price numeric(10,2),
  image_url text,
  created_by uuid references public.profiles(id),
  updated_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.recipe_versions (
  id uuid primary key default uuid_generate_v4(),
  company_id uuid not null references public.companies(id) on delete cascade,
  recipe_id uuid not null references public.recipes(id) on delete cascade,
  snapshot jsonb not null,
  changed_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

-- =========================
-- CHECKLISTS
-- =========================

create table if not exists public.checklists (
  id uuid primary key default uuid_generate_v4(),
  company_id uuid not null references public.companies(id) on delete cascade,
  branch_id uuid references public.branches(id) on delete cascade,
  title_ar text not null,
  title_en text,
  title_ne text,
  checklist_type text not null,
  required_role app_role default 'barista',
  tasks jsonb not null default '[]'::jsonb,
  frequency text not null default 'daily',
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.checklist_logs (
  id uuid primary key default uuid_generate_v4(),
  company_id uuid not null references public.companies(id) on delete cascade,
  branch_id uuid not null references public.branches(id) on delete cascade,
  checklist_id uuid not null references public.checklists(id) on delete cascade,
  completed_by uuid references public.profiles(id),
  completed_tasks jsonb not null default '[]'::jsonb,
  status item_status not null default 'completed',
  notes text,
  completed_at timestamptz not null default now()
);

-- =========================
-- GRINDER CALIBRATION
-- =========================

create table if not exists public.grinder_calibrations (
  id uuid primary key default uuid_generate_v4(),
  company_id uuid not null references public.companies(id) on delete cascade,
  branch_id uuid not null references public.branches(id) on delete cascade,
  grinder_name text not null,
  grinder_model text,
  coffee_bean_type text,
  roast_date date,
  dose_grams numeric(6,2),
  yield_grams numeric(6,2),
  extraction_time_seconds integer,
  grind_setting text,
  notes text,
  calibrated_by uuid references public.profiles(id),
  calibration_date timestamptz not null default now()
);

create table if not exists public.grinder_cleaning_logs (
  id uuid primary key default uuid_generate_v4(),
  company_id uuid not null references public.companies(id) on delete cascade,
  branch_id uuid not null references public.branches(id) on delete cascade,
  grinder_name text not null,
  cleaning_type text not null,
  tasks_completed jsonb not null default '[]'::jsonb,
  cleaned_by uuid references public.profiles(id),
  cleaning_date timestamptz not null default now(),
  notes text,
  before_photo text,
  after_photo text,
  status item_status not null default 'completed'
);

-- =========================
-- ESPRESSO MACHINE CLEANING
-- =========================

create table if not exists public.machine_cleaning_logs (
  id uuid primary key default uuid_generate_v4(),
  company_id uuid not null references public.companies(id) on delete cascade,
  branch_id uuid not null references public.branches(id) on delete cascade,
  machine_name text not null,
  machine_model text,
  cleaning_type text not null,
  tasks_completed jsonb not null default '[]'::jsonb,
  cleaned_by uuid references public.profiles(id),
  cleaning_date timestamptz not null default now(),
  notes text,
  before_photo text,
  after_photo text,
  issue_detected boolean not null default false,
  issue_description text,
  status item_status not null default 'completed'
);

-- =========================
-- WATER QUALITY
-- =========================

create table if not exists public.water_logs (
  id uuid primary key default uuid_generate_v4(),
  company_id uuid not null references public.companies(id) on delete cascade,
  branch_id uuid not null references public.branches(id) on delete cascade,
  tds numeric(8,2),
  ppm numeric(8,2),
  filter_status text,
  maintenance_date date,
  recorded_by uuid references public.profiles(id),
  notes text,
  created_at timestamptz not null default now()
);

-- =========================
-- EQUIPMENT / MAINTENANCE
-- =========================

create table if not exists public.equipment (
  id uuid primary key default uuid_generate_v4(),
  company_id uuid not null references public.companies(id) on delete cascade,
  branch_id uuid not null references public.branches(id) on delete cascade,
  equipment_type text not null,
  equipment_name text not null,
  brand text,
  model text,
  serial_number text,
  purchase_date date,
  warranty_end_date date,
  status item_status not null default 'active',
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.maintenance_logs (
  id uuid primary key default uuid_generate_v4(),
  company_id uuid not null references public.companies(id) on delete cascade,
  branch_id uuid not null references public.branches(id) on delete cascade,
  equipment_id uuid references public.equipment(id) on delete cascade,
  maintenance_type text not null,
  due_date date,
  completed_at timestamptz,
  completed_by uuid references public.profiles(id),
  status item_status not null default 'pending',
  notes text,
  created_at timestamptz not null default now()
);

-- =========================
-- TRAINING / ISSUES / INVENTORY
-- =========================

create table if not exists public.training_videos (
  id uuid primary key default uuid_generate_v4(),
  company_id uuid not null references public.companies(id) on delete cascade,
  branch_id uuid references public.branches(id) on delete cascade,
  title_ar text not null,
  title_en text,
  title_ne text,
  description_ar text,
  description_en text,
  description_ne text,
  video_url text not null,
  category text not null,
  required_role app_role default 'barista',
  created_at timestamptz not null default now()
);

create table if not exists public.issues (
  id uuid primary key default uuid_generate_v4(),
  company_id uuid not null references public.companies(id) on delete cascade,
  branch_id uuid references public.branches(id) on delete cascade,
  title text not null,
  description text,
  issue_type text,
  priority text default 'medium',
  status item_status not null default 'pending',
  reported_by uuid references public.profiles(id),
  assigned_to uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

create table if not exists public.troubleshooting_articles (
  id uuid primary key default uuid_generate_v4(),
  company_id uuid not null references public.companies(id) on delete cascade,
  problem_ar text not null,
  problem_en text,
  problem_ne text,
  causes jsonb not null default '[]'::jsonb,
  solutions jsonb not null default '[]'::jsonb,
  equipment_type text,
  created_at timestamptz not null default now()
);

create table if not exists public.inventory (
  id uuid primary key default uuid_generate_v4(),
  company_id uuid not null references public.companies(id) on delete cascade,
  branch_id uuid not null references public.branches(id) on delete cascade,
  item_name text not null,
  category text,
  quantity numeric(10,2) not null default 0,
  unit text,
  minimum_quantity numeric(10,2) not null default 0,
  updated_by uuid references public.profiles(id),
  updated_at timestamptz not null default now()
);

create table if not exists public.notifications (
  id uuid primary key default uuid_generate_v4(),
  company_id uuid not null references public.companies(id) on delete cascade,
  branch_id uuid references public.branches(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  title text not null,
  message text not null,
  type text not null,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.audit_logs (
  id uuid primary key default uuid_generate_v4(),
  company_id uuid references public.companies(id) on delete cascade,
  user_id uuid references public.profiles(id),
  table_name text not null,
  record_id uuid,
  action text not null,
  old_data jsonb,
  new_data jsonb,
  created_at timestamptz not null default now()
);

-- =========================
-- HELPER FUNCTIONS
-- =========================

create or replace function public.current_company_id()
returns uuid
language sql
stable
as $$
  select company_id from public.profiles where id = auth.uid()
$$;

create or replace function public.current_branch_id()
returns uuid
language sql
stable
as $$
  select branch_id from public.profiles where id = auth.uid()
$$;

create or replace function public.current_role()
returns app_role
language sql
stable
as $$
  select role from public.profiles where id = auth.uid()
$$;

-- =========================
-- ENABLE RLS
-- =========================

alter table public.companies enable row level security;
alter table public.branches enable row level security;
alter table public.profiles enable row level security;
alter table public.recipes enable row level security;
alter table public.recipe_versions enable row level security;
alter table public.checklists enable row level security;
alter table public.checklist_logs enable row level security;
alter table public.grinder_calibrations enable row level security;
alter table public.grinder_cleaning_logs enable row level security;
alter table public.machine_cleaning_logs enable row level security;
alter table public.water_logs enable row level security;
alter table public.equipment enable row level security;
alter table public.maintenance_logs enable row level security;
alter table public.training_videos enable row level security;
alter table public.issues enable row level security;
alter table public.troubleshooting_articles enable row level security;
alter table public.inventory enable row level security;
alter table public.notifications enable row level security;
alter table public.audit_logs enable row level security;

-- =========================
-- BASIC RLS POLICIES
-- =========================

create policy "companies_select_own" on public.companies
for select using (id = public.current_company_id());

create policy "branches_company_access" on public.branches
for all using (company_id = public.current_company_id())
with check (company_id = public.current_company_id());

create policy "profiles_company_access" on public.profiles
for select using (company_id = public.current_company_id() or id = auth.uid());

create policy "profiles_manager_insert" on public.profiles
for insert with check (
  company_id = public.current_company_id()
  and public.current_role() in ('general_manager','branch_manager')
);

create policy "profiles_manager_update" on public.profiles
for update using (
  company_id = public.current_company_id()
  and public.current_role() in ('general_manager','branch_manager')
)
with check (company_id = public.current_company_id());

-- shared company policies
create policy "recipes_company_access" on public.recipes for all using (company_id = public.current_company_id()) with check (company_id = public.current_company_id());
create policy "recipe_versions_company_access" on public.recipe_versions for all using (company_id = public.current_company_id()) with check (company_id = public.current_company_id());
create policy "checklists_company_access" on public.checklists for all using (company_id = public.current_company_id()) with check (company_id = public.current_company_id());
create policy "checklist_logs_company_access" on public.checklist_logs for all using (company_id = public.current_company_id()) with check (company_id = public.current_company_id());
create policy "grinder_calibrations_company_access" on public.grinder_calibrations for all using (company_id = public.current_company_id()) with check (company_id = public.current_company_id());
create policy "grinder_cleaning_company_access" on public.grinder_cleaning_logs for all using (company_id = public.current_company_id()) with check (company_id = public.current_company_id());
create policy "machine_cleaning_company_access" on public.machine_cleaning_logs for all using (company_id = public.current_company_id()) with check (company_id = public.current_company_id());
create policy "water_logs_company_access" on public.water_logs for all using (company_id = public.current_company_id()) with check (company_id = public.current_company_id());
create policy "equipment_company_access" on public.equipment for all using (company_id = public.current_company_id()) with check (company_id = public.current_company_id());
create policy "maintenance_company_access" on public.maintenance_logs for all using (company_id = public.current_company_id()) with check (company_id = public.current_company_id());
create policy "training_company_access" on public.training_videos for all using (company_id = public.current_company_id()) with check (company_id = public.current_company_id());
create policy "issues_company_access" on public.issues for all using (company_id = public.current_company_id()) with check (company_id = public.current_company_id());
create policy "troubleshooting_company_access" on public.troubleshooting_articles for all using (company_id = public.current_company_id()) with check (company_id = public.current_company_id());
create policy "inventory_company_access" on public.inventory for all using (company_id = public.current_company_id()) with check (company_id = public.current_company_id());
create policy "notifications_company_access" on public.notifications for all using (company_id = public.current_company_id()) with check (company_id = public.current_company_id());
create policy "audit_logs_company_access" on public.audit_logs for select using (company_id = public.current_company_id());

-- =========================
-- STORAGE BUCKETS
-- =========================

insert into storage.buckets (id, name, public)
values
  ('recipe-images', 'recipe-images', true),
  ('cleaning-photos', 'cleaning-photos', false),
  ('training-videos', 'training-videos', false)
on conflict (id) do nothing;

-- =========================
-- SEED DATA
-- =========================

insert into public.companies (id, name, legal_name, default_language)
values ('11111111-1111-1111-1111-111111111111', 'Zoy Coffee', 'Zoy Coffee', 'ar')
on conflict do nothing;

insert into public.branches (id, company_id, name, city, location, opening_hours)
values
('22222222-2222-2222-2222-222222222221', '11111111-1111-1111-1111-111111111111', 'فرع الساعة', 'عنيزة', 'Unaizah', '6:00 AM - 12:00 AM'),
('22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'فرع الفهد', 'عنيزة', 'Unaizah', '6:00 AM - 12:00 AM'),
('22222222-2222-2222-2222-222222222223', '11111111-1111-1111-1111-111111111111', 'فرع بريدة', 'بريدة', 'Buraydah', '6:00 AM - 12:00 AM')
on conflict do nothing;

insert into public.recipes (company_id, name_ar, name_en, name_ne, category, cup_size, ingredients, preparation_steps, product_cost, selling_price)
values
('11111111-1111-1111-1111-111111111111', 'سبانش لاتيه', 'Spanish Latte', 'स्पेनिश लाटे', 'coffee', '12oz', '[{"name":"Espresso","qty":"2 shots"},{"name":"Milk","qty":"120ml"},{"name":"Condensed milk","qty":"30ml"}]', '["Prepare espresso","Add condensed milk","Add milk","Serve"]', 5.50, 18.00),
('11111111-1111-1111-1111-111111111111', 'في 60', 'V60', 'भी ६०', 'filter', '300ml', '[{"name":"Coffee","qty":"18g"},{"name":"Water","qty":"300ml"}]', '["Rinse filter","Add coffee","Bloom 30 seconds","Pour in stages"]', 4.00, 16.00)
;

insert into public.checklists (company_id, title_ar, title_en, title_ne, checklist_type, tasks)
values
('11111111-1111-1111-1111-111111111111', 'افتتاح الفرع', 'Opening Checklist', 'खोल्ने चेकलिस्ट', 'opening', '["تشغيل المكائن","فحص الثلاجات","معايرة الطواحين","فحص المخزون"]'),
('11111111-1111-1111-1111-111111111111', 'إغلاق الفرع', 'Closing Checklist', 'बन्द गर्ने चेकलिस्ट', 'closing', '["تنظيف ماكينة الإسبريسو","تنظيف الطواحين","تنظيف البار","إغلاق الكاشير"]')
;

insert into public.troubleshooting_articles (company_id, problem_ar, problem_en, problem_ne, causes, solutions, equipment_type)
values
('11111111-1111-1111-1111-111111111111', 'الاستخلاص سريع جدًا', 'Espresso extraction too fast', 'एस्प्रेसो धेरै छिटो आयो', '["الطحن خشن","جرعة البن قليلة"]', '["اجعل الطحن أنعم","ارفع جرعة البن","تأكد من التامب"]', 'grinder'),
('11111111-1111-1111-1111-111111111111', 'الاستخلاص بطيء جدًا', 'Espresso extraction too slow', 'एस्प्रेसो ढिलो आयो', '["الطحن ناعم جدًا","جرعة البن عالية"]', '["اجعل الطحن أخشن","راجع جرعة البن","نظف البورتافلتر"]', 'grinder')
;
