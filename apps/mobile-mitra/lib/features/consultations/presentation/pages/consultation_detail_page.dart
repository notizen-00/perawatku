import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/auth_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/json_helpers.dart';
import '../../../../shared/widgets/cards/medical_card.dart';
import '../../../../shared/widgets/common/error_card.dart';
import '../../../../shared/widgets/loaders/card_skeleton.dart';
import '../../domain/entities/consultation_detail.dart';
import '../../domain/entities/consultation_message.dart';
import '../cubit/consultation_detail_cubit.dart';

class ConsultationDetailPage extends StatelessWidget {
  const ConsultationDetailPage({required this.consultationId, super.key});

  final int consultationId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ConsultationDetailCubit>()..load(consultationId),
      child: _ConsultationDetailView(consultationId: consultationId),
    );
  }
}

class _ConsultationDetailView extends StatefulWidget {
  const _ConsultationDetailView({required this.consultationId});

  final int consultationId;

  @override
  State<_ConsultationDetailView> createState() => _ConsultationDetailViewState();
}

class _ConsultationDetailViewState extends State<_ConsultationDetailView> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  int _lastMessageCount = 0;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _send() {
    final text = _messageController.text;
    if (text.trim().isEmpty) return;
    context.read<ConsultationDetailCubit>().sendMessage(text);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Konsultasi'),
      ),
      body: BlocConsumer<ConsultationDetailCubit, ConsultationDetailState>(
        listener: (context, state) {
          if (state is ConsultationDetailLoaded &&
              state.detail.messages.length > _lastMessageCount) {
            _lastMessageCount = state.detail.messages.length;
            _scrollToBottom();
          }
        },
        builder: (context, state) {
          return switch (state) {
            ConsultationDetailLoading() ||
            ConsultationDetailInitial() => const _Loading(),
            ConsultationDetailError(:final message) => Padding(
                padding: AppSpacing.screen,
                child: ErrorCard(
                  message: message,
                  onRetry: () => context
                      .read<ConsultationDetailCubit>()
                      .load(widget.consultationId),
                ),
              ),
            ConsultationDetailLoaded(:final detail) => _ChatBody(
                detail: detail,
                scrollController: _scrollController,
                messageController: _messageController,
                onSend: _send,
              ),
            _ => const Padding(
                padding: AppSpacing.screen,
                child: ErrorCard(message: 'State konsultasi tidak dikenali.'),
              ),
          };
        },
      ),
    );
  }
}

class _ChatBody extends StatelessWidget {
  const _ChatBody({
    required this.detail,
    required this.scrollController,
    required this.messageController,
    required this.onSend,
  });

  final ConsultationDetail detail;
  final ScrollController scrollController;
  final TextEditingController messageController;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ConsultationHeaderCard(detail: detail),
        Expanded(
          child: detail.messages.isEmpty
              ? const Center(child: Text('Belum ada pesan. Mulai obrolan dengan pasien.'))
              : ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.mobileMargin,
                    vertical: AppSpacing.md,
                  ),
                  itemCount: detail.messages.length,
                  itemBuilder: (context, index) {
                    final message = detail.messages[index];
                    final isMine = message.senderUserId == sl<AuthSession>().userId;
                    return _ChatBubble(message: message, isMine: isMine);
                  },
                ),
        ),
        _ChatInputBar(controller: messageController, onSend: onSend),
      ],
    );
  }
}

class _ConsultationHeaderCard extends StatelessWidget {
  const _ConsultationHeaderCard({required this.detail});

  final ConsultationDetail detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.mobileMargin,
        AppSpacing.sm,
        AppSpacing.mobileMargin,
        0,
      ),
      child: MedicalCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detail.patientName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${detail.serviceType} · ${detail.complaint}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  formatCurrency(detail.totalAmount),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _StatusActionRow(detail: detail),
          ],
        ),
      ),
    );
  }
}

class _StatusActionRow extends StatelessWidget {
  const _StatusActionRow({required this.detail});

  final ConsultationDetail detail;

  @override
  Widget build(BuildContext context) {
    final status = detail.status.toLowerCase();
    final cubit = context.read<ConsultationDetailCubit>();

    final (label, nextStatus) = switch (status) {
      'pending' => ('Konfirmasi Konsultasi', 'confirmed'),
      'confirmed' => ('Mulai Konsultasi', 'ongoing'),
      'ongoing' => ('Selesaikan Konsultasi', 'completed'),
      _ => (null, null),
    };

    if (label == null || nextStatus == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          _statusLabel(status),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: status == 'cancelled' ? AppColors.error : AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 40,
            child: FilledButton(
              onPressed: () => cubit.updateStatus(nextStatus),
              style: FilledButton.styleFrom(
                shape: const RoundedRectangleBorder(borderRadius: AppRadius.control),
              ),
              child: Text(label),
            ),
          ),
        ),
        if (status == 'pending' || status == 'confirmed') ...[
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            height: 40,
            child: OutlinedButton(
              onPressed: () => cubit.updateStatus('cancelled'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                shape: const RoundedRectangleBorder(borderRadius: AppRadius.control),
              ),
              child: const Text('Batalkan'),
            ),
          ),
        ],
      ],
    );
  }

  String _statusLabel(String status) {
    return switch (status) {
      'completed' => 'Konsultasi selesai',
      'cancelled' => 'Konsultasi dibatalkan',
      _ => status,
    };
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.isMine});

  final ConsultationChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primary : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.message ?? 'Mengirim lampiran',
              style: TextStyle(color: isMine ? Colors.white : colors.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              _time(message.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: isMine ? Colors.white70 : colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _time(DateTime? value) {
    if (value == null) return '-';
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _ChatInputBar extends StatelessWidget {
  const _ChatInputBar({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Tulis pesan...',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.control,
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filled(
              onPressed: onSend,
              icon: const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: AppSpacing.screen,
      child: Column(
        children: [
          CardSkeleton(height: 88),
          SizedBox(height: AppSpacing.md),
          CardSkeleton(height: 360),
        ],
      ),
    );
  }
}
