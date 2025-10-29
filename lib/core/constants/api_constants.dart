class APIConstant {
  // Local Backend (Web App Docker)
  // Use Mac's local IP address for real iOS device testing
  static const baseUrl = "http://172.20.10.6:8000/api/v1";

  // Alternative configurations:
  // For iOS Simulator: "http://localhost:8000/api/v1"
  // For Android Emulator: "http://10.0.2.2:8000/api/v1"
  // For Real iOS Device (same network): "http://172.20.10.6:8000/api/v1"
  // Remote backup: "https://healthify-backend-1p9y.onrender.com/api/v1"

  // Endpoints
  static const String assessmentsEndpoint = "/assessments";
  static const String referralsEndpoint = "/referrals";
  static const String patientsEndpoint = "/patients";
  static const String appointmentsEndpoint = "/appointments";
}
