import '../models/blood_request.dart';
import '../models/page_result.dart';
import 'api/api_client.dart';

class BloodRequestApiService {
  static const defaultPageSize = 10;

  final ApiClient _apiClient;

  BloodRequestApiService(this._apiClient);

  Future<BloodRequest> create(NewBloodRequest request) async {
    final response = await _apiClient.post('/blood-requests', body: request.toJson());
    return BloodRequest.fromJson(response.body);
  }

  /// [bloodGroup] null equivale al filtro "All".
  Future<PageResult<BloodRequest>> list({
    String? bloodGroup,
    int page = 0,
    int size = defaultPageSize,
  }) async {
    final response = await _apiClient.get('/blood-requests', query: {
      'bloodGroup': ?bloodGroup,
      'page': '$page',
      'size': '$size',
    });
    return PageResult.fromJson(response.body, BloodRequest.fromJson);
  }

  Future<BloodRequest> getById(int id) async {
    final response = await _apiClient.get('/blood-requests/$id');
    return BloodRequest.fromJson(response.body);
  }
}
