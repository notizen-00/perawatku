import '../entities/mitra_profile.dart';

abstract class ProfileRepository {
  Future<MitraProfile> getProfile();

  Future<void> updateAvailability(bool isAvailable);

  /// Fills in the professional data (specialization, license/STR number,
  /// etc.) that registration itself no longer collects up front -- this is
  /// the post-registration "lengkapi profil" step before admin verification.
  Future<void> completeProfile({
    String? specialization,
    String? licenseNumber,
    String? workLocation,
    int? yearsOfExperience,
    double? consultationFee,
    String? bio,
    String? strPhotoPath,
    String? ktpPhotoPath,
  });
}
