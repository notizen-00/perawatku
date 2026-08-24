import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/json_helpers.dart';
import '../../../../shared/widgets/cards/medical_card.dart';
import '../../../../shared/widgets/common/error_card.dart';
import '../../../../shared/widgets/loaders/card_skeleton.dart';
import '../../domain/entities/order_detail.dart';
import '../bloc/order_detail_bloc.dart';

class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({required this.orderId, super.key});

  final int orderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OrderDetailBloc>()..add(OrderDetailRequested(orderId)),
      child: _OrderDetailView(orderId: orderId),
    );
  }
}

class _OrderDetailView extends StatelessWidget {
  const _OrderDetailView({required this.orderId});

  final int orderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      bottomNavigationBar: BlocBuilder<OrderDetailBloc, OrderDetailState>(
        builder: (context, state) {
          if (state is! OrderDetailLoaded || _isClosedStatus(state.order.status)) {
            return const SizedBox.shrink();
          }
          return _BottomAction(order: state.order);
        },
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<OrderDetailBloc>().add(OrderDetailRefreshed(orderId));
        },
        child: BlocBuilder<OrderDetailBloc, OrderDetailState>(
          builder: (context, state) {
            return switch (state) {
              OrderDetailLoading() || OrderDetailInitial() => const _Loading(),
              OrderDetailError(:final message) => CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  const _DetailAppBar(),
                  SliverPadding(
                    padding: AppSpacing.screen,
                    sliver: SliverToBoxAdapter(
                      child: _OrderLoadError(message: message),
                    ),
                  ),
                ],
              ),
              OrderDetailLoaded(:final order) => _DetailContent(order: order),
              _ => const _UnknownState(),
            };
          },
        ),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.order});

  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        const _DetailAppBar(),
        SliverPersistentHeader(
          pinned: true,
          delegate: _StatusHeaderDelegate(order: order),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.mobileMargin,
            AppSpacing.md,
            AppSpacing.mobileMargin,
            104,
          ),
          sliver: SliverList.list(
            children: [
              _PatientCard(order: order),
              const SizedBox(height: AppSpacing.sm),
              _AddressCard(order: order),
              const SizedBox(height: AppSpacing.sm),
              _VisitDetailCard(order: order),
              const SizedBox(height: AppSpacing.sm),
              _ServiceSummaryCard(order: order),
              const SizedBox(height: AppSpacing.sm),
              _HistoryCard(order: order),
              const SizedBox(height: AppSpacing.sm),
              _NotesCard(order: order),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailAppBar extends StatelessWidget {
  const _DetailAppBar();

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      snap: true,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: Theme.of(context).colorScheme.surface,
      leading: IconButton(
        onPressed: () => context.canPop() ? context.pop() : context.go('/orders'),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: Text(
        'Detail Pesanan',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.help_outline_rounded, size: 20),
        ),
      ],
    );
  }
}

class _StatusHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _StatusHeaderDelegate({required this.order});

  final OrderDetail order;

  @override
  double get minExtent => 92;

  @override
  double get maxExtent => 112;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final colors = Theme.of(context).colorScheme;
    final status = _statusCopy(order.status, order.paymentStatus);
    final timeText = order.startedAt == '-'
        ? 'Jadwal ${order.scheduledAt}'
        : 'Dimulai pada ${order.startedAt}';
    final etaText = order.etaMinutes <= 0
        ? timeText
        : '$timeText (${order.etaMinutes} menit)';

    return ColoredBox(
      color: colors.surface,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.mobileMargin,
          6 - (2 * progress),
          AppSpacing.mobileMargin,
          6,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            borderRadius: AppRadius.card,
            border: Border.all(color: colors.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowBlue.withValues(
                  alpha: 0.04 + progress * 0.05,
                ),
                blurRadius: 20,
                offset: Offset(0, 8 - progress * 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 6,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Status Saat Ini',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontSize: 10,
                            ),
                      ),
                    ),
                    _TinyStatusPill(text: status.badge),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  status.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule_outlined, size: 14, color: colors.onSurfaceVariant),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        etaText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontSize: 11,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_StatusHeaderDelegate oldDelegate) {
    return oldDelegate.order != order;
  }
}

class _PatientCard extends StatelessWidget {
  const _PatientCard({required this.order});

  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    return MedicalCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 25,
            backgroundColor: Color(0xFFDDF8EA),
            child: Icon(Icons.person_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pasien', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 2),
                Text(
                  order.patientName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _SmallChip(icon: Icons.badge_outlined, text: order.code),
                    if (order.patientPhone != '-')
                      _SmallChip(icon: Icons.phone_outlined, text: order.patientPhone),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _CircleAction(icon: Icons.chat_bubble_rounded, onPressed: () {}),
          const SizedBox(width: AppSpacing.xs),
          _CircleAction(icon: Icons.call_rounded, onPressed: () {}),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.order});

  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    final distanceText = order.distanceKm <= 0
        ? 'Jarak belum tersedia'
        : '${order.distanceKm.toStringAsFixed(1)} km dari lokasi Anda';

    return MedicalCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on_outlined, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.addressLabel, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(order.addressText, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: AppSpacing.sm),
                _SmallChip(icon: Icons.route_outlined, text: distanceText),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.go('/tracking/${order.id}'),
            icon: const Icon(Icons.map_outlined),
          ),
        ],
      ),
    );
  }
}

/// Shows the visit model (sekali visit vs terjadwal, kunjungan rumah vs RS,
/// live-in) and the transport/meal fees admin's fee policy applied to this
/// booking -- see PRD-service-booking-terjadwal-dan-biaya.md.
class _VisitDetailCard extends StatelessWidget {
  const _VisitDetailCard({required this.order});

  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return MedicalCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detail Kunjungan',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _SmallChip(
                icon: order.isRecurring ? Icons.event_repeat_rounded : Icons.event_rounded,
                text: order.isRecurring
                    ? 'Terjadwal · ${_recurrenceLabel(order.recurrence)} · ${order.visitCount}x'
                    : 'Sekali visit',
              ),
              _SmallChip(
                icon: order.isLiveIn ? Icons.hotel_rounded : Icons.directions_walk_rounded,
                text: order.isLiveIn ? 'Live-in (menginap)' : 'Kunjungan biasa',
              ),
              _SmallChip(
                icon: order.isHospitalVisit ? Icons.local_hospital_outlined : Icons.home_outlined,
                text: order.isHospitalVisit ? 'Di rumah sakit' : 'Di rumah pasien',
              ),
            ],
          ),
          if (order.hasExtraFees) ...[
            const SizedBox(height: AppSpacing.sm),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: AppRadius.control,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Biaya tambahan (kebijakan admin)',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontSize: 10,
                          ),
                    ),
                    const SizedBox(height: 4),
                    if (order.transportFee > 0)
                      Text(
                        'Transportasi: ${formatCurrency(order.transportFee)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (order.mealFee > 0)
                      Text(
                        'Uang makan: ${formatCurrency(order.mealFee)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _recurrenceLabel(String recurrence) {
  return switch (recurrence) {
    'weekly' => 'Mingguan',
    'monthly' => 'Bulanan',
    _ => recurrence,
  };
}

class _ServiceSummaryCard extends StatelessWidget {
  const _ServiceSummaryCard({required this.order});

  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    return MedicalCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryValue(
                  label: 'Layanan Kesehatan',
                  value: order.serviceName,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              _SummaryValue(
                label: 'Total Biaya',
                value: formatCurrency(order.totalAmount),
                color: AppColors.primary,
                alignEnd: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: _PaymentChip(status: order.paymentStatus),
          ),
          const SizedBox(height: AppSpacing.md),
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFEFFDF6),
              borderRadius: AppRadius.control,
              border: Border.all(color: const Color(0xFFC4F0DA)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Catatan Keluhan:',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.primary,
                          fontSize: 10,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    order.notes.trim().isEmpty
                        ? 'Tidak ada catatan keluhan dari pasien.'
                        : order.notes,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.order});

  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    return MedicalCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Riwayat Pesanan',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              if (_canAddTindakan(order.status))
                TextButton.icon(
                  onPressed: () => _openAddTindakanSheet(context, order.id),
                  icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                  label: const Text('Tambah Tindakan'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (order.histories.isEmpty)
            Text('Belum ada riwayat dari server.', style: Theme.of(context).textTheme.bodySmall)
          else
            for (var index = 0; index < order.histories.length; index++)
              _ChecklistRow(
                text: _historyTitle(order.histories[index]),
                done: index < order.histories.length - 1,
                active: index == order.histories.length - 1,
                caption: order.histories[index].notes,
                photoUrl: order.histories[index].photoUrl,
                checklist: order.histories[index].checklist,
              ),
        ],
      ),
    );
  }
}

bool _canAddTindakan(String status) {
  final normalized = status.toLowerCase();
  return normalized == 'confirmed' || normalized == 'on_the_way';
}

Future<void> _openAddTindakanSheet(BuildContext context, int orderId) async {
  final bloc = context.read<OrderDetailBloc>();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => BlocProvider.value(
      value: bloc,
      child: _AddTindakanSheet(orderId: orderId),
    ),
  );
}

/// Form mitra untuk mencatat tindakan penanganan pasien: judul, catatan,
/// foto dokumentasi, dan checklist tindakan yang sudah dilakukan. Dikirim
/// ke `POST /mitra/service-bookings/{id}/histories` (lihat
/// [OrderDetailBloc._onTindakanAdded]) dan langsung terlihat di riwayat
/// pesanan pasien juga, karena keduanya membaca relasi `histories` yang sama.
class _AddTindakanSheet extends StatefulWidget {
  const _AddTindakanSheet({required this.orderId});

  final int orderId;

  @override
  State<_AddTindakanSheet> createState() => _AddTindakanSheetState();
}

class _AddTindakanSheetState extends State<_AddTindakanSheet> {
  final _titleController = TextEditingController(text: 'Tindakan penanganan pasien');
  final _descriptionController = TextEditingController();
  final _checklistInputController = TextEditingController();
  final _checklist = <String>[];
  String? _photoPath;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _checklistInputController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1280,
      imageQuality: 82,
    );
    if (file == null || !mounted) return;
    setState(() => _photoPath = file.path);
  }

  void _addChecklistItem() {
    final value = _checklistInputController.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _checklist.add(value);
      _checklistInputController.clear();
    });
  }

  void _submit(BuildContext context) {
    if (_titleController.text.trim().isEmpty || _submitting) return;

    setState(() => _submitting = true);
    context.read<OrderDetailBloc>().add(
          OrderDetailTindakanAdded(
            id: widget.orderId,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            checklist: _checklist,
            photoPath: _photoPath,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return BlocListener<OrderDetailBloc, OrderDetailState>(
      listener: (context, state) {
        if (!_submitting) return;

        if (state is OrderDetailLoaded) {
          Navigator.of(context).pop();
        } else if (state is OrderDetailError) {
          setState(() => _submitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: colors.error),
          );
        }
      },
      child: Builder(
        builder: (context) {
          final submitting = _submitting;
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
                    'Tambah Tindakan',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Catat tindakan yang sudah dilakukan. Pasien bisa melihat catatan ini secara langsung.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _titleController,
                    enabled: !submitting,
                    decoration: const InputDecoration(labelText: 'Judul tindakan'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _descriptionController,
                    enabled: !submitting,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Checklist tindakan', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _checklistInputController,
                          enabled: !submitting,
                          decoration: const InputDecoration(
                            hintText: 'mis. Cek tekanan darah',
                            isDense: true,
                          ),
                          onSubmitted: (_) => _addChecklistItem(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      IconButton.filledTonal(
                        onPressed: submitting ? null : _addChecklistItem,
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                  if (_checklist.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final item in _checklist)
                          InputChip(
                            label: Text(item),
                            onDeleted: submitting
                                ? null
                                : () => setState(() => _checklist.remove(item)),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Text('Foto dokumentasi', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: AppSpacing.xs),
                  if (_photoPath != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: AppRadius.control,
                          child: Image.file(
                            File(_photoPath!),
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: 4,
                          top: 4,
                          child: IconButton.filled(
                            onPressed: submitting ? null : () => setState(() => _photoPath = null),
                            icon: const Icon(Icons.close_rounded, size: 16),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                              minimumSize: const Size(28, 28),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: submitting ? null : _pickPhoto,
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Ambil foto'),
                    ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: submitting ? null : () => _submit(context),
                      icon: submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(submitting ? 'Menyimpan...' : 'Simpan Tindakan'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.order});

  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    return MedicalCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Data',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: _InfoTile(label: 'Status', value: order.status)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _InfoTile(label: 'Jadwal', value: order.scheduledAt)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _InfoTile(label: 'Payment', value: order.paymentStatus)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: AppRadius.control,
            ),
            child: SizedBox(
              height: 72,
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Text(
                  _latestHistoryNote(order),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({required this.order});

  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    final action = _actionFor(order);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.mobileMargin,
          AppSpacing.sm,
          AppSpacing.mobileMargin,
          AppSpacing.sm,
        ),
        child: switch (action) {
          _OrderAction.request => Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => context
                          .read<OrderDetailBloc>()
                          .add(OrderDetailRejected(order.id)),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Tolak'),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: () => context
                          .read<OrderDetailBloc>()
                          .add(OrderDetailAccepted(order.id)),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Terima'),
                    ),
                  ),
                ),
              ],
            ),
          _OrderAction.waitingPayment => SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: null,
                icon: const Icon(Icons.hourglass_top_rounded),
                label: const Text('Menunggu Pembayaran'),
              ),
            ),
          _OrderAction.startJourney => SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: () => context
                    .read<OrderDetailBloc>()
                    .add(OrderDetailJourneyStarted(order.id)),
                icon: const Icon(Icons.near_me_rounded),
                label: const Text('Mulai Berangkat'),
              ),
            ),
          _OrderAction.onTheWay => Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/tracking/${order.id}'),
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Buka Peta'),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: () => context
                          .read<OrderDetailBloc>()
                          .add(OrderDetailArrived(order.id)),
                      icon: const Icon(Icons.location_on_outlined),
                      label: const Text('Saya Sudah Sampai'),
                    ),
                  ),
                ),
              ],
            ),
          _OrderAction.handling => SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: () => context
                    .read<OrderDetailBloc>()
                    .add(OrderDetailTreatmentStarted(order.id)),
                icon: const Icon(Icons.medical_information_outlined),
                label: const Text('Tangani Pasien'),
              ),
            ),
          _OrderAction.finish => SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: () => context
                    .read<OrderDetailBloc>()
                    .add(OrderDetailCompleted(order.id)),
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Selesaikan Layanan'),
              ),
            ),
          _OrderAction.none => SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.info_outline_rounded),
                label: Text(_statusActionLabel(order.status)),
              ),
            ),
        },
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.text,
    this.done = false,
    this.active = false,
    this.caption = '',
    this.photoUrl,
    this.checklist = const [],
  });

  final String text;
  final bool done;
  final bool active;
  final String caption;
  final String? photoUrl;
  final List<String> checklist;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = done || active ? AppColors.primary : colors.outlineVariant;
    final background = done || active ? AppColors.primary : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
              border: Border.all(color: color),
            ),
            child: SizedBox(
              width: 18,
              height: 18,
              child: done
                  ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                  : active
                      ? const Center(
                          child: SizedBox(
                            width: 6,
                            height: 6,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        )
                      : null,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: active ? AppColors.primary : colors.onSurface,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      ),
                ),
                if (caption.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontSize: 11,
                        ),
                  ),
                ],
                if (checklist.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final item in checklist)
                        _SmallChip(icon: Icons.check_circle_outline_rounded, text: item),
                    ],
                  ),
                ],
                if (photoUrl != null && photoUrl!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: AppRadius.control,
                    child: Image.network(
                      photoUrl!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 120,
                        alignment: Alignment.center,
                        color: colors.surfaceContainerLow,
                        child: Icon(Icons.broken_image_outlined, color: colors.onSurfaceVariant),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const _DetailAppBar(),
        SliverPadding(
          padding: AppSpacing.screen,
          sliver: SliverList.list(
            children: const [
              CardSkeleton(height: 80),
              SizedBox(height: AppSpacing.sm),
              CardSkeleton(height: 92),
              SizedBox(height: AppSpacing.sm),
              CardSkeleton(height: 150),
              SizedBox(height: AppSpacing.sm),
              CardSkeleton(height: 170),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrderLoadError extends StatelessWidget {
  const _OrderLoadError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return MedicalCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: colors.onSurfaceVariant),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Pesanan tidak dapat dibuka',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton.icon(
              onPressed: () => context.go('/orders'),
              icon: const Icon(Icons.assignment_outlined),
              label: const Text('Lihat daftar pesanan'),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnknownState extends StatelessWidget {
  const _UnknownState();

  @override
  Widget build(BuildContext context) {
    return const CustomScrollView(
      slivers: [
        _DetailAppBar(),
        SliverPadding(
          padding: AppSpacing.screen,
          sliver: SliverToBoxAdapter(
            child: ErrorCard(message: 'State detail pesanan tidak dikenali.'),
          ),
        ),
      ],
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  const _SmallChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: AppRadius.chip,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppColors.primary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                      fontSize: 9,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TinyStatusPill extends StatelessWidget {
  const _TinyStatusPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFFDDF8EA),
        borderRadius: AppRadius.chip,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.primary,
                fontSize: 9,
              ),
        ),
      ),
    );
  }
}

class _PaymentChip extends StatelessWidget {
  const _PaymentChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final paid = status.toLowerCase() == 'paid';
    final color = paid ? AppColors.primary : Theme.of(context).colorScheme.error;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.chip,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          paid ? 'Pembayaran lunas' : 'Pembayaran $status',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: color,
                fontSize: 10,
              ),
        ),
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({
    required this.label,
    required this.value,
    required this.color,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: AppRadius.control,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Column(
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 9,
                  ),
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCopy {
  const _StatusCopy({required this.title, required this.badge});

  final String title;
  final String badge;
}

_StatusCopy _statusCopy(String status, String paymentStatus) {
  final isPaid = paymentStatus.toLowerCase() == 'paid';
  return switch (status.toLowerCase()) {
    'on_the_way' => const _StatusCopy(
        title: 'Dalam Perjalanan',
        badge: 'Aktif',
      ),
    'confirmed' || 'scheduled' => _StatusCopy(
        title: isPaid ? 'Siap Berangkat' : 'Menunggu Pembayaran',
        badge: 'Aktif',
      ),
    'completed' => const _StatusCopy(title: 'Pesanan Selesai', badge: 'Selesai'),
    'cancelled' => const _StatusCopy(title: 'Pesanan Dibatalkan', badge: 'Batal'),
    _ => const _StatusCopy(title: 'Menunggu Konfirmasi', badge: 'Aktif'),
  };
}

String _historyTitle(OrderHistory history) {
  if (history.title.trim().isNotEmpty) {
    final time = history.createdAt == '-' ? '' : ' - ${history.createdAt}';
    return '${history.title}$time';
  }

  final status = history.status.replaceAll('_', ' ');
  final title = status.isEmpty || status == '-' ? 'Riwayat pesanan' : status;
  final time = history.createdAt == '-' ? '' : ' - ${history.createdAt}';
  return '${_titleCase(title)}$time';
}

String _latestHistoryNote(OrderDetail order) {
  final notes = order.histories
      .map((history) => history.notes.trim())
      .where((note) => note.isNotEmpty)
      .toList();

  if (notes.isNotEmpty) return notes.last;
  if (order.notes.trim().isNotEmpty) return order.notes;
  return 'Belum ada catatan tambahan dari server.';
}

String _titleCase(String value) {
  return value
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');
}

bool _isNewRequest(String status) {
  final normalized = status.toLowerCase();
  return normalized == 'pending' ||
      normalized == 'requested' ||
      normalized == 'waiting' ||
      normalized == 'new';
}

bool _isClosedStatus(String status) {
  final normalized = status.toLowerCase();
  return normalized == 'completed' ||
      normalized == 'cancelled' ||
      normalized == 'canceled' ||
      normalized == 'rejected' ||
      normalized == 'declined';
}

enum _OrderAction {
  request,
  waitingPayment,
  startJourney,
  onTheWay,
  handling,
  finish,
  none,
}

_OrderAction _actionFor(OrderDetail order) {
  final status = order.status.toLowerCase();
  final isPaid = order.paymentStatus.toLowerCase() == 'paid';

  if (_isNewRequest(status)) return _OrderAction.request;
  if (status == 'confirmed' || status == 'scheduled') {
    return isPaid ? _OrderAction.startJourney : _OrderAction.waitingPayment;
  }
  if (status == 'on_the_way') {
    if (!_hasHistory(order, 'arrival')) return _OrderAction.onTheWay;
    if (!_hasHistory(order, 'treatment_started')) return _OrderAction.handling;
    return _OrderAction.finish;
  }
  return _OrderAction.none;
}

bool _hasHistory(OrderDetail order, String marker) {
  final normalizedMarker = marker.toLowerCase();
  return order.histories.any((history) {
    final treatmentType = history.treatmentType.toLowerCase();
    final title = history.title.toLowerCase();
    final notes = history.notes.toLowerCase();
    return treatmentType == normalizedMarker ||
        title.contains(normalizedMarker.replaceAll('_', ' ')) ||
        notes.contains(normalizedMarker.replaceAll('_', ' ')) ||
        (normalizedMarker == 'arrival' &&
            (title.contains('sampai') || title.contains('tiba'))) ||
        (normalizedMarker == 'treatment_started' &&
            title.contains('penanganan'));
  });
}

String _statusActionLabel(String status) {
  return switch (status.toLowerCase()) {
    'completed' => 'Pesanan Selesai',
    'cancelled' || 'canceled' => 'Pesanan Dibatalkan',
    'rejected' || 'declined' => 'Pesanan Ditolak',
    _ => 'Belum Ada Aksi',
  };
}
