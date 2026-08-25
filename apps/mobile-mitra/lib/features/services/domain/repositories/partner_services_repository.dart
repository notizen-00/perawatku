import '../entities/partner_service.dart';

abstract class PartnerServicesRepository {
  Future<List<PartnerService>> getServices();

  Future<PartnerService> updateService({
    required int id,
    bool? isActive,
    bool? isAvailable,
    int? coverageRadiusKm,
    double? price,
    String? notes,
  });
}
