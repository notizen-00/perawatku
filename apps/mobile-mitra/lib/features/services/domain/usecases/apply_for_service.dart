import '../repositories/partner_services_repository.dart';

class ApplyForService {
  const ApplyForService(this.repository);

  final PartnerServicesRepository repository;

  Future<void> call(int serviceId) => repository.applyForService(serviceId);
}
