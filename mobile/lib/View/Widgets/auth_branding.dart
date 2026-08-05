import 'package:flutter/material.dart';

import '../../core/constants.dart';

class AuthBranding extends StatelessWidget {
  final String subtitle;

  const AuthBranding({super.key, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: '${AppConstants.appName}. $subtitle',
      child: Column(
        children: [
          Image.asset(
            'asset/image/logo.png',
            width: 260,
            height: 94,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Keeps authentication content centered when it fits, and scrollable when it
/// does not (including when the keyboard reduces the available height).
class AuthPageLayout extends StatelessWidget {
  final Widget child;

  const AuthPageLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - 48).clamp(0, double.infinity),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
