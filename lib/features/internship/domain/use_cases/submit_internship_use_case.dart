import '../../../../core/result/result.dart';
import '../../../../core/services/maps_service.dart';
import '../../data/models/internship_model.dart';
import '../../data/models/internship_submission_request.dart';
import '../../data/repositories/internship_repository.dart';

/// Orchestrates student placement submission: resolves the company address
/// into coordinates before delegating the write to the repository.
class SubmitInternshipUseCase {
  /// Creates a submit internship use case.
  const SubmitInternshipUseCase(this._repository, this._mapsService);

  final InternshipRepository _repository;
  final MapsService _mapsService;

  /// Executes student placement submission.
  Future<Result<InternshipModel>> call({
    required String studentId,
    required String department,
    required InternshipSubmissionRequest request,
  }) async {
    final geocodeResult = await _mapsService.geocodeAddress(
      request.companyAddress,
    );
    switch (geocodeResult) {
      case Failure<GeocodedLocation>():
        return Failure(geocodeResult.error);
      case Success<GeocodedLocation>(:final data):
        return _repository.submitInternship(
          studentId: studentId,
          department: department,
          request: request,
          companyLatitude: data.latitude,
          companyLongitude: data.longitude,
        );
    }
  }
}
