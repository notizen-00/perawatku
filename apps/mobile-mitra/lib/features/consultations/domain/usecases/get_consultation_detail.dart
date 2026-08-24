import '../entities/consultation_detail.dart';
import '../repositories/consultations_repository.dart';

class GetConsultationDetail {
  const GetConsultationDetail(this._repository);

  final ConsultationsRepository _repository;

  Future<ConsultationDetail> call(int id) => _repository.getConsultationDetail(id);
}
