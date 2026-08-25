import '../../../../core/config/api_endpoints.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/json_helpers.dart';
import '../../domain/entities/partner_service.dart';
import '../../domain/entities/service_catalog_item.dart';
import '../../domain/repositories/partner_services_repository.dart';

class PartnerServicesRepositoryImpl implements PartnerServicesRepository {
  const PartnerServicesRepositoryImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<PartnerService>> getServices() async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.serviceApplications,
        queryParameters: {'per_page': 50},
      );
      return jsonList(response).map(_service).toList();
    } on ApiException catch (error) {
      throw ServerFailure(error.message);
    }
  }

  @override
  Future<PartnerService> updateService({
    required int id,
    bool? isActive,
    bool? isAvailable,
    int? coverageRadiusKm,
    double? price,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.patch(
        '${ApiEndpoints.serviceApplications}/$id',
        body: {
          if (isActive != null) 'is_active': isActive,
          if (isAvailable != null) 'is_available': isAvailable,
          if (coverageRadiusKm != null) 'coverage_radius_km': coverageRadiusKm,
          if (price != null) 'price': price,
          if (notes != null) 'notes': notes,
        },
      );
      final data = jsonObject(response['data']) ?? response;
      return _service(data);
    } on ApiException catch (error) {
      throw ServerFailure(error.message);
    }
  }

  @override
  Future<List<ServiceCatalogItem>> getCatalog({String? search}) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.serviceCatalog,
        queryParameters: {
          'per_page': 50,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      return jsonList(response).map(_catalogItem).toList();
    } on ApiException catch (error) {
      throw ServerFailure(error.message);
    }
  }

  @override
  Future<void> applyForService(int serviceId) async {
    try {
      await _apiClient.post(
        ApiEndpoints.serviceApplications,
        body: {'service_id': serviceId},
      );
    } on ApiException catch (error) {
      throw ServerFailure(error.message);
    }
  }

  ServiceCatalogItem _catalogItem(Map<String, dynamic> json) {
    return ServiceCatalogItem(
      id: asInt(json['id']),
      name: json['name']?.toString() ?? 'Layanan',
      serviceType: json['service_type']?.toString() ?? '',
      serviceMode: json['service_mode']?.toString() ?? 'visit',
      basePrice: asDouble(json['base_price']),
      alreadyApplied: json['already_applied'] == true,
    );
  }

  PartnerService _service(Map<String, dynamic> json) {
    final service = jsonObject(json['service']);
    return PartnerService(
      id: asInt(json['id']),
      serviceId: asInt(json['service_id']),
      name: service?['name']?.toString() ?? 'Layanan',
      serviceType: service?['service_type']?.toString() ?? '',
      serviceMode: service?['service_mode']?.toString() ?? 'visit',
      radiusKm: asInt(json['coverage_radius_km']),
      price: asDouble(json['price']),
      isActive: json['is_active'] == true,
      isAvailable: json['is_available'] == true,
      isVerified: json['is_verified'] == true,
      notes: json['notes']?.toString() ?? '',
    );
  }
}
