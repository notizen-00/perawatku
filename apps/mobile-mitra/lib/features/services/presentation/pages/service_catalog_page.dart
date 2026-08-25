import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/json_helpers.dart';
import '../../../../shared/widgets/cards/medical_card.dart';
import '../../../../shared/widgets/common/error_card.dart';
import '../../../../shared/widgets/loaders/card_skeleton.dart';
import '../../domain/entities/service_catalog_item.dart';
import '../cubit/service_catalog_cubit.dart';

class ServiceCatalogPage extends StatelessWidget {
  const ServiceCatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ServiceCatalogCubit>()..load(),
      child: const _ServiceCatalogView(),
    );
  }
}

class _ServiceCatalogView extends StatefulWidget {
  const _ServiceCatalogView();

  @override
  State<_ServiceCatalogView> createState() => _ServiceCatalogViewState();
}

class _ServiceCatalogViewState extends State<_ServiceCatalogView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajukan Layanan Baru')),
      body: SafeArea(
        child: BlocConsumer<ServiceCatalogCubit, ServiceCatalogState>(
          listener: (context, state) {
            if (state is ServiceCatalogLoaded && state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage!)),
              );
            }
          },
          builder: (context, state) {
            final cubit = context.read<ServiceCatalogCubit>();

            return Column(
              children: [
                Padding(
                  padding: AppSpacing.screen.copyWith(bottom: 0),
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (value) => cubit.load(search: value.trim()),
                    decoration: InputDecoration(
                      hintText: 'Cari layanan...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _searchController.clear();
                                cubit.load();
                              },
                            ),
                    ),
                  ),
                ),
                Expanded(
                  child: switch (state) {
                    ServiceCatalogLoading() ||
                    ServiceCatalogInitial() => ListView(
                      padding: AppSpacing.screen,
                      children: const [
                        CardSkeleton(height: 96),
                        SizedBox(height: AppSpacing.md),
                        CardSkeleton(height: 96),
                      ],
                    ),
                    ServiceCatalogError(:final message) => ListView(
                      padding: AppSpacing.screen,
                      children: [
                        ErrorCard(message: message, onRetry: cubit.load),
                      ],
                    ),
                    ServiceCatalogLoaded(:final items) when items.isEmpty =>
                      ListView(
                        padding: AppSpacing.screen,
                        children: const [_EmptyState()],
                      ),
                    ServiceCatalogLoaded(:final items, :final applyingId) =>
                      ListView(
                        padding: AppSpacing.screen,
                        children: [
                          for (final item in items)
                            _CatalogCard(
                              item: item,
                              applying: applyingId == item.id,
                              onApply: () => cubit.apply(item.id),
                            ),
                        ],
                      ),
                    _ => const SizedBox.shrink(),
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return MedicalCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 40, color: colors.onSurfaceVariant),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Tidak ada layanan yang cocok',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Semua layanan sesuai profesi Anda sudah diajukan, atau coba kata kunci lain.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _CatalogCard extends StatelessWidget {
  const _CatalogCard({
    required this.item,
    required this.applying,
    required this.onApply,
  });

  final ServiceCatalogItem item;
  final bool applying;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return MedicalCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: AppRadius.control,
            ),
            child: const SizedBox(
              width: 42,
              height: 42,
              child: Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.basePrice > 0
                      ? 'Mulai ${formatCurrency(item.basePrice)}'
                      : 'Harga ditentukan saat pengajuan diverifikasi',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (item.alreadyApplied)
            const _AppliedBadge()
          else
            FilledButton(
              onPressed: applying ? null : onApply,
              child: applying
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Ajukan'),
            ),
        ],
      ),
    );
  }
}

class _AppliedBadge extends StatelessWidget {
  const _AppliedBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: AppRadius.chip,
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 14, color: AppColors.primary),
            SizedBox(width: 4),
            Text(
              'Diajukan',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
