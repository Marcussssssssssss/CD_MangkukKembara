-- ============================================================================
-- MangkukKembara - Reset and Insert Dummy Data
--
-- Run the schema reset script first.
-- This file removes existing application data using TRUNCATE and then inserts
-- readable hard-coded dummy records.
--
-- Important:
-- auth_user_id is NULL for dummy profiles. Real registered accounts are linked
-- automatically through the Supabase Auth trigger in the schema script.
-- ============================================================================

begin;

-- ============================================================================
-- 1. TRUNCATE ALL APPLICATION TABLES
-- CASCADE removes dependent rows safely.
-- ============================================================================

truncate table
    public.artwork_campaign_winners,
    public.artwork_votes,
    public.artwork_voting_entries,
    public.artwork_voting_sessions,
    public.artwork_submissions,
    public.artwork_campaign_categories,
    public.artwork_campaigns,
    public.community_comments,
    public.community_post_likes,
    public.community_post_photos,
    public.community_posts,
    public.vendor_tiffins,
    public.vendor_foods,
    public.vendor_operating_hours,
    public.vendors,
    public.pasar_malam_operating_hours,
    public.pasar_malam,
    public.user_tiffin_collection,
    public.tiffin_qr_codes,
    public.heritage_media,
    public.heritage_stories,
    public.heritage_tiffins,
    public.artworks,
    public.heritage_foods,
    public.food_categories,
    public.states,
    public.profiles
cascade;

alter sequence public.profile_number_seq restart with 1000;

-- ============================================================================
-- 2. PROFILES
-- Artist information is stored in profiles, not in a separate artists table.
-- ============================================================================

insert into public.profiles (
    profile_id, auth_user_id, role, display_name, avatar_url,
    biography, website_url, country_code, city, is_active
)
values
    (
        'P0001',
        'fd347b4d-a1d9-4ab3-a5f0-c224439b718b'::uuid,
        'admin',
        'Ken',
        null,
        null,
        null,
        'MY',
        null,
        true
    ),
    (
        'P0002',
        '003ad024-fd48-4a61-9fe1-6ed8bf4ca08d'::uuid,
        'tourist',
        'Siuyee',
        null,
        null,
        null,
        'MY',
        null,
        true
    ),
    (
        'P0003',
        '326bbebb-c691-4c1b-9290-7953d240ee0d'::uuid,
        'tourist',
        'test',
        null,
        null,
        null,
        'MY',
        null,
        true
    );

-- ============================================================================
-- 3. STATES AND FOOD CATEGORIES
-- ============================================================================

insert into public.states (state_id, state_code, state_name, description)
values
    ('S0001', 'PNG', 'Penang', 'A state known for multicultural street food.'),
    ('S0002', 'MLK', 'Melaka', 'A historic state known for Peranakan heritage.'),
    ('S0003', 'KTN', 'Kelantan', 'An East Coast state known for traditional arts and cuisine.'),
    ('S0004', 'SWK', 'Sarawak', 'A Borneo state with diverse indigenous food traditions.');

insert into public.food_categories (
    food_category_id, category_name, description
)
values
    ('FC0001', 'Rice Dishes', 'Traditional meals centred on rice.'),
    ('FC0002', 'Noodles', 'Heritage noodle dishes from Malaysian states.'),
    ('FC0003', 'Traditional Specialities', 'Regional dishes prepared using local customs.');

insert into public.heritage_foods (
    heritage_food_id, food_category_id, state_id, food_name,
    origin_summary, cultural_significance, image_url
)
values
    ('HF0001', 'FC0002', 'S0001', 'Penang Char Kway Teow',
     'A wok-fried flat rice noodle dish associated with Penang hawker culture.',
     'Represents Penang food traditions shaped by migration and trade.',
     'https://res.cloudinary.com/demo/image/upload/mangkukkembara/foods/char-kway-teow.jpg'),

    ('HF0002', 'FC0001', 'S0002', 'Melaka Chicken Rice Ball',
     'Chicken rice served with rice shaped into small balls.',
     'Associated with Melaka food heritage and family-run eateries.',
     'https://res.cloudinary.com/demo/image/upload/mangkukkembara/foods/chicken-rice-ball.jpg'),

    ('HF0003', 'FC0001', 'S0003', 'Nasi Kerabu',
     'Blue-coloured rice served with herbs, vegetables, and side dishes.',
     'Highlights Kelantanese ingredients, colours, and communal eating.',
     'https://res.cloudinary.com/demo/image/upload/mangkukkembara/foods/nasi-kerabu.jpg'),

    ('HF0004', 'FC0002', 'S0004', 'Sarawak Laksa',
     'Rice vermicelli served in an aromatic Sarawak-style broth.',
     'A well-known representation of Sarawak food identity.',
     'https://res.cloudinary.com/demo/image/upload/mangkukkembara/foods/sarawak-laksa.jpg');

-- ============================================================================
-- 4. ARTWORKS AND HERITAGE TIFFINS
-- profile_id identifies the tourist/profile who created the artwork.
-- ============================================================================

insert into public.artworks (
    artwork_id, profile_id, title, description, artwork_meaning,
    cultural_inspiration, image_url, status
)
values
    (
        'A0001',
        'P0002',
        'Wok Trails of Penang',
        'A layered illustration of a hawker wok, shophouses, and noodle lines.',
        'The circular movement represents wok cooking and travel through Penang.',
        'Penang hawker centres, batik line work, and George Town streets.',
        'https://res.cloudinary.com/demo/image/upload/mangkukkembara/artworks/wok-trails-penang.jpg',
        'published'
    ),
    (
        'A0002',
        'P0003',
        'Tiles of Melaka',
        'A composition of Peranakan tiles, rice balls, and historic windows.',
        'The repeated patterns represent recipes passed between generations.',
        'Peranakan decorative arts and Melaka shophouses.',
        'https://res.cloudinary.com/demo/image/upload/mangkukkembara/artworks/tiles-of-melaka.jpg',
        'published'
    ),
    (
        'A0003',
        'P0002',
        'Colours of Kelantan',
        'An illustration inspired by blue rice, local herbs, flowers, and traditional textiles.',
        'The blue and green colours represent the relationship between food and nature.',
        'Kelantanese nasi kerabu, local plants, and traditional textile patterns.',
        'https://res.cloudinary.com/demo/image/upload/mangkukkembara/artworks/colours-of-kelantan.jpg',
        'published'
    ),
    (
        'A0004',
        'P0003',
        'Borneo River Traditions',
        'An artwork showing river journeys, local ingredients, and Sarawak food culture.',
        'The flowing river represents traditions shared between communities and generations.',
        'Sarawak river communities, indigenous patterns, and local cuisine.',
        'https://res.cloudinary.com/demo/image/upload/mangkukkembara/artworks/borneo-river-traditions.jpg',
        'published'
    );

insert into public.heritage_tiffins (
    heritage_tiffin_id, edition_name, state_id, heritage_food_id,
    artwork_id, description, cultural_significance,
    cover_image_url, release_year, status
)
values
    ('HT0001', 'Penang Street Flavours 2026', 'S0001', 'HF0001', 'A0001',
     'A reusable heritage tiffin celebrating Penang hawker food.',
     'Connects sustainable dining with George Town food heritage.',
     'https://res.cloudinary.com/demo/image/upload/mangkukkembara/tiffins/penang.jpg',
     2026, 'active'),

    ('HT0002', 'Melaka Peranakan Heritage 2026', 'S0002', 'HF0002', 'A0002',
     'A reusable tiffin featuring Peranakan colours and Melaka food symbols.',
     'Celebrates the blending of cultures in Melaka.',
     'https://res.cloudinary.com/demo/image/upload/mangkukkembara/tiffins/melaka.jpg',
     2026, 'active'),

    ('HT0003', 'East Coast Colours 2026', 'S0003', 'HF0003', 'A0003',
     'A reusable tiffin inspired by blue rice, herbs, and textiles.',
     'Highlights relationships between food, nature, and craft.',
     'https://res.cloudinary.com/demo/image/upload/mangkukkembara/tiffins/kelantan.jpg',
     2026, 'active'),

    ('HT0004', 'Borneo Traditions 2026', 'S0004', 'HF0004', 'A0004',
     'A reusable tiffin inspired by Borneo river journeys.',
     'Promotes awareness of Sarawak food traditions.',
     'https://res.cloudinary.com/demo/image/upload/mangkukkembara/tiffins/sarawak.jpg',
     2026, 'active');

insert into public.heritage_stories (
    heritage_story_id, heritage_tiffin_id, title, story_body, sort_order
)
values
    ('HS0001', 'HT0001', 'From Port City to Hawker Table',
     'Penang food traditions grew through migration, trade, and neighbourhood hawker culture.', 1),
    ('HS0002', 'HT0002', 'A Recipe in Every Tile',
     'Peranakan tile patterns connect with family recipes and festive gatherings.', 1),
    ('HS0003', 'HT0003', 'The Blue Rice Garden',
     'Herbs, flowers, rice, and markets shape the colours of Kelantanese cuisine.', 1),
    ('HS0004', 'HT0004', 'Meals Along the River',
     'Ingredients and food memories are shared between Sarawak river communities.', 1);

insert into public.heritage_media (
    heritage_media_id, heritage_tiffin_id, media_type, title,
    media_url, thumbnail_url, caption, duration_seconds, sort_order
)
values
    ('HM0001', 'HT0001', 'video', 'Penang Hawker Heritage',
     'https://res.cloudinary.com/demo/video/upload/mangkukkembara/penang.mp4',
     'https://res.cloudinary.com/demo/image/upload/mangkukkembara/penang-thumb.jpg',
     'A short introduction to Penang hawker culture.', 120, 1),
    ('HM0002', 'HT0002', 'video', 'Melaka Peranakan Heritage',
     'https://res.cloudinary.com/demo/video/upload/mangkukkembara/melaka.mp4',
     'https://res.cloudinary.com/demo/image/upload/mangkukkembara/melaka-thumb.jpg',
     'A short introduction to Peranakan heritage.', 135, 1),
    ('HM0003', 'HT0003', 'video', 'Kelantan Food Colours',
     'https://res.cloudinary.com/demo/video/upload/mangkukkembara/kelantan.mp4',
     'https://res.cloudinary.com/demo/image/upload/mangkukkembara/kelantan-thumb.jpg',
     'A short introduction to Kelantanese ingredients.', 110, 1),
    ('HM0004', 'HT0004', 'video', 'Sarawak River Foods',
     'https://res.cloudinary.com/demo/video/upload/mangkukkembara/sarawak.mp4',
     'https://res.cloudinary.com/demo/image/upload/mangkukkembara/sarawak-thumb.jpg',
     'A short introduction to Sarawak food traditions.', 125, 1);

insert into public.tiffin_qr_codes (
    tiffin_qr_code_id, heritage_tiffin_id, code_value
)
values
    ('TQC0001', 'HT0001', 'MKK-HT0001-2026'),
    ('TQC0002', 'HT0002', 'MKK-HT0002-2026'),
    ('TQC0003', 'HT0003', 'MKK-HT0003-2026'),
    ('TQC0004', 'HT0004', 'MKK-HT0004-2026');

insert into public.user_tiffin_collection (
    user_tiffin_collection_id, profile_id, heritage_tiffin_id,
    tiffin_qr_code_id, collected_at
)
values
    ('UTC0001', 'P0001', 'HT0001', 'TQC0001', now() - interval '10 days'),
    ('UTC0002', 'P0001', 'HT0002', 'TQC0002', now() - interval '5 days'),
    ('UTC0003', 'P0002', 'HT0003', 'TQC0003', now() - interval '2 days'),
    -- P0003 is the seeded test@gmail.com account; unlock every Heritage Tiffin.
    ('UTC0004', 'P0003', 'HT0001', 'TQC0001', now() - interval '4 days'),
    ('UTC0005', 'P0003', 'HT0002', 'TQC0002', now() - interval '3 days'),
    ('UTC0006', 'P0003', 'HT0003', 'TQC0003', now() - interval '2 days'),
    ('UTC0007', 'P0003', 'HT0004', 'TQC0004', now() - interval '1 day');

-- ============================================================================
-- 5. PASAR MALAM AND VENDORS
-- ============================================================================

insert into public.pasar_malam (
    pasar_malam_id, state_id, pasar_malam_name, description,
    address_line, latitude, longitude, google_place_id
)
values
    ('PM0001', 'S0001', 'George Town Heritage Night Market',
     'A dummy night market featuring Penang heritage food.',
     'Lebuh Armenian, George Town, Penang', 5.4145000, 100.3381000, 'demo_pm_penang'),
    ('PM0002', 'S0002', 'Melaka Riverside Night Market',
     'A dummy night market near the historic centre of Melaka.',
     'Jalan Hang Jebat, Melaka', 2.1944000, 102.2497000, 'demo_pm_melaka');

insert into public.pasar_malam_operating_hours (
    pasar_malam_operating_hours_id, pasar_malam_id, day_of_week,
    opening_time, closing_time, is_closed
)
values
    ('PMOH0001', 'PM0001', 5, '18:00', '23:00', false),
    ('PMOH0002', 'PM0001', 6, '18:00', '23:00', false),
    ('PMOH0003', 'PM0002', 5, '17:00', '23:30', false),
    ('PMOH0004', 'PM0002', 6, '17:00', '23:30', false);

insert into public.vendors (
    vendor_id, pasar_malam_id, state_id, vendor_name, business_type,
    description, contact_person, contact_number, email, address_line,
    latitude, longitude, google_place_id, cover_image_url,
    participation_status, average_rating, review_count
)
values
    ('V0001', 'PM0001', 'S0001', 'Uncle Tan Char Kway Teow', 'night_market_stall',
     'A heritage food stall serving wok-fried char kway teow.',
     'Tan Kok Ming', '+60123456781', 'tan@example.com',
     'Lot 12, George Town Heritage Night Market', 5.4146000, 100.3382000,
     'demo_vendor_1', 'https://res.cloudinary.com/demo/image/upload/mangkukkembara/vendors/v1.jpg',
     'active', 4.50, 2),

    ('V0002', 'PM0002', 'S0002', 'Nyonya Rice Ball House', 'night_market_stall',
     'A family stall serving Melaka chicken rice balls.',
     'Lim Mei Hua', '+60123456782', 'nyonya@example.com',
     'Lot 8, Melaka Riverside Night Market', 2.1945000, 102.2498000,
     'demo_vendor_2', 'https://res.cloudinary.com/demo/image/upload/mangkukkembara/vendors/v2.jpg',
     'active', 5.00, 1),

    ('V0003', null, 'S0003', 'Warung Nasi Kerabu Bunga', 'restaurant',
     'A restaurant specialising in nasi kerabu and local herbs.',
     'Nur Fatimah', '+60123456783', 'kerabu@example.com',
     'Jalan Sultan, Kota Bharu, Kelantan', 6.1254000, 102.2381000,
     'demo_vendor_3', 'https://res.cloudinary.com/demo/image/upload/mangkukkembara/vendors/v3.jpg',
     'active', 4.00, 1),

    ('V0004', null, 'S0004', 'Kuching Laksa Corner', 'cafe',
     'A café serving Sarawak laksa and local drinks.',
     'Margaret Jantan', '+60123456784', 'laksa@example.com',
     'Jalan Padungan, Kuching, Sarawak', 1.5535000, 110.3593000,
     'demo_vendor_4', 'https://res.cloudinary.com/demo/image/upload/mangkukkembara/vendors/v4.jpg',
     'active', 0.00, 0);

insert into public.vendor_operating_hours (
    vendor_operating_hours_id, vendor_id, day_of_week,
    opening_time, closing_time, is_closed
)
values
    ('VOH0001', 'V0001', 5, '18:00', '23:00', false),
    ('VOH0002', 'V0001', 6, '18:00', '23:00', false),
    ('VOH0003', 'V0002', 5, '17:00', '23:30', false),
    ('VOH0004', 'V0002', 6, '17:00', '23:30', false),
    ('VOH0005', 'V0003', 1, '08:00', '17:00', false),
    ('VOH0006', 'V0004', 2, '08:00', '18:00', false);

insert into public.vendor_foods (
    vendor_food_id, vendor_id, heritage_food_id, is_featured
)
values
    ('VF0001', 'V0001', 'HF0001', true),
    ('VF0002', 'V0002', 'HF0002', true),
    ('VF0003', 'V0003', 'HF0003', true),
    ('VF0004', 'V0004', 'HF0004', true);

insert into public.vendor_tiffins (
    vendor_tiffin_id, vendor_id, heritage_tiffin_id
)
values
    ('VT0001', 'V0001', 'HT0001'),
    ('VT0002', 'V0002', 'HT0002'),
    ('VT0003', 'V0003', 'HT0003'),
    ('VT0004', 'V0004', 'HT0004');

-- ============================================================================
-- 6. COMMUNITY DATA
-- ============================================================================

insert into public.community_posts (
    community_post_id, profile_id, vendor_id, rating,
    written_review, post_comment, like_count, comment_count, created_at
)
values
    ('CP0001', 'P0001', 'V0001', 4,
     'The char kway teow had strong wok aroma and generous ingredients.',
     'A good stop during an evening walk in George Town.', 1, 2,
     now() - interval '8 days'),

    ('CP0002', 'P0002', 'V0002', 5,
     'The rice balls were tasty and the vendor explained their history.',
     'The reusable tiffin design was beautiful.', 1, 0,
     now() - interval '3 days'),

    ('CP0003', 'P0001', 'V0003', 4,
     'Fresh herbs and balanced flavours.',
     'I enjoyed learning about the natural blue colour.', 0, 0,
     now() - interval '1 day');

insert into public.community_post_photos (
    community_post_photo_id, community_post_id, photo_url, sort_order
)
values
    ('CPP0001', 'CP0001', 'https://res.cloudinary.com/demo/image/upload/mangkukkembara/posts/cp1-1.jpg', 1),
    ('CPP0002', 'CP0001', 'https://res.cloudinary.com/demo/image/upload/mangkukkembara/posts/cp1-2.jpg', 2),
    ('CPP0003', 'CP0002', 'https://res.cloudinary.com/demo/image/upload/mangkukkembara/posts/cp2-1.jpg', 1);

insert into public.community_post_likes (
    community_post_like_id, community_post_id, profile_id
)
values
    ('CPL0001', 'CP0001', 'P0002'),
    ('CPL0002', 'CP0002', 'P0001');

insert into public.community_comments (
    community_comment_id, community_post_id, profile_id,
    parent_comment_id, comment_text, created_at
)
values
    ('CC0001', 'CP0001', 'P0002', null,
     'The night market atmosphere looks interesting.', now() - interval '7 days'),
    ('CC0002', 'CP0001', 'P0001', 'CC0001',
     'Yes, it becomes lively after 7 PM.', now() - interval '6 days');

-- ============================================================================
-- 7. ARTWORK CAMPAIGN AND VOTING DATA
-- ============================================================================

insert into public.artwork_campaigns (
    artwork_campaign_id, campaign_title, description,
    submission_start_at, submission_end_at, status,
    created_by_profile_id
)
values
    ('AC0001', 'Heritage Tiffin Design Campaign 2026',
     'A campaign for tourists to submit state-themed heritage tiffin artwork.',
     '2026-01-01 00:00:00+08', '2026-03-31 23:59:59+08',
     'completed', 'P0001');

insert into public.artwork_campaign_categories (
    artwork_campaign_category_id, artwork_campaign_id,
    state_id, category_name
)
values
    ('ACC0001', 'AC0001', 'S0001', 'Penang Heritage Design'),
    ('ACC0002', 'AC0001', 'S0002', 'Melaka Heritage Design');

insert into public.artwork_submissions (
    artwork_submission_id, artwork_campaign_category_id, profile_id,
    artwork_title, design_description, cultural_inspiration,
    artist_statement, artwork_file_url, review_status,
    submitted_at, reviewed_by_profile_id, reviewed_at
)
values
    ('AS0001', 'ACC0001', 'P0002', 'Penang Spice Routes',
     'A design combining spice trails, shophouses, and hawker tools.',
     'Penang trade history and street-food culture.',
     'The design represents movement between cultures and food traditions.',
     'https://res.cloudinary.com/demo/image/upload/mangkukkembara/submissions/as1.jpg',
     'approved', '2026-02-10 10:00:00+08', 'P0001', '2026-04-02 09:00:00+08'),

    ('AS0002', 'ACC0001', 'P0001', 'Island Food Journey',
     'A design showing an island path connecting famous food dishes.',
     'Penang island travel and local cuisine.',
     'The path represents a tourist journey through food.',
     'https://res.cloudinary.com/demo/image/upload/mangkukkembara/submissions/as2.jpg',
     'approved', '2026-02-20 14:00:00+08', 'P0001', '2026-04-02 09:10:00+08'),

    ('AS0003', 'ACC0002', 'P0003', 'Melaka Window Stories',
     'A design using heritage windows, tiles, and dining symbols.',
     'Historic Melaka architecture and Peranakan culture.',
     'Each window represents a story shared across generations.',
     'https://res.cloudinary.com/demo/image/upload/mangkukkembara/submissions/as3.jpg',
     'approved', '2026-02-15 11:00:00+08', 'P0001', '2026-04-02 09:20:00+08');

insert into public.artwork_voting_sessions (
    artwork_voting_session_id, artwork_campaign_id,
    voting_start_at, voting_end_at, status
)
values
    ('AVS0001', 'AC0001',
     '2026-04-10 00:00:00+08', '2026-05-10 23:59:59+08', 'closed');

insert into public.artwork_voting_entries (
    artwork_voting_entry_id, artwork_voting_session_id,
    artwork_campaign_category_id, artwork_submission_id,
    vote_count, published_at
)
values
    ('AVE0001', 'AVS0001', 'ACC0001', 'AS0001', 2, '2026-04-05 10:00:00+08'),
    ('AVE0002', 'AVS0001', 'ACC0001', 'AS0002', 0, '2026-04-05 10:05:00+08'),
    ('AVE0003', 'AVS0001', 'ACC0002', 'AS0003', 1, '2026-04-05 10:10:00+08');

insert into public.artwork_votes (
    artwork_vote_id, artwork_voting_session_id,
    artwork_campaign_category_id, artwork_voting_entry_id,
    profile_id, voted_at
)
values
    ('AV0001', 'AVS0001', 'ACC0001', 'AVE0001', 'P0001', '2026-04-15 12:00:00+08'),
    ('AV0002', 'AVS0001', 'ACC0001', 'AVE0001', 'P0002', '2026-04-16 13:00:00+08'),
    ('AV0003', 'AVS0001', 'ACC0002', 'AVE0003', 'P0001', '2026-04-17 14:00:00+08');

insert into public.artwork_campaign_winners (
    artwork_campaign_winner_id, artwork_campaign_id,
    artwork_campaign_category_id, artwork_voting_entry_id,
    final_vote_count, final_rank, announced_by_profile_id, announced_at
)
values
    ('ACW0001', 'AC0001', 'ACC0001', 'AVE0001', 2, 1, 'P0001', '2026-05-15 10:00:00+08'),
    ('ACW0002', 'AC0001', 'ACC0002', 'AVE0003', 1, 1, 'P0001', '2026-05-15 10:05:00+08');

-- ============================================================================
-- 8. RESTORE PROFILES FOR PRESERVED SUPABASE AUTH USERS
-- auth.users is not truncated by this seed. Recreate every missing link after
-- the dummy P0001-P0007 rows have been inserted; real accounts use P1000+.
-- ============================================================================

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

commit;
