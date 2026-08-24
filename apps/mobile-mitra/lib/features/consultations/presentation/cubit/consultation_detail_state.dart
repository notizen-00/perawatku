part of 'consultation_detail_cubit.dart';

abstract class ConsultationDetailState extends Equatable {
  const ConsultationDetailState();
}

class ConsultationDetailInitial extends ConsultationDetailState {
  const ConsultationDetailInitial();

  @override
  List<Object?> get props => [];
}

class ConsultationDetailLoading extends ConsultationDetailState {
  const ConsultationDetailLoading();

  @override
  List<Object?> get props => [];
}

class ConsultationDetailLoaded extends ConsultationDetailState {
  const ConsultationDetailLoaded(this.detail);

  final ConsultationDetail detail;

  @override
  List<Object?> get props => [detail];
}

class ConsultationDetailError extends ConsultationDetailState {
  const ConsultationDetailError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
