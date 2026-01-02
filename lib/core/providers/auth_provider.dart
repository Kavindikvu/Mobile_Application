import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../data/services/user_service.dart';
import '../data/api_client.dart';
import '../domain/user_profile.dart';
import '../domain/student_profile.dart';
import 'logger_provider.dart';
import 'google_sign_in_provider.dart';

// Auth state
class AuthState {
  final UserProfile? user;
  final StudentProfile? selectedChild;
  final bool isLoading;
  final String? error;
  final String? parentViewLocation;

  const AuthState({
    this.user,
    this.selectedChild,
    this.isLoading = false,
    this.error,
    this.parentViewLocation,
  });

  static const _sentinel = Object();

  AuthState copyWith({
    UserProfile? user,
    Object? selectedChild = _sentinel,
    bool? isLoading,
    Object? error = _sentinel,
    Object? parentViewLocation = _sentinel,
  }) {
    return AuthState(
      user: user ?? this.user,
      selectedChild: selectedChild == _sentinel
          ? this.selectedChild
          : selectedChild as StudentProfile?,
      isLoading: isLoading ?? this.isLoading,
      error: error == _sentinel ? this.error : error as String?,
      parentViewLocation: parentViewLocation == _sentinel
          ? this.parentViewLocation
          : parentViewLocation as String?,
    );
  }

  bool get isAuthenticated => user != null;
  bool get isParent => user?.isParent ?? false;
  bool get isStudent => user?.isStudent ?? false;
  bool get hasSelectedChild => selectedChild != null;
}

// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(const AuthState());

  final Ref _ref;

  Future<void> signInWithGoogle({required bool isParent}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final googleSignIn = _ref.read(googleSignInProvider);

      // Try silent sign-in first to avoid account selection screen if user is already signed in
      GoogleSignInAccount? account;
      try {
        account = await googleSignIn.signInSilently();
        AppLogger.debug('Silent sign-in successful');
      } catch (_) {
        // Silent sign-in failed, proceed with interactive sign-in
        AppLogger.debug('Silent sign-in failed, showing account selection');
      }

      // If silent sign-in didn't work, show account selection
      if (account == null) {
        try {
          account = await googleSignIn.signIn();
        } catch (e, stackTrace) {
          AppLogger.error(
            'Google sign-in flow failed',
            error: e,
            stackTrace: stackTrace,
          );
          // Check if user canceled
          final errorString = e.toString().toLowerCase();
          if (errorString.contains('cancel') || 
              errorString.contains('sign_in_canceled') ||
              errorString.contains('user_canceled')) {
            state = state.copyWith(isLoading: false);
            return;
          }
          // Re-throw to be caught by outer catch
          rethrow;
        }
      }
      
      if (account == null) {
        // User canceled the flow
        state = state.copyWith(isLoading: false);
        return;
      }

      GoogleSignInAuthentication auth;
      try {
        auth = await account.authentication;
      } catch (e, stackTrace) {
        AppLogger.error(
          'Failed to get Google authentication tokens',
          error: e,
          stackTrace: stackTrace,
        );
        rethrow;
      }
      final String? idToken = auth.idToken;
      final String? accessToken = auth.accessToken;

      AppLogger.debug(
        'Google sign-in successful, attempting backend sync',
        context: {
          'hasIdToken': idToken != null,
          'hasAccessToken': accessToken != null,
          'email': AppLogger.sanitize(account.email),
        },
      );

      final parsedName = (account.displayName ?? '').trim().split(' ');
      final first = parsedName.isNotEmpty
          ? parsedName.first
          : (account.email.split('@').first);
      final last = parsedName.length > 1 ? parsedName.sublist(1).join(' ') : '';

      final userService = _ref.read(userServiceProvider);

      UserProfile? backendUser =
          await userService.getUserByEmail(account.email);

      if (backendUser == null) {
        AppLogger.info(
          'Backend user not found by email, attempting registration',
          context: {
            'email': AppLogger.sanitize(account.email),
            'role': isParent ? 'Parent' : 'Student',
          },
        );

        backendUser = await userService.registerUser(
          email: account.email,
          firstName: first,
          lastName: last,
          role: isParent ? UserRole.parent : UserRole.student,
        );
      }

      if (backendUser == null) {
        final fallback = UserProfile(
          id: 'google_${account.id}',
          email: account.email,
          firstName: first,
          lastName: last,
          profileImageUrl: account.photoUrl,
          role: isParent ? UserRole.parent : UserRole.student,
          status: UserStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        AppLogger.warning(
          'Failed to obtain backend user profile, using fallback ID',
          context: {
            'email': AppLogger.sanitize(account.email),
          },
        );

        state = state.copyWith(user: fallback, isLoading: false, error: null);
        return;
      }

      final mergedUser = backendUser.copyWith(
        email: backendUser.email.isNotEmpty ? backendUser.email : account.email,
        firstName:
            backendUser.firstName.isNotEmpty ? backendUser.firstName : first,
        lastName: backendUser.lastName.isNotEmpty ? backendUser.lastName : last,
        profileImageUrl: account.photoUrl ?? backendUser.profileImageUrl,
        role: isParent ? UserRole.parent : UserRole.student,
        updatedAt: DateTime.now(),
      );

      state = state.copyWith(user: mergedUser, isLoading: false, error: null);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Google sign-in failed',
        error: e,
        stackTrace: stackTrace,
      );
      
      // Provide user-friendly error message
      String errorMessage = 'Sign-in failed. Please try again.';
      final errorString = e.toString().toLowerCase();
      
      // Handle PlatformException with error code 10 (DEVELOPER_ERROR)
      if (errorString.contains('platformexception') && 
          (errorString.contains('sign_in_failed') || errorString.contains('api_exception: 10'))) {
        errorMessage = 'Google Sign-In configuration error. Please contact support or check your device settings.';
        AppLogger.error(
          'Google Sign-In DEVELOPER_ERROR (code 10) - This usually means SHA-1 fingerprint is not registered in Firebase Console',
          error: e,
          stackTrace: stackTrace,
        );
      } else if (errorString.contains('network') || errorString.contains('connection')) {
        errorMessage = 'Network error. Please check your connection and try again.';
      } else if (errorString.contains('cancel') || errorString.contains('user_canceled')) {
        errorMessage = 'Sign-in was canceled.';
        state = state.copyWith(isLoading: false);
        return;
      } else if (errorString.contains('sign_in_required') || errorString.contains('sign_in_failed')) {
        errorMessage = 'Sign-in failed. Please try again.';
      }
      
      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      throw UnimplementedError(
        'Email and password login is not yet supported.',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    // Surface a loading flag so UI can react while we clean up credentials.
    state = state.copyWith(isLoading: true, error: null);

    try {
      final google = _ref.read(googleSignInProvider);
      final isSignedIn = await google.isSignedIn();

      if (isSignedIn) {
        try {
          await google.disconnect().timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              AppLogger.warning('Google disconnect timed out');
            },
          );
        } on Object catch (e, stackTrace) {
          AppLogger.info(
            'Google disconnect failed; continuing with sign-out',
            error: e,
            stackTrace: stackTrace,
          );
        }
      }

      await google.signOut().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          AppLogger.warning('Google sign-out timed out');
        },
      );
    } catch (e, stackTrace) {
      AppLogger.warning(
        'Google sign-out failed; clearing local auth state anyway',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      state = const AuthState();
    }
  }

  Future<void> switchToChild(
    StudentProfile child, {
    String? parentLocation,
  }) async {
    if (state.user?.isParent != true) {
      throw Exception('Only parents can switch to child profiles');
    }

    state = state.copyWith(
      selectedChild: child,
      parentViewLocation: parentLocation ?? state.parentViewLocation,
    );
  }

  Future<void> switchToParent() async {
    state = state.copyWith(selectedChild: null);
  }

  void updateChildProfile(StudentProfile updatedChild) {
    final current = state.selectedChild;
    if (current?.id == updatedChild.id) {
      state = state.copyWith(selectedChild: updatedChild);
    }
  }

  Future<void> refreshUser() async {
    if (state.user == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      // TODO: Implement actual refresh logic
      await Future.delayed(const Duration(seconds: 1));

      // For now, just update the loading state
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<UserProfile?> updateUserProfileDetails({
    required String firstName,
    required String lastName,
    String? phoneNumber,
    String? address,
  }) async {
    final currentUser = state.user;
    if (currentUser == null) {
      AppLogger.warning(
          'Attempted to update profile with no authenticated user');
      return null;
    }

    try {
      final userService = _ref.read(userServiceProvider);
      final updated = await userService.updateUserProfile(
        userId: currentUser.id,
        firstName: firstName,
        lastName: lastName,
        mobileNumber: phoneNumber,
        address: address,
      );

      if (updated != null) {
        state = state.copyWith(
          user: currentUser.copyWith(
            firstName: updated.firstName,
            lastName: updated.lastName,
            phoneNumber: updated.phoneNumber,
            address: updated.address,
            profileImageUrl:
                updated.profileImageUrl ?? currentUser.profileImageUrl,
            updatedAt: updated.updatedAt,
          ),
          error: null,
        );
      }

      return updated;
    } on ApiException catch (e, stackTrace) {
      AppLogger.logApiError(
        url: 'user-service/users/${currentUser.id}',
        error: e.message,
        statusCode: e.statusCode,
        stackTrace: stackTrace,
      );
      state = state.copyWith(error: e.message);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to update user profile',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

// Providers
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

final currentUserProvider = Provider<UserProfile?>((ref) {
  return ref.watch(authProvider).user;
});

final selectedChildProvider = Provider<StudentProfile?>((ref) {
  return ref.watch(authProvider).selectedChild;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final isParentProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isParent;
});

final isStudentProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isStudent;
});

final hasSelectedChildProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).hasSelectedChild;
});

// Current context provider (returns either parent or selected child)
final currentContextProvider =
    Provider<({String id, String name, String type})?>((ref) {
  final authState = ref.watch(authProvider);
  final user = authState.user;
  final selectedChild = authState.selectedChild;

  if (user == null) return null;

  if (selectedChild != null) {
    return (
      id: selectedChild.id,
      name: selectedChild.displayName,
      type: 'child',
    );
  } else {
    return (
      id: user.id,
      name: user.displayName,
      type: user.role.name,
    );
  }
});
