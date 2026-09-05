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

// Artwork Story's palette is local so other community pages keep their styling.
const _storyInk = Color(0xFF09251F);
const _storyGreen = Color(0xFF406D49);
const _storyGold = Color(0xFFFFCA35);
const _storyBackground = 'asset/image/artwork_story_background.png';
const _ideaBackground = 'asset/image/artwork_story_idea.png';
const _cultureBackground = 'asset/image/artwork_story_culture.png';

/// C7. Artwork Voting Detail View.
class ArtworkVotingDetailView extends StatefulWidget {
  final String entryId;
  final int initialLayer;
  const ArtworkVotingDetailView({
    super.key,
    required this.entryId,
    this.initialLayer = 0,
  });

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
            backgroundColor: Colors.white,
            appBar: AppBar(
              toolbarHeight: 44,
              title: const Text('Artwork Story'),
              titleTextStyle: const TextStyle(
                color: _storyInk,
                fontSize: 19,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: Colors.white,
              foregroundColor: _storyInk,
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 0,
              elevation: 0,
              centerTitle: false,
            ),
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
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: _ExploreTiffin(
            entry: vm.selectedEntry!,
            initialLayer: widget.initialLayer,
          ),
        ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFD9EDCD),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'FEATURED ARTWORK',
              style: TextStyle(
                color: _storyInk,
                fontSize: 9,
                letterSpacing: 1,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            entry.artworkTitle,
            style: const TextStyle(
              color: _storyInk,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const CircleAvatar(
                radius: 14,
                backgroundColor: Color(0xFFDDE9D8),
                child: Icon(Icons.person_rounded, size: 21, color: _storyGreen),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  'Created by ${entry.submitterName}',
                  style: const TextStyle(color: _storyInk, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 7,
            runSpacing: 6,
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
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(130),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD9E2D6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: _storyGreen),
          const SizedBox(width: 7),
          Text(label, style: const TextStyle(color: _storyInk, fontSize: 12)),
        ],
      ),
    );
  }
}

class _StoryCarousel extends StatefulWidget {
  final ArtworkVotingEntryModel entry;

  const _StoryCarousel({required this.entry});

  @override
  State<_StoryCarousel> createState() => _StoryCarouselState();
}

class _StoryCarouselState extends State<_StoryCarousel> {
  final _controller = PageController(viewportFraction: .70);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final layers = [
      entry.layer1Meaning,
      entry.layer2Meaning,
      entry.layer3Meaning,
    ];
    final layerStory = [
      for (var i = 0; i < layers.length; i++)
        if (layers[i].trim().isNotEmpty) 'Layer ${i + 1}: ${layers[i]}',
    ].join('\n\n');
    final cards = [
      _StoryCard(
        eyebrow: 'THE IDEA',
        title: 'Design narrative',
        body: entry.designDescription,
        icon: Icons.draw_rounded,
      ),
      _StoryCard(
        eyebrow: 'CULTURE',
        title: 'Cultural roots',
        body: entry.culturalInspiration,
        icon: Icons.local_florist_rounded,
        isCulture: true,
      ),
      _StoryCard(
        eyebrow: 'THE DETAILS',
        title: 'Layer meanings',
        body: layerStory,
        icon: Icons.layers_rounded,
      ),
    ];
    return Column(
      children: [
        SizedBox(
          height: 114 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 2),
          child: Padding(
            padding: const EdgeInsets.only(left: 18),
            child: PageView(
              controller: _controller,
              padEnds: false,
              onPageChanged: (page) => setState(() => _page = page),
              children: cards,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(cards.length, (index) {
            return Semantics(
              label: 'Story ${index + 1} of ${cards.length}',
              selected: _page == index,
              button: true,
              child: InkResponse(
                radius: 16,
                onTap: () => _controller.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 9,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _page == index
                          ? _storyGreen
                          : const Color(0xFFD4DED0),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _StoryCard extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String body;
  final IconData icon;
  final bool isCulture;

  const _StoryCard({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.icon,
    this.isCulture = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = body.trim().isEmpty
        ? 'This part of the artwork’s story is waiting to be shared.'
        : body;
    final foreground = isCulture ? const Color(0xFFCB810B) : _storyGreen;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: isCulture ? const Color(0xFFFFF8E6) : const Color(0xFFF0F5EC),
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showModalBottomSheet<void>(
            context: context,
            showDragHandle: true,
            isScrollControlled: true,
            builder: (context) => SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _storyInk,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      text,
                      style: const TextStyle(
                        color: _storyInk,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: _StoryCardBackground(isCulture: isCulture),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 9, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, size: 17, color: foreground),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          eyebrow,
                          style: TextStyle(
                            color: foreground,
                            fontSize: 8,
                            letterSpacing: .8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isCulture ? foreground : _storyInk,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 55),
                        child: Text(
                          text,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _storyInk,
                            fontSize: 10.5,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Frame the supplied card artwork without its outer white margins.
/// The original PNGs are kept intact; only their display bounds are cropped.
class _StoryCardBackground extends StatelessWidget {
  final bool isCulture;
  const _StoryCardBackground({required this.isCulture});

  @override
  Widget build(BuildContext context) {
    final source = isCulture
        ? const Rect.fromLTWH(49, 171, 1350, 745)
        : const Rect.fromLTWH(43, 116, 1366, 855);
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scaleX = constraints.maxWidth / source.width;
          final scaleY = constraints.maxHeight / source.height;
          return ClipRect(
            child: Stack(
              children: [
                Positioned(
                  left: -source.left * scaleX,
                  top: -source.top * scaleY,
                  width: 1448 * scaleX,
                  height: 1086 * scaleY,
                  child: Image.asset(
                    isCulture ? _cultureBackground : _ideaBackground,
                    fit: BoxFit.fill,
                    excludeFromSemantics: true,
                  ),
                ),
              ],
            ),
          );
        },
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
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 564),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: hasVoted
                    ? const [Color(0xFF6F926A), Color(0xFF406D49)]
                    : const [
                        Color(0xFF789774),
                        Color(0xFF416D4C),
                        Color(0xFF315B40),
                      ],
              ),
              border: Border.all(color: const Color(0xFFACC2A7)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x30496938),
                  blurRadius: 16,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(32),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: isVoting ? null : onVote,
                child: Semantics(
                  button: true,
                  enabled: !isVoting,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isVoting)
                          const SizedBox.square(
                            dimension: 19,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        else
                          Icon(
                            hasVoted
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: Colors.white,
                            size: 21,
                          ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            hasVoted
                                ? 'Voted (Tap to Unvote)'
                                : 'Vote for This Artwork',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
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
  final int initialLayer;

  const _ExploreTiffin({required this.entry, this.initialLayer = 0});

  @override
  State<_ExploreTiffin> createState() => _ExploreTiffinState();
}

class _ExploreTiffinState extends State<_ExploreTiffin> {
  _TiffinView _selected = _TiffinView.front;

  @override
  void initState() {
    super.initState();
    _selected = switch (widget.initialLayer) {
      1 => _TiffinView.layer1,
      2 => _TiffinView.layer2,
      3 => _TiffinView.layer3,
      _ => _TiffinView.front,
    };
  }

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
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(_storyBackground),
              fit: BoxFit.fill,
            ),
          ),
          child: Column(
            children: [
              _ArtworkIntro(entry: widget.entry),
              SizedBox(
                height: (MediaQuery.sizeOf(context).width * .49).clamp(
                  170,
                  300,
                ),
                width: double.infinity,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  child: _TiffinImageViewer(
                    key: ValueKey(selectedItem.view),
                    item: selectedItem,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
          child: Row(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                Expanded(
                  child: _TiffinLayerButton(
                    item: items[index],
                    selected: items[index].view == _selected,
                    onTap: () => setState(() => _selected = items[index].view),
                  ),
                ),
                if (index != items.length - 1) const SizedBox(width: 4),
              ],
            ],
          ),
        ),
        if (selectedItem.isPanorama)
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Story of ${selectedItem.title}',
                  style: const TextStyle(
                    color: _storyGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  selectedItem.description.trim().isEmpty
                      ? 'This layer’s story is waiting to be shared.'
                      : selectedItem.description,
                  style: const TextStyle(
                    color: _storyInk,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        Padding(
          // Use some of the spare vertical room before the story carousel. This
          // keeps the story section visually balanced above the fixed vote bar.
          padding: const EdgeInsets.fromLTRB(20, 40, 16, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: _storyGold,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'The story within',
                      style: TextStyle(
                        color: _storyInk,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Discover the meaning behind each layer',
                      style: TextStyle(
                        color: Color(0xFF95929C),
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _StoryCarousel(entry: widget.entry),
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
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x154F6D3B),
              blurRadius: 13,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(
              color: selected
                  ? const Color(0xFF9CA626)
                  : const Color(0xFFE5E7E1),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, .4),
                radius: 1.2,
                colors: selected
                    ? const [Color(0xFFCFE5AF), Color(0xFFFFFFEF)]
                    : const [Color(0xFFF5F7F2), Colors.white],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 18, color: _storyGreen),
                    const SizedBox(height: 2),
                    Text(
                      item.code,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _storyInk,
                        fontSize: 11,
                        height: 1.2,
                      ),
                    ),
                  ],
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
        color: Colors.transparent,
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
                        padding: const EdgeInsets.fromLTRB(40, 6, 40, 10),
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
                right: 20,
                bottom: 18,
                child: OutlinedButton.icon(
                  onPressed: () => _openFullscreen(context),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xCFE7EFDF),
                    foregroundColor: _storyInk,
                    side: const BorderSide(color: Color(0xFF9AB895)),
                    minimumSize: const Size(0, 30),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.zoom_out_map_rounded, size: 15),
                  label: const Text(
                    'Tap to expand',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w400),
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
