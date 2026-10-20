-- Jalankan sekali di Supabase: SQL Editor -> New query -> tempel -> Run

create sequence if not exists player_seq;

create table if not exists players (
  id         uuid primary key default gen_random_uuid(),
  token      uuid not null unique,          -- rahasia pemain, disimpan di browsernya
  num        bigint not null unique,        -- nomor urut: 1, 2, 3, ...
  name       text not null unique,          -- titut_1, titut_2, ...
  clicks     bigint not null default 0,
  last_sync  timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index if not exists players_rank_idx on players (clicks desc, num asc);

-- Kunci tabel: browser tidak boleh baca/tulis langsung, hanya lewat fungsi di bawah
alter table players enable row level security;
revoke all on players from anon, authenticated;

-- 1) Daftar / masuk. Pemain baru otomatis dapat titut_N sesuai giliran.
create or replace function register_player(p_token uuid)
returns table (player_name text, player_clicks bigint)
language plpgsql security definer set search_path = public as $$
declare
  n bigint;
begin
  if not exists (select 1 from players p where p.token = p_token) then
    n := nextval('player_seq');
    insert into players (token, num, name)
    values (p_token, n, 'titut_' || n)
    on conflict (token) do nothing;
  end if;
  return query
    select p.name, p.clicks from players p where p.token = p_token;
end $$;

-- 2) Tambah klik. Dibatasi maksimal ~12 klik/detik per pemain (+ burst 10)
--    supaya tidak gampang dicurangi lewat devtools.
create or replace function add_clicks(p_token uuid, p_delta int)
returns bigint
language plpgsql security definer set search_path = public as $$
declare
  secs    numeric;
  allowed int;
  result  bigint;
begin
  select greatest(extract(epoch from (now() - last_sync)), 0)
    into secs from players where token = p_token;
  if secs is null then
    return null;
  end if;

  if p_delta is null or p_delta <= 0 then
    select clicks into result from players where token = p_token;
    return result;
  end if;

  allowed := least(ceil(secs * 12)::int + 10, 500);

  update players
     set clicks = clicks + least(p_delta, allowed),
         last_sync = now()
   where token = p_token
   returning clicks into result;

  return result;
end $$;

-- 3) Leaderboard
create or replace function get_leaderboard(p_limit int default 10)
returns table (pos bigint, player_name text, player_clicks bigint)
language sql stable security definer set search_path = public as $$
  select row_number() over (order by clicks desc, num asc), name, clicks
  from players
  order by clicks desc, num asc
  limit least(greatest(p_limit, 1), 100);
$$;

-- 4) Peringkat milik sendiri
create or replace function get_my_rank(p_token uuid)
returns table (pos bigint, player_name text, player_clicks bigint)
language sql stable security definer set search_path = public as $$
  select r.pos, r.name, r.clicks
  from (
    select token, name, clicks,
           row_number() over (order by clicks desc, num asc) as pos
    from players
  ) r
  where r.token = p_token;
$$;

grant execute on function register_player(uuid)   to anon;
grant execute on function add_clicks(uuid, int)   to anon;
grant execute on function get_leaderboard(int)    to anon;
grant execute on function get_my_rank(uuid)       to anon;
