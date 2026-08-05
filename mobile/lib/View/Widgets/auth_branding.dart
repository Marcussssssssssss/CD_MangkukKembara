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
            'asset/image/logo_light.png',
            width: 260,
            height: 86,
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
