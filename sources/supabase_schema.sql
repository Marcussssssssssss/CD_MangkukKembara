-- ============================================================================
-- MangkukKembara - Database Reset and Create Script
-- PostgreSQL / Supabase
--
-- Run this file when the database structure changes.
-- It drops the existing application tables and recreates them from zero.
-- Supabase-managed auth.users is NOT dropped.
-- ============================================================================

begin;

-- Supabase Cron uses pg_cron. The scheduled job is installed near the end of
-- this script after all campaign functions and triggers have been created.
create extension if not exists pg_cron;

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
drop table if exists public.artwork_submission_photos cascade;
drop table if exists public.artwork_submissions cascade;
drop table if exists public.artwork_campaign_categories cascade;
drop table if exists public.artwork_campaigns cascade;

drop table if exists public.community_comments cascade;
drop table if exists public.community_post_likes cascade;
drop table if exists public.community_post_photos cascade;
drop table if exists public.community_posts cascade;

drop table if exists public.vendor_tiffins cascade;
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
drop sequence if exists public.heritage_tiffin_number_seq cascade;
drop sequence if exists public.heritage_story_number_seq cascade;
drop sequence if exists public.heritage_media_number_seq cascade;
drop sequence if exists public.tiffin_qr_code_number_seq cascade;
drop sequence if exists public.heritage_tiffin_id_seq cascade;
drop sequence if exists public.heritage_story_id_seq cascade;
drop sequence if exists public.heritage_media_id_seq cascade;
drop sequence if exists public.tiffin_qr_code_id_seq cascade;
drop sequence if exists public.user_tiffin_collection_number_seq cascade;
drop sequence if exists public.community_post_number_seq cascade;
drop sequence if exists public.community_post_photo_number_seq cascade;
drop sequence if exists public.community_post_like_number_seq cascade;
drop sequence if exists public.community_comment_number_seq cascade;
drop sequence if exists public.artwork_submission_number_seq cascade;
drop sequence if exists public.artwork_submission_photo_number_seq cascade;
drop sequence if exists public.artwork_vote_number_seq cascade;
drop sequence if exists public.artwork_campaign_number_seq cascade;
drop sequence if exists public.artwork_voting_session_number_seq cascade;
drop sequence if exists public.artwork_voting_entry_number_seq cascade;
drop sequence if exists public.artwork_number_seq cascade;
drop sequence if exists public.artwork_campaign_winner_number_seq cascade;
drop function if exists public.create_profile_for_new_auth_user() cascade;
drop function if exists public.create_artwork_submission(varchar, varchar, text, text, text, text, text, text, text, text, text) cascade;
drop function if exists public.cast_artwork_vote(varchar) cascade;
drop function if exists public.create_tie_break_session(varchar, timestamptz, timestamptz) cascade;
drop function if exists public.finalize_artwork_voting_session(varchar) cascade;
drop function if exists public.validate_heritage_tiffin_relationships() cascade;
drop trigger if exists on_auth_user_created on auth.users;

-- ============================================================================
-- 2. ACCOUNT MANAGEMENT
-- profile_id uses the project ID format, for example P0001.
-- auth_user_id links the profile to Supabase Auth's UUID.
-- ============================================================================

-- P0001-P0999 are reserved for deterministic seed/demo profiles.
create sequence public.profile_number_seq start 1000;
create sequence public.heritage_tiffin_number_seq start 1000;
create sequence public.heritage_story_number_seq start 1000;
create sequence public.heritage_media_number_seq start 1000;
create sequence public.tiffin_qr_code_number_seq start 1000;

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
    source_artwork_submission_id varchar(6),
    title               varchar(150) not null,
    description         text,
    artwork_meaning     text,
    cultural_inspiration text,
    image_url           text not null,
    status              varchar(20) not null default 'published'
                        check (status in ('draft', 'published', 'inactive')),
    created_at          timestamptz not null default now(),
    updated_at          timestamptz not null default now(),

    constraint uq_artwork_source_submission unique (source_artwork_submission_id),
    constraint chk_artwork_id_format
        check (artwork_id ~ '^A[0-9]{4}$')
);

create table public.heritage_tiffins (
    heritage_tiffin_id  varchar(6) primary key default
                        ('HT' || lpad(nextval('public.heritage_tiffin_number_seq')::text, 4, '0')),
    edition_name        varchar(150) not null unique,
    state_id            varchar(5) not null references public.states(state_id),
    heritage_food_id    varchar(6) not null references public.heritage_foods(heritage_food_id),
    artwork_id          varchar(5) not null unique references public.artworks(artwork_id),
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
    heritage_story_id  varchar(6) primary key default
                       ('HS' || lpad(nextval('public.heritage_story_number_seq')::text, 4, '0')),
    heritage_tiffin_id varchar(6) not null unique references public.heritage_tiffins(heritage_tiffin_id) on delete cascade,
    title               varchar(180) not null,
    story_body          text not null,
    image_url           text,
    sort_order          integer not null default 1,
    is_published        boolean not null default true,

    constraint chk_heritage_story_id_format
        check (heritage_story_id ~ '^HS[0-9]{4}$')
);

create table public.heritage_media (
    heritage_media_id  varchar(6) primary key default
                       ('HM' || lpad(nextval('public.heritage_media_number_seq')::text, 4, '0')),
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

create unique index uq_heritage_media_tiffin_video
on public.heritage_media (heritage_tiffin_id)
where media_type = 'video';

create table public.tiffin_qr_codes (
    tiffin_qr_code_id  varchar(7) primary key default
                       ('TQC' || lpad(nextval('public.tiffin_qr_code_number_seq')::text, 4, '0')),
    heritage_tiffin_id varchar(6) not null unique references public.heritage_tiffins(heritage_tiffin_id) on delete cascade,
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

create table public.vendor_tiffins (
    vendor_tiffin_id    varchar(6) primary key,
    vendor_id           varchar(5) not null references public.vendors(vendor_id) on delete cascade,
    heritage_tiffin_id  varchar(6) not null references public.heritage_tiffins(heritage_tiffin_id),

    constraint uq_vendor_tiffin unique (vendor_id),
    constraint chk_vendor_tiffin_id_format
        check (vendor_tiffin_id ~ '^VT[0-9]{4}$')
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
    state_id            varchar(5) not null references public.states(state_id),
    campaign_title      varchar(180) not null,
    description         text,
    submission_start_at timestamptz not null,
    submission_end_at   timestamptz not null,
    status              varchar(30) not null default 'active'
                        check (status in ('active', 'completed')),
    created_by_profile_id varchar(5) not null references public.profiles(profile_id),
    created_at          timestamptz not null default now(),

    constraint chk_campaign_dates check (submission_end_at > submission_start_at),
    constraint chk_artwork_campaign_id_format
        check (artwork_campaign_id ~ '^AC[0-9]{4}$')
);

create index ix_artwork_campaigns_state
on public.artwork_campaigns (state_id);

-- Keep campaign status consistent whenever a campaign row is created or
-- changed. Time passing alone does not fire PostgreSQL triggers; a scheduled
-- database job is required if rows must change without any write operation.
create or replace function public.complete_expired_artwork_campaign()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
    if new.submission_end_at <= now() then
        new.status := 'completed';
    else
        -- A future deadline always means the campaign is still active. The
        -- admin End Early action stores its actual completion time, so it is
        -- not mistaken for a campaign that runs until 23:59 today.
        new.status := 'active';
    end if;

    return new;
end;
$$;

create trigger complete_expired_artwork_campaign_trigger
before insert or update on public.artwork_campaigns
for each row execute function public.complete_expired_artwork_campaign();

create table public.artwork_submissions (
    artwork_submission_id varchar(6) primary key,
    artwork_campaign_id  varchar(6) not null references public.artwork_campaigns(artwork_campaign_id),
    profile_id          varchar(5) not null references public.profiles(profile_id),
    artwork_title       varchar(180) not null,
    design_description  text not null,
    cultural_inspiration text not null,
    layer_1_meaning     text not null,
    layer_2_meaning     text not null,
    layer_3_meaning     text not null,
    artwork_file_url    text not null,
    review_status       varchar(20) not null default 'pending'
                        check (review_status in ('pending', 'approved', 'rejected')),
    submitted_at        timestamptz not null default now(),
    reviewed_by_profile_id varchar(5) references public.profiles(profile_id),
    reviewed_at         timestamptz,

    constraint chk_artwork_submission_id_format
        check (artwork_submission_id ~ '^AS[0-9]{4}$')
);

-- Every submission includes a consistent set of review photographs. The front
-- image is also retained in artwork_file_url as the public voting thumbnail.
create table public.artwork_submission_photos (
    artwork_submission_photo_id varchar(7) primary key,
    artwork_submission_id varchar(6) not null references public.artwork_submissions(artwork_submission_id) on delete cascade,
    view_type           varchar(30) not null
                        check (view_type in (
                            'front_hero', 'layer_1_flat_360',
                            'layer_2_flat_360', 'layer_3_flat_360'
                        )),
    photo_url           text not null check (length(trim(photo_url)) > 0),
    sort_order          smallint not null check (sort_order between 1 and 4),
    created_at          timestamptz not null default now(),

    constraint uq_artwork_submission_photo_view
        unique (artwork_submission_id, view_type),
    constraint uq_artwork_submission_photo_order
        unique (artwork_submission_id, sort_order),
    constraint chk_artwork_submission_photo_id_format
        check (artwork_submission_photo_id ~ '^ASP[0-9]{4}$')
);

create index ix_artwork_submission_photos_submission
on public.artwork_submission_photos (artwork_submission_id);

create index ix_artwork_submissions_campaign
on public.artwork_submissions (artwork_campaign_id);

create index ix_artwork_submissions_profile
on public.artwork_submissions (profile_id);

-- Artworks are declared before submissions because heritage tiffins depend on
-- them. Add the provenance foreign key now that submissions exist.
alter table public.artworks
add constraint fk_artwork_source_submission
foreign key (source_artwork_submission_id)
references public.artwork_submissions(artwork_submission_id);

create table public.artwork_voting_sessions (
    artwork_voting_session_id varchar(7) primary key,
    artwork_campaign_id varchar(6) not null references public.artwork_campaigns(artwork_campaign_id) on delete cascade,
    voting_start_at    timestamptz not null,
    voting_end_at      timestamptz not null,
    status             varchar(20) not null
                       check (status in ('scheduled', 'active', 'closed')),
    session_type       varchar(20) not null default 'standard'
                       check (session_type in ('standard', 'tie_break')),
    parent_voting_session_id varchar(7),

    constraint chk_voting_dates check (voting_end_at > voting_start_at),
    constraint chk_voting_session_parent check (
        (session_type = 'standard' and parent_voting_session_id is null)
        or
        (session_type = 'tie_break' and parent_voting_session_id is not null)
    ),
    constraint chk_voting_session_not_self_parent check (
        parent_voting_session_id is distinct from artwork_voting_session_id
    ),
    constraint uq_voting_session_id_campaign
        unique (artwork_voting_session_id, artwork_campaign_id),
    constraint fk_voting_session_parent_campaign
        foreign key (parent_voting_session_id, artwork_campaign_id)
        references public.artwork_voting_sessions (
            artwork_voting_session_id,
            artwork_campaign_id
        ),
    constraint chk_artwork_voting_session_id_format
        check (artwork_voting_session_id ~ '^AVS[0-9]{4}$')
);

create unique index uq_one_active_session_per_campaign
on public.artwork_voting_sessions (artwork_campaign_id)
where status = 'active';

create unique index uq_one_standard_session_per_campaign
on public.artwork_voting_sessions (artwork_campaign_id)
where session_type = 'standard';

create unique index uq_one_tie_break_child
on public.artwork_voting_sessions (parent_voting_session_id)
where parent_voting_session_id is not null;

create index ix_artwork_voting_sessions_campaign
on public.artwork_voting_sessions (artwork_campaign_id);

-- Campaign voting uses the same period as artwork submission. Creating the
-- standard session here ensures approved submissions always have a session in
-- which they can be published.
create or replace function public.create_artwork_campaign_voting_session()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
    insert into public.artwork_voting_sessions (
        artwork_campaign_id,
        voting_start_at,
        voting_end_at,
        status,
        session_type,
        parent_voting_session_id
    )
    values (
        new.artwork_campaign_id,
        new.submission_start_at,
        new.submission_end_at,
        case
            when new.submission_end_at <= now() then 'closed'
            when new.submission_start_at > now() then 'scheduled'
            else 'active'
        end,
        'standard',
        null
    )
    on conflict (artwork_campaign_id) where session_type = 'standard'
    do nothing;

    return new;
end;
$$;

create trigger create_artwork_campaign_voting_session_trigger
after insert on public.artwork_campaigns
for each row execute function public.create_artwork_campaign_voting_session();

create table public.artwork_voting_entries (
    artwork_voting_entry_id varchar(7) primary key,
    artwork_voting_session_id varchar(7) not null references public.artwork_voting_sessions(artwork_voting_session_id) on delete cascade,
    artwork_submission_id varchar(6) not null references public.artwork_submissions(artwork_submission_id),
    vote_count          integer not null default 0 check (vote_count >= 0),
    published_at       timestamptz not null default now(),

    constraint uq_voting_entry unique (artwork_voting_session_id, artwork_submission_id),
    constraint uq_voting_entry_id_session
        unique (artwork_voting_entry_id, artwork_voting_session_id),
    constraint chk_artwork_voting_entry_id_format
        check (artwork_voting_entry_id ~ '^AVE[0-9]{4}$')
);

create index ix_artwork_voting_entries_submission
on public.artwork_voting_entries (artwork_submission_id);

create table public.artwork_votes (
    artwork_vote_id     varchar(6) primary key,
    artwork_voting_session_id varchar(7) not null references public.artwork_voting_sessions(artwork_voting_session_id),
    artwork_voting_entry_id varchar(7) not null,
    profile_id          varchar(5) not null references public.profiles(profile_id),
    voted_at            timestamptz not null default now(),

    constraint uq_one_vote_per_session
        unique (artwork_voting_session_id, profile_id),
    constraint fk_vote_entry_session
        foreign key (artwork_voting_entry_id, artwork_voting_session_id)
        references public.artwork_voting_entries (
            artwork_voting_entry_id,
            artwork_voting_session_id
        ),
    constraint chk_artwork_vote_id_format
        check (artwork_vote_id ~ '^AV[0-9]{4}$')
);

create index ix_artwork_votes_entry
on public.artwork_votes (artwork_voting_entry_id);

create index ix_artwork_votes_profile
on public.artwork_votes (profile_id);

create table public.artwork_campaign_winners (
    artwork_campaign_winner_id varchar(7) primary key,
    artwork_campaign_id varchar(6) not null references public.artwork_campaigns(artwork_campaign_id),
    artwork_voting_session_id varchar(7) not null,
    artwork_voting_entry_id varchar(7) not null,
    artwork_id          varchar(5) not null references public.artworks(artwork_id),
    final_vote_count    integer not null default 0 check (final_vote_count >= 0),
    final_rank          integer not null default 1 check (final_rank = 1),
    announced_by_profile_id varchar(5) not null references public.profiles(profile_id),
    announced_at       timestamptz not null default now(),

    constraint uq_campaign_winner unique (artwork_campaign_id),
    constraint uq_campaign_winner_artwork unique (artwork_id),
    constraint fk_winner_session_campaign
        foreign key (artwork_voting_session_id, artwork_campaign_id)
        references public.artwork_voting_sessions (
            artwork_voting_session_id,
            artwork_campaign_id
        ),
    constraint fk_winner_entry_session
        foreign key (artwork_voting_entry_id, artwork_voting_session_id)
        references public.artwork_voting_entries (
            artwork_voting_entry_id,
            artwork_voting_session_id
        ),
    constraint chk_artwork_campaign_winner_id_format
        check (artwork_campaign_winner_id ~ '^ACW[0-9]{4}$')
);

-- Server-generated IDs for user-created records. P0001-style seed IDs remain
-- deterministic, while live records begin at 1000 and never require clients to
-- scan other users' rows to calculate a primary key.
create sequence public.user_tiffin_collection_number_seq start 1000;
create sequence public.community_post_number_seq start 1000;
create sequence public.community_post_photo_number_seq start 1000;
create sequence public.community_post_like_number_seq start 1000;
create sequence public.community_comment_number_seq start 1000;
create sequence public.artwork_submission_number_seq start 1000;
create sequence public.artwork_submission_photo_number_seq start 1000;
create sequence public.artwork_vote_number_seq start 1000;
create sequence public.artwork_campaign_number_seq start 1000;
create sequence public.artwork_voting_session_number_seq start 1000;
create sequence public.artwork_voting_entry_number_seq start 1000;
create sequence public.artwork_number_seq start 1000;
create sequence public.artwork_campaign_winner_number_seq start 1000;

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

alter table public.artwork_submission_photos
alter column artwork_submission_photo_id
set default ('ASP' || lpad(nextval('public.artwork_submission_photo_number_seq')::text, 4, '0'));

alter table public.artwork_votes
alter column artwork_vote_id
set default ('AV' || lpad(nextval('public.artwork_vote_number_seq')::text, 4, '0'));

alter table public.artwork_campaigns
alter column artwork_campaign_id
set default ('AC' || lpad(nextval('public.artwork_campaign_number_seq')::text, 4, '0'));

alter table public.artwork_voting_sessions
alter column artwork_voting_session_id
set default ('AVS' || lpad(nextval('public.artwork_voting_session_number_seq')::text, 4, '0'));

alter table public.artwork_voting_entries
alter column artwork_voting_entry_id
set default ('AVE' || lpad(nextval('public.artwork_voting_entry_number_seq')::text, 4, '0'));

alter table public.artworks
alter column artwork_id
set default ('A' || lpad(nextval('public.artwork_number_seq')::text, 4, '0'));

alter table public.artwork_campaign_winners
alter column artwork_campaign_winner_id
set default ('ACW' || lpad(nextval('public.artwork_campaign_winner_number_seq')::text, 4, '0'));

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

-- Creates the submission and its required review views in one transaction.
-- The server derives the profile and validates the campaign window so clients
-- cannot submit on behalf of another user or bypass campaign dates.
create or replace function public.create_artwork_submission(
    p_artwork_campaign_id varchar(6),
    p_artwork_title varchar(180),
    p_design_description text,
    p_cultural_inspiration text,
    p_layer_1_meaning text,
    p_layer_2_meaning text,
    p_layer_3_meaning text,
    p_front_hero_photo_url text,
    p_layer_1_flat_360_url text,
    p_layer_2_flat_360_url text,
    p_layer_3_flat_360_url text
)
returns public.artwork_submissions
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    selected_profile_id varchar(5);
    created_submission public.artwork_submissions;
begin
    selected_profile_id := public.current_profile_id();
    if selected_profile_id is null then
        raise exception 'An active authenticated profile is required'
            using errcode = '42501';
    end if;

    if nullif(trim(p_artwork_title), '') is null
       or nullif(trim(p_design_description), '') is null
       or nullif(trim(p_cultural_inspiration), '') is null
       or nullif(trim(p_layer_1_meaning), '') is null
       or nullif(trim(p_layer_2_meaning), '') is null
       or nullif(trim(p_layer_3_meaning), '') is null then
        raise exception 'All artwork details are required';
    end if;

    if nullif(trim(p_front_hero_photo_url), '') is null
       or nullif(trim(p_layer_1_flat_360_url), '') is null
       or nullif(trim(p_layer_2_flat_360_url), '') is null
       or nullif(trim(p_layer_3_flat_360_url), '') is null then
        raise exception 'All four required artwork views must be provided';
    end if;

    if not exists (
        select 1
        from public.artwork_campaigns campaign
        where campaign.artwork_campaign_id = p_artwork_campaign_id
          and campaign.status = 'active'
          and now() between campaign.submission_start_at
                        and campaign.submission_end_at
    ) then
        raise exception 'This campaign is no longer accepting artwork';
    end if;

    insert into public.artwork_submissions (
        artwork_campaign_id, profile_id, artwork_title,
        design_description, cultural_inspiration,
        layer_1_meaning, layer_2_meaning, layer_3_meaning,
        artwork_file_url, review_status
    ) values (
        p_artwork_campaign_id, selected_profile_id, trim(p_artwork_title),
        trim(p_design_description), trim(p_cultural_inspiration),
        trim(p_layer_1_meaning), trim(p_layer_2_meaning),
        trim(p_layer_3_meaning), trim(p_front_hero_photo_url), 'pending'
    ) returning * into created_submission;

    insert into public.artwork_submission_photos (
        artwork_submission_id, view_type, photo_url, sort_order
    ) values
        (created_submission.artwork_submission_id, 'front_hero', trim(p_front_hero_photo_url), 1),
        (created_submission.artwork_submission_id, 'layer_1_flat_360', trim(p_layer_1_flat_360_url), 2),
        (created_submission.artwork_submission_id, 'layer_2_flat_360', trim(p_layer_2_flat_360_url), 3),
        (created_submission.artwork_submission_id, 'layer_3_flat_360', trim(p_layer_3_flat_360_url), 4);

    return created_submission;
end;
$$;

revoke all on function public.create_artwork_submission(varchar, varchar, text, text, text, text, text, text, text, text, text) from public;
grant execute on function public.create_artwork_submission(varchar, varchar, text, text, text, text, text, text, text, text, text) to authenticated;

create or replace function public.is_current_profile_admin()
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

revoke all on function public.is_current_profile_admin() from public;
grant execute on function public.is_current_profile_admin() to authenticated;

-- A Tiffin inherits its state from the selected winning Artwork. Its featured
-- food must belong to that same state. Deferred validation also allows the
-- deterministic seed transaction to insert winners after its Tiffin rows.
create or replace function public.validate_heritage_tiffin_relationships()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    campaign_state_id varchar(5);
    food_state_id varchar(5);
begin
    select campaign.state_id
    into campaign_state_id
    from public.artworks artwork
    join public.artwork_campaign_winners winner
      on winner.artwork_id = artwork.artwork_id
    join public.artwork_campaigns campaign
      on campaign.artwork_campaign_id = winner.artwork_campaign_id
    where artwork.artwork_id = new.artwork_id
      and artwork.status = 'published';

    if campaign_state_id is null then
        raise exception 'Artwork must be a published campaign winner.';
    end if;

    if new.state_id <> campaign_state_id then
        raise exception 'Tiffin state must match the winning Artwork campaign state.';
    end if;

    select state_id
    into food_state_id
    from public.heritage_foods
    where heritage_food_id = new.heritage_food_id
      and is_active = true;

    if food_state_id is null or food_state_id <> campaign_state_id then
        raise exception 'Featured Heritage Food must be active and belong to the campaign state.';
    end if;

    return new;
end;
$$;

create constraint trigger validate_heritage_tiffin_relationships
after insert or update on public.heritage_tiffins
deferrable initially deferred
for each row execute function public.validate_heritage_tiffin_relationships();

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

-- Preserve the state and completion history of campaigns once participation
-- begins. Empty campaigns remain editable/deletable by administrators.
create or replace function public.guard_artwork_campaign_mutation()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    campaign_has_history boolean;
begin
    campaign_has_history :=
        exists (
            select 1 from public.artwork_submissions submission
            where submission.artwork_campaign_id = old.artwork_campaign_id
        )
        or exists (
            select 1 from public.artwork_voting_sessions voting_session
            where voting_session.artwork_campaign_id = old.artwork_campaign_id
        )
        or exists (
            select 1 from public.artwork_campaign_winners winner
            where winner.artwork_campaign_id = old.artwork_campaign_id
        );

    if tg_op = 'DELETE' then
        if campaign_has_history then
            raise exception 'A campaign with submissions, voting sessions or a winner cannot be deleted';
        end if;

        return old;
    end if;

    if campaign_has_history
       and new.state_id is distinct from old.state_id then
        raise exception 'Campaign state is immutable after participation begins';
    end if;

    return new;
end;
$$;

create trigger guard_artwork_campaign_mutation_trigger
before update or delete on public.artwork_campaigns
for each row execute function public.guard_artwork_campaign_mutation();

-- Keep standard/tie-break session chains chronological and within one
-- campaign. The composite self-reference provides the same-campaign FK; this
-- trigger enforces the business-state rules that a FK cannot express.
create or replace function public.validate_artwork_voting_session()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    selected_parent_campaign_id varchar(6);
    selected_parent_status varchar(20);
    selected_parent_end_at timestamptz;
    selected_campaign_status varchar(30);
    selected_parent_top_vote_count integer;
    selected_parent_top_tied_count integer;
begin
    select campaign.status
    into selected_campaign_status
    from public.artwork_campaigns campaign
    where campaign.artwork_campaign_id = new.artwork_campaign_id;

    if new.status = 'active'
       and selected_campaign_status <> 'active' then
        raise exception 'Only an active campaign can have an active voting session';
    end if;

    if new.parent_voting_session_id is null then
        return new;
    end if;

    select
        parent_session.artwork_campaign_id,
        parent_session.status,
        parent_session.voting_end_at
    into
        selected_parent_campaign_id,
        selected_parent_status,
        selected_parent_end_at
    from public.artwork_voting_sessions parent_session
    where parent_session.artwork_voting_session_id =
          new.parent_voting_session_id
    for key share;

    if not found then
        raise exception 'Parent voting session % does not exist',
            new.parent_voting_session_id;
    end if;

    if selected_parent_campaign_id <> new.artwork_campaign_id then
        raise exception 'Tie-break session and parent must belong to the same campaign';
    end if;

    if selected_parent_status <> 'closed' then
        raise exception 'A tie-break can only follow a closed voting session';
    end if;

    if new.voting_start_at < selected_parent_end_at then
        raise exception 'Tie-break voting cannot start before its parent session ends';
    end if;

    if exists (
        select 1
        from public.artwork_campaign_winners winner
        where winner.artwork_voting_session_id =
              new.parent_voting_session_id
    ) then
        raise exception 'A finalized session cannot receive a tie-break child';
    end if;

    with parent_results as (
        select
            parent_entry.artwork_voting_entry_id,
            count(parent_vote.artwork_vote_id)::integer as actual_vote_count
        from public.artwork_voting_entries parent_entry
        left join public.artwork_votes parent_vote
          on parent_vote.artwork_voting_entry_id =
             parent_entry.artwork_voting_entry_id
        where parent_entry.artwork_voting_session_id =
              new.parent_voting_session_id
        group by parent_entry.artwork_voting_entry_id
    ),
    parent_top as (
        select max(actual_vote_count) as top_vote_count
        from parent_results
    )
    select
        parent_top.top_vote_count,
        count(*) filter (
            where parent_results.actual_vote_count =
                  parent_top.top_vote_count
        )::integer
    into
        selected_parent_top_vote_count,
        selected_parent_top_tied_count
    from parent_results
    cross join parent_top
    group by parent_top.top_vote_count;

    if selected_parent_top_vote_count is null
       or selected_parent_top_tied_count < 2 then
        raise exception 'A tie-break requires a genuine top tie in its parent session';
    end if;

    return new;
end;
$$;

create trigger validate_artwork_voting_session_trigger
before insert or update of
    artwork_campaign_id,
    voting_start_at,
    voting_end_at,
    session_type,
    parent_voting_session_id
on public.artwork_voting_sessions
for each row execute function public.validate_artwork_voting_session();

-- Voting history becomes progressively immutable. Structural session fields
-- cannot change after entries, a child session or a winner exist, and status
-- may move only scheduled -> active/closed -> closed.
create or replace function public.guard_artwork_voting_session_mutation()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    selected_child_start_at timestamptz;
    selected_campaign_status varchar(30);
begin
    if tg_op = 'DELETE' then
        if exists (
            select 1 from public.artwork_voting_entries entry
            where entry.artwork_voting_session_id =
                  old.artwork_voting_session_id
        )
        or exists (
            select 1 from public.artwork_voting_sessions child_session
            where child_session.parent_voting_session_id =
                  old.artwork_voting_session_id
        )
        or exists (
            select 1 from public.artwork_campaign_winners winner
            where winner.artwork_voting_session_id =
                  old.artwork_voting_session_id
        ) then
            raise exception 'A voting session with entries, a tie-break child or a winner cannot be deleted';
        end if;

        return old;
    end if;

    if (
        new.artwork_campaign_id is distinct from old.artwork_campaign_id
        or new.voting_start_at is distinct from old.voting_start_at
        or new.voting_end_at is distinct from old.voting_end_at
        or new.session_type is distinct from old.session_type
        or new.parent_voting_session_id is distinct from
           old.parent_voting_session_id
    ) and (
        exists (
            select 1 from public.artwork_voting_entries entry
            where entry.artwork_voting_session_id =
                  old.artwork_voting_session_id
        )
        or exists (
            select 1 from public.artwork_voting_sessions child_session
            where child_session.parent_voting_session_id =
                  old.artwork_voting_session_id
        )
        or exists (
            select 1 from public.artwork_campaign_winners winner
            where winner.artwork_voting_session_id =
                  old.artwork_voting_session_id
        )
    ) then
        raise exception 'Voting-session structure is immutable after publication or finalization';
    end if;

    if new.status is distinct from old.status then
        if old.status = 'scheduled'
           and new.status not in ('active', 'closed') then
            raise exception 'Invalid voting-session status transition';
        elsif old.status = 'active'
              and new.status <> 'closed' then
            raise exception 'An active voting session can only be closed';
        elsif old.status = 'closed' then
            raise exception 'A closed voting session cannot be reopened';
        end if;
    end if;

    if new.status = 'active' then
        select campaign.status
        into selected_campaign_status
        from public.artwork_campaigns campaign
        where campaign.artwork_campaign_id = new.artwork_campaign_id;

        if selected_campaign_status <> 'active' then
            raise exception 'Only an active campaign can have an active voting session';
        end if;
    end if;

    select child_session.voting_start_at
    into selected_child_start_at
    from public.artwork_voting_sessions child_session
    where child_session.parent_voting_session_id =
          old.artwork_voting_session_id;

    if found then
        if new.status <> 'closed' then
            raise exception 'A parent session must remain closed after its tie-break is created';
        end if;

        if new.voting_end_at > selected_child_start_at then
            raise exception 'A parent session cannot end after its tie-break begins';
        end if;
    end if;

    return new;
end;
$$;

create trigger guard_artwork_voting_session_mutation_trigger
before update or delete on public.artwork_voting_sessions
for each row execute function public.guard_artwork_voting_session_mutation();

-- An entry must always use an approved submission from its session's
-- campaign. Tie-breaks may contain only the submissions tied for the highest
-- actual vote total in their immediate parent session.
create or replace function public.validate_artwork_voting_entry()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    selected_session_campaign_id varchar(6);
    selected_session_type varchar(20);
    selected_session_status varchar(20);
    selected_parent_session_id varchar(7);
    selected_submission_campaign_id varchar(6);
    selected_review_status varchar(20);
    parent_top_vote_count integer;
    parent_top_tied_count integer;
    selected_submission_is_top integer;
begin
    select
        voting_session.artwork_campaign_id,
        voting_session.session_type,
        voting_session.status,
        voting_session.parent_voting_session_id
    into
        selected_session_campaign_id,
        selected_session_type,
        selected_session_status,
        selected_parent_session_id
    from public.artwork_voting_sessions voting_session
    where voting_session.artwork_voting_session_id =
          new.artwork_voting_session_id
    for share;

    if not found then
        raise exception 'Voting session % does not exist',
            new.artwork_voting_session_id;
    end if;

    select
        submission.artwork_campaign_id,
        submission.review_status
    into
        selected_submission_campaign_id,
        selected_review_status
    from public.artwork_submissions submission
    where submission.artwork_submission_id = new.artwork_submission_id
    for share;

    if not found then
        raise exception 'Artwork submission % does not exist',
            new.artwork_submission_id;
    end if;

    if selected_submission_campaign_id <> selected_session_campaign_id then
        raise exception 'Voting entry submission and session must belong to the same campaign';
    end if;

    if selected_review_status <> 'approved' then
        raise exception 'Only approved submissions can become voting entries';
    end if;

    -- Standard campaign galleries accept newly approved artwork while their
    -- voting session is scheduled or active. Tie-break candidate sets must
    -- remain frozen once voting starts.
    if selected_session_type = 'tie_break'
       and selected_session_status <> 'scheduled' then
        raise exception 'Tie-break entries can only be added to a scheduled session';
    elsif selected_session_type = 'standard'
          and selected_session_status not in ('scheduled', 'active') then
        raise exception 'Standard voting entries can only be added to a scheduled or active session';
    end if;

    if selected_session_type = 'tie_break' then
        with parent_results as (
            select
                parent_entry.artwork_submission_id,
                count(parent_vote.artwork_vote_id)::integer as actual_vote_count
            from public.artwork_voting_entries parent_entry
            left join public.artwork_votes parent_vote
              on parent_vote.artwork_voting_entry_id =
                 parent_entry.artwork_voting_entry_id
            where parent_entry.artwork_voting_session_id =
                  selected_parent_session_id
            group by parent_entry.artwork_submission_id
        ),
        parent_top as (
            select max(actual_vote_count) as top_vote_count
            from parent_results
        )
        select
            parent_top.top_vote_count,
            count(*) filter (
                where parent_results.actual_vote_count =
                      parent_top.top_vote_count
            )::integer,
            count(*) filter (
                where parent_results.artwork_submission_id =
                      new.artwork_submission_id
                  and parent_results.actual_vote_count =
                      parent_top.top_vote_count
            )::integer
        into
            parent_top_vote_count,
            parent_top_tied_count,
            selected_submission_is_top
        from parent_results
        cross join parent_top
        group by parent_top.top_vote_count;

        if parent_top_vote_count is null
           or parent_top_tied_count < 2 then
            raise exception 'Parent voting session does not have a top tie';
        end if;

        if selected_submission_is_top <> 1 then
            raise exception 'Tie-break entries must be top-tied submissions from the parent session';
        end if;
    end if;

    return new;
end;
$$;

create trigger validate_artwork_voting_entry_trigger
before insert or update of
    artwork_voting_session_id,
    artwork_submission_id
on public.artwork_voting_entries
for each row execute function public.validate_artwork_voting_entry();

-- Keep the public campaign gallery in sync with approved submissions. The
-- gallery reads voting entries because votes belong to a specific session;
-- without this trigger, an approved submission can remain invisible until an
-- administrator manually creates its voting-entry row.
create or replace function public.publish_approved_artwork_submission()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
    if new.review_status = 'approved'
       and tg_op = 'INSERT' then
        insert into public.artwork_voting_entries (
            artwork_voting_session_id,
            artwork_submission_id
        )
        select
            voting_session.artwork_voting_session_id,
            new.artwork_submission_id
        from public.artwork_voting_sessions voting_session
        where voting_session.artwork_campaign_id = new.artwork_campaign_id
          and voting_session.session_type = 'standard'
          and voting_session.status in ('scheduled', 'active')
        on conflict (
            artwork_voting_session_id,
            artwork_submission_id
        ) do nothing;
    elsif new.review_status = 'approved'
          and old.review_status is distinct from new.review_status then
        insert into public.artwork_voting_entries (
            artwork_voting_session_id,
            artwork_submission_id
        )
        select
            voting_session.artwork_voting_session_id,
            new.artwork_submission_id
        from public.artwork_voting_sessions voting_session
        where voting_session.artwork_campaign_id = new.artwork_campaign_id
          and voting_session.session_type = 'standard'
          and voting_session.status in ('scheduled', 'active')
        on conflict (
            artwork_voting_session_id,
            artwork_submission_id
        ) do nothing;
    end if;

    return new;
end;
$$;

create trigger publish_approved_artwork_submission_trigger
after insert or update of review_status
on public.artwork_submissions
for each row execute function public.publish_approved_artwork_submission();

-- Also populate a standard session when it is activated with artwork that had
-- already been approved before the session existed.
create or replace function public.publish_approved_artworks_for_session()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
    if new.session_type = 'standard'
       and new.status in ('scheduled', 'active') then
        insert into public.artwork_voting_entries (
            artwork_voting_session_id,
            artwork_submission_id
        )
        select
            new.artwork_voting_session_id,
            submission.artwork_submission_id
        from public.artwork_submissions submission
        where submission.artwork_campaign_id = new.artwork_campaign_id
          and submission.review_status = 'approved'
        on conflict (
            artwork_voting_session_id,
            artwork_submission_id
        ) do nothing;
    end if;

    return new;
end;
$$;

create trigger publish_approved_artworks_for_session_trigger
after insert or update of status
on public.artwork_voting_sessions
for each row execute function public.publish_approved_artworks_for_session();

-- Published entries cannot be repointed or deleted. Direct entry UPDATE is not
-- granted to API roles; only database-owned vote/finalization functions update
-- the cached vote count.
create or replace function public.guard_artwork_voting_entry_mutation()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    selected_session_status varchar(20);
begin
    select voting_session.status
    into selected_session_status
    from public.artwork_voting_sessions voting_session
    where voting_session.artwork_voting_session_id =
          old.artwork_voting_session_id;

    if tg_op = 'DELETE' then
        if selected_session_status <> 'scheduled'
           or exists (
               select 1 from public.artwork_votes vote
               where vote.artwork_voting_entry_id =
                     old.artwork_voting_entry_id
           )
           or exists (
               select 1 from public.artwork_campaign_winners winner
               where winner.artwork_voting_entry_id =
                     old.artwork_voting_entry_id
           ) then
            raise exception 'A published, voted-on or winning entry cannot be deleted';
        end if;

        return old;
    end if;

    if (
        new.artwork_voting_session_id is distinct from
            old.artwork_voting_session_id
        or new.artwork_submission_id is distinct from
           old.artwork_submission_id
    ) and (
        selected_session_status <> 'scheduled'
        or exists (
            select 1 from public.artwork_votes vote
            where vote.artwork_voting_entry_id =
                  old.artwork_voting_entry_id
        )
        or exists (
            select 1 from public.artwork_campaign_winners winner
            where winner.artwork_voting_entry_id =
                  old.artwork_voting_entry_id
        )
    ) then
        raise exception 'A published, voted-on or winning entry cannot be repointed';
    end if;

    return new;
end;
$$;

create trigger guard_artwork_voting_entry_mutation_trigger
before update or delete on public.artwork_voting_entries
for each row execute function public.guard_artwork_voting_entry_mutation();

-- Once a submission participates in voting, its campaign, owner and approval
-- cannot be changed in a way that invalidates existing entries or winners.
create or replace function public.guard_artwork_submission_mutation()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
    if exists (
        select 1
        from public.artwork_voting_entries entry
        where entry.artwork_submission_id = old.artwork_submission_id
    ) and (
        new.artwork_campaign_id is distinct from old.artwork_campaign_id
        or new.profile_id is distinct from old.profile_id
        or (
            old.review_status = 'approved'
            and new.review_status <> 'approved'
        )
    ) then
        raise exception 'A submission used in voting must remain approved in its original campaign and profile';
    end if;

    return new;
end;
$$;

create trigger guard_artwork_submission_mutation_trigger
before update of artwork_campaign_id, profile_id, review_status
on public.artwork_submissions
for each row execute function public.guard_artwork_submission_mutation();

-- A winner must come from a closed terminal session with one undisputed first
-- place. Its published artwork must retain the winning submission as its
-- provenance and the original submitter as the artwork creator.
create or replace function public.validate_artwork_campaign_winner()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    selected_session_campaign_id varchar(6);
    selected_session_status varchar(20);
    selected_submission_id varchar(6);
    selected_submission_profile_id varchar(5);
    selected_actual_vote_count integer;
    selected_top_vote_count integer;
    selected_top_tied_count integer;
    selected_artwork_submission_id varchar(6);
    selected_artwork_profile_id varchar(5);
begin
    select
        voting_session.artwork_campaign_id,
        voting_session.status
    into
        selected_session_campaign_id,
        selected_session_status
    from public.artwork_voting_sessions voting_session
    where voting_session.artwork_voting_session_id =
          new.artwork_voting_session_id;

    if not found
       or selected_session_campaign_id <> new.artwork_campaign_id then
        raise exception 'Winner session must belong to the selected campaign';
    end if;

    if selected_session_status <> 'closed' then
        raise exception 'A winner can only be announced from a closed session';
    end if;

    if exists (
        select 1
        from public.artwork_voting_sessions child_session
        where child_session.parent_voting_session_id =
              new.artwork_voting_session_id
    ) then
        raise exception 'A session with a tie-break child is not terminal';
    end if;

    select
        entry.artwork_submission_id,
        submission.profile_id,
        count(vote.artwork_vote_id)::integer
    into
        selected_submission_id,
        selected_submission_profile_id,
        selected_actual_vote_count
    from public.artwork_voting_entries entry
    join public.artwork_submissions submission
      on submission.artwork_submission_id = entry.artwork_submission_id
    left join public.artwork_votes vote
      on vote.artwork_voting_entry_id = entry.artwork_voting_entry_id
    where entry.artwork_voting_entry_id = new.artwork_voting_entry_id
      and entry.artwork_voting_session_id = new.artwork_voting_session_id
    group by entry.artwork_submission_id, submission.profile_id;

    if not found then
        raise exception 'Winning entry does not belong to the selected session';
    end if;

    with session_results as (
        select
            entry.artwork_voting_entry_id,
            count(vote.artwork_vote_id)::integer as actual_vote_count
        from public.artwork_voting_entries entry
        left join public.artwork_votes vote
          on vote.artwork_voting_entry_id = entry.artwork_voting_entry_id
        where entry.artwork_voting_session_id =
              new.artwork_voting_session_id
        group by entry.artwork_voting_entry_id
    ),
    session_top as (
        select max(actual_vote_count) as top_vote_count
        from session_results
    )
    select
        session_top.top_vote_count,
        count(*) filter (
            where session_results.actual_vote_count =
                  session_top.top_vote_count
        )::integer
    into selected_top_vote_count, selected_top_tied_count
    from session_results
    cross join session_top
    group by session_top.top_vote_count;

    if selected_top_vote_count is null
       or selected_top_tied_count <> 1
       or selected_actual_vote_count <> selected_top_vote_count then
        raise exception 'Winner must be the unique highest-vote entry';
    end if;

    if new.final_rank <> 1
       or new.final_vote_count <> selected_actual_vote_count then
        raise exception 'Winner rank and vote total must match the database result';
    end if;

    select
        artwork.source_artwork_submission_id,
        artwork.profile_id
    into
        selected_artwork_submission_id,
        selected_artwork_profile_id
    from public.artworks artwork
    where artwork.artwork_id = new.artwork_id;

    if not found
       or selected_artwork_submission_id is distinct from selected_submission_id
       or selected_artwork_profile_id <> selected_submission_profile_id then
        raise exception 'Winner artwork must originate from the winning submission and submitter';
    end if;

    return new;
end;
$$;

create trigger validate_artwork_campaign_winner_trigger
before insert or update on public.artwork_campaign_winners
for each row execute function public.validate_artwork_campaign_winner();

-- Record a confirmed winner when a campaign transitions to completed outside
-- finalize_artwork_voting_session (for example, through an admin status update).
-- Completing a campaign early also closes its terminal voting session so that
-- its result can be validated and recorded in the same transaction. A tied or
-- empty result is deliberately left unconfirmed. The unique constraints make
-- this safe to run again, while the normal finalization function remains
-- supported.
create or replace function public.record_completed_campaign_winner()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    selected_session_id varchar(7);
    selected_winning_entry_id varchar(7);
    selected_winning_submission_id varchar(6);
    selected_submission_profile_id varchar(5);
    selected_top_vote_count integer;
    selected_top_tied_count integer;
    selected_artwork_id varchar(5);
    selected_artwork_title varchar(180);
    selected_design_description text;
    selected_cultural_inspiration text;
    selected_layer_1_meaning text;
    selected_layer_2_meaning text;
    selected_layer_3_meaning text;
    selected_artwork_file_url text;
begin
    if new.status <> 'completed'
       or old.status = 'completed'
       or exists (
           select 1
           from public.artwork_campaign_winners winner
           where winner.artwork_campaign_id = new.artwork_campaign_id
       ) then
        return new;
    end if;

    -- Use the terminal session. A tie-break, when present, is therefore selected
    -- instead of its parent session. Do not require it to be closed here: an
    -- administrator may end a campaign while its voting session is still active.
    select voting_session.artwork_voting_session_id
    into selected_session_id
    from public.artwork_voting_sessions voting_session
    where voting_session.artwork_campaign_id = new.artwork_campaign_id
      and not exists (
          select 1
          from public.artwork_voting_sessions child_session
          where child_session.parent_voting_session_id =
                voting_session.artwork_voting_session_id
      )
    order by voting_session.voting_end_at desc
    limit 1;

    if selected_session_id is null then
        return new;
    end if;

    -- Winner validation requires a closed session. Closing scheduled/active
    -- sessions is an allowed terminal transition and also prevents more votes
    -- from being accepted after an early campaign completion.
    update public.artwork_voting_sessions
    set status = 'closed'
    where artwork_voting_session_id = selected_session_id
      and status <> 'closed';

    update public.artwork_voting_entries entry
    set vote_count = (
        select count(*)::integer
        from public.artwork_votes vote
        where vote.artwork_voting_entry_id = entry.artwork_voting_entry_id
    )
    where entry.artwork_voting_session_id = selected_session_id;

    with session_results as (
        select
            entry.artwork_voting_entry_id,
            entry.artwork_submission_id,
            count(vote.artwork_vote_id)::integer as actual_vote_count
        from public.artwork_voting_entries entry
        left join public.artwork_votes vote
          on vote.artwork_voting_entry_id = entry.artwork_voting_entry_id
        where entry.artwork_voting_session_id = selected_session_id
        group by
            entry.artwork_voting_entry_id,
            entry.artwork_submission_id
    ),
    session_top as (
        select max(actual_vote_count) as top_vote_count
        from session_results
    )
    select
        session_top.top_vote_count,
        count(*) filter (
            where session_results.actual_vote_count = session_top.top_vote_count
        )::integer,
        min(session_results.artwork_voting_entry_id) filter (
            where session_results.actual_vote_count = session_top.top_vote_count
        ),
        min(session_results.artwork_submission_id) filter (
            where session_results.actual_vote_count = session_top.top_vote_count
        )
    into
        selected_top_vote_count,
        selected_top_tied_count,
        selected_winning_entry_id,
        selected_winning_submission_id
    from session_results
    cross join session_top
    group by session_top.top_vote_count;

    if selected_top_vote_count is null or selected_top_tied_count <> 1 then
        return new;
    end if;

    select
        submission.profile_id,
        submission.artwork_title,
        submission.design_description,
        submission.cultural_inspiration,
        submission.layer_1_meaning,
        submission.layer_2_meaning,
        submission.layer_3_meaning,
        submission.artwork_file_url
    into
        selected_submission_profile_id,
        selected_artwork_title,
        selected_design_description,
        selected_cultural_inspiration,
        selected_layer_1_meaning,
        selected_layer_2_meaning,
        selected_layer_3_meaning,
        selected_artwork_file_url
    from public.artwork_submissions submission
    where submission.artwork_submission_id = selected_winning_submission_id
      and submission.artwork_campaign_id = new.artwork_campaign_id
      and submission.review_status = 'approved';

    if not found then
        return new;
    end if;

    select artwork.artwork_id
    into selected_artwork_id
    from public.artworks artwork
    where artwork.source_artwork_submission_id = selected_winning_submission_id;

    if selected_artwork_id is null then
        insert into public.artworks (
            profile_id,
            source_artwork_submission_id,
            title,
            description,
            artwork_meaning,
            cultural_inspiration,
            image_url,
            status
        )
        values (
            selected_submission_profile_id,
            selected_winning_submission_id,
            left(selected_artwork_title, 150),
            selected_design_description,
            concat_ws(
                E'\n\n',
                'Layer 1: ' || selected_layer_1_meaning,
                'Layer 2: ' || selected_layer_2_meaning,
                'Layer 3: ' || selected_layer_3_meaning
            ),
            selected_cultural_inspiration,
            selected_artwork_file_url,
            'published'
        )
        returning artwork_id into selected_artwork_id;
    else
        update public.artworks
        set profile_id = selected_submission_profile_id,
            title = left(selected_artwork_title, 150),
            description = selected_design_description,
            artwork_meaning = concat_ws(
                E'\n\n',
                'Layer 1: ' || selected_layer_1_meaning,
                'Layer 2: ' || selected_layer_2_meaning,
                'Layer 3: ' || selected_layer_3_meaning
            ),
            cultural_inspiration = selected_cultural_inspiration,
            image_url = selected_artwork_file_url,
            status = 'published',
            updated_at = now()
        where artwork_id = selected_artwork_id;
    end if;

    insert into public.artwork_campaign_winners (
        artwork_campaign_id,
        artwork_voting_session_id,
        artwork_voting_entry_id,
        artwork_id,
        final_vote_count,
        final_rank,
        announced_by_profile_id
    )
    values (
        new.artwork_campaign_id,
        selected_session_id,
        selected_winning_entry_id,
        selected_artwork_id,
        selected_top_vote_count,
        1,
        new.created_by_profile_id
    )
    on conflict (artwork_campaign_id) do nothing;

    return new;
end;
$$;

create trigger record_completed_campaign_winner_trigger
after update of status on public.artwork_campaigns
for each row
when (new.status = 'completed' and old.status is distinct from new.status)
execute function public.record_completed_campaign_winner();

-- Extending a completed campaign reopens it by changing its status back to
-- active. Its previously announced result is no longer final, so remove the
-- campaign-winner record. The promoted artwork is retained because it may
-- already be referenced elsewhere and can be reused if the same entry wins
-- when the campaign is completed again.
create or replace function public.remove_reopened_campaign_winner()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
    delete from public.artwork_campaign_winners winner
    where winner.artwork_campaign_id = new.artwork_campaign_id;

    return new;
end;
$$;

create trigger remove_reopened_campaign_winner_trigger
after update of status on public.artwork_campaigns
for each row
when (old.status = 'completed' and new.status = 'active')
execute function public.remove_reopened_campaign_winner();

-- Complete every campaign whose submission deadline has passed. This function
-- is intentionally separate from the row trigger because elapsed time does not
-- fire PostgreSQL triggers. Updating status here invokes the winner trigger
-- above for each newly completed campaign.
create or replace function public.complete_expired_artwork_campaigns()
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    completed_count integer;
begin
    update public.artwork_campaigns
    set status = 'completed'
    where status = 'active'
      and submission_end_at <= now();

    get diagnostics completed_count = row_count;
    return completed_count;
end;
$$;

revoke all on function public.complete_expired_artwork_campaigns() from public;

create or replace function public.sync_artwork_voting_entry_vote_count()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
    if tg_op = 'DELETE'
       or (
           tg_op = 'UPDATE'
           and old.artwork_voting_entry_id is distinct from
               new.artwork_voting_entry_id
       ) then
        update public.artwork_voting_entries
        set vote_count = greatest(vote_count - 1, 0)
        where artwork_voting_entry_id = old.artwork_voting_entry_id;
    end if;

    if tg_op = 'INSERT'
       or (
           tg_op = 'UPDATE'
           and old.artwork_voting_entry_id is distinct from
               new.artwork_voting_entry_id
       ) then
        update public.artwork_voting_entries
        set vote_count = vote_count + 1
        where artwork_voting_entry_id = new.artwork_voting_entry_id;
    end if;

    return null;
end;
$$;

create trigger sync_artwork_voting_entry_vote_count_trigger
after insert or delete or update of artwork_voting_entry_id
on public.artwork_votes
for each row execute function public.sync_artwork_voting_entry_vote_count();

-- Participants vote by entry only. Calling this function casts a first vote,
-- moves an existing vote to another entry, or removes it when the selected
-- entry is tapped again. The session lock serializes the change with campaign
-- finalization and the vote-count trigger keeps both entries in sync.
create or replace function public.cast_artwork_vote(
    p_artwork_voting_entry_id varchar(7)
)
returns table (
    vote_id varchar(6),
    entry_id varchar(7),
    session_id varchar(7),
    current_vote_count integer,
    cast_at timestamptz
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    selected_profile_id varchar(5);
    selected_session_id varchar(7);
    selected_submission_status varchar(20);
    selected_submission_campaign_id varchar(6);
    selected_session_campaign_id varchar(6);
    selected_session_status varchar(20);
    selected_voting_start_at timestamptz;
    selected_voting_end_at timestamptz;
    selected_campaign_status varchar(30);
    created_vote_id varchar(6);
    created_voted_at timestamptz;
    existing_entry_id varchar(7);
begin
    selected_profile_id := public.current_profile_id();

    if selected_profile_id is null then
        raise exception 'An active authenticated profile is required'
            using errcode = '42501';
    end if;

    select
        entry.artwork_voting_session_id,
        submission.review_status,
        submission.artwork_campaign_id
    into
        selected_session_id,
        selected_submission_status,
        selected_submission_campaign_id
    from public.artwork_voting_entries entry
    join public.artwork_submissions submission
      on submission.artwork_submission_id = entry.artwork_submission_id
    where entry.artwork_voting_entry_id = p_artwork_voting_entry_id;

    if not found then
        raise exception 'Voting entry % does not exist',
            p_artwork_voting_entry_id;
    end if;

    select
        voting_session.artwork_campaign_id,
        voting_session.status,
        voting_session.voting_start_at,
        voting_session.voting_end_at
    into
        selected_session_campaign_id,
        selected_session_status,
        selected_voting_start_at,
        selected_voting_end_at
    from public.artwork_voting_sessions voting_session
    where voting_session.artwork_voting_session_id = selected_session_id
    for update;

    if selected_submission_campaign_id <> selected_session_campaign_id then
        raise exception 'Voting entry is not valid for its session campaign';
    end if;

    if selected_submission_status <> 'approved' then
        raise exception 'Only approved submissions can receive votes';
    end if;

    if selected_session_status <> 'active'
       or now() < selected_voting_start_at
       or now() > selected_voting_end_at then
        raise exception 'Voting session is not open';
    end if;

    select campaign.status
    into selected_campaign_status
    from public.artwork_campaigns campaign
    where campaign.artwork_campaign_id = selected_session_campaign_id;

    if selected_campaign_status <> 'active' then
        raise exception 'Artwork campaign is not active';
    end if;

    select
        existing_vote.artwork_vote_id,
        existing_vote.artwork_voting_entry_id,
        existing_vote.voted_at
    into
        created_vote_id,
        existing_entry_id,
        created_voted_at
    from public.artwork_votes existing_vote
    where existing_vote.artwork_voting_session_id = selected_session_id
      and existing_vote.profile_id = selected_profile_id
    for update;

    if created_vote_id is null then
        insert into public.artwork_votes (
            artwork_voting_session_id,
            artwork_voting_entry_id,
            profile_id
        )
        values (
            selected_session_id,
            p_artwork_voting_entry_id,
            selected_profile_id
        )
        returning
            artwork_votes.artwork_vote_id,
            artwork_votes.voted_at
        into created_vote_id, created_voted_at;
    elsif existing_entry_id = p_artwork_voting_entry_id then
        delete from public.artwork_votes
        where artwork_vote_id = created_vote_id;
        created_vote_id := null;
        created_voted_at := null;
    else
        update public.artwork_votes
        set artwork_voting_entry_id = p_artwork_voting_entry_id,
            voted_at = now()
        where artwork_vote_id = created_vote_id
        returning artwork_votes.voted_at into created_voted_at;
    end if;

    return query
    select
        created_vote_id,
        p_artwork_voting_entry_id,
        selected_session_id,
        entry.vote_count,
        created_voted_at
    from public.artwork_voting_entries entry
    where entry.artwork_voting_entry_id = p_artwork_voting_entry_id;
end;
$$;

revoke all on function public.cast_artwork_vote(varchar) from public;
grant execute on function public.cast_artwork_vote(varchar) to authenticated;

-- Admin-only creation of the next session in a tie-break chain. Entries are
-- copied from the parent's genuinely top-tied submissions; clients cannot
-- choose a different candidate set.
create or replace function public.create_tie_break_session(
    p_parent_voting_session_id varchar(7),
    p_voting_start_at timestamptz,
    p_voting_end_at timestamptz
)
returns varchar(7)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    selected_campaign_id varchar(6);
    selected_campaign_status varchar(30);
    selected_parent_status varchar(20);
    selected_parent_end_at timestamptz;
    selected_top_vote_count integer;
    selected_top_tied_count integer;
    created_session_id varchar(7);
begin
    if not public.is_current_profile_admin() then
        raise exception 'Administrator access is required'
            using errcode = '42501';
    end if;

    if p_voting_end_at <= p_voting_start_at then
        raise exception 'Tie-break end time must be after its start time';
    end if;

    select
        parent_session.artwork_campaign_id,
        parent_session.status,
        parent_session.voting_end_at
    into
        selected_campaign_id,
        selected_parent_status,
        selected_parent_end_at
    from public.artwork_voting_sessions parent_session
    where parent_session.artwork_voting_session_id =
          p_parent_voting_session_id
    for update;

    if not found then
        raise exception 'Parent voting session % does not exist',
            p_parent_voting_session_id;
    end if;

    if selected_parent_status <> 'closed' then
        raise exception 'A tie-break can only follow a closed session';
    end if;

    select campaign.status
    into selected_campaign_status
    from public.artwork_campaigns campaign
    where campaign.artwork_campaign_id = selected_campaign_id
    for update;

    if selected_campaign_status <> 'active' then
        raise exception 'A tie-break can only be created for an active campaign';
    end if;

    if p_voting_start_at < selected_parent_end_at then
        raise exception 'Tie-break voting cannot start before its parent session ends';
    end if;

    if exists (
        select 1
        from public.artwork_voting_sessions child_session
        where child_session.parent_voting_session_id =
              p_parent_voting_session_id
    ) then
        raise exception 'This session already has a tie-break child';
    end if;

    with parent_results as (
        select
            entry.artwork_voting_entry_id,
            count(vote.artwork_vote_id)::integer as actual_vote_count
        from public.artwork_voting_entries entry
        left join public.artwork_votes vote
          on vote.artwork_voting_entry_id = entry.artwork_voting_entry_id
        where entry.artwork_voting_session_id =
              p_parent_voting_session_id
        group by entry.artwork_voting_entry_id
    ),
    parent_top as (
        select max(actual_vote_count) as top_vote_count
        from parent_results
    )
    select
        parent_top.top_vote_count,
        count(*) filter (
            where parent_results.actual_vote_count =
                  parent_top.top_vote_count
        )::integer
    into selected_top_vote_count, selected_top_tied_count
    from parent_results
    cross join parent_top
    group by parent_top.top_vote_count;

    if selected_top_vote_count is null
       or selected_top_tied_count < 2 then
        raise exception 'Parent session does not have a top tie';
    end if;

    insert into public.artwork_voting_sessions (
        artwork_campaign_id,
        voting_start_at,
        voting_end_at,
        status,
        session_type,
        parent_voting_session_id
    )
    values (
        selected_campaign_id,
        p_voting_start_at,
        p_voting_end_at,
        'scheduled',
        'tie_break',
        p_parent_voting_session_id
    )
    returning artwork_voting_session_id into created_session_id;

    with parent_results as (
        select
            entry.artwork_submission_id,
            count(vote.artwork_vote_id)::integer as actual_vote_count
        from public.artwork_voting_entries entry
        left join public.artwork_votes vote
          on vote.artwork_voting_entry_id = entry.artwork_voting_entry_id
        where entry.artwork_voting_session_id =
              p_parent_voting_session_id
        group by entry.artwork_submission_id
    ),
    parent_top as (
        select max(actual_vote_count) as top_vote_count
        from parent_results
    )
    insert into public.artwork_voting_entries (
        artwork_voting_session_id,
        artwork_submission_id
    )
    select
        created_session_id,
        parent_results.artwork_submission_id
    from parent_results
    cross join parent_top
    where parent_results.actual_vote_count = parent_top.top_vote_count
    order by parent_results.artwork_submission_id;

    return created_session_id;
end;
$$;

revoke all on function public.create_tie_break_session(varchar, timestamptz, timestamptz)
from public;
grant execute on function public.create_tie_break_session(varchar, timestamptz, timestamptz)
to authenticated;

-- Admin-only finalization of a closed, terminal session. A tied result is
-- deliberately rejected so the admin can schedule a tie-break with explicit
-- dates. A unique winner, artwork promotion, winner record and campaign status
-- change are committed atomically.
create or replace function public.finalize_artwork_voting_session(
    p_artwork_voting_session_id varchar(7)
)
returns varchar(7)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    selected_admin_profile_id varchar(5);
    selected_campaign_id varchar(6);
    selected_session_status varchar(20);
    selected_campaign_status varchar(30);
    selected_top_vote_count integer;
    selected_top_tied_count integer;
    selected_winning_entry_id varchar(7);
    selected_winning_submission_id varchar(6);
    selected_submission_profile_id varchar(5);
    selected_artwork_title varchar(180);
    selected_design_description text;
    selected_cultural_inspiration text;
    selected_layer_1_meaning text;
    selected_layer_2_meaning text;
    selected_layer_3_meaning text;
    selected_artwork_meaning text;
    selected_artwork_file_url text;
    selected_artwork_id varchar(5);
    existing_winner_id varchar(7);
    created_winner_id varchar(7);
begin
    if not public.is_current_profile_admin() then
        raise exception 'Administrator access is required'
            using errcode = '42501';
    end if;

    selected_admin_profile_id := public.current_profile_id();

    select
        voting_session.artwork_campaign_id,
        voting_session.status
    into
        selected_campaign_id,
        selected_session_status
    from public.artwork_voting_sessions voting_session
    where voting_session.artwork_voting_session_id =
          p_artwork_voting_session_id
    for update;

    if not found then
        raise exception 'Voting session % does not exist',
            p_artwork_voting_session_id;
    end if;

    if selected_session_status <> 'closed' then
        raise exception 'Only a closed voting session can be finalized';
    end if;

    if exists (
        select 1
        from public.artwork_voting_sessions child_session
        where child_session.parent_voting_session_id =
              p_artwork_voting_session_id
    ) then
        raise exception 'Only the terminal session in a tie-break chain can be finalized';
    end if;

    select campaign.status
    into selected_campaign_status
    from public.artwork_campaigns campaign
    where campaign.artwork_campaign_id = selected_campaign_id
    for update;

    select winner.artwork_campaign_winner_id
    into existing_winner_id
    from public.artwork_campaign_winners winner
    where winner.artwork_campaign_id = selected_campaign_id;

    if existing_winner_id is not null then
        return existing_winner_id;
    end if;

    if selected_campaign_status <> 'active' then
        raise exception 'Only an active campaign can be finalized';
    end if;

    update public.artwork_voting_entries entry
    set vote_count = (
        select count(*)::integer
        from public.artwork_votes vote
        where vote.artwork_voting_entry_id =
              entry.artwork_voting_entry_id
    )
    where entry.artwork_voting_session_id =
          p_artwork_voting_session_id;

    with session_results as (
        select
            entry.artwork_voting_entry_id,
            entry.artwork_submission_id,
            count(vote.artwork_vote_id)::integer as actual_vote_count
        from public.artwork_voting_entries entry
        left join public.artwork_votes vote
          on vote.artwork_voting_entry_id = entry.artwork_voting_entry_id
        where entry.artwork_voting_session_id =
              p_artwork_voting_session_id
        group by
            entry.artwork_voting_entry_id,
            entry.artwork_submission_id
    ),
    session_top as (
        select max(actual_vote_count) as top_vote_count
        from session_results
    )
    select
        session_top.top_vote_count,
        count(*) filter (
            where session_results.actual_vote_count =
                  session_top.top_vote_count
        )::integer,
        min(session_results.artwork_voting_entry_id) filter (
            where session_results.actual_vote_count =
                  session_top.top_vote_count
        ),
        min(session_results.artwork_submission_id) filter (
            where session_results.actual_vote_count =
                  session_top.top_vote_count
        )
    into
        selected_top_vote_count,
        selected_top_tied_count,
        selected_winning_entry_id,
        selected_winning_submission_id
    from session_results
    cross join session_top
    group by session_top.top_vote_count;

    if selected_top_vote_count is null then
        raise exception 'Voting session has no entries';
    end if;

    if selected_top_tied_count <> 1 then
        raise exception 'Top vote is tied; create a tie-break session before finalizing';
    end if;

    select
        submission.profile_id,
        submission.artwork_title,
        submission.design_description,
        submission.cultural_inspiration,
        submission.layer_1_meaning,
        submission.layer_2_meaning,
        submission.layer_3_meaning,
        submission.artwork_file_url
    into
        selected_submission_profile_id,
        selected_artwork_title,
        selected_design_description,
        selected_cultural_inspiration,
        selected_layer_1_meaning,
        selected_layer_2_meaning,
        selected_layer_3_meaning,
        selected_artwork_file_url
    from public.artwork_submissions submission
    where submission.artwork_submission_id =
          selected_winning_submission_id
      and submission.review_status = 'approved';

    if not found then
        raise exception 'Winning submission is not approved';
    end if;

    selected_artwork_meaning := concat_ws(
        E'\n\n',
        'Layer 1: ' || selected_layer_1_meaning,
        'Layer 2: ' || selected_layer_2_meaning,
        'Layer 3: ' || selected_layer_3_meaning
    );

    select artwork.artwork_id
    into selected_artwork_id
    from public.artworks artwork
    where artwork.source_artwork_submission_id =
          selected_winning_submission_id;

    if selected_artwork_id is null then
        insert into public.artworks (
            profile_id,
            source_artwork_submission_id,
            title,
            description,
            artwork_meaning,
            cultural_inspiration,
            image_url,
            status
        )
        values (
            selected_submission_profile_id,
            selected_winning_submission_id,
            left(selected_artwork_title, 150),
            selected_design_description,
            selected_artwork_meaning,
            selected_cultural_inspiration,
            selected_artwork_file_url,
            'published'
        )
        returning artwork_id into selected_artwork_id;
    else
        update public.artworks
        set profile_id = selected_submission_profile_id,
            title = left(selected_artwork_title, 150),
            description = selected_design_description,
            artwork_meaning = selected_artwork_meaning,
            cultural_inspiration = selected_cultural_inspiration,
            image_url = selected_artwork_file_url,
            status = 'published',
            updated_at = now()
        where artwork_id = selected_artwork_id;
    end if;

    insert into public.artwork_campaign_winners (
        artwork_campaign_id,
        artwork_voting_session_id,
        artwork_voting_entry_id,
        artwork_id,
        final_vote_count,
        final_rank,
        announced_by_profile_id
    )
    values (
        selected_campaign_id,
        p_artwork_voting_session_id,
        selected_winning_entry_id,
        selected_artwork_id,
        selected_top_vote_count,
        1,
        selected_admin_profile_id
    )
    returning artwork_campaign_winner_id into created_winner_id;

    update public.artwork_campaigns
    set submission_end_at = least(submission_end_at, now()),
        status = 'completed'
    where artwork_campaign_id = selected_campaign_id;

    return created_winner_id;
end;
$$;

revoke all on function public.finalize_artwork_voting_session(varchar)
from public;
grant execute on function public.finalize_artwork_voting_session(varchar)
to authenticated;

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
alter table public.vendor_tiffins enable row level security;
alter table public.community_posts enable row level security;
alter table public.community_post_photos enable row level security;
alter table public.community_post_likes enable row level security;
alter table public.community_comments enable row level security;
alter table public.artwork_campaigns enable row level security;
alter table public.artwork_submissions enable row level security;
alter table public.artwork_submission_photos enable row level security;
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

create policy heritage_tiffins_admin_manage on public.heritage_tiffins
for all to authenticated
using (public.is_current_profile_admin())
with check (public.is_current_profile_admin());

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

create policy heritage_stories_admin_manage on public.heritage_stories
for all to authenticated
using (public.is_current_profile_admin())
with check (public.is_current_profile_admin());

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

create policy heritage_media_admin_manage on public.heritage_media
for all to authenticated
using (public.is_current_profile_admin())
with check (public.is_current_profile_admin());

create policy tiffin_qr_authenticated_read on public.tiffin_qr_codes
for select to authenticated
using (
    is_active = true
    and (expires_at is null or expires_at > now())
);

create policy tiffin_qr_admin_manage on public.tiffin_qr_codes
for all to authenticated
using (public.is_current_profile_admin())
with check (public.is_current_profile_admin());

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

create policy vendors_admin_manage on public.vendors
for all to authenticated
using (public.is_current_profile_admin())
with check (public.is_current_profile_admin());

create policy vendor_hours_public_read on public.vendor_operating_hours
for select to anon, authenticated
using (
    exists (
        select 1 from public.vendors parent_vendor
        where parent_vendor.vendor_id = vendor_operating_hours.vendor_id
          and parent_vendor.participation_status = 'active'
    )
);

create policy vendor_hours_admin_manage on public.vendor_operating_hours
for all to authenticated
using (public.is_current_profile_admin())
with check (public.is_current_profile_admin());

create policy vendor_foods_public_read on public.vendor_foods
for select to anon, authenticated
using (
    exists (
        select 1 from public.vendors parent_vendor
        where parent_vendor.vendor_id = vendor_foods.vendor_id
          and parent_vendor.participation_status = 'active'
    )
);

create policy vendor_foods_admin_manage on public.vendor_foods
for all to authenticated
using (public.is_current_profile_admin())
with check (public.is_current_profile_admin());

create policy vendor_tiffin_public_read on public.vendor_tiffins
for select to anon, authenticated
using (
    exists (
        select 1 from public.vendors parent_vendor
        where parent_vendor.vendor_id = vendor_tiffins.vendor_id
          and parent_vendor.participation_status = 'active'
    )
);

create policy vendor_tiffins_admin_manage on public.vendor_tiffins
for all to authenticated
using (public.is_current_profile_admin())
with check (public.is_current_profile_admin());

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
using (status in ('active', 'completed'));

create policy campaigns_admin_manage on public.artwork_campaigns
for all to authenticated
using (public.is_current_profile_admin())
with check (public.is_current_profile_admin());

create policy submissions_public_read on public.artwork_submissions
for select to anon, authenticated
using (
    review_status = 'approved'
    and exists (
        select 1
        from public.artwork_campaigns campaign
        where campaign.artwork_campaign_id =
              artwork_submissions.artwork_campaign_id
          and campaign.status in ('active', 'completed')
    )
);

create policy submissions_own_read on public.artwork_submissions
for select to authenticated
using (profile_id = public.current_profile_id());

create policy submissions_admin_read on public.artwork_submissions
for select to authenticated
using (public.is_current_profile_admin());

create policy submissions_admin_update on public.artwork_submissions
for update to authenticated
using (public.is_current_profile_admin())
with check (public.is_current_profile_admin());

create policy submission_photos_public_read
on public.artwork_submission_photos
for select to anon, authenticated
using (
    exists (
        select 1
        from public.artwork_submissions submission
        join public.artwork_campaigns campaign
          on campaign.artwork_campaign_id = submission.artwork_campaign_id
        where submission.artwork_submission_id =
              artwork_submission_photos.artwork_submission_id
          and submission.review_status = 'approved'
          and campaign.status in ('active', 'completed')
    )
);

create policy submission_photos_own_read
on public.artwork_submission_photos
for select to authenticated
using (
    exists (
        select 1 from public.artwork_submissions submission
        where submission.artwork_submission_id =
              artwork_submission_photos.artwork_submission_id
          and submission.profile_id = public.current_profile_id()
    )
);

create policy submission_photos_admin_read
on public.artwork_submission_photos
for select to authenticated
using (public.is_current_profile_admin());

create policy voting_sessions_public_read on public.artwork_voting_sessions
for select to anon, authenticated
using (
    exists (
        select 1 from public.artwork_campaigns campaigns
        where campaigns.artwork_campaign_id = artwork_voting_sessions.artwork_campaign_id
          and campaigns.status in ('active', 'completed')
    )
);

create policy voting_sessions_admin_manage
on public.artwork_voting_sessions
for all to authenticated
using (public.is_current_profile_admin())
with check (public.is_current_profile_admin());

create policy voting_entries_public_read on public.artwork_voting_entries
for select to anon, authenticated
using (
    exists (
        select 1
        from public.artwork_submissions submission
        join public.artwork_voting_sessions voting_session
          on voting_session.artwork_voting_session_id =
             artwork_voting_entries.artwork_voting_session_id
        join public.artwork_campaigns campaign
          on campaign.artwork_campaign_id =
             voting_session.artwork_campaign_id
        where submission.artwork_submission_id =
              artwork_voting_entries.artwork_submission_id
          and submission.artwork_campaign_id =
              voting_session.artwork_campaign_id
          and submission.review_status = 'approved'
          and campaign.status in ('active', 'completed')
    )
);

create policy voting_entries_admin_manage
on public.artwork_voting_entries
for all to authenticated
using (public.is_current_profile_admin())
with check (public.is_current_profile_admin());

create policy artwork_votes_own_read on public.artwork_votes
for select to authenticated
using (profile_id = public.current_profile_id());

create policy artwork_votes_admin_read on public.artwork_votes
for select to authenticated
using (public.is_current_profile_admin());

create policy campaign_winners_public_read
on public.artwork_campaign_winners
for select to anon, authenticated
using (
    exists (
        select 1 from public.artwork_campaigns campaigns
        where campaigns.artwork_campaign_id = artwork_campaign_winners.artwork_campaign_id
          and campaigns.status = 'completed'
    )
    and exists (
        select 1 from public.artworks winner_artwork
        where winner_artwork.artwork_id = artwork_campaign_winners.artwork_id
          and winner_artwork.status = 'published'
    )
);

create policy campaign_winners_admin_read
on public.artwork_campaign_winners
for select to authenticated
using (public.is_current_profile_admin());

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
    entry.artwork_voting_entry_id,
    entry.artwork_voting_session_id,
    voting_session.artwork_campaign_id,
    entry.artwork_submission_id,
    entry.vote_count,
    dense_rank() over (
        partition by entry.artwork_voting_session_id
        order by entry.vote_count desc
    ) as ranking,
    row_number() over (
        partition by entry.artwork_voting_session_id
        order by
            entry.vote_count desc,
            entry.published_at asc,
            entry.artwork_voting_entry_id
    ) as display_order,
    count(*) over (
        partition by
            entry.artwork_voting_session_id,
            entry.vote_count
    ) as tied_entry_count
from public.artwork_voting_entries entry
join public.artwork_voting_sessions voting_session
  on voting_session.artwork_voting_session_id =
     entry.artwork_voting_session_id;

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
    public.vendor_tiffins, public.community_posts,
    public.community_post_photos, public.community_comments,
    public.artwork_campaigns, public.artwork_submissions,
    public.artwork_submission_photos,
    public.artwork_voting_sessions,
    public.artwork_voting_entries, public.artwork_campaign_winners
to anon, authenticated;

grant select on public.tiffin_qr_codes, public.user_tiffin_collection,
    public.community_post_likes, public.artwork_votes
to authenticated;

grant insert, update, delete on public.heritage_tiffins,
    public.heritage_stories, public.heritage_media,
    public.tiffin_qr_codes
to authenticated;

grant usage, select on sequence public.heritage_tiffin_number_seq,
    public.heritage_story_number_seq, public.heritage_media_number_seq,
    public.tiffin_qr_code_number_seq
to authenticated;

grant insert on public.user_tiffin_collection, public.community_posts,
    public.community_post_photos, public.community_post_likes,
    public.community_comments
to authenticated;

-- These table grants are broad enough for PostgREST, while the accompanying
-- RLS policies allow the operations only for active administrators.
grant insert, update, delete on public.artwork_campaigns,
    public.artwork_voting_sessions
to authenticated;

grant insert, delete on public.artwork_voting_entries
to authenticated;

grant update (
    review_status,
    reviewed_by_profile_id,
    reviewed_at
) on public.artwork_submissions to authenticated;

grant delete on public.community_posts, public.community_post_likes
to authenticated;

grant update (rating, written_review, post_comment, status, updated_at)
on public.community_posts to authenticated;

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
    public.artwork_campaign_number_seq,
    public.artwork_voting_session_number_seq,
    public.artwork_voting_entry_number_seq
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

-- Recreate one idempotent daily schedule. pg_cron expressions use UTC on
-- Supabase, so 16:05 UTC runs at 00:05 in Malaysia (UTC+08).
do $$
declare
    existing_job_id bigint;
begin
    for existing_job_id in
        select jobid
        from cron.job
        where jobname = 'complete-expired-artwork-campaigns-daily'
    loop
        perform cron.unschedule(existing_job_id);
    end loop;

    perform cron.schedule(
        'complete-expired-artwork-campaigns-daily',
        '5 16 * * *',
        'select public.complete_expired_artwork_campaigns();'
    );
end;
$$;

notify pgrst, 'reload schema';
commit;
