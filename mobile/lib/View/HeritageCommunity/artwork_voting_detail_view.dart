import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Model/Repositories/HeritageCommunity/artwork_campaign_model.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../ViewModel/HeritageCommunity/artwork_voting_view_model.dart';
import '../../ViewModel/AccountManagement/auth_view_model.dart';
import '../Widgets/app_network_image.dart';
import '../Widgets/loading_widget.dart';
import '../Widgets/error_state_widget.dart';
import 'heritage_community_style.dart';

/// C7. Artwork Voting Detail View.
class ArtworkVotingDetailView extends StatefulWidget {
  final String entryId;
  const ArtworkVotingDetailView({super.key, required this.entryId});

  @override
  State<ArtworkVotingDetailView> createState() =>
      _ArtworkVotingDetailViewState();
}

class _ArtworkVotingDetailViewState extends State<ArtworkVotingDetailView> {
  late final ArtworkVotingViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = ArtworkVotingViewModel();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _vm.loadEntry(widget.entryId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer2<ArtworkVotingViewModel, AuthViewModel>(
        builder: (ctx, vm, auth, _) {
          return Scaffold(
            backgroundColor: HeritageCommunityStyle.background,
            appBar: heritageCommunityAppBar(title: 'Artwork Story'),
            body: vm.isLoading
                ? const LoadingSpinner()
                : vm.hasError || vm.selectedEntry == null
                ? ErrorStateWidget(
                    message: vm.errorMessage ?? 'Could not load this entry.',
                    onRetry: () => vm.loadEntry(widget.entryId),
                  )
                : RefreshIndicator(
                    onRefresh: () =>
                        vm.loadEntry(widget.entryId, showLoading: false),
                    child: _buildContent(ctx, vm),
                  ),
            bottomNavigationBar:
                !vm.isLoading &&
                    !vm.hasError &&
                    vm.selectedEntry != null &&
                    vm.selectedEntry!.isVotingOpen
                ? _VoteBar(
                    hasVoted: vm.selectedEntry!.hasCurrentUserVoted,
                    isVoting: vm.isVoting,
                    onVote: () => _submitVote(ctx, auth),
                  )
                : null,
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext ctx, ArtworkVotingViewModel vm) {
    final e = vm.selectedEntry!;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ArtworkIntro(entry: e),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ExploreTiffin(entry: e),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 26, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'The story within',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 230,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                _StoryCard(
                  eyebrow: 'THE IDEA',
                  title: 'Design narrative',
                  body: e.designDescription,
                  icon: Icons.draw_rounded,
                  colors: const [Color(0xFFEAF2E6), Color(0xFFD6E5D1)],
                  foreground: AppColors.primary,
                ),
                const SizedBox(width: 12),
                _StoryCard(
                  eyebrow: 'THE ROOTS',
                  title: 'Cultural inspiration',
                  body: e.culturalInspiration,
                  icon: Icons.local_florist_rounded,
                  colors: const [Color(0xFFFFF4D9), Color(0xFFFFE4A3)],
                  foreground: AppColors.accentDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitVote(BuildContext context, AuthViewModel auth) async {
    if (!auth.isLoggedIn) {
      await Navigator.pushNamed(context, AppRoutes.login);
      return;
    }
    final entry = _vm.selectedEntry;
    if (entry == null || _vm.isVoting) return;
    final wasVoted = entry.hasCurrentUserVoted;
    final ok = await _vm.vote(
      entry.id,
      auth.currentUser!.id,
      refreshEntry: true,
    );
    if (!context.mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(wasVoted ? 'Vote removed.' : 'Vote submitted!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_vm.errorMessage ?? 'Vote could not be updated.'),
        ),
      );
    }
  }
}

class _ArtworkIntro extends StatelessWidget {
  final ArtworkVotingEntryModel entry;

  const _ArtworkIntro({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 18),
      padding: const EdgeInsets.fromLTRB(20, 20, 18, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF2E6), Color(0xFFD6E5D1)],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.primary, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F335C31),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -18,
            bottom: -30,
            child: Icon(
              Icons.palette_rounded,
              size: 126,
              color: Color(0x16335C31),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'FEATURED ARTWORK',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                entry.artworkTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  height: 1.12,
                ),
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  const CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(0x52335C31),
                    child: Icon(
                      Icons.brush_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Created by ${entry.submitterName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ArtworkStat(
                    icon: Icons.emoji_events_rounded,
                    label: 'Rank #${entry.currentRank}',
                  ),
                  _ArtworkStat(
                    icon: Icons.favorite_rounded,
                    label: '${entry.voteCount} votes',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArtworkStat extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ArtworkStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0x8AFFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryContainer),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String body;
  final IconData icon;
  final List<Color> colors;
  final Color foreground;

  const _StoryCard({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.icon,
    required this.colors,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final text = body.trim().isEmpty
        ? 'This part of the artwork’s story is waiting to be shared.'
        : body;
    return Container(
      width: MediaQuery.sizeOf(context).width * .78,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            bottom: -18,
            child: Icon(icon, size: 100, color: foreground.withAlpha(18)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(150),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 17, color: foreground),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    eyebrow,
                    style: TextStyle(
                      color: foreground.withAlpha(190),
                      fontSize: 9,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                title,
                style: TextStyle(
                  color: foreground,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  text,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VoteBar extends StatelessWidget {
  final bool hasVoted;
  final bool isVoting;
  final VoidCallback onVote;

  const _VoteBar({
    required this.hasVoted,
    required this.isVoting,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 12,
      shadowColor: Colors.black26,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: hasVoted
                  ? AppColors.successLight
                  : AppColors.primary,
              foregroundColor: hasVoted ? AppColors.success : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: isVoting
                ? SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: hasVoted ? AppColors.success : Colors.white,
                    ),
                  )
                : Icon(
                    hasVoted
                        ? Icons.check_circle_rounded
                        : Icons.favorite_border_rounded,
                  ),
            label: Text(
              hasVoted ? 'Voted (Tap to Unvote)' : 'Vote for This Artwork',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            onPressed: isVoting ? null : onVote,
          ),
        ),
      ),
    );
  }
}

enum _TiffinView { front, layer1, layer2, layer3 }

class _TiffinViewItem {
  final _TiffinView view;
  final String code;
  final String title;
  final String imageUrl;
  final String description;
  final bool isPanorama;

  const _TiffinViewItem({
    required this.view,
    required this.code,
    required this.title,
    required this.imageUrl,
    required this.description,
    this.isPanorama = true,
  });
}

class _ExploreTiffin extends StatefulWidget {
  final ArtworkVotingEntryModel entry;

  const _ExploreTiffin({required this.entry});

  @override
  State<_ExploreTiffin> createState() => _ExploreTiffinState();
}

class _ExploreTiffinState extends State<_ExploreTiffin> {
  _TiffinView _selected = _TiffinView.front;

  List<_TiffinViewItem> get _items => [
    _TiffinViewItem(
      view: _TiffinView.front,
      code: 'Front',
      title: 'Front / Hero View',
      imageUrl: widget.entry.artworkUrl,
      description: widget.entry.designDescription,
      isPanorama: false,
    ),
    _TiffinViewItem(
      view: _TiffinView.layer1,
      code: 'Layer 1',
      title: 'Layer 1',
      imageUrl: widget.entry.layer1Flat360Url,
      description: widget.entry.layer1Meaning,
    ),
    _TiffinViewItem(
      view: _TiffinView.layer2,
      code: 'Layer 2',
      title: 'Layer 2',
      imageUrl: widget.entry.layer2Flat360Url,
      description: widget.entry.layer2Meaning,
    ),
    _TiffinViewItem(
      view: _TiffinView.layer3,
      code: 'Layer 3',
      title: 'Layer 3',
      imageUrl: widget.entry.layer3Flat360Url,
      description: widget.entry.layer3Meaning,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final selectedItem = items.firstWhere((item) => item.view == _selected);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explore the artwork',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Discover every side of the design',
                    style: TextStyle(color: AppColors.textHint, fontSize: 12),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(
                selectedItem.code,
                key: ValueKey(selectedItem.code),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 320,
          width: double.infinity,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.accentLight, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(27),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26335C31),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: _TiffinImageViewer(
              key: ValueKey(selectedItem.view),
              item: selectedItem,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              Expanded(
                child: _TiffinLayerButton(
                  item: items[index],
                  selected: items[index].view == _selected,
                  onTap: () => setState(() => _selected = items[index].view),
                ),
              ),
              if (index != items.length - 1) const SizedBox(width: 6),
            ],
          ],
        ),
        const SizedBox(height: 12),
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final slide = Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: slide, child: child),
              );
            },
            child: selectedItem.view == _TiffinView.front
                ? const SizedBox.shrink(key: ValueKey('front-no-meaning'))
                : Container(
                    key: ValueKey('${selectedItem.view}-meaning'),
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.accentContainer,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.accentLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.auto_stories_rounded,
                              size: 17,
                              color: AppColors.accentDark,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              'Story of ${selectedItem.title}',
                              style: const TextStyle(
                                color: AppColors.accentDark,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          selectedItem.description.trim().isEmpty
                              ? 'This layer’s story is waiting to be shared.'
                              : selectedItem.description,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _TiffinLayerButton extends StatelessWidget {
  final _TiffinViewItem item;
  final bool selected;
  final VoidCallback onTap;

  const _TiffinLayerButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icon = switch (item.view) {
      _TiffinView.front => Icons.view_in_ar_rounded,
      _TiffinView.layer1 => Icons.looks_one_rounded,
      _TiffinView.layer2 => Icons.looks_two_rounded,
      _TiffinView.layer3 => Icons.looks_3_rounded,
    };
    return Semantics(
      button: true,
      selected: selected,
      label: 'Show ${item.title}',
      child: Material(
        color: selected ? AppColors.primaryLight : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? AppColors.primaryLight : AppColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 52,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected ? AppColors.accentLight : AppColors.primary,
                ),
                const SizedBox(height: 2),
                Text(
                  item.code,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TiffinImageViewer extends StatelessWidget {
  final _TiffinViewItem item;

  const _TiffinImageViewer({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: AppColors.surfaceVariant,
        child: Stack(
          children: [
            Positioned.fill(
              child: item.isPanorama
                  ? LayoutBuilder(
                      builder: (context, constraints) {
                        final imageHeight = constraints.maxHeight;
                        final imageWidth = imageHeight * 5;
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: SizedBox(
                            width: imageWidth,
                            height: imageHeight,
                            child: AppNetworkImage(
                              imageUrl: item.imageUrl,
                              width: imageWidth,
                              height: imageHeight,
                              fit: BoxFit.contain,
                              targetOptimizationWidth: 2000,
                            ),
                          ),
                        );
                      },
                    )
                  : GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _openFullscreen(context),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: AppNetworkImage(
                          imageUrl: item.imageUrl,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          targetOptimizationWidth: 1000,
                        ),
                      ),
                    ),
            ),
            if (item.isPanorama)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withAlpha(235),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.swipe_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Swipe',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (!item.isPanorama)
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xD9335C31),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.zoom_out_map_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Tap to expand',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openFullscreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            _FullscreenArtworkView(imageUrl: item.imageUrl, title: item.title),
      ),
    );
  }
}

class _FullscreenArtworkView extends StatelessWidget {
  final String imageUrl;
  final String title;

  const _FullscreenArtworkView({required this.imageUrl, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(
        child: Center(
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 5,
            child: AppNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              targetOptimizationWidth: 1800,
            ),
          ),
        ),
      ),
    );
  }
}
