import '../../../../core/config/api_endpoints.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/json_helpers.dart';
import '../../domain/entities/mitra_profile.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<MitraProfile> getProfile() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.me);
      final user = jsonObject(response['data']) ?? response;
      final profile = jsonObject(user['partner_profile']);

      return MitraProfile(
        name: user['name']?.toString() ?? 'Mitra',
        email: user['email']?.toString() ?? '-',
        phone: user['phone']?.toString() ?? '-',
        profession: profile?['profession']?.toString() ?? '-',
        verificationStatus: profile?['verification_status']?.toString() ?? '-',
        workLocation: profile?['work_location']?.toString() ?? '-',
      );
    } on ApiException catch (error) {
      throw ServerFailure(error.message);
    }
  }

  @override
  Future<void> updateAvailability(bool isAvailable) async {
    try {
      await _apiClient.patch(
        ApiEndpoints.mitraProfile,
        body: {'is_available': isAvailable},
      );
    } on ApiException catch (error) {
      throw ServerFailure(error.message);
    }
  }

  @override
  Future<void> completeProfile({
    String? specialization,
    String? licenseNumber,
    String? workLocation,
    int? yearsOfExperience,
    double? consultationFee,
    String? bio,
    String? strPhotoPath,
    String? ktpPhotoPath,
  }) async {
    try {
      if (strPhotoPath == null && ktpPhotoPath == null) {
        await _apiClient.patch(
          ApiEndpoints.mitraProfile,
          body: {
            if (specialization != null && specialization.isNotEmpty)
              'specialization': specialization,
            if (licenseNumber != null && licenseNumber.isNotEmpty)
              'license_number': licenseNumber,
            if (workLocation != null && workLocation.isNotEmpty)
              'work_location': workLocation,
            if (yearsOfExperience != null) 'years_of_experience': yearsOfExperience,
            if (consultationFee != null) 'consultation_fee': consultationFee,
            if (bio != null && bio.isNotEmpty) 'bio': bio,
          },
        );
        return;
      }

      await _apiClient.patchMultipart(
        ApiEndpoints.mitraProfile,
        fields: {
          if (specialization != null && specialization.isNotEmpty)
            'specialization': specialization,
          if (licenseNumber != null && licenseNumber.isNotEmpty)
            'license_number': licenseNumber,
          if (workLocation != null && workLocation.isNotEmpty)
            'work_location': workLocation,
          if (yearsOfExperience != null)
            'years_of_experience': yearsOfExperience.toString(),
          if (consultationFee != null) 'consultation_fee': consultationFee.toString(),
          if (bio != null && bio.isNotEmpty) 'bio': bio,
        },
        files: {
          if (strPhotoPath != null) 'str_photo': strPhotoPath,
          if (ktpPhotoPath != null) 'ktp_photo': ktpPhotoPath,
        },
      );
    } on ApiException catch (error) {
      throw ServerFailure(error.message);
    }
  }
}
