import 'package:equatable/equatable.dart';

class ActiveTracking extends Equatable {
  const ActiveTracking({
    required this.id,
    required this.bookingCode,
    required this.title,
    required this.patientName,
    required this.patientPhone,
    required this.status,
    required this.scheduledAt,
    required this.startedAt,
    required this.etaMinutes,
    required this.distanceKm,
    required this.totalAmount,
    required this.notes,
    required this.addressLabel,
    required this.addressText,
    required this.paymentStatus,
    required this.histories,
    this.patientLatitude,
    this.patientLongitude,
  });

  final int id;
  final String bookingCode;
  final String title;
  final String patientName;
  final String patientPhone;
  final String status;
  final String scheduledAt;
  final String startedAt;
  final int etaMinutes;
  final double distanceKm;
  final double totalAmount;
  final String notes;
  final String addressLabel;
  final String addressText;
  final String paymentStatus;
  final List<TrackingHistory> histories;
  final double? patientLatitude;
  final double? patientLongitude;

  bool get hasPatientLocation =>
      patientLatitude != null &&
      patientLongitude != null &&
      (patientLatitude != 0 || patientLongitude != 0);

  bool get hasActiveService => status != 'idle';

  @override
  List<Object?> get props => [
    id,
    bookingCode,
    title,
    patientName,
    patientPhone,
    status,
    scheduledAt,
    startedAt,
    etaMinutes,
    distanceKm,
    totalAmount,
    notes,
    addressLabel,
    addressText,
    paymentStatus,
    histories,
    patientLatitude,
    patientLongitude,
  ];
}

class TrackingHistory extends Equatable {
  const TrackingHistory({
    required this.title,
    required this.status,
    required this.notes,
    required this.treatmentType,
    required this.createdAt,
  });

  final String title;
  final String status;
  final String notes;
  final String treatmentType;
  final String createdAt;

  @override
  List<Object?> get props => [title, status, notes, treatmentType, createdAt];
}
