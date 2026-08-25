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
import '../../../../shared/widgets/navigation/mitra_scaffold.dart';
import '../../domain/entities/partner_service.dart';
import '../cubit/partner_services_cubit.dart';

class PartnerServicesPage extends StatelessWidget {
  const PartnerServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PartnerServicesCubit>()..load(),
      child: BlocBuilder<PartnerServicesCubit, PartnerServicesState>(
        builder: (context, state) {
          return MitraScaffold(
            title: 'Layanan',
            activeIndex: 3,
            onRefresh: context.read<PartnerServicesCubit>().load,
            child: switch (state) {
              PartnerServicesLoading() || PartnerServicesInitial() => const _Loading(),
              PartnerServicesError(:final message) => ErrorCard(
                message: message,
                onRetry: context.read<PartnerServicesCubit>().load,
              ),
              PartnerServicesLoaded(:final services) when services.isEmpty =>
                const _EmptyState(),
              PartnerServicesLoaded(:final services) => Column(
                children: [
                  for (final service in services)
                    _ServiceCard(service: service),
                ],
              ),
              _ => const ErrorCard(message: 'State layanan tidak dikenali.'),
            },
          );
        },
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        CardSkeleton(height: 168),
        SizedBox(height: AppSpacing.md),
        CardSkeleton(height: 168),
      ],
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
          Icon(Icons.medical_services_outlined, size: 40, color: colors.onSurfaceVariant),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Belum ada layanan diajukan',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Layanan yang sudah Anda ajukan lewat pendaftaran akan tampil di sini.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service});

  final PartnerService service;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final cubit = context.read<PartnerServicesCubit>();

    return MedicalCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: AppRadius.control,
                ),
                child: const SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(Icons.medical_services_rounded, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: 4,
                      children: [
                        _InfoChip(icon: Icons.route_outlined, text: '${service.radiusKm} km'),
                        if (service.price > 0)
                          _InfoChip(
                            icon: service.allowsCustomPrice
                                ? Icons.payments_outlined
                                : Icons.lock_outline_rounded,
                            text: formatCurrency(service.price),
                          ),
                        _VerificationBadge(isVerified: service.isVerified),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _openEditSheet(context, service),
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Edit layanan',
              ),
            ],
          ),
          const Divider(height: AppSpacing.lg),
          _ToggleRow(
            icon: Icons.power_settings_new_rounded,
            label: 'Aktifkan Layanan',
            subtitle: service.isActive
                ? 'Pasien bisa melihat dan memesan layanan ini'
                : 'Layanan disembunyikan dari pasien',
            value: service.isActive,
            onChanged: (value) => cubit.toggleActive(service.id, value),
          ),
          const SizedBox(height: AppSpacing.xs),
          _ToggleRow(
            icon: Icons.event_available_outlined,
            label: 'Tersedia Sekarang',
            subtitle: service.isAvailable
                ? 'Siap menerima order baru untuk layanan ini'
                : 'Order baru untuk layanan ini dijeda sementara',
            value: service.isAvailable,
            onChanged: (value) => cubit.toggleAvailable(service.id, value),
          ),
          if (service.notes.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: AppRadius.control,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Text(
                  service.notes,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openEditSheet(BuildContext context, PartnerService service) async {
    final cubit = context.read<PartnerServicesCubit>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => BlocProvider.value(
        value: cubit,
        child: _EditServiceSheet(service: service),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: AppRadius.chip,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: colors.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              text,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontSize: 10,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerificationBadge extends StatelessWidget {
  const _VerificationBadge({required this.isVerified});

  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    final color = isVerified ? AppColors.primary : AppColors.secondary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.chip,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isVerified ? Icons.verified_rounded : Icons.hourglass_top_rounded,
              size: 12,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              isVerified ? 'Terverifikasi' : 'Menunggu Verifikasi',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: value ? AppColors.primary : colors.onSurfaceVariant),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }
}

class _LockedPriceField extends StatelessWidget {
  const _LockedPriceField({required this.price});

  final double price;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: AppRadius.control,
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Icon(Icons.lock_outline_rounded, size: 18, color: colors.onSurfaceVariant),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Harga: ${formatCurrency(price)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    'Ditentukan admin, tidak bisa diubah mitra.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditServiceSheet extends StatefulWidget {
  const _EditServiceSheet({required this.service});

  final PartnerService service;

  @override
  State<_EditServiceSheet> createState() => _EditServiceSheetState();
}

class _EditServiceSheetState extends State<_EditServiceSheet> {
  late final _radiusController = TextEditingController(
    text: widget.service.radiusKm.toString(),
  );
  late final _priceController = TextEditingController(
    text: widget.service.price > 0 ? widget.service.price.toStringAsFixed(0) : '',
  );
  late final _notesController = TextEditingController(text: widget.service.notes);
  bool _submitting = false;

  @override
  void dispose() {
    _radiusController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context) async {
    final radius = int.tryParse(_radiusController.text.trim());
    if (radius == null || radius < 1 || _submitting) return;

    setState(() => _submitting = true);
    await context.read<PartnerServicesCubit>().updateDetails(
          widget.service.id,
          coverageRadiusKm: radius,
          // Non-konsultasi: harga dikunci ke base_price admin (backend
          // mengabaikannya juga kalau tetap dikirim), jadi jangan kirim sama
          // sekali supaya tidak menampilkan seolah-olah berubah.
          price: widget.service.allowsCustomPrice
              ? (double.tryParse(_priceController.text.trim()) ?? 0)
              : null,
          notes: _notesController.text.trim(),
        );
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.mobileMargin,
        right: AppSpacing.mobileMargin,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Edit ${widget.service.name}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _radiusController,
              enabled: !_submitting,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Radius jangkauan (km)',
                prefixIcon: Icon(Icons.route_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (widget.service.allowsCustomPrice)
              TextField(
                controller: _priceController,
                enabled: !_submitting,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Harga (opsional)',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
              )
            else
              _LockedPriceField(price: widget.service.price),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _notesController,
              enabled: !_submitting,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _submitting ? null : () => _submit(context),
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(_submitting ? 'Menyimpan...' : 'Simpan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
