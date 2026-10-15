import 'dart:typed_data';

import '../general/utils/date_format.dart';
import '../models/donor.dart';
import '../models/page_result.dart';
import 'api/api_client.dart';
import 'api/api_exception.dart';

typedef DonorSaveResult = ({Donor donor, bool created});

class DonorApiService {
  final ApiClient _apiClient;

  DonorApiService(this._apiClient);

  /// Registro de donante del usuario, o null si todavía no se ha registrado (404).
  Future<Donor?> getMyDonor() async {
    try {
      final response = await _apiClient.get('/donors/me');
      return Donor.fromJson(response.body);
    } on ApiException catch (error) {
      if (error.type == ApiErrorType.notFound) return null;
      rethrow;
    }
  }

  /// Crea (201) o actualiza (200) el registro de donante.
  Future<DonorSaveResult> saveMyDonor({
    required String name,
    required String contactNumber,
    required String bloodGroup,
    required String location,
    required DateTime lastDonationDate,
  }) async {
    final response = await _apiClient.put('/donors/me', body: {
      'name': name,
      'contactNumber': contactNumber,
      'bloodGroup': bloodGroup,
      'location': location,
      'lastDonationDate': toApiDate(lastDonationDate),
    });

    return (donor: Donor.fromJson(response.body), created: response.statusCode == 201);
  }

  /// Sube (o reemplaza) la foto del donante. El servidor acepta JPG o PNG de hasta 2 MB.
  Future<Donor> uploadPhoto(Uint8List bytes, String fileName) async {
    final response = await _apiClient.putMultipart(
      '/donors/me/photo',
      field: 'photo',
      bytes: bytes,
      fileName: fileName,
    );
    return Donor.fromJson(response.body);
  }

  /// Foto del donante, o null si todavía no tiene (404).
  Future<Uint8List?> getMyPhoto() async {
    try {
      return await _apiClient.getBytes('/donors/me/photo');
    } on ApiException catch (error) {
      if (error.type == ApiErrorType.notFound) return null;
      rethrow;
    }
  }

  /// Da o retira el consentimiento para aparecer en la búsqueda de donantes.
  Future<Donor> updateSearchVisibility(bool visibleInSearch) async {
    final response = await _apiClient.patch('/donors/me/visibility', body: {
      'visibleInSearch': visibleInSearch,
    });
    return Donor.fromJson(response.body);
  }

  /// Donantes que autorizaron aparecer (sin incluir al usuario). [bloodGroup] null = todos.
  Future<PageResult<DonorSearchResult>> search({
    String? bloodGroup,
    String? location,
    int page = 0,
    int size = 10,
  }) async {
    final response = await _apiClient.get('/donors', query: {
      'bloodGroup': ?bloodGroup,
      'location': ?location,
      'page': '$page',
      'size': '$size',
    });
    return PageResult.fromJson(response.body, DonorSearchResult.fromJson);
  }
}
