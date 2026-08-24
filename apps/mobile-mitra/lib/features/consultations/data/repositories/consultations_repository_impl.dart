import '../../../../core/config/api_endpoints.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/json_helpers.dart';
import '../../domain/entities/consultation_detail.dart';
import '../../domain/entities/consultation_message.dart';
import '../../domain/entities/consultation_summary.dart';
import '../../domain/repositories/consultations_repository.dart';

class ConsultationsRepositoryImpl implements ConsultationsRepository {
  const ConsultationsRepositoryImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<ConsultationSummary>> getConsultations() async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.consultations,
        queryParameters: {'per_page': 50},
      );

      return jsonList(response).map(_summary).toList();
    } on ApiException catch (error) {
      throw ServerFailure(error.message);
    }
  }

  @override
  Future<ConsultationDetail> getConsultationDetail(int id) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.consultation(id));
      final detail = jsonObject(response['data']) ?? response;
      return _detail(detail);
    } on ApiException catch (error) {
      throw ServerFailure(error.message);
    }
  }

  @override
  Future<ConsultationDetail> updateStatus(int id, String status) async {
    try {
      final response = await _apiClient.patch(
        ApiEndpoints.consultationStatus(id),
        body: {'status': status},
      );
      final detail = jsonObject(response['data']) ?? response;
      return _detail(detail);
    } on ApiException catch (error) {
      throw ServerFailure(error.message);
    }
  }

  @override
  Future<ConsultationChatMessage> sendMessage(int id, String message) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.consultationMessages(id),
        body: {'message_type': 'text', 'message': message},
      );
      final data = jsonObject(response['data']) ?? response;
      return ConsultationChatMessage.fromJson(data);
    } on ApiException catch (error) {
      throw ServerFailure(error.message);
    }
  }

  ConsultationSummary _summary(Map<String, dynamic> json) {
    final patient = jsonObject(json['patient']);
    final payment = jsonObject(json['payment']);
    final scheduledValue = json['scheduled_at'] ?? json['created_at'];

    return ConsultationSummary(
      id: asInt(json['id']),
      code: json['consultation_code']?.toString() ?? '-',
      patientName: patient?['name']?.toString() ?? 'Pasien',
      patientPhone: patient?['phone']?.toString() ?? '-',
      serviceType: json['service_type']?.toString() ?? 'Konsultasi',
      complaint: json['complaint']?.toString() ?? '-',
      status: json['status']?.toString() ?? 'pending',
      scheduledAt: displayTime(scheduledValue),
      createdAt: displayTime(json['created_at']),
      totalAmount: asDouble(json['consultation_fee'] ?? payment?['amount']),
      paymentStatus: payment?['status']?.toString() ?? 'unpaid',
    );
  }

  ConsultationDetail _detail(Map<String, dynamic> json) {
    final patient = jsonObject(json['patient']);
    final payment = jsonObject(json['payment']);
    final scheduledValue = json['scheduled_at'] ?? json['created_at'];
    final messages = json['messages'];

    return ConsultationDetail(
      id: asInt(json['id']),
      code: json['consultation_code']?.toString() ?? '-',
      patientName: patient?['name']?.toString() ?? 'Pasien',
      patientPhone: patient?['phone']?.toString() ?? '-',
      serviceType: json['service_type']?.toString() ?? 'Konsultasi',
      complaint: json['complaint']?.toString() ?? '-',
      diagnosis: json['diagnosis']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      scheduledAt: displayTime(scheduledValue),
      totalAmount: asDouble(json['consultation_fee'] ?? payment?['amount']),
      paymentStatus: payment?['status']?.toString() ?? 'unpaid',
      messages: messages is List
          ? messages
              .whereType<Map<String, dynamic>>()
              .map(ConsultationChatMessage.fromJson)
              .toList()
          : const [],
    );
  }
}
