import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../ViewModel/HeritageExperience/tiffin_content_view_model.dart';
import '../Widgets/empty_state_widget.dart';
import '../Widgets/error_state_widget.dart';
import '../Widgets/loading_widget.dart';

/// B7. Heritage Story View with previous/next navigation.
class HeritageStoryView extends StatefulWidget {
  final String tiffinId;
  const HeritageStoryView({super.key, required this.tiffinId});

  @override
  State<HeritageStoryView> createState() => _HeritageStoryViewState();
}

class _HeritageStoryViewState extends State<HeritageStoryView>
    with SingleTickerProviderStateMixin {
  late final TiffinContentViewModel _vm;
  late final AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _vm = TiffinContentViewModel();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _vm.loadTiffin(widget.tiffinId);
      if (mounted && !_vm.hasError && _vm.stories.isNotEmpty) {
        _entranceController.forward();
      }
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
        builder: (ctx, vm, _) => Scaffold(
          backgroundColor: _StoryColors.cream,
          appBar: AppBar(
            backgroundColor: _StoryColors.cream,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              tooltip: 'Back',
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: _StoryColors.green,
              ),
              onPressed: () => Navigator.maybePop(ctx),
            ),
            title: Text(
              'Heritage Story',
              style: GoogleFonts.playfairDisplay(
                color: _StoryColors.green,
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: [
              if (vm.stories.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Center(
                    child: Text(
                      '${vm.currentStoryIndex + 1} / ${vm.stories.length}',
                      style: GoogleFonts.nunito(
                        color: _StoryColors.muted,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
	              ),
	            ),
	          ],
          ),
          body: vm.isLoading
              ? const LoadingSpinner()
              : vm.hasError
              ? ErrorStateWidget(onRetry: () => _vm.retry(widget.tiffinId))
              : vm.stories.isEmpty
              ? RefreshableStateView(
                  onRefresh: () =>
                      vm.loadTiffin(widget.tiffinId, showLoading: false),
                  child: const Center(
                    child: Text('No stories available for this tiffin.'),
                  ),
                )
              : _buildStoryPage(ctx, vm),
        ),
      ),
    );
  }

  Widget _buildStoryPage(BuildContext context, TiffinContentViewModel vm) {
    final story = vm.currentStory!;
    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              IgnorePointer(
                child: Image.asset(
                  'asset/image/heritage_story_illustration.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
              RefreshIndicator(
            color: _StoryColors.green,
            onRefresh: () => vm.loadTiffin(widget.tiffinId, showLoading: false),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                24,
                6,
                24,
                MediaQuery.paddingOf(context).bottom + 32,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
                    children: [
                      // NEW: Heritage header decoration
                      const _HeritageHeaderDivider(),
                      const SizedBox(height: 28),

                      // NEW: Story label
                      _StoryEntrance(
                        controller: _entranceController,
                        interval: const Interval(0, .38, curve: Curves.easeOutCubic),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.account_balance_outlined,
                              color: _StoryColors.gold,
                              size: 25,
                            ),
                            const SizedBox(height: 9),
                            Text(
                              '•  HERITAGE STORY  •',
                              style: GoogleFonts.nunito(
                                color: _StoryColors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.7,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // NEW: Story title styling
                      _StoryEntrance(
                        controller: _entranceController,
                        interval: const Interval(.10, .60, curve: Curves.easeOutCubic),
                        child: LayoutBuilder(
                          builder: (context, constraints) => Text(
                            story.title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.playfairDisplay(
                              color: _StoryColors.text,
                              fontSize: constraints.maxWidth >= 500 ? 40 : 34,
                              height: 1.13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 17),
                      const _GoldDivider(),
                      const SizedBox(height: 18),
                      _StoryEntrance(
                        controller: _entranceController,
                        interval: const Interval(.20, .70, curve: Curves.easeOutCubic),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 510),
                          child: Text(
                            story.body,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              color: _StoryColors.text,
                              fontSize: 17,
                              height: 1.58,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      // NEW: Heritage illustration
                      // The illustration now fills the page background.
                      SizedBox(height: MediaQuery.sizeOf(context).height * .24),

                      // NEW: Decorative quote
                      _StoryEntrance(
                        controller: _entranceController,
                        interval: const Interval(.46, 1, curve: Curves.easeOutCubic),
                        child: const Column(
                          children: [
                            _QuoteDivider(),
                            SizedBox(height: 11),
                            Text(
                              '“Every story has a place.”',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _StoryColors.green,
                                fontSize: 20,
                                height: 1.35,
                                fontStyle: FontStyle.italic,
                                fontFamily: 'serif',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

abstract final class _StoryColors {
  static const green = Color(0xFF335C31);
  static const text = Color(0xFF283427);
  static const cream = Color(0xFFFAF7F0);
  static const gold = Color(0xFFD6A84B);
  static const muted = Color(0xFF7A8B76);
}

class _HeritageHeaderDivider extends StatelessWidget {
  const _HeritageHeaderDivider();

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Expanded(child: Divider(color: _StoryColors.green, thickness: .7)),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Icon(Icons.diamond_outlined, size: 14, color: _StoryColors.gold),
      ),
      Expanded(child: Divider(color: _StoryColors.green, thickness: .7)),
    ],
  );
}

class _GoldDivider extends StatelessWidget {
  const _GoldDivider();

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(width: 36, child: Divider(color: _StoryColors.gold, thickness: 1)),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Icon(Icons.diamond_outlined, size: 12, color: _StoryColors.gold),
      ),
      SizedBox(width: 36, child: Divider(color: _StoryColors.gold, thickness: 1)),
    ],
  );
}

class _QuoteDivider extends StatelessWidget {
  const _QuoteDivider();

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(width: 30, child: Divider(color: _StoryColors.gold, thickness: 1)),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Icon(Icons.auto_awesome_rounded, size: 13, color: _StoryColors.gold),
      ),
      SizedBox(width: 30, child: Divider(color: _StoryColors.gold, thickness: 1)),
    ],
  );
}

// NEW: Entrance animation
class _StoryEntrance extends StatelessWidget {
  const _StoryEntrance({
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
        position: Tween<Offset>(begin: const Offset(0, .035), end: Offset.zero)
            .animate(animation),
        child: child,
      ),
    );
  }
}
