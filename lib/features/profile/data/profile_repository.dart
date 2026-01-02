import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/data/asset_data_provider.dart';
import '../../../../core/domain/user_profile.dart';
import '../../../../core/providers/auth_provider.dart';

final assetDataProviderProvider =
    Provider<AssetDataProvider>((ref) => const AssetDataProvider());

class ProfileRepository {
  const ProfileRepository(this._assetDataProvider);

  final AssetDataProvider _assetDataProvider;

  Future<UserProfile> getCurrentUserProfile() async {
    try {
      final data = await _assetDataProvider
          .loadMap('assets/data/current_user_profile.json');
      return UserProfile.fromJson(data);
    } catch (e) {
      throw Exception('Failed to load user profile: $e');
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    // TODO: Implement profile update functionality
    // This would typically update the backend
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final assetDataProvider = ref.watch(assetDataProviderProvider);
  return ProfileRepository(assetDataProvider);
});

final currentUserProfileProvider = FutureProvider<UserProfile>((ref) async {
  // Prefer live authenticated user from auth state
  final authedUser = ref.watch(currentUserProvider);
  if (authedUser != null) return authedUser;

  // Fallback to asset-based profile for demo/offline
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getCurrentUserProfile();
});
