import 'package:equatable/equatable.dart';

class PartnerService extends Equatable {
  const PartnerService({
    required this.id,
    required this.serviceId,
    required this.name,
    required this.serviceType,
    required this.serviceMode,
    required this.radiusKm,
    required this.price,
    required this.isActive,
    required this.isAvailable,
    required this.isVerified,
    required this.notes,
  });

  final int id;
  final int serviceId;
  final String name;
  final String serviceType;
  final String serviceMode;
  final int radiusKm;
  final double price;

  /// Mirrors backend `PartnerServiceController::serviceUsesPartnerCustomPrice`
  /// -- only consultation-style services let the mitra set their own price;
  /// everything else is locked to the admin's `service.base_price` (the
  /// backend silently overrides any price sent for these, so the UI must
  /// not pretend it's editable).
  bool get allowsCustomPrice =>
      serviceType == 'consultation' || const ['chat', 'voice', 'video'].contains(serviceMode);

  /// Mitra menawarkan layanan ini atau tidak (toggle utama aktif/nonaktif).
  final bool isActive;

  /// Layanan ini sedang bisa diambil order atau di-pause sementara.
  final bool isAvailable;

  /// Hanya admin yang bisa mengubah ini (lihat PartnerServiceController::verify).
  final bool isVerified;
  final String notes;

  PartnerService copyWith({
    int? radiusKm,
    double? price,
    bool? isActive,
    bool? isAvailable,
    String? notes,
  }) {
    return PartnerService(
      id: id,
      serviceId: serviceId,
      name: name,
      serviceType: serviceType,
      serviceMode: serviceMode,
      radiusKm: radiusKm ?? this.radiusKm,
      price: price ?? this.price,
      isActive: isActive ?? this.isActive,
      isAvailable: isAvailable ?? this.isAvailable,
      isVerified: isVerified,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
    id,
    serviceId,
    name,
    serviceType,
    serviceMode,
    radiusKm,
    price,
    isActive,
    isAvailable,
    isVerified,
    notes,
  ];
}
