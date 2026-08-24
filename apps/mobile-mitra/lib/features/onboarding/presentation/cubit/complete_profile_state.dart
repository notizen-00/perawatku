part of 'complete_profile_cubit.dart';

abstract class CompleteProfileState extends Equatable {
  const CompleteProfileState();
}

class CompleteProfileInitial extends CompleteProfileState {
  const CompleteProfileInitial();

  @override
  List<Object?> get props => [];
}

class CompleteProfileSubmitting extends CompleteProfileState {
  const CompleteProfileSubmitting();

  @override
  List<Object?> get props => [];
}

class CompleteProfileSuccess extends CompleteProfileState {
  const CompleteProfileSuccess();

  @override
  List<Object?> get props => [];
}

class CompleteProfileError extends CompleteProfileState {
  const CompleteProfileError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
