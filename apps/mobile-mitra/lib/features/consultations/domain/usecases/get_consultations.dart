import '../entities/consultation_summary.dart';
import '../repositories/consultations_repository.dart';

class GetConsultations {
  const GetConsultations(this._repository);

  final ConsultationsRepository _repository;

  Future<List<ConsultationSummary>> call() => _repository.getConsultations();
}
