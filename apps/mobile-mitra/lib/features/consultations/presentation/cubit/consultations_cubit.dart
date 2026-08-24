import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/services/reverb_websocket_service.dart';
import '../../domain/entities/consultation_summary.dart';
import '../../domain/usecases/get_consultations.dart';

part 'consultations_state.dart';

class ConsultationsCubit extends Cubit<ConsultationsState> {
  ConsultationsCubit(this._getConsultations, this._reverb)
    : super(const ConsultationsInitial()) {
    _eventSubscription = _reverb.events.listen(_onRealtimeEvent);
  }

  final GetConsultations _getConsultations;
  final ReverbWebSocketService _reverb;
  StreamSubscription<ReverbEvent>? _eventSubscription;

  Future<void> load() async {
    emit(const ConsultationsLoading());
    await _fetch();
  }

  /// New consultation / new message / status change pushed from the
  /// backend via the mitra's already-subscribed `private-user.{id}.notifications`
  /// channel -- refetch quietly so the list stays live without flashing a
  /// loading skeleton over data the user is currently looking at.
  void _onRealtimeEvent(ReverbEvent event) {
    if (event.name != 'notification.created') return;
    if (event.dataAsMap['reference_type']?.toString() != 'consultation') return;

    _fetch();
  }

  Future<void> _fetch() async {
    try {
      emit(ConsultationsLoaded(await _getConsultations()));
    } on Failure catch (error) {
      if (state is! ConsultationsLoaded) emit(ConsultationsError(error.message));
    } catch (_) {
      if (state is! ConsultationsLoaded) {
        emit(const ConsultationsError('Konsultasi belum bisa dimuat.'));
      }
    }
  }

  @override
  Future<void> close() {
    _eventSubscription?.cancel();
    return super.close();
  }
}
