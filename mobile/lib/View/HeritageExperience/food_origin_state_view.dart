import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../Model/Repositories/HeritageExperience/heritage_food_model.dart';
import '../../Model/Repositories/HeritageTreasureMap/treasure_map_repository.dart';
import '../../Model/Repositories/HeritageTreasureMap/vendor_model.dart';
import '../../ViewModel/HeritageExperience/tiffin_content_view_model.dart';
import '../../core/app_routes.dart';
import '../Widgets/empty_state_widget.dart';
import '../Widgets/error_state_widget.dart';
import '../Widgets/loading_widget.dart';

class FoodOriginStateView extends StatefulWidget {
  /// This route receives a tiffin ID and resolves its linked heritage food.
  final String foodId;

  const FoodOriginStateView({super.key, required this.foodId});

  @override
  State<FoodOriginStateView> createState() => _FoodOriginStateViewState();
}

class _FoodOriginStateViewState extends State<FoodOriginStateView> {
  late final TiffinContentViewModel _vm;
  final _vendorRepository = TreasureMapRepository();
  bool _isOpeningVendor = false;

  @override
  void initState() {
    super.initState();
    _vm = TiffinContentViewModel();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _vm.loadFoodForTiffin(widget.foodId),
    );
  }

  /// Opens an active vendor already linked to this exact heritage food.
  Future<void> _openFoodVendor(HeritageFoodModel food) async {
    if (_isOpeningVendor) return;

    setState(() => _isOpeningVendor = true);
    try {
      final vendors = await _vendorRepository.fetchVendors(query: food.name);
      final matches = vendors.where(
        (vendor) => vendor.heritageFoods.any(
          (vendorFood) => vendorFood.toLowerCase() == food.name.toLowerCase(),
        ),
      ).toList();

      // A food can be sold by several vendors. Prefer the one located in the
      // food's origin state, then use its name/description to select the most
      // specific match instead of taking an arbitrary first result.
      final stateMatches = food.originStateName == null
          ? matches
          : matches
                .where(
                  (vendor) =>
                      vendor.state.toLowerCase() ==
                      food.originStateName!.toLowerCase(),
                )
                .toList();
      final candidates = stateMatches.isEmpty ? matches : stateMatches;
      candidates.sort(
        (a, b) => _vendorFoodRelevance(b, food).compareTo(
          _vendorFoodRelevance(a, food),
        ),
      );
      final matchingVendor = candidates.isEmpty ? null : candidates.first;

      if (!mounted) return;
      if (matchingVendor == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No active vendor is linked to this heritage food yet.'),
          ),
        );
        return;
      }

      await Navigator.pushNamed(
        context,
        AppRoutes.vendorDetail,
        arguments: matchingVendor.id,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open the vendor right now.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isOpeningVendor = false);
    }
  }

  int _vendorFoodRelevance(VendorModel vendor, HeritageFoodModel food) {
    final searchableText = '${vendor.name} ${vendor.description}'.toLowerCase();
    return food.name
        .toLowerCase()
        .split(RegExp(r'\\s+'))
        .where((term) => term.isNotEmpty)
        .where(searchableText.contains)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer<TiffinContentViewModel>(
        builder: (context, vm, _) => Scaffold(
          backgroundColor: _FoodColors.cream,
          appBar: AppBar(
            backgroundColor: _FoodColors.cream,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              tooltip: 'Back',
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: _FoodColors.green,
              ),
              onPressed: () => Navigator.maybePop(context),
            ),
            title: Text(
              'Food Origin & State',
              style: GoogleFonts.playfairDisplay(
                color: _FoodColors.green,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: vm.isLoading
              ? const LoadingSpinner()
              : vm.hasError
              ? ErrorStateWidget(
                  message:
                      vm.errorMessage ?? 'Could not load this heritage food.',
                  onRetry: () => vm.loadFoodForTiffin(widget.foodId),
                )
              : vm.food == null
              ? RefreshableStateView(
                  onRefresh: () =>
                      vm.loadFoodForTiffin(widget.foodId, showLoading: false),
                  child: const EmptyStateWidget(
                    icon: Icons.rice_bowl_outlined,
                    title: 'Food story unavailable',
                    subtitle: 'No published food is linked to this tiffin.',
                  ),
                )
              : _buildContent(vm.food!),
        ),
      ),
    );
  }

  Widget _buildContent(HeritageFoodModel food) {
    final subtitle = [food.categoryName, food.originStateName]
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .join(' • ');
    return Stack(
      fit: StackFit.expand,
      children: [
        // NEW: Heritage background
        IgnorePointer(
          child: Image.asset(
            'asset/image/heritage_background.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        IgnorePointer(
          child: ColoredBox(color: _FoodColors.cream.withValues(alpha: .16)),
        ),
        SafeArea(
          top: false,
          child: RefreshIndicator(
            color: _FoodColors.green,
            onRefresh: () =>
                _vm.loadFoodForTiffin(widget.foodId, showLoading: false),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _HeaderDivider(),
                  const SizedBox(height: 24),
                  // NEW: Hero food card
                  _FoodHero(food: food, subtitle: subtitle),
                  const SizedBox(height: 22),
                  // NEW: Origin summary card
                  _OriginCard(
                    icon: Icons.menu_book_rounded,
                    title: 'Origin Summary',
                    content: food.originSummary,
                    fallback: 'Origin details have not been published yet.',
                  ),
                  const SizedBox(height: 14),
                  // NEW: Cultural significance card
                  _OriginCard(
                    icon: Icons.account_balance_outlined,
                    title: 'Cultural Significance',
                    content: food.culturalSignificance,
                    fallback: 'Cultural notes have not been published yet.',
                  ),
                  const SizedBox(height: 14),
                  // NEW: Origin state card
                  _OriginCard(
                    icon: Icons.location_on_rounded,
                    title: 'Origin State',
                    content: food.originStateName,
                    fallback: 'Origin state unavailable.',
                  ),
                  const SizedBox(height: 24),
                  // NEW: Vendor button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          colors: [_FoodColors.green, Color(0xFF234823)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _FoodColors.green.withValues(alpha: .25),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.map_outlined, size: 21),
                        label: Text(
                          'Browse Heritage Food Vendors',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        onPressed: _isOpeningVendor
                            ? null
                            : () => _openFoodVendor(food),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // NEW: Heritage illustration
                  const _HeritageOrnament(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

abstract final class _FoodColors {
  static const green = Color(0xFF335C31);
  static const text = Color(0xFF283427);
  static const cream = Color(0xFFFAF7F0);
  static const gold = Color(0xFFD6A84B);
}

class _FoodHero extends StatelessWidget {
  const _FoodHero({required this.food, required this.subtitle});

  final HeritageFoodModel food;
  final String subtitle;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 16 / 9,
    child: Material(
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: .18),
      child: Ink(
        decoration: BoxDecoration(
          color: _FoodColors.green,
          image: food.imageUrl?.trim().isNotEmpty ?? false
              ? DecorationImage(
                  image: NetworkImage(food.imageUrl!),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: .42),
                    BlendMode.darken,
                  ),
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.rice_bowl_rounded, color: Colors.white, size: 42),
              const Spacer(),
              Text(
                food.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: 28,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: GoogleFonts.nunito(
                    color: Colors.white.withValues(alpha: .88),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

class _OriginCard extends StatelessWidget {
  const _OriginCard({
    required this.icon,
    required this.title,
    required this.content,
    required this.fallback,
  });

  final IconData icon;
  final String title;
  final String? content;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    final body = content?.trim().isNotEmpty == true ? content! : fallback;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _FoodColors.green.withValues(alpha: .08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .045),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: const BoxDecoration(
              color: Color(0xFFEEF3EC),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _FoodColors.gold, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    color: _FoodColors.green,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  body,
                  style: GoogleFonts.nunito(
                    color: _FoodColors.text,
                    fontSize: 15,
                    height: 1.52,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderDivider extends StatelessWidget {
  const _HeaderDivider();

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Expanded(child: Divider(color: _FoodColors.gold, thickness: 1)),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Icon(Icons.auto_awesome_rounded, color: _FoodColors.gold, size: 14),
      ),
      Expanded(child: Divider(color: _FoodColors.gold, thickness: 1)),
    ],
  );
}

class _HeritageOrnament extends StatelessWidget {
  const _HeritageOrnament();

  @override
  Widget build(BuildContext context) => const _HeaderDivider();
}
