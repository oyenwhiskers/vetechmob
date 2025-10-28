import '../models/dashboard.dart';
import 'api_client.dart';

class DashboardService {
  final _api = ApiClient();

  Future<DashboardData> getDashboard() async {
    final res = await _api.get('/dashboard');
    
    // Check for error status codes
    if (res.statusCode != 200) {
      final errorMessage = res.data is Map 
          ? (res.data['message'] ?? 'Server error') 
          : 'Server error';
      throw Exception('Failed to fetch dashboard (${res.statusCode}): $errorMessage');
    }
    
    final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return DashboardData.fromJson(data);
  }
}
