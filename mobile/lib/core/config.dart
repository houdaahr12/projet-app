/// Override at launch when the API is not running on the same host.
/// Web / desktop: http://127.0.0.1:8000
/// Android emulator: http://10.0.2.2:8000
/// Physical phone: http://<computer-LAN-IP>:8000
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8000',
);

// Kept as an alias for the existing admin/doctor management service.
const String baseUrl = apiBaseUrl;
