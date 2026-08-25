import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/partner_service.dart';
import '../../domain/usecases/get_partner_services.dart';
import '../../domain/usecases/update_partner_service.dart';

part 'partner_services_state.dart';

class PartnerServicesCubit extends Cubit<PartnerServicesState> {
  PartnerServicesCubit(this._getPartnerServices, this._updatePartnerService)
    : super(const PartnerServicesInitial());

  final GetPartnerServices _getPartnerServices;
  final UpdatePartnerService _updatePartnerService;

  Future<void> load() async {
    emit(const PartnerServicesLoading());
    try {
      emit(PartnerServicesLoaded(await _getPartnerServices()));
    } on Failure catch (error) {
      emit(PartnerServicesError(error.message));
    } catch (_) {
      emit(const PartnerServicesError('Layanan belum bisa dimuat.'));
    }
  }

  Future<void> toggleActive(int id, bool value) {
    return _optimisticUpdate(
      id: id,
      apply: (service) => service.copyWith(isActive: value),
      request: () => _updatePartnerService(id: id, isActive: value),
    );
  }

  Future<void> toggleAvailable(int id, bool value) {
    return _optimisticUpdate(
      id: id,
      apply: (service) => service.copyWith(isAvailable: value),
      request: () => _updatePartnerService(id: id, isAvailable: value),
    );
  }

  Future<void> updateDetails(
    int id, {
    required int coverageRadiusKm,
    double? price,
    required String notes,
  }) {
    return _optimisticUpdate(
      id: id,
      apply: (service) => service.copyWith(
        radiusKm: coverageRadiusKm,
        price: price,
        notes: notes,
      ),
      request: () => _updatePartnerService(
        id: id,
        coverageRadiusKm: coverageRadiusKm,
        price: price,
        notes: notes,
      ),
    );
  }

  /// Updates the item in the list immediately (so the switch/UI responds
  /// right away), then confirms with the server; reverts just that one item
  /// if the request fails instead of blowing away the whole loaded list.
  Future<void> _optimisticUpdate({
    required int id,
    required PartnerService Function(PartnerService current) apply,
    required Future<PartnerService> Function() request,
  }) async {
    final current = state;
    if (current is! PartnerServicesLoaded) return;

    final index = current.services.indexWhere((service) => service.id == id);
    if (index == -1) return;

    final previous = current.services[index];
    final optimisticList = [...current.services];
    optimisticList[index] = apply(previous);
    emit(PartnerServicesLoaded(optimisticList));

    try {
      final updated = await request();
      final confirmedList = [...optimisticList];
      final confirmedIndex = confirmedList.indexWhere((service) => service.id == id);
      if (confirmedIndex != -1) confirmedList[confirmedIndex] = updated;
      emit(PartnerServicesLoaded(confirmedList));
    } catch (_) {
      final revertedList = [...optimisticList];
      final revertIndex = revertedList.indexWhere((service) => service.id == id);
      if (revertIndex != -1) revertedList[revertIndex] = previous;
      emit(PartnerServicesLoaded(revertedList));
    }
  }
}
