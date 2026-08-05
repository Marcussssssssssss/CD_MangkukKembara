import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../Model/Repositories/HeritageExperience/qr_scan_result_model.dart';

/// B3. Result returned by the secure scan_tiffin_qr() RPC.
class ScanResultView extends StatelessWidget {
  final QrScanResultModel result;
  const ScanResultView({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final isNew = result.isNewlyCollected;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                builder: (_, value, child) =>
                    Transform.scale(scale: value, child: child),
                child: Icon(
                  isNew ? Icons.check_circle_rounded : Icons.star_rounded,
                  size: 96,
                  color: isNew ? AppColors.success : AppColors.accent,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isNew ? 'Tiffin collected!' : 'Already in your collection',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.kitchen_rounded,
                    color: AppColors.primary,
                  ),
                  title: Text(result.editionName),
                  subtitle: Text(result.state),
                  trailing: Icon(
                    isNew ? Icons.add_task_rounded : Icons.done_all_rounded,
                    color: AppColors.success,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isNew
                    ? 'The tiffin was securely added to your personal collection.'
                    : 'No duplicate was created. You can continue exploring its story.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.explore_rounded),
                  label: const Text('View Heritage Experience'),
                  onPressed: () => Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.tiffinExperience,
                    arguments: result.tiffinId,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.heritageExperience,
                    (_) => false,
                  ),
                  child: const Text('Return to Collection'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
