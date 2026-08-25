part of 'service_catalog_cubit.dart';

abstract class ServiceCatalogState extends Equatable {
  const ServiceCatalogState();
}

class ServiceCatalogInitial extends ServiceCatalogState {
  const ServiceCatalogInitial();

  @override
  List<Object?> get props => [];
}

class ServiceCatalogLoading extends ServiceCatalogState {
  const ServiceCatalogLoading();

  @override
  List<Object?> get props => [];
}

class ServiceCatalogLoaded extends ServiceCatalogState {
  const ServiceCatalogLoaded(this.items, {this.applyingId, this.errorMessage});

  final List<ServiceCatalogItem> items;

  /// Id layanan yang sedang diajukan (untuk menampilkan loading di tombolnya).
  final int? applyingId;

  /// Pesan error sementara (misal pengajuan gagal) yang tetap menampilkan
  /// daftar yang sudah dimuat, bukan mengganti seluruh state ke error.
  final String? errorMessage;

  @override
  List<Object?> get props => [items, applyingId, errorMessage];
}

class ServiceCatalogError extends ServiceCatalogState {
  const ServiceCatalogError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
