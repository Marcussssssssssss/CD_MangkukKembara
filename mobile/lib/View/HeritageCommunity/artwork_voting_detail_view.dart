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
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text('Artwork')),
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
    const artColor = AppColors.primary;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _ExploreTiffin(entry: e),
          ),

          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.primaryContainer, width: 1.4),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.artworkTitle,
                  style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ARTWORK BY',
                            style: TextStyle(
                              color: AppColors.textHint,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            e.submitterName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(height: 1),
                const SizedBox(height: 16),
                // Rank + votes
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: artColor.withAlpha(40),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Rank #${e.currentRank}',
                        style: TextStyle(
                          color: artColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.how_to_vote_rounded,
                      size: 16,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${e.voteCount} votes',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _Section('Design Description', e.designDescription),
                _Section(
                  'Cultural Inspiration',
                  e.culturalInspiration,
                  bottomPadding: 0,
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
        SizedBox(
          height: 300,
          width: double.infinity,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _TiffinImageViewer(
              key: ValueKey(selectedItem.view),
              item: selectedItem,
            ),
          ),
        ),
        const SizedBox(height: 10),
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
        const SizedBox(height: 10),
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
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${selectedItem.title} Meaning',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
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
    return Semantics(
      button: true,
      selected: selected,
      label: 'Show ${item.title}',
      child: Material(
        color: selected ? AppColors.primary : AppColors.tagBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 46,
            child: Center(
              child: Text(
                item.code,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
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
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: SizedBox(
                        width: 640,
                        child: AppNetworkImage(
                          imageUrl: item.imageUrl,
                          width: 640,
                          fit: BoxFit.cover,
                          targetOptimizationWidth: 1400,
                        ),
                      ),
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
                        '360°',
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

class _Section extends StatelessWidget {
  final String title;
  final String body;
  final double bottomPadding;

  const _Section(this.title, this.body, {this.bottomPadding = 18});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
