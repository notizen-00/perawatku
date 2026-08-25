import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/service_catalog_item.dart';
import '../../domain/usecases/apply_for_service.dart';
import '../../domain/usecases/get_service_catalog.dart';

part 'service_catalog_state.dart';

class ServiceCatalogCubit extends Cubit<ServiceCatalogState> {
  ServiceCatalogCubit(this._getServiceCatalog, this._applyForService)
    : super(const ServiceCatalogInitial());

  final GetServiceCatalog _getServiceCatalog;
  final ApplyForService _applyForService;

  Future<void> load({String? search}) async {
    emit(const ServiceCatalogLoading());
    try {
      emit(ServiceCatalogLoaded(await _getServiceCatalog(search: search)));
    } on Failure catch (error) {
      emit(ServiceCatalogError(error.message));
    } catch (_) {
      emit(const ServiceCatalogError('Katalog layanan belum bisa dimuat.'));
    }
  }

  Future<void> apply(int serviceId) async {
    final current = state;
    if (current is! ServiceCatalogLoaded) return;

    final index = current.items.indexWhere((item) => item.id == serviceId);
    if (index == -1) return;

    final previous = current.items[index];
    final optimisticList = [...current.items];
    optimisticList[index] = previous.copyWith(alreadyApplied: true);
    emit(ServiceCatalogLoaded(optimisticList, applyingId: serviceId));

    try {
      await _applyForService(serviceId);
      emit(ServiceCatalogLoaded(optimisticList));
    } catch (_) {
      final revertedList = [...optimisticList];
      revertedList[index] = previous;
      emit(
        ServiceCatalogLoaded(
          revertedList,
          errorMessage: 'Pengajuan gagal, coba lagi.',
        ),
      );
    }
  }
}
