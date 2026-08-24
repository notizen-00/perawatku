import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/services/reverb_websocket_service.dart';
import '../../domain/entities/consultation_detail.dart';
import '../../domain/entities/consultation_message.dart';
import '../../domain/usecases/get_consultation_detail.dart';
import '../../domain/usecases/send_consultation_message.dart';
import '../../domain/usecases/update_consultation_status.dart';

part 'consultation_detail_state.dart';

class ConsultationDetailCubit extends Cubit<ConsultationDetailState> {
  ConsultationDetailCubit(
    this._getConsultationDetail,
    this._sendMessage,
    this._updateStatus,
    this._reverb,
  ) : super(const ConsultationDetailInitial());

  final GetConsultationDetail _getConsultationDetail;
  final SendConsultationMessage _sendMessage;
  final UpdateConsultationStatus _updateStatus;
  final ReverbWebSocketService _reverb;
  StreamSubscription<ReverbEvent>? _eventSubscription;
  int? _consultationId;

  Future<void> load(int id) async {
    _consultationId = id;
    emit(const ConsultationDetailLoading());

    try {
      final detail = await _getConsultationDetail(id);
      emit(ConsultationDetailLoaded(detail));

      // private-consultation.{id} broadcasts every new message in this
      // thread in real time (ChatMessageCreated on the backend), regardless
      // of who sent it -- so both sides see new messages instantly.
      await _reverb.subscribeConsultation(id);
      _eventSubscription ??= _reverb.events.listen(_onRealtimeEvent);
    } on Failure catch (error) {
      emit(ConsultationDetailError(error.message));
    } catch (_) {
      emit(const ConsultationDetailError('Detail konsultasi belum bisa dimuat.'));
    }
  }

  void _onRealtimeEvent(ReverbEvent event) {
    final id = _consultationId;
    if (id == null) return;
    if (event.name != 'chat.message.created') return;
    if (event.channel != 'private-consultation.$id') return;

    final current = state;
    if (current is! ConsultationDetailLoaded) return;

    final message = ConsultationChatMessage.fromJson(event.dataAsMap);
    if (current.detail.messages.any((existing) => existing.id == message.id)) {
      return;
    }

    emit(
      ConsultationDetailLoaded(
        current.detail.copyWithMessages([...current.detail.messages, message]),
      ),
    );
  }

  Future<void> sendMessage(String message) async {
    final id = _consultationId;
    final current = state;
    final trimmed = message.trim();
    if (id == null || trimmed.isEmpty || current is! ConsultationDetailLoaded) {
      return;
    }

    try {
      final sent = await _sendMessage(id, trimmed);
      if (current.detail.messages.any((existing) => existing.id == sent.id)) {
        return;
      }
      emit(
        ConsultationDetailLoaded(
          current.detail.copyWithMessages([...current.detail.messages, sent]),
        ),
      );
    } on Failure catch (error) {
      emit(ConsultationDetailError(error.message));
      emit(current);
    } catch (_) {
      emit(const ConsultationDetailError('Pesan belum bisa dikirim.'));
      emit(current);
    }
  }

  Future<void> updateStatus(String status) async {
    final id = _consultationId;
    final current = state;
    if (id == null) return;

    try {
      emit(ConsultationDetailLoaded(await _updateStatus(id, status)));
    } on Failure catch (error) {
      emit(ConsultationDetailError(error.message));
      if (current is ConsultationDetailLoaded) emit(current);
    } catch (_) {
      emit(const ConsultationDetailError('Status belum bisa diperbarui.'));
      if (current is ConsultationDetailLoaded) emit(current);
    }
  }

  @override
  Future<void> close() {
    _eventSubscription?.cancel();
    return super.close();
  }
}
