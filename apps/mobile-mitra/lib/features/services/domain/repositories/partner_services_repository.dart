import '../entities/partner_service.dart';
import '../entities/service_catalog_item.dart';

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

  /// Katalog layanan yang bisa diajukan, sudah difilter server-side sesuai
  /// profesi mitra.
  Future<List<ServiceCatalogItem>> getCatalog({String? search});

  /// Mengajukan layanan baru dari katalog (menunggu verifikasi admin).
  Future<void> applyForService(int serviceId);
}
