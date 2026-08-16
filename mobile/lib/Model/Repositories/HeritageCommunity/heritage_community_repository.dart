import 'package:image_picker/image_picker.dart';

import '../../../core/app_exception.dart';
import '../../Services/cloudinary_api_service.dart';
import '../../Services/supabase_api_service.dart';
import 'artwork_campaign_model.dart';
import 'artwork_submission_model.dart';
import 'campaign_winner_model.dart';
import 'community_comment_model.dart';
import 'community_post_model.dart';
import 'voting_entry_model.dart';

class HeritageCommunityRepository {
  final SupabaseApiService _api;
  final CloudinaryApiService _cloudinary;

  HeritageCommunityRepository({
    SupabaseApiService? api,
    CloudinaryApiService? cloudinary,
  }) : _api = api ?? SupabaseApiService(),
       _cloudinary = cloudinary ?? CloudinaryApiService(supabase: api);

  Future<List<CommunityPostModel>> fetchPosts({
    String? query,
    String? sort,
    int page = 1,
  }) async {
    var request = _api.client
        .from('community_posts')
        .select('''
      *,
      vendors(vendor_name, states(state_name)),
      community_post_photos(photo_url, sort_order)
    ''')
        .eq('status', 'published');
    if (query != null && query.trim().isNotEmpty) {
      final escaped = query.trim().replaceAll(',', r'\,');
      request = request.or(
        'written_review.ilike.%$escaped%,post_comment.ilike.%$escaped%',
      );
    }
    final from = (page - 1) * 10;
    final to = from + 9;
    List<Map<String, dynamic>> rows;
    try {
      rows = await _api.guard(() {
        final ordered = switch (sort) {
          'Popular' => request.order('like_count', ascending: false),
          _ when sort == 'New' => request.order('created_at', ascending: false),
          _ =>
            request
                .order('like_count', ascending: false)
                .order('created_at', ascending: false),
        };
        return ordered.range(from, to);
      });
    } catch (_) {
      // Verify an empty public feed with a relation-free query. This prevents
      // PostgREST relationship/cache errors from being shown as an API failure
      // when the table genuinely contains no published posts.
      final publishedRows = await _api.guard(
        () => _api.client
            .from('community_posts')
            .select('community_post_id')
            .eq('status', 'published')
            .limit(1),
      );
      if (publishedRows.isEmpty) return [];
      rethrow;
    }
    return _mapPosts(rows);
  }

  Future<CommunityPostModel?> fetchPostById(String id) async {
    // RLS limits anonymous users to published posts and lets an author open
    // their own draft/hidden review from the profile history.
    final row = await _api.guard(
      () => _api.client
          .from('community_posts')
          .select('''
        *,
        vendors(vendor_name, states(state_name)),
        community_post_photos(photo_url, sort_order)
      ''')
          .eq('community_post_id', id)
          .maybeSingle(),
    );
    if (row == null) return null;
    final mapped = await _mapPosts([row]);
    return mapped.single;
  }

  /// Returns every review created by the signed-in user, including drafts or
  /// hidden posts that are not available in the public community feed.
  Future<List<CommunityPostModel>> fetchMyPosts(String userId) async {
    final user = _api.requireUser();
    if (user.id != userId) throw const AppException('Review access denied.');
    final profileId = await _currentProfileId();
    final rows = await _api.guard(
      () => _api.client
          .from('community_posts')
          .select('''
        *,
        vendors(vendor_name, states(state_name)),
        community_post_photos(photo_url, sort_order)
      ''')
          .eq('profile_id', profileId)
          .order('created_at', ascending: false),
    );
    return _mapPosts(rows);
  }

  Future<List<CommunityPostModel>> _mapPosts(
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) return [];
    final authorIds = rows.map((row) => row['profile_id'] as String).toSet();
    final profiles = await _fetchPublicProfiles(authorIds);
    final user = _api.currentUser;
    var likedIds = <String>{};
    if (user != null) {
      final profileId = await _currentProfileId();
      final postIds = rows
          .map((row) => row['community_post_id'] as String)
          .toList();
      final likes = await _api.guard(
        () => _api.client
            .from('community_post_likes')
            .select('community_post_id')
            .eq('profile_id', profileId)
            .inFilter('community_post_id', postIds),
      );
      likedIds = likes.map((row) => row['community_post_id'] as String).toSet();
    }
    return rows
        .map(
          (row) => CommunityPostModel.fromJson(
            row,
            author: profiles[row['profile_id']],
            isLikedByCurrentUser: likedIds.contains(row['community_post_id']),
          ),
        )
        .toList();
  }

  Future<Map<String, Map<String, dynamic>>> _fetchPublicProfiles(
    Set<String> ids,
  ) async {
    if (ids.isEmpty) return {};
    final rows = await _api.guard(
      () => _api.client
          .from('public_profiles')
          .select('profile_id, display_name, avatar_url')
          .inFilter('profile_id', ids.toList()),
    );
    return {for (final row in rows) row['profile_id'] as String: row};
  }

  Future<List<CommunityCommentModel>> fetchCommentsByPostId(
    String postId,
  ) async {
    final rows = await _api.guard(
      () => _api.client
          .from('community_comments')
          .select()
          .eq('community_post_id', postId)
          .eq('status', 'published')
          .order('created_at'),
    );
    final profiles = await _fetchPublicProfiles(
      rows.map((row) => row['profile_id'] as String).toSet(),
    );
    final replies = <String, List<CommunityCommentModel>>{};
    for (final row in rows.where((row) => row['parent_comment_id'] != null)) {
      final parentId = row['parent_comment_id'] as String;
      replies
          .putIfAbsent(parentId, () => [])
          .add(
            CommunityCommentModel.fromJson(
              row,
              author: profiles[row['profile_id']],
            ),
          );
    }
    return rows
        .where((row) => row['parent_comment_id'] == null)
        .map(
          (row) => CommunityCommentModel.fromJson(
            row,
            author: profiles[row['profile_id']],
            replies: replies[row['community_comment_id']] ?? const [],
          ),
        )
        .toList();
  }

  Future<void> addComment(String postId, String body, String? parentId) async {
    _api.requireUser();
    final profileId = await _currentProfileId();
    final trimmed = body.trim();
    if (trimmed.isEmpty) throw const AppException('Comment cannot be empty.');
    if (parentId != null) {
      final parent = await _api.guard(
        () => _api.client
            .from('community_comments')
            .select('community_post_id, parent_comment_id')
            .eq('community_comment_id', parentId)
            .maybeSingle(),
      );
      if (parent == null ||
          parent['community_post_id'] != postId ||
          parent['parent_comment_id'] != null) {
        throw const AppException(
          'Replies can only be added to top-level comments.',
        );
      }
    }
    await _api.guard(
      () => _api.client.from('community_comments').insert({
        'community_post_id': postId,
        'profile_id': profileId,
        'parent_comment_id': parentId,
        'comment_text': trimmed,
        'status': 'published',
      }),
    );
  }

  Future<CommunityPostModel> toggleLike(
    String postId,
    String userId,
    bool isLiked,
  ) async {
    final user = _api.requireUser();
    if (user.id != userId) throw const AppException('Like access denied.');
    final profileId = await _currentProfileId();
    final existingLike = await _api.guard(
      () => _api.client
          .from('community_post_likes')
          .select('community_post_like_id')
          .eq('community_post_id', postId)
          .eq('profile_id', profileId)
          .maybeSingle(),
    );
    if (isLiked || existingLike != null) {
      await _api.guard(
        () => _api.client
            .from('community_post_likes')
            .delete()
            .eq('community_post_id', postId)
            .eq('profile_id', profileId),
      );
    } else {
      await _api.guard(
        () => _api.client.from('community_post_likes').insert({
          'community_post_id': postId,
          'profile_id': profileId,
        }),
      );
    }
    final likeCount = await _api.client
        .from('community_post_likes')
        .count()
        .eq('community_post_id', postId);
    final post = await fetchPostById(postId);
    if (post == null) throw const AppException('Post is unavailable.');
    return post.copyWith(likeCount: likeCount);
  }

  Future<CommunityPostModel> createPost({
    required String userId,
    required String vendorId,
    required double rating,
    required String reviewText,
    List<XFile> photos = const [],
  }) async {
    if (photos.length > 5) {
      throw const AppException('A post may contain at most 5 photos.');
    }
    final user = _api.requireUser();
    if (user.id != userId) throw const AppException('Post creation denied.');
    if (rating < 1 || rating > 5) {
      throw const AppException('Choose a rating from 1 to 5.');
    }
    if (reviewText.trim().isEmpty) {
      throw const AppException('Review is required.');
    }

    final uploaded = <CloudinaryUploadResult>[];
    for (final photo in photos) {
      uploaded.add(
        await _cloudinary.uploadImage(
          photo,
          folder: 'mangkukkembara/community/${user.id}',
        ),
      );
    }
    final profileId = await _currentProfileId();
    final created = await _api.guard(
      () => _api.client
          .from('community_posts')
          .insert({
            'profile_id': profileId,
            'vendor_id': vendorId,
            'rating': rating.round(),
            'written_review': reviewText.trim(),
            'post_comment': null,
            'status': 'published',
          })
          .select('community_post_id')
          .single(),
    );
    final postId = created['community_post_id'] as String;
    try {
      if (uploaded.isNotEmpty) {
        await _api.guard(
          () => _api.client
              .from('community_post_photos')
              .insert(
                uploaded
                    .asMap()
                    .entries
                    .map(
                      (entry) => {
                        'community_post_id': postId,
                        'photo_url': entry.value.secureUrl,
                        'sort_order': entry.key + 1,
                      },
                    )
                    .toList(),
              ),
        );
      }
    } catch (error) {
      await _api.client
          .from('community_posts')
          .delete()
          .eq('community_post_id', postId);
      rethrow;
    }
    final post = await fetchPostById(postId);
    if (post == null) {
      throw const AppException('Published post could not be loaded.');
    }
    return post;
  }

  Future<List<ArtworkCampaignModel>> fetchCampaigns() async {
    final rows = await _api.guard(
      () => _api.client
          .from('artwork_campaigns')
          .select('*, states(state_name)')
          .inFilter('status', const ['active', 'completed'])
          .order('created_at', ascending: false),
    );
    return rows.map(ArtworkCampaignModel.fromJson).toList();
  }

  Future<String> _currentProfileId() async {
    final user = _api.requireUser();
    final profile = await _api.guard(
      () => _api.client
          .from('profiles')
          .select('profile_id')
          .eq('auth_user_id', user.id)
          .maybeSingle(),
    );
    if (profile == null) {
      throw const AppException(
        'Your account profile is missing. Please contact support.',
      );
    }
    return profile['profile_id'] as String;
  }

  Future<List<ArtworkVotingEntryModel>> fetchVotingEntries(
    String campaignId, {
    String? sort,
  }) async {
    final sessions = await _api.guard(
      () => _api.client
          .from('artwork_voting_sessions')
          .select(
            'artwork_voting_session_id, status, session_type, voting_start_at',
          )
          .eq('artwork_campaign_id', campaignId)
          .order('voting_start_at', ascending: false),
    );
    if (sessions.isEmpty) return [];

    final session = sessions.firstWhere(
      (row) => row['status'] == 'active',
      orElse: () => sessions.first,
    );
    return _fetchVotingEntriesForSession(
      session['artwork_voting_session_id'] as String,
      campaignId: campaignId,
      sort: sort,
    );
  }

  Future<List<ArtworkVotingEntryModel>> _fetchVotingEntriesForSession(
    String sessionId, {
    required String campaignId,
    String? sort,
  }) async {
    var request = _api.client
        .from('artwork_voting_entries')
        .select('''
      *, artwork_submissions!inner(
        artwork_campaign_id, profile_id, artwork_title,
        design_description, cultural_inspiration,
        layer_1_meaning, layer_2_meaning, layer_3_meaning,
        artwork_file_url, submitted_at
      ), artwork_voting_sessions!inner(
        artwork_campaign_id, status, voting_start_at, voting_end_at
      )
    ''')
        .eq('artwork_voting_session_id', sessionId)
        .eq('artwork_submissions.artwork_campaign_id', campaignId)
        .eq('artwork_voting_sessions.artwork_campaign_id', campaignId);
    final rows = await _api.guard(
      () => switch (sort) {
        'New' => request.order('published_at', ascending: false),
        'Popular' => request.order('vote_count', ascending: false),
        _ => request.order('vote_count', ascending: false),
      },
    );
    final submitterIds = rows
        .map((row) => row['artwork_submissions'] as Map<String, dynamic>?)
        .whereType<Map<String, dynamic>>()
        .map((submission) => submission['profile_id'] as String)
        .toSet();
    final profiles = await _fetchPublicProfiles(submitterIds);
    final user = _api.currentUser;
    var votedEntryIds = <String>{};
    if (user != null && rows.isNotEmpty) {
      final profileId = await _currentProfileId();
      final votes = await _api.guard(
        () => _api.client
            .from('artwork_votes')
            .select('artwork_voting_entry_id')
            .eq('profile_id', profileId)
            .inFilter(
              'artwork_voting_entry_id',
              rows
                  .map((row) => row['artwork_voting_entry_id'] as String)
                  .toList(),
            ),
      );
      votedEntryIds = votes
          .map((row) => row['artwork_voting_entry_id'] as String)
          .toSet();
    }
    final byRank = [...rows]
      ..sort(
        (a, b) => ((b['vote_count'] as num?)?.toInt() ?? 0).compareTo(
          (a['vote_count'] as num?)?.toInt() ?? 0,
        ),
      );
    final rankById = <String, int>{};
    for (var i = 0; i < byRank.length; i++) {
      rankById[byRank[i]['artwork_voting_entry_id'] as String] = i + 1;
    }
    return rows.map((row) {
      final submission = row['artwork_submissions'] as Map<String, dynamic>?;
      return ArtworkVotingEntryModel.fromJson(
        row,
        rank: rankById[row['artwork_voting_entry_id']] ?? 0,
        hasVoted: votedEntryIds.contains(row['artwork_voting_entry_id']),
        submitter: profiles[submission?['profile_id']],
      );
    }).toList();
  }

  Future<ArtworkVotingEntryModel?> fetchVotingEntryById(String id) async {
    final row = await _api.guard(
      () => _api.client
          .from('artwork_voting_entries')
          .select('''
            artwork_voting_session_id,
            artwork_voting_sessions!inner(artwork_campaign_id)
          ''')
          .eq('artwork_voting_entry_id', id)
          .maybeSingle(),
    );
    if (row == null) return null;
    final session = row['artwork_voting_sessions'] as Map<String, dynamic>?;
    final campaignId = session?['artwork_campaign_id'] as String?;
    if (campaignId == null) return null;
    final entries = await _fetchVotingEntriesForSession(
      row['artwork_voting_session_id'] as String,
      campaignId: campaignId,
    );
    return entries.where((entry) => entry.id == id).firstOrNull;
  }

  Future<void> submitVote(String entryId, String userId) async {
    final user = _api.requireUser();
    if (user.id != userId) throw const AppException('Vote access denied.');

    // The database function derives the profile and voting session from the
    // authenticated user and entry. It also checks the campaign/session dates
    // and atomically enforces one vote per profile per active session.
    await _api.guard(
      () => _api.client.rpc(
        'cast_artwork_vote',
        params: {'p_artwork_voting_entry_id': entryId},
      ),
    );
  }

  Future<ArtworkSubmissionModel> submitArtwork({
    required String campaignId,
    required String userId,
    required String artworkTitle,
    required String designDescription,
    required String culturalInspiration,
    required String layer1Meaning,
    required String layer2Meaning,
    required String layer3Meaning,
    required XFile frontHeroFile,
    required XFile layer1Flat360File,
    required XFile layer2Flat360File,
    required XFile layer3Flat360File,
    required XFile topArtworkFile,
  }) async {
    final user = _api.requireUser();
    if (user.id != userId) {
      throw const AppException('Artwork submission denied.');
    }
    final campaign = await _api.guard(
      () => _api.client
          .from('artwork_campaigns')
          .select(
            'campaign_title, status, submission_start_at, submission_end_at',
          )
          .eq('artwork_campaign_id', campaignId)
          .single(),
    );
    final campaignStart = DateTime.tryParse(
      campaign['submission_start_at'] as String? ?? '',
    );
    final campaignEnd = DateTime.tryParse(
      campaign['submission_end_at'] as String? ?? '',
    );
    final now = DateTime.now();
    if (campaign['status'] != 'active' ||
        campaignStart == null ||
        campaignEnd == null ||
        now.isBefore(campaignStart) ||
        now.isAfter(campaignEnd)) {
      throw const AppException('This campaign is no longer accepting artwork.');
    }
    final uploadFolder =
        'mangkukkembara/artwork-submissions/${user.id}/$campaignId';
    final uploads = await Future.wait([
      _cloudinary.uploadImage(
        frontHeroFile,
        folder: '$uploadFolder/front-hero',
        maxBytes: 10 * 1024 * 1024,
      ),
      _cloudinary.uploadImage(
        layer1Flat360File,
        folder: '$uploadFolder/layer-1-flat-360',
        maxBytes: 10 * 1024 * 1024,
      ),
      _cloudinary.uploadImage(
        layer2Flat360File,
        folder: '$uploadFolder/layer-2-flat-360',
        maxBytes: 10 * 1024 * 1024,
      ),
      _cloudinary.uploadImage(
        layer3Flat360File,
        folder: '$uploadFolder/layer-3-flat-360',
        maxBytes: 10 * 1024 * 1024,
      ),
      _cloudinary.uploadImage(
        topArtworkFile,
        folder: '$uploadFolder/top',
        maxBytes: 10 * 1024 * 1024,
      ),
    ]);
    final response = await _api.guard(
      () => _api.client.rpc(
        'create_artwork_submission',
        params: {
          'p_artwork_campaign_id': campaignId,
          'p_artwork_title': artworkTitle.trim(),
          'p_design_description': designDescription.trim(),
          'p_cultural_inspiration': culturalInspiration.trim(),
          'p_layer_1_meaning': layer1Meaning.trim(),
          'p_layer_2_meaning': layer2Meaning.trim(),
          'p_layer_3_meaning': layer3Meaning.trim(),
          'p_front_hero_photo_url': uploads[0].secureUrl,
          'p_layer_1_flat_360_url': uploads[1].secureUrl,
          'p_layer_2_flat_360_url': uploads[2].secureUrl,
          'p_layer_3_flat_360_url': uploads[3].secureUrl,
          'p_top_photo_url': uploads[4].secureUrl,
        },
      ),
    );
    final json = switch (response) {
      final Map<String, dynamic> row => row,
      final List<dynamic> rows when rows.length == 1 =>
        rows.single as Map<String, dynamic>,
      _ => throw const AppException(
        'The submitted artwork could not be confirmed.',
      ),
    };
    return ArtworkSubmissionModel.fromJson(
      json,
      campaignName: campaign['campaign_title'] as String,
    );
  }

  /// Returns every artwork submission owned by the currently signed-in user.
  /// The submission policy deliberately permits owners to see pending and
  /// rejected entries, while the public listing only exposes approved work.
  Future<List<ArtworkSubmissionModel>> fetchMyArtworkSubmissions(
    String userId,
  ) async {
    final user = _api.requireUser();
    if (user.id != userId) {
      throw const AppException('Artwork submission access denied.');
    }
    final profileId = await _currentProfileId();
    final rows = await _api.guard(
      () => _api.client
          .from('artwork_submissions')
          .select('''
        *, artwork_campaigns(campaign_title),
        artwork_submission_photos(view_type, photo_url, sort_order)
      ''')
          .eq('profile_id', profileId)
          .order('submitted_at', ascending: false),
    );
    return rows.map((row) {
      final campaign = row['artwork_campaigns'] as Map<String, dynamic>?;
      return ArtworkSubmissionModel.fromJson(
        row,
        campaignName:
            campaign?['campaign_title'] as String? ?? 'Artwork campaign',
      );
    }).toList();
  }

  Future<List<VotingEntryModel>> fetchRankings(String campaignId) async {
    final sessions = await _api.guard(
      () => _api.client
          .from('artwork_voting_sessions')
          .select('artwork_voting_session_id')
          .eq('artwork_campaign_id', campaignId),
    );
    if (sessions.isEmpty) return [];
    final sessionIds = sessions
        .map((row) => row['artwork_voting_session_id'] as String)
        .toList();
    final rows = await _api.guard(
      () => _api.client
          .from('v_artwork_rankings')
          .select()
          .inFilter('artwork_voting_session_id', sessionIds)
          .order('ranking'),
    );
    if (rows.isEmpty) return [];
    final submissionIds = rows
        .map((row) => row['artwork_submission_id'] as String)
        .toList();
    final submissions = await _api.guard(
      () => _api.client
          .from('artwork_submissions')
          .select(
            'artwork_submission_id, profile_id, artwork_title, artwork_file_url',
          )
          .inFilter('artwork_submission_id', submissionIds),
    );
    final submissionById = {
      for (final submission in submissions)
        submission['artwork_submission_id'] as String: submission,
    };
    final profiles = await _fetchPublicProfiles(
      submissions.map((row) => row['profile_id'] as String).toSet(),
    );
    return rows.map((row) {
      final submission =
          submissionById[row['artwork_submission_id']] ?? const {};
      final rank = (row['ranking'] as num).toInt();
      return VotingEntryModel(
        id: row['artwork_voting_entry_id'] as String,
        artworkTitle: submission['artwork_title'] as String? ?? '',
        submitterName:
            profiles[submission['profile_id']]?['display_name'] as String? ??
            'Artist unavailable',
        rank: rank,
        voteCount: (row['vote_count'] as num).toInt(),
        isWinner: rank == 1,
        artworkUrl: submission['artwork_file_url'] as String?,
      );
    }).toList();
  }

  Future<List<CampaignWinnerModel>> fetchWinners(String campaignId) async {
    final rows = await _api.guard(
      () => _api.client
          .from('artwork_campaign_winners')
          .select('''
        *,
        artwork_campaigns!inner(
          artwork_campaign_id, campaign_title, states(state_name)
        ),
        artwork_voting_entries(
          vote_count,
          artwork_submissions(
            artwork_title, design_description, cultural_inspiration,
            layer_1_meaning, layer_2_meaning, layer_3_meaning,
            profile_id, artwork_file_url
          )
        )
      ''')
          .eq('artwork_campaign_id', campaignId),
    );
    if (rows.isEmpty) return [];
    final submitterIds = rows
        .map((row) => row['artwork_voting_entries'] as Map<String, dynamic>?)
        .whereType<Map<String, dynamic>>()
        .map((entry) => entry['artwork_submissions'] as Map<String, dynamic>?)
        .whereType<Map<String, dynamic>>()
        .map((submission) => submission['profile_id'] as String)
        .toSet();
    final profiles = await _fetchPublicProfiles(submitterIds);
    return rows.map((row) {
      final campaign = row['artwork_campaigns'] as Map<String, dynamic>;
      final entry = row['artwork_voting_entries'] as Map<String, dynamic>;
      final submission = entry['artwork_submissions'] as Map<String, dynamic>;
      final state = campaign['states'] as Map<String, dynamic>?;
      final profile = profiles[submission['profile_id']];
      return CampaignWinnerModel(
        id: row['artwork_campaign_winner_id'] as String,
        campaignId: row['artwork_campaign_id'] as String,
        campaignName: campaign['campaign_title'] as String? ?? '',
        stateName: state?['state_name'] as String? ?? '',
        artworkTitle: submission['artwork_title'] as String,
        winnerName: profile?['display_name'] as String? ?? 'Artist unavailable',
        designDescription: submission['design_description'] as String,
        culturalInspiration: submission['cultural_inspiration'] as String,
        layer1Meaning: submission['layer_1_meaning'] as String,
        layer2Meaning: submission['layer_2_meaning'] as String,
        layer3Meaning: submission['layer_3_meaning'] as String,
        finalVoteCount: (row['final_vote_count'] as num).toInt(),
        announcedAt: DateTime.parse(row['announced_at'] as String),
        artworkUrl: submission['artwork_file_url'] as String?,
      );
    }).toList();
  }

  Future<CampaignWinnerModel?> fetchWinnerById(String id) async {
    final winner = await _api.guard(
      () => _api.client
          .from('artwork_campaign_winners')
          .select('artwork_campaign_id')
          .eq('artwork_campaign_winner_id', id)
          .maybeSingle(),
    );
    if (winner == null) return null;
    final winners = await fetchWinners(winner['artwork_campaign_id'] as String);
    return winners.where((item) => item.id == id).firstOrNull;
  }
}
