import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/api_config.dart';
import '../api_client.dart';
import '../models/api_subject_model.dart';

class SubjectService {
  final ApiClient _client;

  SubjectService(this._client);

  Future<List<ApiSubjectModel>> getAllSubjects() async {
    final response = await _client.getList('/subjects');
    return response
        .map((json) => ApiSubjectModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<ApiSubjectModel> getSubjectById(String subjectId) async {
    final response = await _client.get('/subjects/$subjectId');
    return ApiSubjectModel.fromJson(response);
  }
}

final subjectServiceProvider = Provider<SubjectService>((ref) {
  final apiClient = ref.watch(apiClientProvider(ApiConfig.subjectServiceBaseUrl));
  return SubjectService(apiClient);
});

