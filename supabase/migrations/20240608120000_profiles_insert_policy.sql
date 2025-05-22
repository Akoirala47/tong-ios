-- Allow users to insert their own profile row
create policy "Users can insert their own profile" on profiles
  for insert with check (auth.uid() = id); 