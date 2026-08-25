import '../entities/service_catalog_item.dart';
import '../repositories/partner_services_repository.dart';

class GetServiceCatalog {
  const GetServiceCatalog(this.repository);

  final PartnerServicesRepository repository;

  Future<List<ServiceCatalogItem>> call({String? search}) =>
      repository.getCatalog(search: search);
}
