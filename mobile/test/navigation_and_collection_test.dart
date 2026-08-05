import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mangkuk_kembara/Model/Repositories/HeritageExperience/heritage_tiffin_model.dart';
import 'package:mangkuk_kembara/Model/Repositories/HeritageExperience/heritage_experience_repository.dart';
import 'package:mangkuk_kembara/View/Widgets/map_home_button.dart';
import 'package:mangkuk_kembara/View/Widgets/tiffin_card.dart';
import 'package:mangkuk_kembara/ViewModel/HeritageExperience/heritage_experience_view_model.dart';
import 'package:mangkuk_kembara/core/app_routes.dart';

void main() {
  testWidgets('module arrow returns to the existing Treasure Map route', (
    tester,
  ) async {
    var mapBuilds = 0;
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.treasureMap,
        routes: {
          AppRoutes.treasureMap: (context) {
            mapBuilds++;
            return Scaffold(
              body: TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.heritageExperience),
                child: const Text('Open Experience'),
              ),
            );
          },
          AppRoutes.heritageExperience: (_) => MapBackScope(
            child: Scaffold(
              appBar: AppBar(leading: const MapHomeButton()),
              body: const Text('Experience'),
            ),
          ),
        },
      ),
    );

    await tester.tap(find.text('Open Experience'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Open Experience'), findsOneWidget);
    expect(mapBuilds, 1);
  });

  testWidgets('platform back returns a module landing page to Treasure Map', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          AppRoutes.treasureMap: (context) => Scaffold(
            body: TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.community),
              child: const Text('Open Community'),
            ),
          ),
          AppRoutes.community: (_) =>
              const MapBackScope(child: Scaffold(body: Text('Community'))),
        },
      ),
    );
    await tester.tap(find.text('Open Community'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Open Community'), findsOneWidget);
  });

  testWidgets('collected tiffin cards do not show a collected indicator', (
    tester,
  ) async {
    const tiffin = HeritageTiffinModel(
      id: 'tiffin-1',
      editionName: 'Penang Edition',
      state: 'Pulau Pinang',
      stateCode: 'PNG',
      summary: 'Heritage food',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 220,
            height: 320,
            child: TiffinCard(tiffin: tiffin, onTap: () {}),
          ),
        ),
      ),
    );

    expect(find.text('Collected'), findsNothing);
    expect(find.byIcon(Icons.check_rounded), findsNothing);
    expect(find.text('Tap to explore'), findsOneWidget);
  });

  test('Experience exposes empty and collected-only states', () async {
    final repository = _FakeHeritageExperienceRepository();
    final viewModel = HeritageExperienceViewModel(repo: repository);

    await viewModel.loadTiffins(userId: 'user-1');
    expect(viewModel.isEmpty, isTrue);

    repository.collected = const [
      HeritageTiffinModel(
        id: 'owned-tiffin',
        editionName: 'Owned Edition',
        state: 'Johor',
        stateCode: 'JHR',
        summary: '',
      ),
    ];
    await viewModel.loadTiffins(userId: 'user-1');

    expect(viewModel.tiffins.map((item) => item.id), ['owned-tiffin']);
    expect(viewModel.collectedCount, 1);
    expect(viewModel.totalCount, 4);
  });
}

class _FakeHeritageExperienceRepository extends Fake
    implements HeritageExperienceRepository {
  List<HeritageTiffinModel> collected = [];

  @override
  Future<Set<String>> fetchCollectedTiffinIds(String userId) async =>
      collected.map((item) => item.id).toSet();

  @override
  Future<List<HeritageTiffinModel>> fetchCollectedTiffins(
    String userId, {
    String? state,
  }) async => state == null
      ? collected
      : collected.where((item) => item.state == state).toList();

  @override
  Future<int> fetchTotalActiveTiffinCount() async => 4;
}
