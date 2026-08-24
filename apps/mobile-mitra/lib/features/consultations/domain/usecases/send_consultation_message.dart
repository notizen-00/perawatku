import '../entities/consultation_message.dart';
import '../repositories/consultations_repository.dart';

class SendConsultationMessage {
  const SendConsultationMessage(this._repository);

  final ConsultationsRepository _repository;

  Future<ConsultationChatMessage> call(int id, String message) =>
      _repository.sendMessage(id, message);
}
