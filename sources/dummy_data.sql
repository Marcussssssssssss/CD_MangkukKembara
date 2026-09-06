-- ============================================================================
-- MangkukKembara - Reset and Insert Dummy Data
--
-- Run the schema reset script first.
-- This file removes existing application data using TRUNCATE and then inserts
-- readable hard-coded dummy records.
--
-- Important:
-- P0001-P0003 use fixed development Auth UUIDs. Any other preserved Auth users
-- are linked to newly generated P1000+ profiles near the end of this script.
-- ============================================================================
begin;
-- ============================================================================
-- 1. TRUNCATE ALL APPLICATION TABLES
-- CASCADE removes dependent rows safely.
-- ============================================================================
truncate table public.artwork_campaign_winners,
public.artwork_votes,
public.artwork_voting_entries,
public.artwork_voting_sessions,
public.artwork_submission_photos,
public.artwork_submissions,
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
public.profiles cascade;
alter sequence public.profile_number_seq restart with 1000;
alter sequence public.heritage_tiffin_number_seq restart with 1000;
alter sequence public.heritage_story_number_seq restart with 1000;
alter sequence public.heritage_media_number_seq restart with 1000;
alter sequence public.tiffin_qr_code_number_seq restart with 1000;
alter sequence public.user_tiffin_collection_number_seq restart with 1000;
alter sequence public.community_post_number_seq restart with 1000;
alter sequence public.community_post_photo_number_seq restart with 1000;
alter sequence public.community_post_like_number_seq restart with 1000;
alter sequence public.community_comment_number_seq restart with 1000;
alter sequence public.artwork_number_seq restart with 1000;
alter sequence public.artwork_campaign_number_seq restart with 1000;
alter sequence public.artwork_submission_number_seq restart with 1000;
alter sequence public.artwork_submission_photo_number_seq restart with 1000;
alter sequence public.artwork_voting_session_number_seq restart with 1000;
alter sequence public.artwork_voting_entry_number_seq restart with 1000;
alter sequence public.artwork_vote_number_seq restart with 1000;
alter sequence public.artwork_campaign_winner_number_seq restart with 1000;
-- ============================================================================
-- 2. PROFILES
-- Artist information is stored in profiles, not in a separate artists table.
-- ============================================================================
insert into public.profiles (
        profile_id,
        auth_user_id,
        role,
        display_name,
        avatar_url,
        biography,
        website_url,
        country_code,
        city,
        is_active
    )
values (
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
        'admin',
        'test',
        null,
        null,
        null,
        'MY',
        null,
        true
    ),
    (
        'P1002',
        '9982e9ef-6d0a-45e4-9ba1-3bed6ccd8385'::uuid,
        'admin',
        'Marcus',
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
values (
        'S0001',
        'PNG',
        'Penang',
        'A state known for multicultural street food.'
    ),
    (
        'S0002',
        'MLK',
        'Melaka',
        'A historic state known for Peranakan heritage.'
    ),
    (
        'S0003',
        'KTN',
        'Kelantan',
        'An East Coast state known for traditional arts and cuisine.'
    ),
    (
        'S0004',
        'SWK',
        'Sarawak',
        'A Borneo state with diverse indigenous food traditions.'
    ),
    ('S0005', 'JHR', 'Johor', null),
    ('S0006', 'KDH', 'Kedah', null),
    ('S0007', 'NSN', 'Negeri Sembilan', null),
    ('S0008', 'PHG', 'Pahang', null),
    ('S0009', 'PRK', 'Perak', null),
    ('S0010', 'PLS', 'Perlis', null),
    ('S0011', 'SBH', 'Sabah', null),
    ('S0012', 'SGR', 'Selangor', null),
    ('S0013', 'TRG', 'Terengganu', null),
    ('S0014', 'KUL', 'Kuala Lumpur', null),
    ('S0015', 'LBN', 'Labuan', null),
    ('S0016', 'PJY', 'Putrajaya', null);
insert into public.food_categories (
        food_category_id,
        category_name,
        description
    )
values (
        'FC0001',
        'Rice Dishes',
        'Traditional meals centred on rice.'
    ),
    (
        'FC0002',
        'Noodles',
        'Heritage noodle dishes from Malaysian states.'
    ),
    (
        'FC0003',
        'Traditional Specialities',
        'Regional dishes prepared using local customs.'
    ),
    (
        'FC0004',
        'Traditional Desserts',
        'Traditional Malaysian sweets, puddings, and desserts.'
    );
insert into public.heritage_foods (
        heritage_food_id,
        food_category_id,
        state_id,
        food_name,
        origin_summary,
        cultural_significance,
        image_url
    )
values (
        'HF0001',
        'FC0002',
        'S0001',
        'Penang Char Kway Teow',
        'A wok-fried flat rice noodle dish associated with Penang hawker culture.',
        'Represents Penang food traditions shaped by migration and trade.',
        'https://res.cloudinary.com/hv2ectij/image/upload/v1786290630/Penang_Char_Kway_Teow_xwkaoq.jpg'
    ),
    (
        'HF0002',
        'FC0001',
        'S0002',
        'Melaka Chicken Rice Ball',
        'Chicken rice served with rice shaped into small balls.',
        'Associated with Melaka food heritage and family-run eateries.',
        'https://res.cloudinary.com/hv2ectij/image/upload/v1786290629/Melaka_Chicken_Rice_Ball_egx2ky.jpg'
    ),
    (
        'HF0003',
        'FC0001',
        'S0003',
        'Nasi Kerabu',
        'Blue-coloured rice served with herbs, vegetables, and side dishes.',
        'Highlights Kelantanese ingredients, colours, and communal eating.',
        'https://res.cloudinary.com/hv2ectij/image/upload/v1786290630/Nasi_Kerabu_h0zkda.jpg'
    ),
    (
        'HF0004',
        'FC0002',
        'S0004',
        'Sarawak Laksa',
        'Rice vermicelli served in an aromatic Sarawak-style broth.',
        'A well-known representation of Sarawak food identity.',
        'https://res.cloudinary.com/hv2ectij/image/upload/v1786290629/Sarawak_Laksa_yyvjsc.jpg'
    ),
    ('HF0005', 'FC0002', 'S0005', 'Laksa Johor', null, null, null),
    ('HF0006', 'FC0002', 'S0006', 'Laksa Kuala Kedah', null, null, null),
    ('HF0007', 'FC0003', 'S0007', 'Masak Lemak Cili Api', null, null, null),
    ('HF0008', 'FC0003', 'S0008', 'Patin Masak Tempoyak', null, null, null),
    ('HF0009', 'FC0002', 'S0009', 'Ipoh Sar Hor Fun', null, null, null),
    ('HF0010', 'FC0002', 'S0010', 'Laksa Perlis', null, null, null),
    ('HF0011', 'FC0003', 'S0011', 'Hinava', null, null, null),
    ('HF0012', 'FC0003', 'S0012', 'Satay Kajang', null, null, null),
    ('HF0013', 'FC0001', 'S0013', 'Nasi Dagang', null, null, null),
    ('HF0014', 'FC0002', 'S0014', 'Kuala Lumpur Hokkien Mee', null, null, null),
    ('HF0015', 'FC0004', 'S0015', 'Labuan Coconut Pudding', null, null, null);
-- ============================================================================
-- 4. ARTWORKS AND HERITAGE TIFFINS
-- profile_id identifies the tourist/profile who created the artwork.
-- ============================================================================
insert into public.artworks (
        artwork_id,
        profile_id,
        title,
        description,
        artwork_meaning,
        cultural_inspiration,
        image_url,
        status
    )
values (
        'A0001',
        'P0002',
        'Wok Trails of Penang',
        'A layered illustration of a hawker wok, shophouses, and noodle lines.',
        'The circular movement represents wok cooking and travel through Penang.',
        'Penang hawker centres, batik line work, and George Town streets.',
        'https://res.cloudinary.com/hv2ectij/image/upload/v1787289201/penang_evowlw.png',
        'published'
    ),
    (
        'A0002',
        'P0003',
        'Tiles of Melaka',
        'A composition of Peranakan tiles, rice balls, and historic windows.',
        'The repeated patterns represent recipes passed between generations.',
        'Peranakan decorative arts and Melaka shophouses.',
        'https://res.cloudinary.com/hv2ectij/image/upload/v1787289200/melaka_wqzlqa.png',
        'published'
    ),
    (
        'A0003',
        'P0002',
        'Colours of Kelantan',
        'An illustration inspired by blue rice, local herbs, flowers, and traditional textiles.',
        'The blue and green colours represent the relationship between food and nature.',
        'Kelantanese nasi kerabu, local plants, and traditional textile patterns.',
        'https://res.cloudinary.com/hv2ectij/image/upload/v1787289204/east_xervnk.png',
        'published'
    ),
    (
        'A0004',
        'P0003',
        'Borneo River Traditions',
        'An artwork showing river journeys, local ingredients, and Sarawak food culture.',
        'The flowing river represents traditions shared between communities and generations.',
        'Sarawak river communities, indigenous patterns, and local cuisine.',
        'https://res.cloudinary.com/hv2ectij/image/upload/v1787289200/borneo_p0z9n5.png',
        'published'
    );
insert into public.heritage_tiffins (
        heritage_tiffin_id,
        edition_name,
        state_id,
        heritage_food_id,
        artwork_id,
        description,
        cultural_significance,
        cover_image_url,
        release_year,
        status
    )
values (
        'HT0001',
        'Penang Street Flavours 2026',
        'S0001',
        'HF0001',
        'A0001',
        'A reusable heritage tiffin celebrating Penang hawker food.',
        'Connects sustainable dining with George Town food heritage.',
        'https://res.cloudinary.com/hv2ectij/image/upload/v1787289201/penang_evowlw.png',
        2026,
        'active'
    ),
    (
        'HT0002',
        'Melaka Peranakan Heritage 2026',
        'S0002',
        'HF0002',
        'A0002',
        'A reusable tiffin featuring Peranakan colours and Melaka food symbols.',
        'Celebrates the blending of cultures in Melaka.',
        'https://res.cloudinary.com/hv2ectij/image/upload/v1787289200/melaka_wqzlqa.png',
        2026,
        'active'
    ),
    (
        'HT0003',
        'East Coast Colours 2026',
        'S0003',
        'HF0003',
        'A0003',
        'A reusable tiffin inspired by blue rice, herbs, and textiles.',
        'Highlights relationships between food, nature, and craft.',
        'https://res.cloudinary.com/hv2ectij/image/upload/v1787289204/east_xervnk.png',
        2026,
        'active'
    ),
    (
        'HT0004',
        'Borneo Traditions 2026',
        'S0004',
        'HF0004',
        'A0004',
        'A reusable tiffin inspired by Borneo river journeys.',
        'Promotes awareness of Sarawak food traditions.',
        'https://res.cloudinary.com/hv2ectij/image/upload/v1787289200/borneo_p0z9n5.png',
        2026,
        'active'
    );
insert into public.heritage_stories (
        heritage_story_id,
        heritage_tiffin_id,
        title,
        story_body,
        sort_order
    )
values (
        'HS0001',
        'HT0001',
        'From Port City to Hawker Table',
        'Penang food traditions grew through migration, trade, and neighbourhood hawker culture.',
        1
    ),
    (
        'HS0002',
        'HT0002',
        'A Recipe in Every Tile',
        'Peranakan tile patterns connect with family recipes and festive gatherings.',
        1
    ),
    (
        'HS0003',
        'HT0003',
        'The Blue Rice Garden',
        'Herbs, flowers, rice, and markets shape the colours of Kelantanese cuisine.',
        1
    ),
    (
        'HS0004',
        'HT0004',
        'Meals Along the River',
        'Ingredients and food memories are shared between Sarawak river communities.',
        1
    );
insert into public.heritage_media (
        heritage_media_id,
        heritage_tiffin_id,
        media_type,
        title,
        media_url,
        thumbnail_url,
        caption,
        duration_seconds,
        sort_order
    )
values (
        'HM0001',
        'HT0001',
        'video',
        'Penang Hawker Heritage',
        'https://res.cloudinary.com/demo/video/upload/mangkukkembara/penang.mp4',
        'https://res.cloudinary.com/demo/image/upload/mangkukkembara/penang-thumb.jpg',
        'A short introduction to Penang hawker culture.',
        120,
        1
    ),
    (
        'HM0002',
        'HT0002',
        'video',
        'Melaka Peranakan Heritage',
        'https://res.cloudinary.com/demo/video/upload/mangkukkembara/melaka.mp4',
        'https://res.cloudinary.com/demo/image/upload/mangkukkembara/melaka-thumb.jpg',
        'A short introduction to Peranakan heritage.',
        135,
        1
    ),
    (
        'HM0003',
        'HT0003',
        'video',
        'Kelantan Food Colours',
        'https://res.cloudinary.com/demo/video/upload/mangkukkembara/kelantan.mp4',
        'https://res.cloudinary.com/demo/image/upload/mangkukkembara/kelantan-thumb.jpg',
        'A short introduction to Kelantanese ingredients.',
        110,
        1
    ),
    (
        'HM0004',
        'HT0004',
        'video',
        'Sarawak River Foods',
        'https://res.cloudinary.com/demo/video/upload/mangkukkembara/sarawak.mp4',
        'https://res.cloudinary.com/demo/image/upload/mangkukkembara/sarawak-thumb.jpg',
        'A short introduction to Sarawak food traditions.',
        125,
        1
    );
insert into public.tiffin_qr_codes (
        tiffin_qr_code_id,
        heritage_tiffin_id,
        code_value
    )
values ('TQC0001', 'HT0001', 'MKK-HT0001-2026'),
    ('TQC0002', 'HT0002', 'MKK-HT0002-2026'),
    ('TQC0003', 'HT0003', 'MKK-HT0003-2026'),
    ('TQC0004', 'HT0004', 'MKK-HT0004-2026');
insert into public.user_tiffin_collection (
        user_tiffin_collection_id,
        profile_id,
        heritage_tiffin_id,
        tiffin_qr_code_id,
        collected_at
    )
values (
        'UTC0001',
        'P0001',
        'HT0001',
        'TQC0001',
        now() - interval '10 days'
    ),
    (
        'UTC0002',
        'P0001',
        'HT0002',
        'TQC0002',
        now() - interval '5 days'
    ),
    (
        'UTC0003',
        'P0002',
        'HT0003',
        'TQC0003',
        now() - interval '2 days'
    ),
    -- P0003 is the seeded test@gmail.com account; unlock every Heritage Tiffin.
    (
        'UTC0004',
        'P0003',
        'HT0001',
        'TQC0001',
        now() - interval '4 days'
    ),
    (
        'UTC0005',
        'P0003',
        'HT0002',
        'TQC0002',
        now() - interval '3 days'
    ),
    (
        'UTC0006',
        'P0003',
        'HT0003',
        'TQC0003',
        now() - interval '2 days'
    ),
    (
        'UTC0007',
        'P0003',
        'HT0004',
        'TQC0004',
        now() - interval '1 day'
    );
-- ============================================================================
-- 5. PASAR MALAM AND VENDORS
-- ============================================================================
insert into public.pasar_malam (
        pasar_malam_id,
        state_id,
        pasar_malam_name,
        description,
        address_line,
        latitude,
        longitude,
        google_place_id
    )
values (
        'PM0001',
        'S0001',
        'George Town Heritage Night Market',
        'A dummy night market featuring Penang heritage food.',
        'Lebuh Armenian, George Town, Penang',
        5.4145000,
        100.3381000,
        'demo_pm_penang'
    ),
    (
        'PM0002',
        'S0002',
        'Melaka Riverside Night Market',
        'A dummy night market near the historic centre of Melaka.',
        'Jalan Hang Jebat, Melaka',
        2.1944000,
        102.2497000,
        'demo_pm_melaka'
    );
insert into public.pasar_malam_operating_hours (
        pasar_malam_operating_hours_id,
        pasar_malam_id,
        day_of_week,
        opening_time,
        closing_time,
        is_closed
    )
values ('PMOH0001', 'PM0001', 5, '18:00', '23:00', false),
    ('PMOH0002', 'PM0001', 6, '18:00', '23:00', false),
    ('PMOH0003', 'PM0002', 5, '17:00', '23:30', false),
    ('PMOH0004', 'PM0002', 6, '17:00', '23:30', false);
insert into public.vendors (
        vendor_id,
        pasar_malam_id,
        state_id,
        vendor_name,
        business_type,
        description,
        contact_person,
        contact_number,
        email,
        address_line,
        latitude,
        longitude,
        google_place_id,
        cover_image_url,
        participation_status,
        average_rating,
        review_count
    )
values (
        'V0001',
        'PM0001',
        'S0001',
        'Uncle Tan Char Kway Teow',
        'night_market_stall',
        'A heritage food stall serving wok-fried char kway teow.',
        'Tan Kok Ming',
        '+60123456781',
        'tan@example.com',
        'Lot 12, George Town Heritage Night Market',
        5.4146000,
        100.3382000,
        'demo_vendor_1',
        'https://res.cloudinary.com/hv2ectij/image/upload/v1786293488/ChatGPT_Image_Aug_10_2026_12_37_40_AM_5_lyyamv.png',
        'active',
        4.50,
        2
    ),
    (
        'V0002',
        'PM0002',
        'S0002',
        'Nyonya Rice Ball House',
        'night_market_stall',
        'A family stall serving Melaka chicken rice balls.',
        'Lim Mei Hua',
        '+60123456782',
        'nyonya@example.com',
        'Lot 8, Melaka Riverside Night Market',
        2.1945000,
        102.2498000,
        'demo_vendor_2',
        'https://res.cloudinary.com/hv2ectij/image/upload/v1786293490/ChatGPT_Image_Aug_10_2026_12_37_39_AM_2_bltwe7.png',
        'active',
        5.00,
        1
    ),
    (
        'V0003',
        null,
        'S0003',
        'Warung Nasi Kerabu Bunga',
        'restaurant',
        'A restaurant specialising in nasi kerabu and local herbs.',
        'Nur Fatimah',
        '+60123456783',
        'kerabu@example.com',
        'Jalan Sultan, Kota Bharu, Kelantan',
        6.1254000,
        102.2381000,
        'demo_vendor_3',
        'https://res.cloudinary.com/hv2ectij/image/upload/v1786293489/ChatGPT_Image_Aug_10_2026_12_37_40_AM_6_lfgjoi.png',
        'active',
        4.00,
        1
    ),
    (
        'V0004',
        null,
        'S0004',
        'Kuching Laksa Corner',
        'cafe',
        'A café serving Sarawak laksa and local drinks.',
        'Margaret Jantan',
        '+60123456784',
        'laksa@example.com',
        'Jalan Padungan, Kuching, Sarawak',
        1.5535000,
        110.3593000,
        'demo_vendor_4',
        'https://res.cloudinary.com/hv2ectij/image/upload/v1786292362/ChatGPT_Image_Aug_10_2026_12_18_23_AM_2_u8p2k9.png',
        'active',
        0.00,
        0
    ),
    (
        'V0005',
        'PM0001',
        'S0001',
        'Sister Lee Hokkien Mee',
        'night_market_stall',
        'A late-night noodle stall serving Penang-style prawn mee with a rich chilli broth.',
        'Lee Jia Wen',
        '+60123456785',
        'sisterlee@example.com',
        'Lot 18, George Town Heritage Night Market',
        5.4147200,
        100.3383400,
        'demo_vendor_5',
        'https://res.cloudinary.com/hv2ectij/image/upload/v1786293487/ChatGPT_Image_Aug_10_2026_12_37_39_AM_4_yuobtm.png',
        'active',
        4.80,
        15
    ),
    (
        'V0006',
        'PM0001',
        'S0001',
        'Heritage Rice Bowl Penang',
        'night_market_stall',
        'A market stall pairing local rice dishes with rotating heritage side dishes.',
        'Aisha Rahman',
        '+60123456786',
        'ricebowl.penang@example.com',
        'Lot 25, George Town Heritage Night Market',
        5.4143800,
        100.3379400,
        'demo_vendor_6',
        'https://res.cloudinary.com/hv2ectij/image/upload/v1786293488/ChatGPT_Image_Aug_10_2026_12_37_38_AM_1_fnrsoz.png',
        'active',
        0.00,
        0
    ),
    (
        'V0007',
        'PM0002',
        'S0002',
        'Jonker Nyonya Kitchen',
        'night_market_stall',
        'A Peranakan family stall known for savoury rice dishes and traditional spice blends.',
        'Chong Pei Ling',
        '+60123456787',
        'jonkernyonya@example.com',
        'Lot 14, Melaka Riverside Night Market',
        2.1946100,
        102.2495600,
        'demo_vendor_7',
        'https://res.cloudinary.com/hv2ectij/image/upload/v1786292363/ChatGPT_Image_Aug_10_2026_12_18_23_AM_1_nqg4nl.png',
        'active',
        4.25,
        8
    ),
    (
        'V0008',
        'PM0002',
        'S0002',
        'Riverside Heritage Bites',
        'night_market_stall',
        'A friendly night-market stall offering small portions of Malaysian heritage favourites.',
        'Muhammad Hafiz',
        '+60123456788',
        'riversidebites@example.com',
        'Lot 21, Melaka Riverside Night Market',
        2.1942400,
        102.2499100,
        'demo_vendor_8',
        'https://res.cloudinary.com/hv2ectij/image/upload/v1786293490/ChatGPT_Image_Aug_10_2026_12_37_39_AM_3_ba0mch.png',
        'active',
        3.75,
        4
    );
insert into public.vendor_operating_hours (
        vendor_operating_hours_id,
        vendor_id,
        day_of_week,
        opening_time,
        closing_time,
        is_closed
    )
values ('VOH0001', 'V0001', 5, '18:00', '23:00', false),
    ('VOH0002', 'V0001', 6, '18:00', '23:00', false),
    ('VOH0003', 'V0002', 5, '17:00', '23:30', false),
    ('VOH0004', 'V0002', 6, '17:00', '23:30', false),
    ('VOH0005', 'V0003', 1, '08:00', '17:00', false),
    ('VOH0006', 'V0004', 2, '08:00', '18:00', false),
    ('VOH0007', 'V0005', 5, '18:30', '23:00', false),
    ('VOH0008', 'V0005', 6, '18:30', '23:00', false),
    ('VOH0009', 'V0006', 5, '18:00', '22:30', false),
    ('VOH0010', 'V0006', 6, '18:00', '22:30', false),
    ('VOH0011', 'V0007', 5, '17:30', '23:30', false),
    ('VOH0012', 'V0007', 6, '17:30', '23:30', false),
    ('VOH0013', 'V0008', 5, '17:00', '22:00', false),
    ('VOH0014', 'V0008', 6, '17:00', '22:00', false);
insert into public.vendor_foods (
        vendor_food_id,
        vendor_id,
        heritage_food_id,
        is_featured
    )
values ('VF0001', 'V0001', 'HF0001', true),
    ('VF0002', 'V0002', 'HF0002', true),
    ('VF0003', 'V0003', 'HF0003', true),
    ('VF0004', 'V0004', 'HF0004', true),
    ('VF0005', 'V0005', 'HF0001', true),
    ('VF0006', 'V0005', 'HF0002', false),
    ('VF0007', 'V0006', 'HF0002', true),
    ('VF0008', 'V0006', 'HF0003', false),
    ('VF0009', 'V0007', 'HF0002', true),
    ('VF0010', 'V0007', 'HF0003', false),
    ('VF0011', 'V0008', 'HF0004', true),
    ('VF0012', 'V0008', 'HF0001', false);
insert into public.vendor_tiffins (
        vendor_tiffin_id,
        vendor_id,
        heritage_tiffin_id
    )
values ('VT0001', 'V0001', 'HT0001'),
    ('VT0002', 'V0002', 'HT0002'),
    ('VT0003', 'V0003', 'HT0003'),
    ('VT0004', 'V0004', 'HT0004'),
    ('VT0005', 'V0005', 'HT0001'),
    ('VT0006', 'V0006', 'HT0001'),
    ('VT0007', 'V0007', 'HT0002'),
    ('VT0008', 'V0008', 'HT0002');
-- ============================================================================
-- 6. COMMUNITY DATA
-- ============================================================================
insert into public.community_posts (
        community_post_id,
        profile_id,
        vendor_id,
        rating,
        written_review,
        post_comment,
        like_count,
        comment_count,
        created_at
    )
values (
        'CP0001',
        'P0001',
        'V0001',
        4,
        'The char kway teow had strong wok aroma and generous ingredients.',
        'A good stop during an evening walk in George Town.',
        1,
        2,
        now() - interval '8 days'
    ),
    (
        'CP0002',
        'P0002',
        'V0002',
        5,
        'The rice balls were tasty and the vendor explained their history.',
        'The reusable tiffin design was beautiful.',
        1,
        0,
        now() - interval '3 days'
    ),
    (
        'CP0003',
        'P0001',
        'V0003',
        4,
        'Fresh herbs and balanced flavours.',
        'I enjoyed learning about the natural blue colour.',
        0,
        0,
        now() - interval '1 day'
    );
insert into public.community_post_photos (
        community_post_photo_id,
        community_post_id,
        photo_url,
        sort_order
    )
values (
        'CPP0001',
        'CP0001',
        'https://res.cloudinary.com/hv2ectij/image/upload/v1786297888/ChatGPT_Image_Aug_10_2026_01_51_06_AM_2_cteav7.png',
        1
    ),
    (
        'CPP0002',
        'CP0001',
        'https://res.cloudinary.com/hv2ectij/image/upload/v1786297888/ChatGPT_Image_Aug_10_2026_01_51_06_AM_3_jaoaws.png',
        2
    ),
    (
        'CPP0003',
        'CP0002',
        'https://res.cloudinary.com/hv2ectij/image/upload/v1786297888/ChatGPT_Image_Aug_10_2026_01_51_05_AM_1_exarhe.png',
        1
    );
insert into public.community_post_likes (
        community_post_like_id,
        community_post_id,
        profile_id
    )
values ('CPL0001', 'CP0001', 'P0002'),
    ('CPL0002', 'CP0002', 'P0001');
insert into public.community_comments (
        community_comment_id,
        community_post_id,
        profile_id,
        parent_comment_id,
        comment_text,
        created_at
    )
values (
        'CC0001',
        'CP0001',
        'P0002',
        null,
        'The night market atmosphere looks interesting.',
        now() - interval '7 days'
    ),
    (
        'CC0002',
        'CP0001',
        'P0001',
        'CC0001',
        'Yes, it becomes lively after 7 PM.',
        now() - interval '6 days'
    );
-- ============================================================================
-- 7. ARTWORK CAMPAIGN AND VOTING DATA
-- ============================================================================
-- The seed supplies stable AVS0001... IDs below. Suppress automatic standard
-- session creation while inserting its campaigns so those references remain
-- deterministic.
alter table public.artwork_campaigns
disable trigger create_artwork_campaign_voting_session_trigger;

insert into public.artwork_campaigns (
        artwork_campaign_id,
        state_id,
        campaign_title,
        description,
        submission_start_at,
        submission_end_at,
        status,
        created_by_profile_id
    )
values (
        'AC0001',
        'S0001',
        'Penang Heritage Tiffin Design Campaign 2026',
        'A completed campaign for a Penang-inspired heritage tiffin design.',
        '2026-01-01 00:00:00+08',
        '2026-03-31 23:59:00+08',
        'completed',
        'P0001'
    ),
    (
        'AC0002',
        'S0002',
        'Melaka Heritage Tiffin Design Campaign 2026',
        'A completed campaign for a Melaka-inspired heritage tiffin design.',
        '2026-01-01 00:00:00+08',
        '2026-03-31 23:59:00+08',
        'completed',
        'P0001'
    ),
    (
        'AC0003',
        'S0003',
        'Kelantan Heritage Tiffin Design Campaign 2026',
        'A completed campaign for a Kelantan-inspired heritage tiffin design.',
        '2026-01-01 00:00:00+08',
        '2026-03-31 23:59:00+08',
        'completed',
        'P0001'
    ),
    (
        'AC0004',
        'S0004',
        'Sarawak Heritage Tiffin Design Campaign 2026',
        'A completed campaign for a Sarawak-inspired heritage tiffin design.',
        '2026-01-01 00:00:00+08',
        '2026-03-31 23:59:00+08',
        'completed',
        'P0001'
    ),
    (
        'AC0005',
        'S0001',
        'Penang Food Stories Tiffin Design Campaign',
        'An active campaign inviting Penang-inspired food-story artwork.',
        (current_date - 30) + time '00:00:00',
        (current_date + 60) + time '23:59:00',
        'active',
        'P0001'
    );

alter table public.artwork_campaigns
enable trigger create_artwork_campaign_voting_session_trigger;

insert into public.artwork_submissions (
        artwork_submission_id,
        artwork_campaign_id,
        profile_id,
        artwork_title,
        design_description,
        cultural_inspiration,
        layer_1_meaning,
        layer_2_meaning,
        layer_3_meaning,
        artwork_file_url,
        review_status,
        submitted_at,
        reviewed_by_profile_id,
        reviewed_at
    )
values (
        'AS0001',
        'AC0001',
        'P0002',
        'Penang Spice Routes',
        'A design combining spice trails, shophouses, and hawker tools.',
        'Penang trade history and street-food culture.',
        'The design represents movement between cultures and food traditions.',
        'The middle layer celebrates the shophouses and communities connected by those routes.',
        'The lower layer honours the hawker tools and shared meals that sustain Penang food heritage.',
        'https://res.cloudinary.com/hv2ectij/image/upload/v1787280686/Penang_Spice_Routes_covwsj.png',
        'approved',
        '2026-02-10 10:00:00+08',
        'P0001',
        '2026-04-02 09:00:00+08'
    ),
    (
        'AS0002',
        'AC0001',
        'P0001',
        'Island Food Journey',
        'A design showing an island path connecting famous food dishes.',
        'Penang island travel and local cuisine.',
        'The path represents a tourist journey through food.',
        'The middle layer maps the neighbourhoods where distinct food traditions meet.',
        'The lower layer represents the local tables where each journey becomes a shared memory.',
        'https://res.cloudinary.com/hv2ectij/image/upload/v1787280685/Island_Food_Journey_xr4mu7.png',
        'approved',
        '2026-02-20 14:00:00+08',
        'P0001',
        '2026-04-02 09:10:00+08'
    ),
    (
        'AS0003',
        'AC0002',
        'P0003',
        'Melaka Window Stories',
        'A design using heritage windows, tiles, and dining symbols.',
        'Historic Melaka architecture and Peranakan culture.',
        'Each window represents a story shared across generations.',
        'The middle layer uses tile patterns to represent cultural exchange and continuity.',
        'The lower layer celebrates dining traditions that bring families together.',
        'https://res.cloudinary.com/hv2ectij/image/upload/v1787280687/Melaka_Window_Stories_o7x6la.png',
        'approved',
        '2026-02-15 11:00:00+08',
        'P0001',
        '2026-04-02 09:20:00+08'
    ),
    (
        'AS0004',
        'AC0002',
        'P0002',
        'River of Spices',
        'Flowing spice motifs connect Melaka river scenes with traditional serving ware.',
        'Melaka River trade and Peranakan kitchens.',
        'The layered river pattern celebrates ingredients carried between communities.',
        'The middle layer represents the kitchens where traded spices became family recipes.',
        'The lower layer honours serving ware and meals shared across Melaka communities.',
        'https://res.cloudinary.com/hv2ectij/image/upload/v1787280683/River_of_Spices_krzw0r.png',
        'approved',
        '2026-02-25 16:00:00+08',
        'P0001',
        '2026-04-02 09:30:00+08'
    ),
    (
        'AS0005',
        'AC0003',
        'P0001',
        'Moonlight Wau',
        'A bold tiffin pattern combining the wau bulan with rice grains and local flowers.',
        'Kelantan kite craftsmanship and nasi kerabu colours.',
        'The circular composition reflects a shared meal beneath the moon.',
        'The middle layer links the movement of the wau bulan with local floral motifs.',
        'The lower layer celebrates rice, herbs, and the communal table of Kelantan.',
        'https://res.cloudinary.com/hv2ectij/image/upload/v1787280685/Moonlight_Wau_pxe6cf.png',
        'approved',
        '2026-02-12 09:15:00+08',
        'P0001',
        '2026-04-02 09:40:00+08'
    ),
    (
        'AS0006',
        'AC0003',
        'P0003',
        'Blue Rice Garden',
        'Butterfly-pea blossoms and herb leaves form a garden around each tiffin tier.',
        'The natural ingredients and colours of nasi kerabu.',
        'Every illustrated herb honours the growers and cooks behind the dish.',
        'The middle layer represents the garden biodiversity behind nasi kerabu.',
        'The lower layer celebrates the cooks who transform those ingredients into heritage food.',
        'https://res.cloudinary.com/hv2ectij/image/upload/v1787280684/Blue_Rice_Garden_s3bef9.png',
        'approved',
        '2026-03-01 12:30:00+08',
        'P0001',
        '2026-04-02 09:50:00+08'
    ),
    (
        'AS0007',
        'AC0004',
        'P0002',
        'Borneo Morning Mist',
        'A layered design of river lines, pepper vines, and the colours of a Kuching sunrise.',
        'Sarawak river life and laksa ingredients.',
        'Soft gradients represent recipes remembered across generations.',
        'The middle layer follows pepper vines and river routes between Sarawak communities.',
        'The lower layer represents the warmth of kitchens at the start of a new day.',
        'https://res.cloudinary.com/hv2ectij/image/upload/v1787280684/Borneo_Morning_Mist_unj2wj.png',
        'approved',
        '2026-02-18 15:45:00+08',
        'P0001',
        '2026-04-02 10:00:00+08'
    ),
    (
        'AS0008',
        'AC0004',
        'P0003',
        'Hornbill Supper',
        'A graphic hornbill watches over bowls, chopsticks, and native foliage.',
        'Sarawak wildlife, forests, and communal dining.',
        'The design connects care for cultural foodways with care for the land.',
        'The middle layer honours native foliage and the forest ecosystems surrounding communities.',
        'The lower layer celebrates bowls shared at communal suppers.',
        'https://res.cloudinary.com/hv2ectij/image/upload/v1787280686/Hornbill_Supper_xp5fpt.png',
        'approved',
        '2026-03-05 18:20:00+08',
        'P0001',
        '2026-04-02 10:10:00+08'
    ),
    (
        'AS0009',
        'AC0005',
        'P0002',
        'Hawker Lanterns',
        'Warm lanterns illuminate illustrated hawker tools and noodle bowls.',
        'George Town night markets and hawker culture.',
        'The artwork captures the warmth of discovering food after sunset.',
        'The middle layer represents the tools and movement of night-market cooks.',
        'The lower layer celebrates noodle bowls enjoyed together beneath the lanterns.',
        'https://res.cloudinary.com/hv2ectij/image/upload/v1787280690/Hawker_Lanterns_qnktet.png',
        'approved',
        now() - interval '6 days',
        'P0001',
        now() - interval '5 days'
    ),
    (
        'AS0010',
        'AC0005',
        'P0003',
        'Five-Foot Way Feast',
        'Shophouse arches frame a sequence of Penang dishes and tableware.',
        'George Town architecture and shared street-side meals.',
        'Each arch is a doorway into a different family food memory.',
        'The middle layer connects the five-foot way with dishes served along the street.',
        'The lower layer represents tables where neighbours and visitors gather.',
        'https://res.cloudinary.com/hv2ectij/image/upload/v1787280689/Five-Foot_Way_Feast_eioxul.png',
        'approved',
        now() - interval '12 days',
        'P0001',
        now() - interval '10 days'
    ),
    (
        'AS0012',
        'AC0002',
        'P0003',
        'Melaka Family Table',
        'A round table illustration surrounded by rice balls, ceramics, and family hands.',
        'Family-run eateries and recipes passed down in Melaka.',
        'The open composition invites everyone to take a place at the table.',
        'The middle layer honours ceramics and dishes used across generations.',
        'The lower layer represents the hands that prepare and share family recipes.',
        'https://res.cloudinary.com/hv2ectij/image/upload/v1787280687/Melaka_Family_Table_oci8d1.png',
        'approved',
        '2026-03-08 10:00:00+08',
        'P0001',
        '2026-03-15 10:10:00+08'
    ),
    (
        'AS0013',
        'AC0003',
        'P0002',
        'Kelantan Bloom',
        'Blue blossoms, woven motifs, and grains of rice create a bright botanical design.',
        'Butterfly-pea flowers, songket, and Kelantanese cuisine.',
        'The piece celebrates colour drawn from nature and craft.',
        'The middle layer weaves botanical forms into traditional textile rhythms.',
        'The lower layer honours rice and the natural ingredients central to Kelantanese cuisine.',
        'https://res.cloudinary.com/hv2ectij/image/upload/v1787280684/Kelantan_Bloom_hmyjot.png',
        'approved',
        '2026-03-12 10:00:00+08',
        'P0001',
        '2026-03-16 10:00:00+08'
    ),
    (
        'AS0014',
        'AC0004',
        'P0003',
        'Laksa Lines',
        'Steam and noodle lines weave through pepper leaves and river contours.',
        'The aroma of Sarawak laksa and the rivers of Borneo.',
        'Continuous lines represent the journeys that keep food traditions alive.',
        'The middle layer connects pepper leaves and steam with Sarawak river contours.',
        'The lower layer celebrates the bowls and communities that carry laksa traditions forward.',
        'https://res.cloudinary.com/hv2ectij/image/upload/v1787280686/Laksa_Lines_nrk8fz.png',
        'approved',
        '2026-03-14 10:00:00+08',
        'P0001',
        '2026-03-18 10:00:00+08'
    ),
    (
        'AS0015',
        'AC0001',
        'P0002',
        'Hawker Lanterns',
        'Warm lanterns illuminate illustrated hawker tools and noodle bowls.',
        'George Town night markets and hawker culture.',
        'The artwork captures the warmth of discovering food after sunset.',
        'The middle layer represents the tools and movement of night-market cooks.',
        'The lower layer celebrates noodle bowls enjoyed together beneath the lanterns.',
        'https://res.cloudinary.com/hv2ectij/image/upload/v1787280690/Hawker_Lanterns_qnktet.png',
        'approved',
        '2026-03-10 10:00:00+08',
        'P0001',
        '2026-03-15 10:00:00+08'
    ),
    (
        'AS0016',
        'AC0005',
        'P0002',
        'Penang Spice Routes',
        'A design combining spice trails, shophouses, and hawker tools.',
        'Penang trade history and street-food culture.',
        'The design represents movement between cultures and food traditions.',
        'The middle layer celebrates the shophouses and communities connected by those routes.',
        'The lower layer honours the hawker tools and shared meals that sustain Penang food heritage.',
        'https://res.cloudinary.com/hv2ectij/image/upload/v1787280686/Penang_Spice_Routes_covwsj.png',
        'approved',
        now() - interval '4 days',
        'P0001',
        now() - interval '3 days'
    );

-- Each submission requires one hero view and three flattened 360-degree layer
-- files. Reusing the seeded artwork URL keeps this fixture
-- self-contained while preserving the production table shape and ordering.
insert into public.artwork_submission_photos (
        artwork_submission_id,
        view_type,
        photo_url,
        sort_order
    )
select submission.artwork_submission_id,
    required_view.view_type,
    submission.artwork_file_url,
    required_view.sort_order
from public.artwork_submissions submission
cross join (
        values ('front_hero', 1),
            ('layer_1_flat_360', 2),
            ('layer_2_flat_360', 3),
            ('layer_3_flat_360', 4)
    ) as required_view(view_type, sort_order);
-- Link each published tiffin artwork to the submission that won its campaign.
-- The artwork IDs are preserved because heritage_tiffins already reference them.
update public.artworks as artwork
set source_artwork_submission_id = submission.artwork_submission_id,
    profile_id = submission.profile_id,
    title = submission.artwork_title,
    description = submission.design_description,
    artwork_meaning = concat_ws(
        E'\n\n',
        'Layer 1: ' || submission.layer_1_meaning,
        'Layer 2: ' || submission.layer_2_meaning,
        'Layer 3: ' || submission.layer_3_meaning
    ),
    cultural_inspiration = submission.cultural_inspiration,
    image_url = submission.artwork_file_url,
    updated_at = now()
from public.artwork_submissions as submission
join (
        values ('A0001', 'AS0001'),
            ('A0002', 'AS0003'),
            ('A0003', 'AS0005'),
            ('A0004', 'AS0008')
    ) as winning_artwork(artwork_id, artwork_submission_id)
    on winning_artwork.artwork_submission_id = submission.artwork_submission_id
where artwork.artwork_id = winning_artwork.artwork_id;
-- Keep deterministic AVE0001... IDs: the normal session trigger would publish
-- approved submissions immediately with sequence-generated entry IDs.
alter table public.artwork_voting_sessions
disable trigger publish_approved_artworks_for_session_trigger;

insert into public.artwork_voting_sessions (
        artwork_voting_session_id,
        artwork_campaign_id,
        voting_start_at,
        voting_end_at,
        status,
        session_type,
        parent_voting_session_id
    )
values (
        'AVS0001',
        'AC0001',
        '2026-04-10 00:00:00+08',
        '2026-05-10 23:59:59+08',
        'scheduled',
        'standard',
        null
    ),
    (
        'AVS0002',
        'AC0002',
        '2026-04-10 00:00:00+08',
        '2026-05-10 23:59:59+08',
        'scheduled',
        'standard',
        null
    ),
    (
        'AVS0003',
        'AC0003',
        '2026-04-10 00:00:00+08',
        '2026-05-10 23:59:59+08',
        'scheduled',
        'standard',
        null
    ),
    (
        'AVS0004',
        'AC0004',
        '2026-04-10 00:00:00+08',
        '2026-05-10 23:59:59+08',
        'scheduled',
        'standard',
        null
    ),
    (
        'AVS0005',
        'AC0005',
        now() - interval '30 days',
        now() + interval '60 days',
        'scheduled',
        'standard',
        null
    );
-- Start every cached total at zero. The database vote trigger derives the final
-- totals from the vote rows inserted immediately after these entries.
insert into public.artwork_voting_entries (
        artwork_voting_entry_id,
        artwork_voting_session_id,
        artwork_submission_id,
        vote_count,
        published_at
    )
values (
        'AVE0001',
        'AVS0001',
        'AS0001',
        0,
        '2026-04-05 10:00:00+08'
    ),
    (
        'AVE0002',
        'AVS0001',
        'AS0002',
        0,
        '2026-04-05 10:05:00+08'
    ),
    (
        'AVE0003',
        'AVS0001',
        'AS0015',
        0,
        '2026-04-05 10:10:00+08'
    ),
    (
        'AVE0004',
        'AVS0002',
        'AS0003',
        0,
        '2026-04-05 10:15:00+08'
    ),
    (
        'AVE0005',
        'AVS0002',
        'AS0004',
        0,
        '2026-04-05 10:20:00+08'
    ),
    (
        'AVE0006',
        'AVS0002',
        'AS0012',
        0,
        '2026-04-05 10:25:00+08'
    ),
    (
        'AVE0007',
        'AVS0003',
        'AS0005',
        0,
        '2026-04-05 10:30:00+08'
    ),
    (
        'AVE0008',
        'AVS0003',
        'AS0006',
        0,
        '2026-04-05 10:35:00+08'
    ),
    (
        'AVE0009',
        'AVS0003',
        'AS0013',
        0,
        '2026-04-05 10:40:00+08'
    ),
    (
        'AVE0010',
        'AVS0004',
        'AS0007',
        0,
        '2026-04-05 10:45:00+08'
    ),
    (
        'AVE0011',
        'AVS0004',
        'AS0008',
        0,
        '2026-04-05 10:50:00+08'
    ),
    (
        'AVE0012',
        'AVS0004',
        'AS0014',
        0,
        '2026-04-05 10:55:00+08'
    ),
    (
        'AVE0013',
        'AVS0005',
        'AS0009',
        0,
        now() - interval '6 days'
    ),
    (
        'AVE0014',
        'AVS0005',
        'AS0010',
        0,
        now() - interval '9 days'
    ),
    (
        'AVE0015',
        'AVS0005',
        'AS0016',
        0,
        now() - interval '3 days'
    );

alter table public.artwork_voting_sessions
enable trigger publish_approved_artworks_for_session_trigger;

-- Entries can only be published while a session is scheduled. Transition each
-- session only after its complete entry list has been inserted.
update public.artwork_voting_sessions
set status = 'closed'
where artwork_voting_session_id in (
        'AVS0001',
        'AVS0002',
        'AVS0003',
        'AVS0004'
    );

update public.artwork_voting_sessions
set status = 'active'
where artwork_voting_session_id = 'AVS0005';
insert into public.artwork_votes (
        artwork_vote_id,
        artwork_voting_session_id,
        artwork_voting_entry_id,
        profile_id,
        voted_at
    )
values (
        'AV0001',
        'AVS0001',
        'AVE0001',
        'P0001',
        '2026-04-15 12:00:00+08'
    ),
    (
        'AV0002',
        'AVS0001',
        'AVE0001',
        'P0002',
        '2026-04-16 13:00:00+08'
    ),
    (
        'AV0003',
        'AVS0002',
        'AVE0004',
        'P0001',
        '2026-04-17 14:00:00+08'
    ),
    (
        'AV0004',
        'AVS0003',
        'AVE0007',
        'P0001',
        '2026-04-18 10:00:00+08'
    ),
    (
        'AV0005',
        'AVS0003',
        'AVE0007',
        'P0002',
        '2026-04-18 10:05:00+08'
    ),
    (
        'AV0006',
        'AVS0003',
        'AVE0008',
        'P0003',
        '2026-04-18 10:10:00+08'
    ),
    (
        'AV0007',
        'AVS0004',
        'AVE0010',
        'P0001',
        '2026-04-19 11:00:00+08'
    ),
    (
        'AV0008',
        'AVS0004',
        'AVE0011',
        'P0002',
        '2026-04-19 11:05:00+08'
    ),
    (
        'AV0009',
        'AVS0004',
        'AVE0011',
        'P0003',
        '2026-04-19 11:10:00+08'
    );
insert into public.artwork_campaign_winners (
        artwork_campaign_winner_id,
        artwork_campaign_id,
        artwork_voting_session_id,
        artwork_voting_entry_id,
        artwork_id,
        final_vote_count,
        final_rank,
        announced_by_profile_id,
        announced_at
    )
values (
        'ACW0001',
        'AC0001',
        'AVS0001',
        'AVE0001',
        'A0001',
        2,
        1,
        'P0001',
        '2026-05-15 10:00:00+08'
    ),
    (
        'ACW0002',
        'AC0002',
        'AVS0002',
        'AVE0004',
        'A0002',
        1,
        1,
        'P0001',
        '2026-05-15 10:05:00+08'
    ),
    (
        'ACW0003',
        'AC0003',
        'AVS0003',
        'AVE0007',
        'A0003',
        2,
        1,
        'P0001',
        '2026-05-15 10:10:00+08'
    ),
    (
        'ACW0004',
        'AC0004',
        'AVS0004',
        'AVE0011',
        'A0004',
        2,
        1,
        'P0001',
        '2026-05-15 10:15:00+08'
    );
-- ============================================================================
-- 8. RESTORE PROFILES FOR PRESERVED SUPABASE AUTH USERS
-- auth.users is not truncated by this seed. Recreate every missing link after
-- the dummy P0001-P0003 rows have been inserted; real accounts use P1000+.
-- ============================================================================
select setval(
        'public.profile_number_seq',
        greatest(
            1000,
            coalesce(
                (
                    select max(
                            substring(
                                profile_id
                                from 2
                            )::integer
                        ) + 1
                    from public.profiles
                ),
                1000
            )
        ),
        false
    );
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
select 'P' || lpad(
        nextval('public.profile_number_seq')::text,
        4,
        '0'
    ),
    users.id,
    'tourist',
    left(
        coalesce(
            nullif(
                trim(users.raw_user_meta_data->>'display_name'),
                ''
            ),
            split_part(coalesce(users.email, 'Tourist'), '@', 1)
        ),
        80
    ),
    nullif(
        left(
            upper(users.raw_user_meta_data->>'country_code'),
            2
        ),
        ''
    ),
    nullif(trim(users.raw_user_meta_data->>'city'), ''),
    case
        when coalesce(users.raw_user_meta_data->>'date_of_birth', '') ~ '^\d{4}-\d{2}-\d{2}$' then (users.raw_user_meta_data->>'date_of_birth')::date
    end,
    case
        when lower(users.raw_user_meta_data->>'gender') in (
            'male',
            'female',
            'non_binary',
            'prefer_not_to_say',
            'other'
        ) then lower(users.raw_user_meta_data->>'gender')
    end
from auth.users users
where not exists (
        select 1
        from public.profiles profiles
        where profiles.auth_user_id = users.id
    )
order by users.created_at;
do $$ begin if exists (
    select 1
    from auth.users users
        left join public.profiles profiles on profiles.auth_user_id = users.id
    where profiles.profile_id is null
) then raise exception 'Profile backfill failed: one or more Auth users are orphaned';
end if;
end;
$$;
-- ============================================================================
-- 9. VERIFY THE CATEGORY-FREE CAMPAIGN SEED
-- Any failed assertion aborts and rolls back this entire seed transaction.
-- ============================================================================
do $$
begin
    if (select count(*) from public.artwork_campaigns) <> 5
        or (select count(*) from public.artwork_submissions) <> 15
        or (select count(*) from public.artwork_submission_photos) <> 60
        or (select count(*) from public.artwork_voting_sessions) <> 5
        or (select count(*) from public.artwork_voting_entries) <> 15
        or (select count(*) from public.artwork_votes) <> 9
        or (select count(*) from public.artwork_campaign_winners) <> 4 then
        raise exception 'Seed verification failed: unexpected campaign subsystem row counts';
    end if;

    if exists (
        select 1
        from public.artwork_campaigns
        where status not in ('active', 'completed')
    ) then
        raise exception 'Seed verification failed: unexpected artwork campaign status';
    end if;

    if (select count(*) from public.artwork_campaigns where status = 'completed') <> 4
        or (select count(*) from public.artwork_campaigns where status = 'active') <> 1 then
        raise exception 'Seed verification failed: expected four completed campaigns and one active campaign';
    end if;

    if exists (
        select 1
        from public.artwork_campaigns campaign
        left join public.artwork_submissions submission
            on submission.artwork_campaign_id = campaign.artwork_campaign_id
        group by campaign.artwork_campaign_id
        having count(submission.artwork_submission_id) <> 3
    ) then
        raise exception 'Seed verification failed: every campaign must have exactly three artwork designs';
    end if;

    if exists (
        select 1
        from public.artwork_submissions submission
        join public.artwork_campaigns campaign
            on campaign.artwork_campaign_id = submission.artwork_campaign_id
        join public.states state on state.state_id = campaign.state_id
        where campaign.artwork_campaign_id between 'AC0001' and 'AC0005'
          and not (
              (state.state_code = 'PNG' and submission.artwork_submission_id in ('AS0001', 'AS0002', 'AS0009', 'AS0010', 'AS0015', 'AS0016'))
              or (state.state_code = 'MLK' and submission.artwork_submission_id in ('AS0003', 'AS0004', 'AS0012'))
              or (state.state_code = 'KTN' and submission.artwork_submission_id in ('AS0005', 'AS0006', 'AS0013'))
              or (state.state_code = 'SWK' and submission.artwork_submission_id in ('AS0007', 'AS0008', 'AS0014'))
          )
    ) then
        raise exception 'Seed verification failed: artwork design does not match its campaign state';
    end if;

    if exists (
        select 1
        from public.artwork_submissions submission
        left join public.artwork_submission_photos photo
            on photo.artwork_submission_id = submission.artwork_submission_id
        group by submission.artwork_submission_id
        having count(photo.artwork_submission_photo_id) <> 4
            or count(distinct photo.view_type) <> 4
            or min(photo.sort_order) <> 1
            or max(photo.sort_order) <> 4
    ) then
        raise exception 'Seed verification failed: a submission does not have all four artwork views';
    end if;

    if (select count(*) from public.artwork_voting_sessions where status = 'closed') <> 4
        or (select count(*) from public.artwork_voting_sessions where status = 'active') <> 1
        or (select count(*) from public.artwork_voting_sessions where status = 'scheduled') <> 0 then
        raise exception 'Seed verification failed: unexpected final voting session statuses';
    end if;

    if exists (
        select 1
        from public.artwork_voting_entries as entry
        join public.artwork_voting_sessions as session
            on session.artwork_voting_session_id = entry.artwork_voting_session_id
        join public.artwork_submissions as submission
            on submission.artwork_submission_id = entry.artwork_submission_id
        where session.artwork_campaign_id <> submission.artwork_campaign_id
    ) then
        raise exception 'Seed verification failed: an entry crosses campaign boundaries';
    end if;

    if exists (
        select 1
        from public.artwork_votes as vote
        join public.artwork_voting_entries as entry
            on entry.artwork_voting_entry_id = vote.artwork_voting_entry_id
        where entry.artwork_voting_session_id <> vote.artwork_voting_session_id
    ) then
        raise exception 'Seed verification failed: a vote and its entry use different sessions';
    end if;

    if exists (
        select 1
        from public.artwork_votes
        group by artwork_voting_session_id, profile_id
        having count(*) > 1
    ) then
        raise exception 'Seed verification failed: a profile voted more than once in one session';
    end if;

    if exists (
        select 1
        from public.artwork_voting_entries as entry
        left join public.artwork_votes as vote
            on vote.artwork_voting_entry_id = entry.artwork_voting_entry_id
        group by entry.artwork_voting_entry_id, entry.vote_count
        having entry.vote_count <> count(vote.artwork_vote_id)
    ) then
        raise exception 'Seed verification failed: a cached vote count is incorrect';
    end if;

    if exists (
        select 1
        from public.artwork_campaign_winners as winner
        join public.artwork_voting_entries as entry
            on entry.artwork_voting_entry_id = winner.artwork_voting_entry_id
        join public.artwork_voting_sessions as session
            on session.artwork_voting_session_id = winner.artwork_voting_session_id
        join public.artworks as artwork
            on artwork.artwork_id = winner.artwork_id
        where session.artwork_campaign_id <> winner.artwork_campaign_id
            or entry.artwork_voting_session_id <> winner.artwork_voting_session_id
            or artwork.source_artwork_submission_id <> entry.artwork_submission_id
    ) then
        raise exception 'Seed verification failed: a winner relationship is inconsistent';
    end if;
end;
$$;
commit;
