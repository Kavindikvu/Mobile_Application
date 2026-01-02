import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/student_profile.dart';
import '../../../core/domain/avatar_catalog.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/logger_provider.dart';
import '../../../core/data/api_client.dart';
import '../../../core/data/services/student_service.dart';
import '../../../core/services/app_toast.dart';
class ParentChildrenState {
  final List<StudentProfile> children;
  final List<PendingChildRequest> pendingRequests;
  final List<DuplicateStudentProfile> duplicateProfiles;
  final bool isProcessing;
  final String? errorMessage;

  const ParentChildrenState({
    required this.children,
    required this.pendingRequests,
    required this.duplicateProfiles,
    this.isProcessing = false,
    this.errorMessage,
  });

  factory ParentChildrenState.initial() => const ParentChildrenState(
        children: [],
        pendingRequests: [],
        duplicateProfiles: [],
      );

  ParentChildrenState copyWith({
    List<StudentProfile>? children,
    List<PendingChildRequest>? pendingRequests,
    List<DuplicateStudentProfile>? duplicateProfiles,
    bool? isProcessing,
    String? errorMessage,
  }) {
    return ParentChildrenState(
      children: children ?? this.children,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      duplicateProfiles: duplicateProfiles ?? this.duplicateProfiles,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: errorMessage,
    );
  }

  bool get hasChildren => children.isNotEmpty;
  bool get hasPendingRequests => pendingRequests.isNotEmpty;
  bool get hasDuplicateProfiles => duplicateProfiles.isNotEmpty;
  bool get showAddChildCallout => !hasChildren && !hasPendingRequests;
}

class ParentChildrenController extends AsyncNotifier<ParentChildrenState> {
  ParentChildrenController();

  late final StudentService _studentService;

  @override
  FutureOr<ParentChildrenState> build() async {
    _studentService = ref.read(studentServiceProvider);

    final user = ref.watch(currentUserProvider);
    if (user == null || !user.isParent) {
      return ParentChildrenState.initial();
    }

    return _loadState(parentId: user.id);
  }

  Future<ParentChildrenState> _loadState({required String parentId}) async {
    try {
      final children = await _studentService.getStudentsByParent(parentId);
      return ParentChildrenState(
        children: children,
        pendingRequests: const [],
        duplicateProfiles: const [],
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to load children for parent $parentId',
        error: e,
        stackTrace: stackTrace,
      );
      AppToast.showApiError(
        statusCode: e is ApiException ? e.statusCode : 500,
        message: e is ApiException ? e.message : null,
      );
      return ParentChildrenState(
        children: const [],
        pendingRequests: const [],
        duplicateProfiles: const [],
        errorMessage:
            'We couldn\'t reach the student service. Try again or check back shortly.',
      );
    }
  }

  Future<void> refresh() async {
    final user = ref.read(currentUserProvider);
    if (user == null || !user.isParent) return;
    state = const AsyncLoading();
    try {
      final refreshed = await _loadState(parentId: user.id);
      state = AsyncData(refreshed);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to refresh parent children state',
        error: e,
        stackTrace: stackTrace,
      );
      state = AsyncError(e, stackTrace);
    }
  }

  Future<void> createChild({
    required String name,
    required int grade,
    required String medium,
    required String address,
    required List<String> cities,
    String? parentContact,
  }) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    state = AsyncData(currentState.copyWith(isProcessing: true));
    try {
      final created = await _studentService.createStudent(
        name: name,
        grade: grade,
        medium: medium,
        parentId: user.id,
        address: address,
        cities: cities,
        parentContact: parentContact,
      );

      AppToast.success('Child profile created successfully.');
      state = AsyncData(
        currentState.copyWith(
          children: [...currentState.children, created],
          isProcessing: false,
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to create child profile',
        error: e,
        stackTrace: stackTrace,
      );
      AppToast.showApiError(
        statusCode: e is ApiException ? e.statusCode : 500,
        message: e is ApiException ? e.message : null,
      );
      state = AsyncData(
        currentState.copyWith(
          isProcessing: false,
          errorMessage:
              'We couldn\'t create the child profile. Please retry once you have a stable connection.',
        ),
      );
    }
  }

  Future<void> removeChild(String studentId) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    state = AsyncData(currentState.copyWith(isProcessing: true));
    try {
      await _studentService.deleteStudent(studentId);
      AppToast.success('Child profile removed.');
      state = AsyncData(
        currentState.copyWith(
          children: currentState.children
              .where((child) => child.id != studentId)
              .toList(),
          isProcessing: false,
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to remove child',
        error: e,
        stackTrace: stackTrace,
      );
      AppToast.showApiError(
        statusCode: e is ApiException ? e.statusCode : 500,
        message: e is ApiException ? e.message : null,
      );
      state = AsyncData(
        currentState.copyWith(
          isProcessing: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> assignAvatar({
    required String studentId,
    String? avatarId,
  }) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final index =
        currentState.children.indexWhere((child) => child.id == studentId);
    if (index == -1) {
      AppLogger.warning(
        'Attempted to assign avatar to unknown child',
        context: {'studentId': studentId},
      );
      return;
    }

    final resolvedAvatar = avatarId != null && avatarId.isNotEmpty
        ? '$kAvatarScheme$avatarId'
        : null;

    if (currentState.children[index].profileImageUrl == resolvedAvatar) {
      AppToast.info(
        'No changes made to ${currentState.children[index].displayName}\'s avatar.',
      );
      return;
    }

    final updatedChild = currentState.children[index].copyWith(
      profileImageUrl: resolvedAvatar,
      lastUpdatedAt: DateTime.now(),
    );

    final updatedChildren = [...currentState.children];
    updatedChildren[index] = updatedChild;

    state = AsyncData(
      currentState.copyWith(
        children: updatedChildren,
      ),
    );

    ref.read(authProvider.notifier).updateChildProfile(updatedChild);

    if (resolvedAvatar == null) {
      AppToast.info(
        '${updatedChild.displayName} will now use initials.',
      );
    } else {
      AppToast.success(
        '${updatedChild.displayName} has a new avatar!',
      );
    }
  }

  Future<void> approvePendingRequest(String requestId) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        errorMessage:
            'Approving pending requests is not available until the service endpoints are ready.',
      ),
    );
    AppToast.warning(
      'Approving requests will be available once the service is ready.',
    );
  }

  Future<void> rejectPendingRequest(String requestId) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        errorMessage:
            'Rejecting pending requests is not available until the service endpoints are ready.',
      ),
    );
    AppToast.warning(
      'Rejecting requests will be available once the service is ready.',
    );
  }

  Future<void> mergeDuplicates(
    List<String> duplicateIds, {
    String? mergedName,
    int? mergedGrade,
    String? mergedMedium,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        errorMessage:
            'Merging duplicate profiles is not available until the service endpoints are ready.',
      ),
    );
    AppToast.info(
      'Duplicate management will be available soon.',
    );
  }
}

final parentChildrenControllerProvider =
    AsyncNotifierProvider<ParentChildrenController, ParentChildrenState>(
  ParentChildrenController.new,
);
