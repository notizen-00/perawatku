import 'package:equatable/equatable.dart';

import 'consultation_message.dart';

class ConsultationDetail extends Equatable {
  const ConsultationDetail({
    required this.id,
    required this.code,
    required this.patientName,
    required this.patientPhone,
    required this.serviceType,
    required this.complaint,
    required this.diagnosis,
    required this.notes,
    required this.status,
    required this.scheduledAt,
    required this.totalAmount,
    required this.paymentStatus,
    required this.messages,
  });

  final int id;
  final String code;
  final String patientName;
  final String patientPhone;
  final String serviceType;
  final String complaint;
  final String diagnosis;
  final String notes;
  final String status;
  final String scheduledAt;
  final double totalAmount;
  final String paymentStatus;
  final List<ConsultationChatMessage> messages;

  ConsultationDetail copyWithMessages(List<ConsultationChatMessage> messages) {
    return ConsultationDetail(
      id: id,
      code: code,
      patientName: patientName,
      patientPhone: patientPhone,
      serviceType: serviceType,
      complaint: complaint,
      diagnosis: diagnosis,
      notes: notes,
      status: status,
      scheduledAt: scheduledAt,
      totalAmount: totalAmount,
      paymentStatus: paymentStatus,
      messages: messages,
    );
  }

  @override
  List<Object?> get props => [
    id,
    code,
    patientName,
    patientPhone,
    serviceType,
    complaint,
    diagnosis,
    notes,
    status,
    scheduledAt,
    totalAmount,
    paymentStatus,
    messages,
  ];
}
