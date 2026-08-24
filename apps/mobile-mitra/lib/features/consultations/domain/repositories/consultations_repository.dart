import '../entities/consultation_detail.dart';
import '../entities/consultation_message.dart';
import '../entities/consultation_summary.dart';

abstract class ConsultationsRepository {
  Future<List<ConsultationSummary>> getConsultations();

  Future<ConsultationDetail> getConsultationDetail(int id);

  Future<ConsultationDetail> updateStatus(int id, String status);

  Future<ConsultationChatMessage> sendMessage(int id, String message);
}
