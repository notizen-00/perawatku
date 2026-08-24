part of 'consultations_cubit.dart';

abstract class ConsultationsState extends Equatable {
  const ConsultationsState();
}

class ConsultationsInitial extends ConsultationsState {
  const ConsultationsInitial();

  @override
  List<Object?> get props => [];
}

class ConsultationsLoading extends ConsultationsState {
  const ConsultationsLoading();

  @override
  List<Object?> get props => [];
}

class ConsultationsLoaded extends ConsultationsState {
  const ConsultationsLoaded(this.consultations);

  final List<ConsultationSummary> consultations;

  @override
  List<Object?> get props => [consultations];
}

class ConsultationsError extends ConsultationsState {
  const ConsultationsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
