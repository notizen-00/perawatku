import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../profile/domain/usecases/complete_mitra_profile.dart';

part 'complete_profile_state.dart';

class CompleteProfileCubit extends Cubit<CompleteProfileState> {
  CompleteProfileCubit(this._completeMitraProfile) : super(const CompleteProfileInitial());

  final CompleteMitraProfile _completeMitraProfile;

  Future<void> submit({
    String? specialization,
    String? licenseNumber,
    String? workLocation,
    int? yearsOfExperience,
    double? consultationFee,
    String? bio,
  }) async {
    emit(const CompleteProfileSubmitting());

    try {
      await _completeMitraProfile(
        specialization: specialization,
        licenseNumber: licenseNumber,
        workLocation: workLocation,
        yearsOfExperience: yearsOfExperience,
        consultationFee: consultationFee,
        bio: bio,
      );
      emit(const CompleteProfileSuccess());
    } on Failure catch (error) {
      emit(CompleteProfileError(error.message));
    } catch (_) {
      emit(const CompleteProfileError('Data profil belum bisa disimpan.'));
    }
  }
}
