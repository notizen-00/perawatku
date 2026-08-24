import '../entities/consultation_detail.dart';
import '../repositories/consultations_repository.dart';

class UpdateConsultationStatus {
  const UpdateConsultationStatus(this._repository);

  final ConsultationsRepository _repository;

  Future<ConsultationDetail> call(int id, String status) =>
      _repository.updateStatus(id, status);
}
