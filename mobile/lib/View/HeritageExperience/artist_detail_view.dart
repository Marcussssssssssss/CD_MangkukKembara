import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../Model/Repositories/HeritageExperience/artist_model.dart';
import '../../ViewModel/HeritageExperience/tiffin_content_view_model.dart';
import '../Widgets/error_state_widget.dart';
import '../Widgets/loading_widget.dart';

/// B5. Artist Detail View.
class ArtistDetailView extends StatefulWidget {
  final String artistId;
  const ArtistDetailView({super.key, required this.artistId});

  @override
  State<ArtistDetailView> createState() => _ArtistDetailViewState();
}

class _ArtistDetailViewState extends State<ArtistDetailView>
    with SingleTickerProviderStateMixin {
  late final TiffinContentViewModel _vm;
  late final AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _vm = TiffinContentViewModel();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _vm.loadArtist(widget.artistId);
      if (mounted && !_vm.hasError) _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer<TiffinContentViewModel>(
        builder: (context, vm, _) => Scaffold(
          backgroundColor: _ArtistColors.cream,
          appBar: AppBar(
            backgroundColor: _ArtistColors.cream,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              tooltip: 'Back',
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: _ArtistColors.green,
              ),
              onPressed: () => Navigator.maybePop(context),
            ),
            title: Text(
              'Artist',
              style: GoogleFonts.playfairDisplay(
                color: _ArtistColors.green,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: vm.isLoading
              ? const LoadingSpinner()
              : vm.hasError || vm.artist == null
              ? ErrorStateWidget(
                  message: vm.errorMessage ?? 'Could not load this artist.',
                  onRetry: () => _vm.loadArtist(widget.artistId),
                )
              : RefreshIndicator(
                  color: _ArtistColors.green,
                  onRefresh: () =>
                      _vm.loadArtist(widget.artistId, showLoading: false),
                  child: _buildContent(vm.artist!),
                ),
        ),
      ),
    );
  }

  Widget _buildContent(ArtistModel artist) => SingleChildScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
    child: Column(
      children: [
        // Artist Hero Section
        _EntranceAnimation(
          controller: _entranceController,
          interval: const Interval(0, .62, curve: Curves.easeOutCubic),
          child: _ArtistHero(artist: artist),
        ),
      ],
    ),
  );
}

abstract final class _ArtistColors {
  static const green = Color(0xFF335C31);
  static const text = Color(0xFF283427);
  static const cream = Color(0xFFFAF7F0);
  static const gold = Color(0xFFD6A84B);
  static const muted = Color(0xFF7A8378);
}

class _ArtistHero extends StatelessWidget {
  const _ArtistHero({required this.artist});
  final ArtistModel artist;

  @override
  Widget build(BuildContext context) {
    final name = artist.displayName.trim();
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    final photoUrl = artist.photoUrl?.trim();
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
    return SizedBox(
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
        Positioned(
          top: 48,
          left: 8,
          child: Icon(
            Icons.local_florist_outlined,
            size: 92,
            color: _ArtistColors.green.withValues(alpha: .07),
          ),
        ),
        Positioned(
          top: 12,
          right: 8,
          child: Icon(
            Icons.account_balance_outlined,
            size: 84,
            color: _ArtistColors.green.withValues(alpha: .06),
          ),
        ),
        Column(
          children: [
            Container(
              width: 120,
              height: 120,
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _ArtistColors.gold,
              ),
              child: CircleAvatar(
                backgroundColor: _ArtistColors.green,
                backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
                onBackgroundImageError: hasPhoto ? (_, _) {} : null,
                child: hasPhoto
                    ? null
                    : Text(
                        initial,
                        style: GoogleFonts.playfairDisplay(
                          color: Colors.white,
                          fontSize: 46,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              name.isEmpty ? 'Artist' : name,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: _ArtistColors.text,
              ),
            ),
            if (artist.stageName != null && artist.stageName != artist.fullName)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  artist.fullName,
                  style: GoogleFonts.nunito(color: _ArtistColors.muted),
                ),
              ),
            const SizedBox(height: 12),
            const _GoldDivider(),
            const SizedBox(height: 12),
            Text(
              'FEATURED ARTIST',
              style: GoogleFonts.nunito(
                color: _ArtistColors.green,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.45,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Heritage Tiffin Collection',
              style: GoogleFonts.nunito(
                color: _ArtistColors.muted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        ],
      ),
    );
  }
}

class _GoldDivider extends StatelessWidget {
  const _GoldDivider();

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(width: 34, child: Divider(color: _ArtistColors.gold, thickness: 1)),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Icon(Icons.diamond_outlined, color: _ArtistColors.gold, size: 13),
      ),
      SizedBox(width: 34, child: Divider(color: _ArtistColors.gold, thickness: 1)),
    ],
  );
}

// Entrance Animation
class _EntranceAnimation extends StatelessWidget {
  const _EntranceAnimation({
    required this.controller,
    required this.interval,
    required this.child,
  });
  final AnimationController controller;
  final Interval interval;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(parent: controller, curve: interval);
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, .055), end: Offset.zero)
            .animate(animation),
        child: child,
      ),
    );
  }
}
