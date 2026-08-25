import 'package:equatable/equatable.dart';

/// One entry from the service catalog a mitra can apply to offer, already
/// filtered server-side to match their profession (see backend
/// `PartnerServiceController::catalog`).
class ServiceCatalogItem extends Equatable {
  const ServiceCatalogItem({
    required this.id,
    required this.name,
    required this.serviceType,
    required this.serviceMode,
    required this.basePrice,
    required this.alreadyApplied,
  });

  final int id;
  final String name;
  final String serviceType;
  final String serviceMode;
  final double basePrice;
  final bool alreadyApplied;

  ServiceCatalogItem copyWith({bool? alreadyApplied}) {
    return ServiceCatalogItem(
      id: id,
      name: name,
      serviceType: serviceType,
      serviceMode: serviceMode,
      basePrice: basePrice,
      alreadyApplied: alreadyApplied ?? this.alreadyApplied,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    serviceType,
    serviceMode,
    basePrice,
    alreadyApplied,
  ];
}
