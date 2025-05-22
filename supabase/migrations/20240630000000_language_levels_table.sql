-- Create language_levels table if it doesn't exist
create table if not exists language_levels (
  id serial primary key,
  language_id integer references languages(id),
  code text not null,
  name text not null,
  ordinal integer not null,
  hours_target integer not null,
  created_at timestamptz default now(),
  unique(language_id, code)
);

-- Update topics table structure to match our seeding script requirements
alter table topics add column if not exists language_level_id integer references language_levels(id);
alter table topics add column if not exists slug text;
alter table topics add column if not exists can_do_statement text;
alter table topics add column if not exists order_in_level integer default 99;

-- Update lessons table structure for content
alter table lessons add column if not exists order_in_topic integer default 0;
alter table lessons add column if not exists slug text;

-- Update cards table for additional fields
alter table cards add column if not exists ipa text;
alter table cards add column if not exists order_in_lesson integer default 0;

-- Create Storage bucket for content generation logs
insert into storage.buckets (id, name, public)
values ('content-generation-log', 'content-generation-log', false)
on conflict (id) do nothing;

-- Allow authenticated users to upload to the content-generation-log bucket
create policy "Allow authenticated users to upload logs" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'content-generation-log');

-- Allow authenticated users to read from content-generation-log bucket
create policy "Allow authenticated users to read logs" on storage.objects
  for select to authenticated
  using (bucket_id = 'content-generation-log'); 