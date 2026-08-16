-- ============================================================================
-- MangkukKembara - Database Reset and Create Script
-- PostgreSQL / Supabase
--
-- Run this file when the database structure changes.
-- It drops the existing application tables and recreates them from zero.
-- Supabase-managed auth.users is NOT dropped.
-- ============================================================================

begin;

-- ============================================================================
-- 1. DROP OLD OBJECTS
-- Drop child tables before parent tables.
-- ============================================================================

drop view if exists public.v_artwork_rankings cascade;
drop view if exists public.v_collection_progress cascade;
drop view if exists public.public_profiles cascade;

drop table if exists public.artwork_campaign_winners cascade;
drop table if exists public.artwork_votes cascade;
drop table if exists public.artwork_voting_entries cascade;
drop table if exists public.artwork_voting_sessions cascade;
drop table if exists public.artwork_submissions cascade;
drop table if exists public.artwork_campaign_categories cascade;
drop table if exists public.artwork_campaigns cascade;

drop table if exists public.community_comments cascade;
drop table if exists public.community_post_likes cascade;
drop table if exists public.community_post_photos cascade;
drop table if exists public.community_posts cascade;

drop table if exists public.vendor_tiffin_availability cascade;
drop table if exists public.vendor_foods cascade;
drop table if exists public.vendor_operating_hours cascade;
drop table if exists public.vendors cascade;
drop table if exists public.pasar_malam_operating_hours cascade;
drop table if exists public.pasar_malam cascade;

drop table if exists public.user_tiffin_collection cascade;
drop table if exists public.tiffin_qr_codes cascade;
drop table if exists public.heritage_media cascade;
drop table if exists public.heritage_stories cascade;
drop table if exists public.heritage_tiffins cascade;
drop table if exists public.artworks cascade;
drop table if exists public.heritage_foods cascade;
drop table if exists public.food_categories cascade;
drop table if exists public.states cascade;
drop table if exists public.profiles cascade;

drop sequence if exists public.profile_number_seq cascade;
drop sequence if exists public.user_tiffin_collection_number_seq cascade;
drop sequence if exists public.community_post_number_seq cascade;
drop sequence if exists public.community_post_photo_number_seq cascade;
drop sequence if exists public.community_post_like_number_seq cascade;
drop sequence if exists public.community_comment_number_seq cascade;
drop sequence if exists public.artwork_submission_number_seq cascade;
drop sequence if exists public.artwork_vote_number_seq cascade;
drop function if exists public.create_profile_for_new_auth_user() cascade;
drop trigger if exists on_auth_user_created on auth.users;

-- ============================================================================
-- 2. ACCOUNT MANAGEMENT
-- profile_id uses the project ID format, for example P0001.
-- auth_user_id links the profile to Supabase Auth's UUID.
-- ============================================================================

-- P0001-P0999 are reserved for deterministic seed/demo profiles.
create sequence public.profile_number_seq start 1000;

create table public.profiles (
    profile_id         varchar(5) primary key,
    auth_user_id       uuid unique references auth.users(id) on delete cascade,
    role               varchar(20) not null default 'tourist'
                       check (role in ('tourist', 'admin')),
    display_name       varchar(80) not null,
    avatar_url         text,
    biography          text,
    website_url        text,
    country_code       char(2),
    city               varchar(100),
    date_of_birth      date,
    gender             varchar(30),
    is_active          boolean not null default true,
    created_at         timestamptz not null default now(),
    updated_at         timestamptz not null default now(),

    constraint chk_profile_id_format
        check (profile_id ~ '^P[0-9]{4}$')
);

-- Automatically creates a normal tourist profile after Supabase Auth signup.
create or replace function public.create_profile_for_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
    new_profile_id varchar(5);
    new_date_of_birth date;
    new_gender varchar(30);
begin
    new_profile_id := 'P' || lpad(nextval('public.profile_number_seq')::text, 4, '0');
    if coalesce(new.raw_user_meta_data ->> 'date_of_birth', '') ~ '^\d{4}-\d{2}-\d{2}$' then
        new_date_of_birth := (new.raw_user_meta_data ->> 'date_of_birth')::date;
    end if;
    new_gender := case
        when lower(new.raw_user_meta_data ->> 'gender') in (
            'male', 'female', 'non_binary', 'prefer_not_to_say', 'other'
        ) then lower(new.raw_user_meta_data ->> 'gender')
    end;

    insert into public.profiles (
        profile_id,
        auth_user_id,
        role,
        display_name,
        country_code,
        city,
        date_of_birth,
        gender
    )
    values (
        new_profile_id,
        new.id,
        'tourist',
        left(coalesce(
            nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''),
            split_part(coalesce(new.email, 'Tourist'), '@', 1)
        ), 80),
        nullif(left(upper(new.raw_user_meta_data ->> 'country_code'), 2), ''),
        nullif(trim(new.raw_user_meta_data ->> 'city'), ''),
        new_date_of_birth,
        new_gender
    );

    return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.create_profile_for_new_auth_user();

-- ============================================================================
-- 3. REFERENCE TABLES
-- ============================================================================

create table public.states (
    state_id           varchar(5) primary key,
    state_code         varchar(10) not null unique,
    state_name         varchar(80) not null unique,
    description        text,
    is_active          boolean not null default true,

    constraint chk_state_id_format
        check (state_id ~ '^S[0-9]{4}$')
);

create table public.food_categories (
    food_category_id   varchar(6) primary key,
    category_name      varchar(100) not null unique,
    description        text,
    is_active          boolean not null default true,

    constraint chk_food_category_id_format
        check (food_category_id ~ '^FC[0-9]{4}$')
);

create table public.heritage_foods (
    heritage_food_id       varchar(6) primary key,
    food_category_id       varchar(6) not null references public.food_categories(food_category_id),
    state_id               varchar(5) not null references public.states(state_id),
    food_name              varchar(150) not null,
    origin_summary         text,
    cultural_significance  text,
    image_url              text,
    is_active              boolean not null default true,
    created_at             timestamptz not null default now(),

    constraint uq_heritage_food unique (food_name, state_id),
    constraint chk_heritage_food_id_format
        check (heritage_food_id ~ '^HF[0-9]{4}$')
);

-- ============================================================================
-- 4. ARTWORK AND HERITAGE TIFFIN
-- There is no artists table. The artwork creator is a normal profile.
-- ============================================================================

create table public.artworks (
    artwork_id          varchar(5) primary key,
    profile_id          varchar(5) not null references public.profiles(profile_id),
    source_artwork_submission_id varchar(6) unique,
    title               varchar(150) not null,
    description         text,
    artwork_meaning     text,
    cultural_inspiration text,
    image_url           text not null,
    status              varchar(20) not null default 'published'
                        check (status in ('draft', 'published', 'inactive')),
    created_at          timestamptz not null default now(),
    updated_at          timestamptz not null default now(),

    constraint chk_artwork_id_format
        check (artwork_id ~ '^A[0-9]{4}$')
);

create table public.heritage_tiffins (
    heritage_tiffin_id  varchar(6) primary key,
    edition_name        varchar(150) not null unique,
    state_id            varchar(5) not null references public.states(state_id),
    heritage_food_id    varchar(6) not null references public.heritage_foods(heritage_food_id),
    artwork_id          varchar(5) not null references public.artworks(artwork_id),
    description         text,
    cultural_significance text,
    cover_image_url     text,
    release_year        integer,
    status              varchar(20) not null default 'active'
                        check (status in ('draft', 'active', 'inactive')),
    created_at          timestamptz not null default now(),
    updated_at          timestamptz not null default now(),

    constraint chk_heritage_tiffin_id_format
        check (heritage_tiffin_id ~ '^HT[0-9]{4}$')
);

create table public.heritage_stories (
    heritage_story_id  varchar(6) primary key,
    heritage_tiffin_id varchar(6) not null references public.heritage_tiffins(heritage_tiffin_id) on delete cascade,
    title               varchar(180) not null,
    story_body          text not null,
    image_url           text,
    sort_order          integer not null default 1,
    is_published        boolean not null default true,

    constraint chk_heritage_story_id_format
        check (heritage_story_id ~ '^HS[0-9]{4}$')
);

create table public.heritage_media (
    heritage_media_id  varchar(6) primary key,
    heritage_tiffin_id varchar(6) not null references public.heritage_tiffins(heritage_tiffin_id) on delete cascade,
    media_type         varchar(20) not null
                       check (media_type in ('image', 'video', 'audio')),
    title              varchar(180) not null,
    media_url          text not null,
    thumbnail_url      text,
    caption            text,
    duration_seconds   integer,
    sort_order         integer not null default 1,
    is_published       boolean not null default true,

    constraint chk_heritage_media_id_format
        check (heritage_media_id ~ '^HM[0-9]{4}$')
);

create table public.tiffin_qr_codes (
    tiffin_qr_code_id  varchar(7) primary key,
    heritage_tiffin_id varchar(6) not null references public.heritage_tiffins(heritage_tiffin_id) on delete cascade,
    code_value         text not null unique,
    is_active          boolean not null default true,
    generated_at       timestamptz not null default now(),
    expires_at         timestamptz,

    constraint chk_tiffin_qr_code_id_format
        check (tiffin_qr_code_id ~ '^TQC[0-9]{4}$')
);

create table public.user_tiffin_collection (
    user_tiffin_collection_id varchar(7) primary key,
    profile_id          varchar(5) not null references public.profiles(profile_id) on delete cascade,
    heritage_tiffin_id  varchar(6) not null references public.heritage_tiffins(heritage_tiffin_id),
    tiffin_qr_code_id   varchar(7) not null references public.tiffin_qr_codes(tiffin_qr_code_id),
    collected_at        timestamptz not null default now(),

    constraint uq_user_tiffin unique (profile_id, heritage_tiffin_id),
    constraint chk_user_tiffin_collection_id_format
        check (user_tiffin_collection_id ~ '^UTC[0-9]{4}$')
);

-- ============================================================================
-- 5. PASAR MALAM AND VENDORS
-- ============================================================================

create table public.pasar_malam (
    pasar_malam_id     varchar(6) primary key,
    state_id           varchar(5) not null references public.states(state_id),
    pasar_malam_name   varchar(150) not null,
    description        text,
    address_line       text not null,
    latitude           numeric(10,7) not null,
    longitude          numeric(10,7) not null,
    google_place_id    text,
    is_active          boolean not null default true,

    constraint uq_pasar_malam unique (pasar_malam_name, address_line),
    constraint chk_pasar_malam_id_format
        check (pasar_malam_id ~ '^PM[0-9]{4}$')
);

create table public.pasar_malam_operating_hours (
    pasar_malam_operating_hours_id varchar(8) primary key,
    pasar_malam_id      varchar(6) not null references public.pasar_malam(pasar_malam_id) on delete cascade,
    day_of_week         smallint not null check (day_of_week between 0 and 6),
    opening_time        time,
    closing_time        time,
    is_closed           boolean not null default false,

    constraint uq_pasar_malam_hours unique (pasar_malam_id, day_of_week),
    constraint chk_pasar_malam_hours_id_format
        check (pasar_malam_operating_hours_id ~ '^PMOH[0-9]{4}$')
);

create table public.vendors (
    vendor_id           varchar(5) primary key,
    pasar_malam_id      varchar(6) references public.pasar_malam(pasar_malam_id),
    state_id            varchar(5) not null references public.states(state_id),
    vendor_name         varchar(150) not null,
    business_type       varchar(30) not null
                        check (business_type in ('restaurant', 'cafe', 'food_stall', 'night_market_stall')),
    description         text,
    contact_person      varchar(100),
    contact_number      varchar(30),
    email               varchar(150),
    address_line        text not null,
    latitude            numeric(10,7) not null,
    longitude           numeric(10,7) not null,
    google_place_id     text,
    cover_image_url     text,
    participation_status varchar(20) not null default 'active'
                         check (participation_status in ('pending', 'active', 'inactive')),
    average_rating      numeric(3,2) not null default 0 check (average_rating between 0 and 5),
    review_count        integer not null default 0 check (review_count >= 0),
    created_at          timestamptz not null default now(),
    updated_at          timestamptz not null default now(),

    constraint uq_vendor unique (vendor_name, address_line),
    constraint chk_vendor_id_format
        check (vendor_id ~ '^V[0-9]{4}$')
);

create table public.vendor_operating_hours (
    vendor_operating_hours_id varchar(7) primary key,
    vendor_id           varchar(5) not null references public.vendors(vendor_id) on delete cascade,
    day_of_week         smallint not null check (day_of_week between 0 and 6),
    opening_time        time,
    closing_time        time,
    is_closed           boolean not null default false,

    constraint uq_vendor_hours unique (vendor_id, day_of_week),
    constraint chk_vendor_hours_id_format
        check (vendor_operating_hours_id ~ '^VOH[0-9]{4}$')
);

create table public.vendor_foods (
    vendor_food_id      varchar(6) primary key,
    vendor_id           varchar(5) not null references public.vendors(vendor_id) on delete cascade,
    heritage_food_id    varchar(6) not null references public.heritage_foods(heritage_food_id),
    is_featured         boolean not null default false,

    constraint uq_vendor_food unique (vendor_id, heritage_food_id),
    constraint chk_vendor_food_id_format
        check (vendor_food_id ~ '^VF[0-9]{4}$')
);

create table public.vendor_tiffin_availability (
    vendor_tiffin_availability_id varchar(7) primary key,
    vendor_id           varchar(5) not null references public.vendors(vendor_id) on delete cascade,
    heritage_tiffin_id  varchar(6) not null references public.heritage_tiffins(heritage_tiffin_id),
    quantity_available  integer not null default 0 check (quantity_available >= 0),
    availability_status varchar(20) not null default 'available'
                        check (availability_status in ('available', 'low_stock', 'unavailable')),
    updated_at          timestamptz not null default now(),

    constraint uq_vendor_tiffin unique (vendor_id, heritage_tiffin_id),
    constraint chk_vendor_tiffin_availability_id_format
        check (vendor_tiffin_availability_id ~ '^VTA[0-9]{4}$')
);

-- ============================================================================
-- 6. HERITAGE COMMUNITY
-- ============================================================================

create table public.community_posts (
    community_post_id  varchar(6) primary key,
    profile_id         varchar(5) not null references public.profiles(profile_id),
    vendor_id          varchar(5) not null references public.vendors(vendor_id),
    rating             smallint not null check (rating between 1 and 5),
    written_review     text not null,
    post_comment       text,
    status             varchar(20) not null default 'published'
                       check (status in ('draft', 'published', 'hidden')),
    like_count         integer not null default 0,
    comment_count      integer not null default 0,
    created_at         timestamptz not null default now(),
    updated_at         timestamptz not null default now(),

    constraint chk_community_post_id_format
        check (community_post_id ~ '^CP[0-9]{4}$')
);

create table public.community_post_photos (
    community_post_photo_id varchar(7) primary key,
    community_post_id varchar(6) not null references public.community_posts(community_post_id) on delete cascade,
    photo_url           text not null,
    sort_order          integer not null default 1,

    constraint chk_community_post_photo_id_format
        check (community_post_photo_id ~ '^CPP[0-9]{4}$')
);

create table public.community_post_likes (
    community_post_like_id varchar(7) primary key,
    community_post_id varchar(6) not null references public.community_posts(community_post_id) on delete cascade,
    profile_id         varchar(5) not null references public.profiles(profile_id) on delete cascade,
    created_at         timestamptz not null default now(),

    constraint uq_community_post_like unique (community_post_id, profile_id),
    constraint chk_community_post_like_id_format
        check (community_post_like_id ~ '^CPL[0-9]{4}$')
);

create table public.community_comments (
    community_comment_id varchar(6) primary key,
    community_post_id varchar(6) not null references public.community_posts(community_post_id) on delete cascade,
    profile_id         varchar(5) not null references public.profiles(profile_id),
    parent_comment_id  varchar(6) references public.community_comments(community_comment_id) on delete cascade,
    comment_text       text not null,
    status             varchar(20) not null default 'published'
                       check (status in ('published', 'hidden')),
    created_at         timestamptz not null default now(),

    constraint chk_community_comment_id_format
        check (community_comment_id ~ '^CC[0-9]{4}$')
);

-- ============================================================================
-- 7. ARTWORK CAMPAIGN AND VOTING
-- ============================================================================

create table public.artwork_campaigns (
    artwork_campaign_id varchar(6) primary key,
    campaign_title      varchar(180) not null,
    description         text,
    submission_start_at timestamptz not null,
    submission_end_at   timestamptz not null,
    status              varchar(30) not null
                        check (status in ('draft', 'open_submission', 'voting', 'completed', 'cancelled')),
    created_by_profile_id varchar(5) not null references public.profiles(profile_id),
    created_at          timestamptz not null default now(),

    constraint chk_campaign_dates check (submission_end_at > submission_start_at),
    constraint chk_artwork_campaign_id_format
        check (artwork_campaign_id ~ '^AC[0-9]{4}$')
);

create table public.artwork_campaign_categories (
    artwork_campaign_category_id varchar(7) primary key,
    artwork_campaign_id varchar(6) not null references public.artwork_campaigns(artwork_campaign_id) on delete cascade,
    state_id            varchar(5) not null references public.states(state_id),
    category_name       varchar(150) not null,

    constraint uq_campaign_category unique (artwork_campaign_id, state_id),
    constraint chk_artwork_campaign_category_id_format
        check (artwork_campaign_category_id ~ '^ACC[0-9]{4}$')
);

create table public.artwork_submissions (
    artwork_submission_id varchar(6) primary key,
    artwork_campaign_category_id varchar(7) not null references public.artwork_campaign_categories(artwork_campaign_category_id),
    profile_id          varchar(5) not null references public.profiles(profile_id),
    artwork_title       varchar(180) not null,
    design_description  text not null,
    cultural_inspiration text,
    artist_statement    text,
    artwork_file_url    text not null,
    review_status       varchar(20) not null default 'pending'
                        check (review_status in ('pending', 'approved', 'rejected')),
    submitted_at        timestamptz not null default now(),
    reviewed_by_profile_id varchar(5) references public.profiles(profile_id),
    reviewed_at         timestamptz,

    constraint chk_artwork_submission_id_format
        check (artwork_submission_id ~ '^AS[0-9]{4}$')
);

create table public.artwork_voting_sessions (
    artwork_voting_session_id varchar(7) primary key,
    artwork_campaign_id varchar(6) not null references public.artwork_campaigns(artwork_campaign_id) on delete cascade,
    session_type       varchar(20) not null default 'standard'
                       check (session_type in ('standard', 'tie_break')),
    parent_voting_session_id varchar(7)
                       references public.artwork_voting_sessions(artwork_voting_session_id),
    voting_start_at    timestamptz not null,
    voting_end_at      timestamptz not null,
    status             varchar(20) not null
                       check (status in ('scheduled', 'active', 'closed')),

    constraint chk_voting_dates check (voting_end_at > voting_start_at),
    constraint chk_tie_break_parent check (
        (session_type = 'standard' and parent_voting_session_id is null)
        or
        (session_type = 'tie_break' and parent_voting_session_id is not null)
    ),
    constraint chk_artwork_voting_session_id_format
        check (artwork_voting_session_id ~ '^AVS[0-9]{4}$')
);

create table public.artwork_voting_entries (
    artwork_voting_entry_id varchar(7) primary key,
    artwork_voting_session_id varchar(7) not null references public.artwork_voting_sessions(artwork_voting_session_id) on delete cascade,
    artwork_campaign_category_id varchar(7) not null references public.artwork_campaign_categories(artwork_campaign_category_id),
    artwork_submission_id varchar(6) not null references public.artwork_submissions(artwork_submission_id),
    vote_count          integer not null default 0,
    published_at       timestamptz not null default now(),

    constraint uq_voting_entry unique (artwork_voting_session_id, artwork_submission_id),
    constraint chk_artwork_voting_entry_id_format
        check (artwork_voting_entry_id ~ '^AVE[0-9]{4}$')
);

create table public.artwork_votes (
    artwork_vote_id     varchar(6) primary key,
    artwork_voting_session_id varchar(7) not null references public.artwork_voting_sessions(artwork_voting_session_id),
    artwork_campaign_category_id varchar(7) not null references public.artwork_campaign_categories(artwork_campaign_category_id),
    artwork_voting_entry_id varchar(7) not null references public.artwork_voting_entries(artwork_voting_entry_id),
    profile_id          varchar(5) not null references public.profiles(profile_id),
    voted_at            timestamptz not null default now(),

    constraint uq_one_vote_per_category
        unique (artwork_voting_session_id, artwork_campaign_category_id, profile_id),
    constraint chk_artwork_vote_id_format
        check (artwork_vote_id ~ '^AV[0-9]{4}$')
);

create table public.artwork_campaign_winners (
    artwork_campaign_winner_id varchar(7) primary key,
    artwork_campaign_id varchar(6) not null references public.artwork_campaigns(artwork_campaign_id),
    artwork_campaign_category_id varchar(7) not null references public.artwork_campaign_categories(artwork_campaign_category_id),
    artwork_voting_entry_id varchar(7) not null references public.artwork_voting_entries(artwork_voting_entry_id),
    artwork_id          varchar(5) unique references public.artworks(artwork_id),
    final_vote_count    integer not null default 0,
    final_rank          integer not null default 1,
    announced_by_profile_id varchar(5) not null references public.profiles(profile_id),
    announced_at       timestamptz not null default now(),

    constraint uq_campaign_winner unique (artwork_campaign_id, artwork_campaign_category_id),
    constraint chk_artwork_campaign_winner_id_format
        check (artwork_campaign_winner_id ~ '^ACW[0-9]{4}$')
);

alter table public.artworks
    add constraint fk_artwork_source_submission
    foreign key (source_artwork_submission_id)
    references public.artwork_submissions(artwork_submission_id);

-- Server-generated IDs for user-created records. P0001-style seed IDs remain
-- deterministic, while live records begin at 1000 and never require clients to
-- scan other users' rows to calculate a primary key.
create sequence public.user_tiffin_collection_number_seq start 1000;
create sequence public.community_post_number_seq start 1000;
create sequence public.community_post_photo_number_seq start 1000;
create sequence public.community_post_like_number_seq start 1000;
create sequence public.community_comment_number_seq start 1000;
create sequence public.artwork_submission_number_seq start 1000;
create sequence public.artwork_vote_number_seq start 1000;

alter table public.user_tiffin_collection
alter column user_tiffin_collection_id
set default ('UTC' || lpad(nextval('public.user_tiffin_collection_number_seq')::text, 4, '0'));

alter table public.community_posts
alter column community_post_id
set default ('CP' || lpad(nextval('public.community_post_number_seq')::text, 4, '0'));

alter table public.community_post_photos
alter column community_post_photo_id
set default ('CPP' || lpad(nextval('public.community_post_photo_number_seq')::text, 4, '0'));

alter table public.community_post_likes
alter column community_post_like_id
set default ('CPL' || lpad(nextval('public.community_post_like_number_seq')::text, 4, '0'));

alter table public.community_comments
alter column community_comment_id
set default ('CC' || lpad(nextval('public.community_comment_number_seq')::text, 4, '0'));

alter table public.artwork_submissions
alter column artwork_submission_id
set default ('AS' || lpad(nextval('public.artwork_submission_number_seq')::text, 4, '0'));

alter table public.artwork_votes
alter column artwork_vote_id
set default ('AV' || lpad(nextval('public.artwork_vote_number_seq')::text, 4, '0'));

-- ============================================================================
-- 8. ROW LEVEL SECURITY (RLS)
-- Auth users are represented by profiles.auth_user_id. Seed/demo profiles have
-- a NULL auth_user_id and are exposed publicly only through public_profiles.
-- ============================================================================

create or replace function public.current_profile_id()
returns varchar(5)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
    select profile_id
    from public.profiles
    where auth_user_id = auth.uid()
      and is_active = true
    limit 1
$$;

revoke all on function public.current_profile_id() from public;
grant execute on function public.current_profile_id() to authenticated;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
    select exists (
        select 1
        from public.profiles
        where auth_user_id = auth.uid()
          and role = 'admin'
          and is_active = true
    )
$$;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;

create or replace function public.is_registered_user()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
    select exists (
        select 1
        from public.profiles
        where auth_user_id = auth.uid()
          and role = 'tourist'
          and is_active = true
    )
$$;

revoke all on function public.is_registered_user() from public;
grant execute on function public.is_registered_user() to authenticated;

create or replace function public.is_valid_reply_parent(
    requested_parent_id varchar(6),
    requested_post_id varchar(6)
)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
    select requested_parent_id is null or exists (
        select 1 from public.community_comments parent_comment
        where parent_comment.community_comment_id = requested_parent_id
          and parent_comment.community_post_id = requested_post_id
          and parent_comment.parent_comment_id is null
          and parent_comment.status = 'published'
    )
$$;

revoke all on function public.is_valid_reply_parent(varchar, varchar) from public;
grant execute on function public.is_valid_reply_parent(varchar, varchar) to authenticated;

-- Recreate profiles for Auth users that existed before this reset. Real
-- accounts use P1000+; P0001-P0999 remain available for deterministic seeds.
select setval(
    'public.profile_number_seq',
    greatest(
        1000,
        coalesce(
            (select max(substring(profile_id from 2)::integer) + 1
             from public.profiles),
            1000
        )
    ),
    false
);

insert into public.profiles (
    profile_id, auth_user_id, role, display_name, country_code, city,
    date_of_birth, gender
)
select
    'P' || lpad(nextval('public.profile_number_seq')::text, 4, '0'),
    users.id,
    'tourist',
    left(coalesce(
        nullif(trim(users.raw_user_meta_data ->> 'display_name'), ''),
        split_part(coalesce(users.email, 'Tourist'), '@', 1)
    ), 80),
    nullif(left(upper(users.raw_user_meta_data ->> 'country_code'), 2), ''),
    nullif(trim(users.raw_user_meta_data ->> 'city'), ''),
    case
        when coalesce(users.raw_user_meta_data ->> 'date_of_birth', '')
             ~ '^\d{4}-\d{2}-\d{2}$'
        then (users.raw_user_meta_data ->> 'date_of_birth')::date
    end,
    case
        when lower(users.raw_user_meta_data ->> 'gender') in (
            'male', 'female', 'non_binary', 'prefer_not_to_say', 'other'
        ) then lower(users.raw_user_meta_data ->> 'gender')
    end
from auth.users users
where not exists (
    select 1 from public.profiles profiles
    where profiles.auth_user_id = users.id
)
order by users.created_at;

-- Denormalized counters are database-owned so clients never need broad update
-- access to community posts or artwork entries.
create or replace function public.sync_community_post_like_count()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    target_post_id varchar(6);
begin
    target_post_id := case
        when tg_op = 'DELETE' then old.community_post_id
        else new.community_post_id
    end;
    update public.community_posts
    set like_count = (
        select count(*) from public.community_post_likes likes
        where likes.community_post_id = target_post_id
    )
    where community_post_id = target_post_id;
    return null;
end;
$$;

create trigger sync_community_post_like_count_trigger
after insert or delete on public.community_post_likes
for each row execute function public.sync_community_post_like_count();

create or replace function public.sync_community_post_comment_count()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
    if tg_op <> 'INSERT' then
        update public.community_posts
        set comment_count = (
            select count(*) from public.community_comments comments
            where comments.community_post_id = old.community_post_id
              and comments.status = 'published'
        )
        where community_post_id = old.community_post_id;
    end if;
    if tg_op <> 'DELETE' then
        update public.community_posts
        set comment_count = (
            select count(*) from public.community_comments comments
            where comments.community_post_id = new.community_post_id
              and comments.status = 'published'
        )
        where community_post_id = new.community_post_id;
    end if;
    return null;
end;
$$;

create trigger sync_community_post_comment_count_trigger
after insert or delete or update of community_post_id, status
on public.community_comments
for each row execute function public.sync_community_post_comment_count();

create or replace function public.sync_artwork_voting_entry_vote_count()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
    if tg_op <> 'INSERT' then
        update public.artwork_voting_entries
        set vote_count = (
            select count(*) from public.artwork_votes votes
            where votes.artwork_voting_entry_id = old.artwork_voting_entry_id
        )
        where artwork_voting_entry_id = old.artwork_voting_entry_id;
    end if;
    if tg_op <> 'DELETE' then
        update public.artwork_voting_entries
        set vote_count = (
            select count(*) from public.artwork_votes votes
            where votes.artwork_voting_entry_id = new.artwork_voting_entry_id
        )
        where artwork_voting_entry_id = new.artwork_voting_entry_id;
    end if;
    return null;
end;
$$;

create trigger sync_artwork_voting_entry_vote_count_trigger
after insert or delete or update of artwork_voting_entry_id
on public.artwork_votes
for each row execute function public.sync_artwork_voting_entry_vote_count();

alter table public.profiles enable row level security;
alter table public.states enable row level security;
alter table public.food_categories enable row level security;
alter table public.heritage_foods enable row level security;
alter table public.artworks enable row level security;
alter table public.heritage_tiffins enable row level security;
alter table public.heritage_stories enable row level security;
alter table public.heritage_media enable row level security;
alter table public.tiffin_qr_codes enable row level security;
alter table public.user_tiffin_collection enable row level security;
alter table public.pasar_malam enable row level security;
alter table public.pasar_malam_operating_hours enable row level security;
alter table public.vendors enable row level security;
alter table public.vendor_operating_hours enable row level security;
alter table public.vendor_foods enable row level security;
alter table public.vendor_tiffin_availability enable row level security;
alter table public.community_posts enable row level security;
alter table public.community_post_photos enable row level security;
alter table public.community_post_likes enable row level security;
alter table public.community_comments enable row level security;
alter table public.artwork_campaigns enable row level security;
alter table public.artwork_campaign_categories enable row level security;
alter table public.artwork_submissions enable row level security;
alter table public.artwork_voting_sessions enable row level security;
alter table public.artwork_voting_entries enable row level security;
alter table public.artwork_votes enable row level security;
alter table public.artwork_campaign_winners enable row level security;

-- Full profiles are private to their linked Auth user.
create policy profiles_own_read on public.profiles
for select to authenticated
using (auth_user_id = auth.uid());

create policy profiles_own_update on public.profiles
for update to authenticated
using (auth_user_id = auth.uid())
with check (auth_user_id = auth.uid());

create policy profiles_admin_read on public.profiles
for select to authenticated
using (public.is_admin());

-- Public/reference heritage content.
create policy states_public_read on public.states
for select to anon, authenticated using (is_active = true);

create policy food_categories_public_read on public.food_categories
for select to anon, authenticated using (is_active = true);

create policy heritage_foods_public_read on public.heritage_foods
for select to anon, authenticated using (is_active = true);

create policy artworks_public_read on public.artworks
for select to anon, authenticated using (status = 'published');

create policy heritage_tiffins_public_read on public.heritage_tiffins
for select to anon, authenticated using (status = 'active');

create policy heritage_stories_public_read on public.heritage_stories
for select to anon, authenticated
using (
    is_published = true
    and exists (
        select 1 from public.heritage_tiffins tiffins
        where tiffins.heritage_tiffin_id = heritage_stories.heritage_tiffin_id
          and tiffins.status = 'active'
    )
);

create policy heritage_media_public_read on public.heritage_media
for select to anon, authenticated
using (
    is_published = true
    and exists (
        select 1 from public.heritage_tiffins tiffins
        where tiffins.heritage_tiffin_id = heritage_media.heritage_tiffin_id
          and tiffins.status = 'active'
    )
);

create policy tiffin_qr_authenticated_read on public.tiffin_qr_codes
for select to authenticated
using (
    is_active = true
    and (expires_at is null or expires_at > now())
);

create policy collection_own_read on public.user_tiffin_collection
for select to authenticated
using (profile_id = public.current_profile_id());

create policy collection_own_insert on public.user_tiffin_collection
for insert to authenticated
with check (
    profile_id = public.current_profile_id()
    and exists (
        select 1 from public.tiffin_qr_codes qr
        where qr.tiffin_qr_code_id = user_tiffin_collection.tiffin_qr_code_id
          and qr.heritage_tiffin_id = user_tiffin_collection.heritage_tiffin_id
          and qr.is_active = true
          and (qr.expires_at is null or qr.expires_at > now())
    )
);

-- Map and vendor content.
create policy pasar_malam_public_read on public.pasar_malam
for select to anon, authenticated using (is_active = true);

create policy pasar_malam_hours_public_read
on public.pasar_malam_operating_hours
for select to anon, authenticated
using (
    exists (
        select 1 from public.pasar_malam markets
        where markets.pasar_malam_id = pasar_malam_operating_hours.pasar_malam_id
          and markets.is_active = true
    )
);

create policy vendors_public_read on public.vendors
for select to anon, authenticated
using (participation_status = 'active');

create policy vendor_hours_public_read on public.vendor_operating_hours
for select to anon, authenticated
using (
    exists (
        select 1 from public.vendors parent_vendor
        where parent_vendor.vendor_id = vendor_operating_hours.vendor_id
          and parent_vendor.participation_status = 'active'
    )
);

create policy vendor_foods_public_read on public.vendor_foods
for select to anon, authenticated
using (
    exists (
        select 1 from public.vendors parent_vendor
        where parent_vendor.vendor_id = vendor_foods.vendor_id
          and parent_vendor.participation_status = 'active'
    )
);

create policy vendor_tiffin_public_read on public.vendor_tiffin_availability
for select to anon, authenticated
using (
    exists (
        select 1 from public.vendors parent_vendor
        where parent_vendor.vendor_id = vendor_tiffin_availability.vendor_id
          and parent_vendor.participation_status = 'active'
    )
);

-- Community content and user-owned writes.
create policy community_posts_public_read on public.community_posts
for select to anon, authenticated using (status = 'published');

create policy community_posts_own_insert on public.community_posts
for insert to authenticated
with check (
    profile_id = public.current_profile_id()
    and status in ('draft', 'published')
    and exists (
        select 1 from public.vendors selected_vendor
        where selected_vendor.vendor_id = community_posts.vendor_id
          and selected_vendor.participation_status = 'active'
    )
);

create policy community_posts_own_update on public.community_posts
for update to authenticated
using (profile_id = public.current_profile_id())
with check (profile_id = public.current_profile_id());

create policy community_posts_own_delete on public.community_posts
for delete to authenticated
using (profile_id = public.current_profile_id());

create policy community_photos_public_read on public.community_post_photos
for select to anon, authenticated
using (
    exists (
        select 1 from public.community_posts posts
        where posts.community_post_id = community_post_photos.community_post_id
          and posts.status = 'published'
    )
);

create policy community_photos_own_insert on public.community_post_photos
for insert to authenticated
with check (
    exists (
        select 1 from public.community_posts posts
        where posts.community_post_id = community_post_photos.community_post_id
          and posts.profile_id = public.current_profile_id()
    )
);

create policy community_likes_authenticated_read
on public.community_post_likes
for select to authenticated
using (
    exists (
        select 1 from public.community_posts posts
        where posts.community_post_id = community_post_likes.community_post_id
          and posts.status = 'published'
    )
);

create policy community_likes_own_insert on public.community_post_likes
for insert to authenticated
with check (
    profile_id = public.current_profile_id()
    and exists (
        select 1 from public.community_posts posts
        where posts.community_post_id = community_post_likes.community_post_id
          and posts.status = 'published'
    )
);

create policy community_likes_own_delete on public.community_post_likes
for delete to authenticated
using (profile_id = public.current_profile_id());

create policy community_comments_public_read on public.community_comments
for select to anon, authenticated
using (
    status = 'published'
    and exists (
        select 1 from public.community_posts posts
        where posts.community_post_id = community_comments.community_post_id
          and posts.status = 'published'
    )
);

create policy community_comments_own_insert on public.community_comments
for insert to authenticated
with check (
    profile_id = public.current_profile_id()
    and status = 'published'
    and exists (
        select 1 from public.community_posts posts
        where posts.community_post_id = community_comments.community_post_id
          and posts.status = 'published'
    )
    and public.is_valid_reply_parent(parent_comment_id, community_post_id)
);

-- Artwork campaign reads and user-owned participation.
create policy campaigns_public_read on public.artwork_campaigns
for select to anon, authenticated
using (status in ('open_submission', 'voting', 'completed'));

create policy campaign_categories_public_read
on public.artwork_campaign_categories
for select to anon, authenticated
using (
    exists (
        select 1 from public.artwork_campaigns campaigns
        where campaigns.artwork_campaign_id = artwork_campaign_categories.artwork_campaign_id
          and campaigns.status in ('open_submission', 'voting', 'completed')
    )
);

create policy submissions_public_read on public.artwork_submissions
for select to anon, authenticated
using (review_status = 'approved');

create policy submissions_own_read on public.artwork_submissions
for select to authenticated
using (profile_id = public.current_profile_id());

create policy submissions_own_insert on public.artwork_submissions
for insert to authenticated
with check (
    profile_id = public.current_profile_id()
    and public.is_registered_user()
    and review_status = 'pending'
    and exists (
        select 1
        from public.artwork_campaign_categories categories
        join public.artwork_campaigns campaigns
          on campaigns.artwork_campaign_id = categories.artwork_campaign_id
        where categories.artwork_campaign_category_id = artwork_submissions.artwork_campaign_category_id
          and campaigns.status = 'open_submission'
          and now() between campaigns.submission_start_at
                        and campaigns.submission_end_at
    )
);

create policy voting_sessions_public_read on public.artwork_voting_sessions
for select to anon, authenticated
using (
    exists (
        select 1 from public.artwork_campaigns campaigns
        where campaigns.artwork_campaign_id = artwork_voting_sessions.artwork_campaign_id
          and campaigns.status in ('voting', 'completed')
    )
);

create policy voting_entries_public_read on public.artwork_voting_entries
for select to anon, authenticated
using (
    exists (
        select 1 from public.artwork_submissions submissions
        where submissions.artwork_submission_id = artwork_voting_entries.artwork_submission_id
          and submissions.review_status = 'approved'
    )
);

create policy artwork_votes_own_read on public.artwork_votes
for select to authenticated
using (profile_id = public.current_profile_id());

create policy artwork_votes_own_insert on public.artwork_votes
for insert to authenticated
with check (
    profile_id = public.current_profile_id()
    and public.is_registered_user()
    and exists (
        select 1 from public.artwork_voting_entries entries
        join public.artwork_voting_sessions sessions
          on sessions.artwork_voting_session_id = entries.artwork_voting_session_id
        where entries.artwork_voting_entry_id = artwork_votes.artwork_voting_entry_id
          and entries.artwork_voting_session_id = artwork_votes.artwork_voting_session_id
          and entries.artwork_campaign_category_id = artwork_votes.artwork_campaign_category_id
          and sessions.status = 'active'
          and now() between sessions.voting_start_at and sessions.voting_end_at
    )
);

create policy campaign_winners_public_read
on public.artwork_campaign_winners
for select to anon, authenticated
using (
    exists (
        select 1 from public.artwork_campaigns campaigns
        where campaigns.artwork_campaign_id = artwork_campaign_winners.artwork_campaign_id
          and campaigns.status = 'completed'
    )
);

-- An authenticated administrator has access to every management function in
-- the admin portal. Registered users retain only their public and own-record
-- policies above; there is no separate per-feature permission model.
create policy admin_artworks_manage on public.artworks
for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy admin_tiffins_manage on public.heritage_tiffins
for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy admin_tiffin_stories_manage on public.heritage_stories
for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy admin_tiffin_media_manage on public.heritage_media
for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy admin_tiffin_qr_codes_manage on public.tiffin_qr_codes
for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy admin_vendors_manage on public.vendors
for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy admin_vendor_hours_manage on public.vendor_operating_hours
for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy admin_vendor_foods_manage on public.vendor_foods
for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy admin_vendor_tiffins_manage on public.vendor_tiffin_availability
for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy admin_campaigns_manage on public.artwork_campaigns
for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy admin_campaign_categories_manage on public.artwork_campaign_categories
for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy admin_submissions_manage on public.artwork_submissions
for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy admin_voting_sessions_manage on public.artwork_voting_sessions
for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy admin_voting_entries_manage on public.artwork_voting_entries
for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy admin_votes_read on public.artwork_votes
for select to authenticated using (public.is_admin());

create policy admin_campaign_winners_manage on public.artwork_campaign_winners
for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- ============================================================================
-- 9. SIMPLE VIEWS
-- ============================================================================

create view public.public_profiles
with (security_barrier = true) as
select
    profile_id,
    display_name,
    avatar_url,
    biography,
    website_url
from public.profiles
where is_active = true;

create view public.v_collection_progress
with (security_invoker = true) as
select
    p.profile_id,
    count(distinct utc.heritage_tiffin_id) as collected_count,
    count(distinct ht.heritage_tiffin_id) as total_active_tiffins,
    case
        when count(distinct ht.heritage_tiffin_id) = 0 then 0
        else round(
            count(distinct utc.heritage_tiffin_id)::numeric
            / count(distinct ht.heritage_tiffin_id)::numeric * 100,
            2
        )
    end as collection_percentage
from public.profiles p
cross join public.heritage_tiffins ht
left join public.user_tiffin_collection utc
    on utc.profile_id = p.profile_id
   and utc.heritage_tiffin_id = ht.heritage_tiffin_id
where ht.status = 'active'
group by p.profile_id;

create view public.v_artwork_rankings
with (security_invoker = true) as
select
    ave.artwork_voting_entry_id,
    ave.artwork_voting_session_id,
    ave.artwork_campaign_category_id,
    ave.artwork_submission_id,
    ave.vote_count,
    dense_rank() over (
        partition by ave.artwork_voting_session_id, ave.artwork_campaign_category_id
        order by ave.vote_count desc, ave.published_at asc
    ) as ranking
from public.artwork_voting_entries ave;

-- PostgREST privileges. RLS remains the row-level authority.
revoke all on public.profiles from anon, authenticated;
grant select on public.profiles to authenticated;
grant update (
    display_name, avatar_url, biography, website_url, country_code, city,
    date_of_birth, gender, updated_at
) on public.profiles to authenticated;

grant select on public.states, public.food_categories, public.heritage_foods,
    public.artworks, public.heritage_tiffins, public.heritage_stories,
    public.heritage_media, public.pasar_malam,
    public.pasar_malam_operating_hours, public.vendors,
    public.vendor_operating_hours, public.vendor_foods,
    public.vendor_tiffin_availability, public.community_posts,
    public.community_post_photos, public.community_comments,
    public.artwork_campaigns, public.artwork_campaign_categories,
    public.artwork_submissions, public.artwork_voting_sessions,
    public.artwork_voting_entries, public.artwork_campaign_winners
to anon, authenticated;

grant select on public.tiffin_qr_codes, public.user_tiffin_collection,
    public.community_post_likes, public.artwork_votes
to authenticated;

grant insert on public.user_tiffin_collection, public.community_posts,
    public.community_post_photos, public.community_post_likes,
    public.community_comments, public.artwork_submissions,
    public.artwork_votes
to authenticated;

grant delete on public.community_posts, public.community_post_likes
to authenticated;

grant update (rating, written_review, post_comment, status, updated_at)
on public.community_posts to authenticated;

grant insert, update, delete on public.artworks, public.heritage_tiffins,
    public.heritage_stories, public.heritage_media, public.tiffin_qr_codes,
    public.vendors, public.vendor_operating_hours, public.vendor_foods,
    public.vendor_tiffin_availability, public.artwork_campaigns,
    public.artwork_campaign_categories, public.artwork_submissions,
    public.artwork_voting_sessions, public.artwork_voting_entries,
    public.artwork_campaign_winners
to authenticated;

revoke all on public.public_profiles, public.v_collection_progress,
    public.v_artwork_rankings from public;
grant select on public.public_profiles to anon, authenticated;
grant select on public.v_artwork_rankings to anon, authenticated;
grant select on public.v_collection_progress to authenticated;

grant usage, select on public.user_tiffin_collection_number_seq,
    public.community_post_number_seq,
    public.community_post_photo_number_seq,
    public.community_post_like_number_seq,
    public.community_comment_number_seq,
    public.artwork_submission_number_seq,
    public.artwork_vote_number_seq
to authenticated;

do $$
begin
    if exists (
        select 1 from auth.users users
        left join public.profiles profiles on profiles.auth_user_id = users.id
        where profiles.profile_id is null
    ) then
        raise exception 'Profile backfill failed: one or more Auth users are orphaned';
    end if;
end;
$$;

notify pgrst, 'reload schema';
commit;
