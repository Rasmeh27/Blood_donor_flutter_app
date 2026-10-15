import 'package:http/http.dart' as http;

import '../repositories/auth_repository.dart';
import 'api/api_client.dart';
import 'auth_service_api.dart';
import 'blood_request_api_service.dart';
import 'donor_api_service.dart';
import 'session_service.dart';
import 'user_api_service.dart';

/// Punto único donde se crean los servicios. Las pantallas los obtienen de [instance];
/// las pruebas reemplazan [instance] con un ApiClient que usa un http.Client simulado.
class AppServices {
  static AppServices instance = AppServices.create();

  final SessionService session;
  final ApiClient apiClient;
  final AuthRepository auth;
  final UserApiService users;
  final DonorApiService donors;
  final BloodRequestApiService bloodRequests;

  AppServices({required this.session, required this.apiClient})
      : auth = AuthServiceApi(apiClient, session),
        users = UserApiService(apiClient, session),
        donors = DonorApiService(apiClient),
        bloodRequests = BloodRequestApiService(apiClient);

  factory AppServices.create({http.Client? httpClient, SessionService? session}) {
    final sessionService = session ?? SessionService();
    return AppServices(
      session: sessionService,
      apiClient: ApiClient(httpClient: httpClient ?? http.Client(), session: sessionService),
    );
  }
}
