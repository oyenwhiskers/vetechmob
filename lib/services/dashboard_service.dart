import '../models/dashboard.dart';
import 'api_client.dart';

class DashboardService {
  final _api = ApiClient();

  Future<DashboardData> getDashboard() async {
    final res = await _api.get('/dashboard');
    final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return DashboardData.fromJson(data);
  }
}
