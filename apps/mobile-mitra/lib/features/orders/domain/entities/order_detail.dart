import 'package:equatable/equatable.dart';

class OrderDetail extends Equatable {
  const OrderDetail({
    required this.id,
    required this.code,
    required this.serviceName,
    required this.patientName,
    required this.patientPhone,
    required this.status,
    required this.scheduledAt,
    required this.startedAt,
    required this.totalAmount,
    required this.notes,
    required this.addressLabel,
    required this.addressText,
    required this.distanceKm,
    required this.etaMinutes,
    required this.paymentStatus,
    required this.histories,
    required this.visitPlan,
    required this.careMode,
    required this.locationType,
    required this.recurrence,
    required this.visitCount,
    required this.transportFee,
    required this.mealFee,
  });

  final int id;
  final String code;
  final String serviceName;
  final String patientName;
  final String patientPhone;
  final String status;
  final String scheduledAt;
  final String startedAt;
  final double totalAmount;
  final String notes;
  final String addressLabel;
  final String addressText;
  final double distanceKm;
  final int etaMinutes;
  final String paymentStatus;
  final List<OrderHistory> histories;

  /// `once` atau `recurring` -- lihat PRD-service-booking-terjadwal-dan-biaya.md.
  final String visitPlan;

  /// `visit` atau `live_in`.
  final String careMode;

  /// `home` atau `hospital`.
  final String locationType;

  /// `weekly`/`monthly`, hanya relevan kalau [visitPlan] == 'recurring'.
  final String recurrence;
  final int visitCount;
  final double transportFee;
  final double mealFee;

  bool get isRecurring => visitPlan == 'recurring';
  bool get isLiveIn => careMode == 'live_in';
  bool get isHospitalVisit => locationType == 'hospital';
  bool get hasExtraFees => transportFee > 0 || mealFee > 0;

  @override
  List<Object?> get props => [
    id,
    code,
    serviceName,
    patientName,
    patientPhone,
    status,
    scheduledAt,
    startedAt,
    totalAmount,
    notes,
    addressLabel,
    addressText,
    distanceKm,
    etaMinutes,
    paymentStatus,
    histories,
    visitPlan,
    careMode,
    locationType,
    recurrence,
    visitCount,
    transportFee,
    mealFee,
  ];
}

class OrderHistory extends Equatable {
  const OrderHistory({
    required this.title,
    required this.status,
    required this.notes,
    required this.treatmentType,
    required this.createdAt,
    required this.photoUrl,
    required this.checklist,
  });

  final String title;
  final String status;
  final String notes;
  final String treatmentType;
  final String createdAt;
  final String? photoUrl;
  final List<String> checklist;

  @override
  List<Object?> get props => [
    title,
    status,
    notes,
    treatmentType,
    createdAt,
    photoUrl,
    checklist,
  ];
}
