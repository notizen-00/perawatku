import '../repositories/profile_repository.dart';

class CompleteMitraProfile {
  const CompleteMitraProfile(this.repository);

  final ProfileRepository repository;

  Future<void> call({
    String? specialization,
    String? licenseNumber,
    String? workLocation,
    int? yearsOfExperience,
    double? consultationFee,
    String? bio,
  }) {
    return repository.completeProfile(
      specialization: specialization,
      licenseNumber: licenseNumber,
      workLocation: workLocation,
      yearsOfExperience: yearsOfExperience,
      consultationFee: consultationFee,
      bio: bio,
    );
  }
}
