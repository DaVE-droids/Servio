import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/providers/authentication_providers.dart';
import '../../../../core/result/result.dart';
import '../../../profile/data/models/user_model.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

/// Who the signed-in coordinator is, for the notifications and audit
/// events their actions produce.
class CoordinatorIdentity {
  /// Creates a coordinator identity.
  const CoordinatorIdentity({required this.id, required this.name});

  /// The coordinator's Firebase UID.
  final String id;

  /// The coordinator's display name.
  final String name;
}

/// Resolves the signed-in coordinator's identity.
///
/// The **id comes from the auth session**, not the profile, because it is
/// what the security rules compare against: `audit_events` requires
/// `actorId == request.auth.uid`, so an id sourced from a profile that
/// hasn't loaded yet fails the whole batched write.
///
/// The name is fetched with the profile *use case*, not read from
/// `profileControllerProvider`. That controller can already hold a state
/// built before the auth session resolved — `user: null` alongside a
/// "session expired" message — and both reading its value and awaiting
/// its future hand that cached state straight back, so the name fell
/// through to a placeholder even though the profile was perfectly
/// readable. Going to the repository directly is one document read with
/// no cached-state ambiguity.
Future<CoordinatorIdentity?> readCoordinatorIdentity(Ref ref) async {
  final uid = switch (ref.read(authSessionProvider)) {
    AsyncData(:final value) => value.firebaseUser?.uid,
    _ => null,
  };
  if (uid == null) {
    return null;
  }

  var name = 'A coordinator';
  final result = await ref.read(getCurrentUserUseCaseProvider).call(uid);
  if (result case Success<UserModel>(:final data)) {
    final fullName = '${data.firstName} ${data.lastName}'.trim();
    if (fullName.isNotEmpty) {
      name = fullName;
    }
  }
  // A failed lookup keeps the fallback name rather than blocking the
  // action — the name is denormalized display text; the id is what the
  // security rules actually check.

  return CoordinatorIdentity(id: uid, name: name);
}
