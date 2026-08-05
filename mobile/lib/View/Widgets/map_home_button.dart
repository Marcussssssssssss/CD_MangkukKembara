import 'package:flutter/material.dart';
import '../../core/app_routes.dart';

/// AppBar leading button that returns to the Heritage Treasure Map.
class MapHomeButton extends StatelessWidget {
  const MapHomeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Return to Heritage Treasure Map',
      child: Tooltip(
        message: 'Return to Heritage Treasure Map',
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => returnToTreasureMap(context),
        ),
      ),
    );
  }
}

/// Makes the platform back gesture/button return module landing pages to Map.
class MapBackScope extends StatelessWidget {
  final Widget child;

  const MapBackScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final canReturnByPopping = Navigator.of(context).canPop();
    return PopScope(
      canPop: canReturnByPopping,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        returnToTreasureMap(context);
      },
      child: child,
    );
  }
}

/// Returns to the existing map route when possible, otherwise replaces the
/// current root. This keeps exactly one Treasure Map in the navigator stack.
void returnToTreasureMap(BuildContext context) {
  final navigator = Navigator.of(context);
  if (!navigator.canPop()) {
    navigator.pushReplacementNamed(AppRoutes.treasureMap);
    return;
  }
  var foundMap = false;
  navigator.popUntil((route) {
    foundMap = route.settings.name == AppRoutes.treasureMap;
    return foundMap;
  });
  if (!foundMap) {
    navigator.pushReplacementNamed(AppRoutes.treasureMap);
  }
}
