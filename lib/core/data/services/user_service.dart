import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/api_config.dart';
import '../../domain/user_profile.dart';
import '../api_client.dart';
import '../../providers/logger_provider.dart';
import '../cache/in_memory_cache.dart';
import '../cache/request_deduplicator.dart';

class UserService {
  final ApiClient _client;
  final String _baseUrl;
  final http.Client _httpClient;
  final InMemoryCache _cache;
  final RequestDeduplicator _deduplicator;

  UserService(
    this._client,
    this._baseUrl, {
    http.Client? httpClient,
    InMemoryCache? cache,
    RequestDeduplicator? deduplicator,
  })  : _httpClient = httpClient ?? http.Client(),
        _cache = cache ?? InMemoryCache(),
        _deduplicator = deduplicator ?? RequestDeduplicator();

  /// Get user by ID from user-service
  /// Returns a map with firstName and lastName, or null if user not found
  /// 404 errors are handled silently as they're expected when a user doesn't exist
  /// Uses caching and request deduplication for performance
  Future<Map<String, String>?> getUserById(String userId) async {
    // Check cache first
    final cacheKey = 'user_$userId';
    final cached = _cache.get<Map<String, String>>(cacheKey);
    if (cached != null) {
      AppLogger.debug(
        'User data served from cache',
        context: {'userId': userId},
      );
      return cached;
    }

    // Use deduplication to prevent multiple simultaneous requests
    return _deduplicator.deduplicate(
      cacheKey,
      () async {
        try {
          final uri = Uri.parse('$_baseUrl/users/$userId');
          final requestHeaders = {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          };

          final response = await _httpClient.get(uri, headers: requestHeaders);

          // Handle 404 silently - user doesn't exist, which is expected
          if (response.statusCode == 404) {
            return null;
          }

          // Log non-404 errors
          if (response.statusCode < 200 || response.statusCode >= 300) {
            AppLogger.logApiError(
              url: uri.toString(),
              error: 'HTTP ${response.statusCode}',
              statusCode: response.statusCode,
            );
            return null;
          }

          // Parse successful response
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          final firstName = responseData['firstName'] as String? ?? '';
          final lastName = responseData['lastName'] as String? ?? '';

          if (firstName.isEmpty && lastName.isEmpty) {
            AppLogger.warning(
              'User found but name fields are empty',
              context: {'userId': userId},
            );
            return null;
          }

          final userData = {
            'firstName': firstName,
            'lastName': lastName,
          };

          // Cache the result (1 hour TTL for user data)
          _cache.set(cacheKey, userData, ttl: const Duration(hours: 1));

          return userData;
        } catch (e, stackTrace) {
          // Log unexpected errors (network errors, parsing errors, etc.)
          AppLogger.logApiError(
            url: '$_baseUrl/users/$userId',
            error: e,
            stackTrace: stackTrace,
          );
          return null;
        }
      },
    );
  }

  Future<UserProfile?> getUserByEmail(String email) async {
    final uri = Uri.parse('$_baseUrl/users').replace(
      queryParameters: {'email': email},
    );
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    try {
      AppLogger.logApiRequest(
        method: 'GET',
        url: uri.toString(),
        headers: headers,
        queryParameters: {'email': email},
      );

      final stopwatch = Stopwatch()..start();
      final response = await _client.client.get(uri, headers: headers);
      stopwatch.stop();

      AppLogger.logApiResponse(
        statusCode: response.statusCode,
        url: uri.toString(),
        headers: response.headers,
        body: response.body,
        duration: stopwatch.elapsed,
      );

      if (response.statusCode == 404) {
        // Expected when the user is not yet registered.
        return null;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        AppLogger.logApiError(
          url: uri.toString(),
          error: 'HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        );
        return null;
      }

      if (response.body.isEmpty) {
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        AppLogger.warning(
          'Unexpected response type when fetching user by email',
          context: {
            'email': email,
            'type': decoded.runtimeType.toString(),
          },
        );
        return null;
      }

      if (decoded.isEmpty) {
        return null;
      }

      final firstMatch = decoded.first;
      if (firstMatch is! Map<String, dynamic>) {
        AppLogger.warning(
          'Unexpected response entry type when fetching user by email',
          context: {
            'email': email,
            'type': firstMatch.runtimeType.toString(),
          },
        );
        return null;
      }

      return _mapToUserProfile(firstMatch);
    } catch (e, stackTrace) {
      AppLogger.logApiError(
        url: uri.toString(),
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<UserProfile?> registerUser({
    required String email,
    required String firstName,
    required String lastName,
    required UserRole role,
    String? mobileNumber,
    String? address,
  }) async {
    try {
      final payload = <String, dynamic>{
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'role': _formatRoleForApi(role),
        'mobileNumber': mobileNumber != null && mobileNumber.trim().isNotEmpty
            ? mobileNumber.trim()
            : _defaultMobileNumber,
        'address': address != null && address.trim().isNotEmpty
            ? address.trim()
            : _defaultAddress,
      };

      final response = await _client.post(
        '/users/register',
        body: payload,
      );

      if (response.isEmpty) {
        return null;
      }

      return _mapToUserProfile(response);
    } catch (e, stackTrace) {
      AppLogger.logApiError(
        url: '$_baseUrl/users/register',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<UserProfile?> updateUserProfile({
    required String userId,
    required String firstName,
    required String lastName,
    String? mobileNumber,
    String? address,
  }) async {
    final payload = <String, dynamic>{
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      if (mobileNumber != null && mobileNumber.trim().isNotEmpty)
        'mobileNumber': mobileNumber.trim(),
      if (address != null && address.trim().isNotEmpty)
        'address': address.trim(),
    };

    try {
      final response = await _client.put(
        '/users/$userId',
        body: payload,
      );

      if (response.isEmpty) {
        AppLogger.warning(
          'Received empty response when updating user profile',
          context: {'userId': userId},
        );
        return null;
      }

      return _mapToUserProfile(response);
    } on ApiException catch (e, stackTrace) {
      AppLogger.logApiError(
        url: '$_baseUrl/users/$userId',
        error: e.message,
        statusCode: e.statusCode,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.logApiError(
        url: '$_baseUrl/users/$userId',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  String get _defaultMobileNumber => '0000000000';
  String get _defaultAddress => 'Address pending update';

  String _formatRoleForApi(UserRole role) {
    switch (role) {
      case UserRole.parent:
        return 'PARENT';
      case UserRole.student:
        return 'STUDENT';
      case UserRole.teacher:
        return 'TEACHER';
      case UserRole.admin:
        return 'ADMIN';
    }
  }

  UserRole _parseRole(String? role) {
    if (role == null || role.isEmpty) {
      return UserRole.student;
    }

    final normalized = role.toLowerCase();
    for (final value in UserRole.values) {
      if (value.name.toLowerCase() == normalized) {
        return value;
      }
    }

    return UserRole.student;
  }

  UserStatus _parseStatus(String? status) {
    if (status == null || status.isEmpty) {
      return UserStatus.active;
    }

    final normalized = status.toLowerCase();
    for (final value in UserStatus.values) {
      if (value.name.toLowerCase() == normalized) {
        return value;
      }
    }

    return UserStatus.active;
  }

  UserProfile _mapToUserProfile(
    Map<String, dynamic> json,
  ) {
    final rawId = json['id'] ?? json['userId'];
    final id = rawId is String
        ? rawId
        : rawId != null
            ? rawId.toString()
            : '';

    final createdAtRaw = json['createdAt'] as String?;
    final updatedAtRaw = json['updatedAt'] as String?;

    final createdAt = createdAtRaw != null
        ? DateTime.tryParse(createdAtRaw) ?? DateTime.now()
        : DateTime.now();
    final updatedAt = updatedAtRaw != null
        ? DateTime.tryParse(updatedAtRaw) ?? DateTime.now()
        : DateTime.now();

    final phoneNumber = json['mobileNumber'] as String?;

    if (id.isEmpty) {
      AppLogger.warning(
        'User payload missing ID',
        context: {'payload': json},
      );
    }

    return UserProfile(
      id: id,
      email: json['email'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      phoneNumber: phoneNumber?.isNotEmpty == true ? phoneNumber : null,
      profileImageUrl: json['profileImageUrl'] as String?,
      role: _parseRole(json['role'] as String?),
      status: _parseStatus(json['status'] as String?),
      createdAt: createdAt,
      updatedAt: updatedAt,
      preferences: json['preferences'] as Map<String, dynamic>?,
      childrenIds: (json['childrenIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      parentId: json['parentId'] as String?,
      academicInfo: json['academicInfo'] as Map<String, dynamic>?,
      parentInfo: json['parentInfo'] as Map<String, dynamic>?,
    );
  }

  /// Get multiple users by IDs
  /// Returns a map of userId -> fullName
  /// Optimized with caching and batch processing (max 10 concurrent requests)
  Future<Map<String, String>> getUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) return {};

    final Map<String, String> userMap = {};
    final uncachedIds = <String>[];

    // Check cache first
    for (final userId in userIds) {
      final cached = _cache.get<Map<String, String>>('user_$userId');
      if (cached != null) {
        final fullName = '${cached['firstName']} ${cached['lastName']}'.trim();
        if (fullName.isNotEmpty) {
          userMap[userId] = fullName;
        }
      } else {
        uncachedIds.add(userId);
      }
    }

    // Fetch uncached users in batches to avoid overwhelming the API
    if (uncachedIds.isNotEmpty) {
      const batchSize = 10; // Limit concurrent requests
      
      for (var i = 0; i < uncachedIds.length; i += batchSize) {
        final batch = uncachedIds.skip(i).take(batchSize).toList();
        
        // Fetch batch in parallel
        final futures = batch.map((userId) async {
          final user = await getUserById(userId);
          if (user != null) {
            final fullName = '${user['firstName']} ${user['lastName']}'.trim();
            if (fullName.isNotEmpty) {
              return MapEntry(userId, fullName);
            }
          }
          return null;
        });

        final results = await Future.wait(futures);
        for (final result in results) {
          if (result != null) {
            userMap[result.key] = result.value;
          }
        }
      }
    }

    AppLogger.debug(
      'Fetched users by IDs',
      context: {
        'total': userIds.length,
        'cached': userIds.length - uncachedIds.length,
        'fetched': uncachedIds.length,
      },
    );

    return userMap;
  }
}

final userServiceProvider = Provider<UserService>((ref) {
  final apiClient = ref.watch(apiClientProvider(ApiConfig.userServiceBaseUrl));
  final cache = InMemoryCache();
  final deduplicator = RequestDeduplicator();
  return UserService(apiClient, ApiConfig.userServiceBaseUrl, cache: cache, deduplicator: deduplicator);
});
