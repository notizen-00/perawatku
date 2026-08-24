import '../entities/active_tracking.dart';
import '../repositories/tracking_repository.dart';

class GetActiveTracking {
  const GetActiveTracking(this.repository);

  final TrackingRepository repository;

  Future<ActiveTracking> call({int? bookingId}) =>
      repository.getActiveTracking(bookingId: bookingId);
}
