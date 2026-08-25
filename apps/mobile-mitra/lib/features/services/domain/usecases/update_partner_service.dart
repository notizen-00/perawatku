import '../entities/partner_service.dart';
import '../repositories/partner_services_repository.dart';

class UpdatePartnerService {
  const UpdatePartnerService(this.repository);

  final PartnerServicesRepository repository;

  Future<PartnerService> call({
    required int id,
    bool? isActive,
    bool? isAvailable,
    int? coverageRadiusKm,
    double? price,
    String? notes,
  }) {
    return repository.updateService(
      id: id,
      isActive: isActive,
      isAvailable: isAvailable,
      coverageRadiusKm: coverageRadiusKm,
      price: price,
      notes: notes,
    );
  }
}
