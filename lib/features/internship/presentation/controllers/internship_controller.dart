import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/result/result.dart';
import '../../../authentication/presentation/providers/authentication_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/models/internship_model.dart';
import '../../data/models/internship_submission_request.dart';
import 'internship_state.dart';
import '../providers/internship_providers.dart';

/// Controller for student internship UI state and actions.
class InternshipController extends AsyncNotifier<InternshipState> {
  /// Builds the initial internship state by loading the current placement.
  /// Watches the auth session (not just reads it) so switching accounts —
  /// logging out and into a different user in the same app session —
  /// reloads the correct placement instead of continuing to serve whichever
  /// user was signed in when this provider first built.
  @override
  Future<InternshipState> build() async {
    final uid = switch (ref.watch(authSessionProvider)) {
      AsyncData(:final value) => value.firebaseUser?.uid,
      _ => null,
    };
    return _loadCurrentInternship(uid);
  }

  /// Refreshes the current internship.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadCurrentInternship(_currentUid()));
  }

  /// Submits a student placement request.
  Future<bool> submit(InternshipSubmissionRequest request) async {
    final previous = switch (state) {
      AsyncData(:final value) => value,
      _ => const InternshipState(),
    };
    if (previous.currentInternship != null) {
      state = AsyncData(
        previous.copyWith(
          clearMessages: true,
          errorMessage: 'You already have an internship placement on record.',
        ),
      );
      return false;
    }

    state = AsyncData(
      previous.copyWith(isSubmitting: true, clearMessages: true),
    );
    final uid = _currentUid();
    if (uid == null) {
      state = AsyncData(
        previous.copyWith(
          isSubmitting: false,
          clearMessages: true,
          errorMessage: 'Your session has expired. Please sign in again.',
        ),
      );
      return false;
    }

    final profile = switch (ref.read(profileControllerProvider)) {
      AsyncData(:final value) => value.user,
      _ => null,
    };
    if (profile == null) {
      state = AsyncData(
        previous.copyWith(
          isSubmitting: false,
          clearMessages: true,
          errorMessage:
              'Your profile could not be loaded. Please refresh and try again.',
        ),
      );
      return false;
    }

    final result = await ref
        .read(submitInternshipUseCaseProvider)
        .call(studentId: uid, department: profile.department, request: request);

    switch (result) {
      case Success<InternshipModel>(:final data):
        state = AsyncData(
          previous.copyWith(
            currentInternship: data,
            isSubmitting: false,
            clearMessages: true,
            successMessage: 'Internship placement submitted for review.',
            lastLoadedAt: DateTime.now().toUtc(),
          ),
        );
        return true;
      case Failure<InternshipModel>(:final error):
        state = AsyncData(
          previous.copyWith(
            isSubmitting: false,
            clearMessages: true,
            errorMessage: error.message,
          ),
        );
        return false;
    }
  }

  Future<InternshipState> _loadCurrentInternship(String? uid) async {
    if (uid == null) {
      return const InternshipState(
        errorMessage: 'Your session has expired. Please sign in again.',
      );
    }

    final result = await ref
        .read(getCurrentInternshipUseCaseProvider)
        .call(uid);
    switch (result) {
      case Success<InternshipModel?>(:final data):
        return InternshipState(
          currentInternship: data,
          lastLoadedAt: DateTime.now().toUtc(),
        );
      case Failure<InternshipModel?>(:final error):
        return InternshipState(errorMessage: error.message);
    }
  }

  String? _currentUid() {
    final session = switch (ref.read(authSessionProvider)) {
      AsyncData(:final value) => value,
      _ => null,
    };
    return session?.firebaseUser?.uid;
  }
}
