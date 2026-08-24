import 'package:equatable/equatable.dart';

class ConsultationSummary extends Equatable {
  const ConsultationSummary({
    required this.id,
    required this.code,
    required this.patientName,
    required this.patientPhone,
    required this.serviceType,
    required this.complaint,
    required this.status,
    required this.scheduledAt,
    required this.createdAt,
    required this.totalAmount,
    required this.paymentStatus,
  });

  final int id;
  final String code;
  final String patientName;
  final String patientPhone;
  final String serviceType;
  final String complaint;
  final String status;
  final String scheduledAt;
  final String createdAt;
  final double totalAmount;
  final String paymentStatus;

  @override
  List<Object?> get props => [
    id,
    code,
    patientName,
    patientPhone,
    serviceType,
    complaint,
    status,
    scheduledAt,
    createdAt,
    totalAmount,
    paymentStatus,
  ];
}
