# Supabase and Cloudinary setup

The mobile app reads live Supabase data. It does not fall back to local mock
repositories when Supabase is empty or unavailable, so the database schema,
Row Level Security policies, Auth profile links, and seed data must be applied
correctly.

## 1. Choose the correct database workflow

There are two different setup paths. Do not mix them.

### A. Fresh development reset

Use this path only when it is acceptable to delete and recreate all application
tables and application data. Supabase-managed `auth.users` accounts are
preserved.

Run these files in the Supabase SQL editor in this exact order:

1. `sources/supabase_schema.sql`
2. `sources/dummy_data.sql`

The schema script drops and recreates the application schema, installs the Auth
profile trigger, backfills profiles for preserved Auth accounts, enables RLS,
and creates the required policies and counter triggers.

The dummy-data script truncates application data, inserts the development data,
and then recreates any profile links required by the preserved Auth accounts.
Dummy profiles remain intentionally unlinked with `auth_user_id = NULL`.

Both scripts are destructive to application data. Do not run them on a deployed
database merely to repair an existing account or RLS problem.

### B. Repair an existing deployed database

Use this path when existing application data and Supabase Auth accounts must be
preserved.

Run only:

1. `supabase/migrations/202608050003_repair_rls_and_auth_profiles.sql`

This migration is non-destructive. It adds the Auth-to-profile mapping,
backfills missing profiles, installs the current RLS policies, and adds the
post/comment/like and artwork-vote counter triggers.

Do not run either of these legacy migrations against the current schema:

- `supabase/migrations/202608040001_mobile_public_access.sql`
- `supabase/migrations/202608040002_public_profiles_and_pasar_malam.sql`

They target an obsolete UUID-column schema and are incompatible with the
current string IDs such as `profile_id` and `community_post_id`. In particular,
do not use `supabase db push` while those legacy files remain in the migration
directory unless the remote migration history has already marked them as
applied. Use the SQL editor with the specific current script instead.

## 2. Database access model

Keep Row Level Security enabled.

- Logged-out users may read active map data, published community content,
  active heritage content, visible campaigns, and safe profile fields exposed
  through `public_profiles`.
- Logged-out users cannot read the full `profiles` table.
- Logged-in users may read and update only their own full profile.
- Collections, likes, comments, posts, submissions, and votes are protected by
  the current user's mapped `profile_id`.
- Photo, operating-hour, category, and other relation tables are readable only
  when their parent record is visible.
- Post like/comment counts and artwork vote counts are maintained by database
  triggers rather than client-side counter updates.

The Flutter repositories use the current tables and views directly. The legacy
`create_community_post_with_photos` and `scan_tiffin_qr` RPCs are not part of
the current mobile data flow.

## 3. Configure and deploy the Cloudinary Edge Function

The Cloudinary API secret must never be added to Flutter, source control, the
database, or a `--dart-define`. Store the Cloudinary credentials as Supabase
Edge Function secrets:

```sh
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase secrets set CLOUDINARY_CLOUD_NAME=YOUR_CLOUD_NAME
supabase secrets set CLOUDINARY_API_KEY=YOUR_API_KEY
supabase secrets set CLOUDINARY_API_SECRET=YOUR_API_SECRET
supabase functions deploy cloudinary-upload
supabase functions deploy admin-create-heritage-food
```

The project currently uses the function configuration in
`supabase/config.toml`, where JWT verification is enabled. Supabase provides
`SUPABASE_URL` and `SUPABASE_ANON_KEY` automatically to the Edge Function
environment; do not copy a service-role key into Flutter.

The function at `supabase/functions/cloudinary-upload/index.ts`:

- requires a valid Supabase user session;
- accepts JPG, PNG, and WebP images;
- accepts MP4 and WebM Heritage Tiffin videos from administrators;
- accepts administrator-managed Heritage Food and Vendor images;
- limits profile images to 5 MB, other images to 10 MB, and heritage videos to 50 MB;
- restricts uploads to the authenticated user's approved folders;
- signs the Cloudinary upload on the server; and
- returns the Cloudinary `secure_url` for storage in Supabase.

The `admin-create-heritage-food` function verifies that the caller is an active
administrator, validates the active State and food category, prevents duplicate
food names within a State, allocates the next `HF0000` identifier, and inserts
the new row into `heritage_foods`.

## 4. Configure Supabase Auth redirects

In Supabase Dashboard > Authentication > URL Configuration, add both redirect
URLs to the allowed redirect URL list:

```text
io.mangkukkembara.app://reset-password
io.mangkukkembara.app://email-confirmed
```

The URL scheme is declared in the Android and iOS runner configurations. The
app sends the email-confirmation redirect during registration and the password
recovery redirect when requesting a password reset.

Enable email confirmation for the target environment. Registration then
creates the Auth account and asks the user to verify the email before logging
in. After verification and login, the app routes to the Treasure Map.

## 5. Run Flutter

From `mobile/`:

```sh
flutter pub get
flutter run
```

The configured Supabase URL and publishable key have development defaults in
`mobile/lib/core/backend_config.dart`. Override them for another environment
without changing source code:

```sh
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLISHABLE_KEY \
  --dart-define=PASSWORD_RECOVERY_REDIRECT=io.mangkukkembara.app://reset-password \
  --dart-define=EMAIL_CONFIRMATION_REDIRECT=io.mangkukkembara.app://email-confirmed
```

The Supabase publishable/anon key is public client configuration. Database
authorization must continue to be enforced by RLS.

## 6. Database verification

After applying the schema or repair migration, confirm that no Auth account is
missing its linked profile:

```sql
select users.id, users.email
from auth.users users
left join public.profiles profiles on profiles.auth_user_id = users.id
where profiles.profile_id is null;
```

Expected result: zero rows.

Confirm that every Auth UUID maps to exactly one profile:

```sql
select users.id, count(profiles.profile_id) as profile_count
from auth.users users
left join public.profiles profiles on profiles.auth_user_id = users.id
group by users.id
having count(profiles.profile_id) <> 1;
```

Expected result: zero rows.

## Verification checklist

- Logged-out users can load Treasure Map vendors, published community posts,
  heritage content, and visible artwork campaigns.
- Logged-out users cannot query full records from `profiles`.
- Registration asks for email verification before login.
- Editing an account email asks for the current password, leaves the old email
  active, and sends verification messages according to Supabase Auth's secure
  email-change setting. In the hosted Supabase dashboard, keep **Secure email
  change** enabled and allow-list the `EMAIL_CONFIRMATION_REDIRECT` URL.
- A verified user can log in and is routed to the Treasure Map.
- My Account loads the authenticated user's linked profile without a
  single-object coercion error.
- Experience loads the authenticated user's collection and keeps guest access
  collection-only.
- A user can update only their own profile and collection.
- Community post publishing, comments, one-level replies, likes, and unlikes
  work under RLS.
- Artwork submissions and voting work under RLS.
- Profile, community-post, and artwork images upload through
  `cloudinary-upload`; no Cloudinary API secret is present in the app bundle.
- Network and validation failures display real retryable errors rather than
  fabricated data.

