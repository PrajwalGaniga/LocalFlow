import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/provider.dart';
import '../models/consumer.dart';
import '../models/service_request.dart';
import '../models/notification_item.dart';
import '../models/provider_wallet.dart';
import '../models/service_location.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        'User-Agent': 'LocalFlowMobileApp/1.0',
      };

  // ---------- Locations ----------

  Future<List<ServiceLocation>> getServiceLocations() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/locations/');
    final res = await http.get(uri, headers: _headers);

    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => ServiceLocation.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<String>> getDistricts() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/locations/districts');
    final res = await http.get(uri, headers: _headers);

    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => e.toString()).toList();
    }
    return ['Bengaluru Urban', 'Dakshina Kannada', 'Udupi', 'Mysuru'];
  }

  Future<List<ServiceLocation>> getLocationsByDistrict(String district) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/locations/by-district/${Uri.encodeComponent(district)}');
    final res = await http.get(uri, headers: _headers);

    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => ServiceLocation.fromJson(e)).toList();
    }
    return [];
  }

  // ---------- Provider Auth & Profile ----------

  Future<Provider?> getProviderByPhone(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('${ApiConfig.baseUrl}/providers/by-phone/$cleanPhone');
    final res = await http.get(uri, headers: _headers);

    if (res.statusCode == 200) {
      return Provider.fromJson(jsonDecode(res.body));
    } else if (res.statusCode == 404) {
      return null;
    }
    throw Exception('Failed to lookup provider: ${res.body}');
  }

  Future<List<Provider>> getAllProvidersByPhone(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('${ApiConfig.baseUrl}/providers/all-by-phone/$cleanPhone');
    final res = await http.get(uri, headers: _headers);

    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => Provider.fromJson(e)).toList();
    } else if (res.statusCode == 404) {
      return [];
    }
    throw Exception('Failed to lookup provider profiles: ${res.body}');
  }

  Future<Provider> loginProvider(String phone, String? password) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('${ApiConfig.baseUrl}/providers/login');
    final res = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({'phone': cleanPhone, 'password': password}),
    );

    if (res.statusCode == 200) {
      return Provider.fromJson(jsonDecode(res.body));
    }
    final err = jsonDecode(res.body)['detail'] ?? 'Login failed';
    throw Exception(err);
  }

  Future<Provider> registerProvider({
    required String name,
    required String phone,
    required String skill,
    required int locationId,
    int? rateMin,
    int? rateMax,
    String? password,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('${ApiConfig.baseUrl}/providers/');
    final res = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'name': name.trim(),
        'phone': cleanPhone,
        'skill': skill.trim().toLowerCase(),
        'location_id': locationId,
        'rate_min': rateMin,
        'rate_max': rateMax,
        'password': password,
      }),
    );

    if (res.statusCode == 201) {
      return Provider.fromJson(jsonDecode(res.body));
    }
    final err = jsonDecode(res.body)['detail'] ?? 'Registration failed';
    throw Exception(err);
  }

  Future<Provider> updateProviderProfile(
    int providerId, {
    String? name,
    String? skill,
    int? locationId,
    int? rateMin,
    int? rateMax,
    String? availabilityStatus,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/providers/$providerId');
    final Map<String, dynamic> body = {};
    if (name != null) body['name'] = name.trim();
    if (skill != null) body['skill'] = skill.trim().toLowerCase();
    if (locationId != null) body['location_id'] = locationId;
    if (rateMin != null) body['rate_min'] = rateMin;
    if (rateMax != null) body['rate_max'] = rateMax;
    if (availabilityStatus != null) body['availability_status'] = availabilityStatus;

    final res = await http.patch(
      uri,
      headers: _headers,
      body: jsonEncode(body),
    );

    if (res.statusCode == 200) {
      return Provider.fromJson(jsonDecode(res.body));
    }
    final err = jsonDecode(res.body)['detail'] ?? 'Failed to update profile';
    throw Exception(err);
  }

  Future<List<Provider>> browseProviders({String? skill, int? locationId}) async {
    final queryParams = <String, String>{};
    if (skill != null && skill.isNotEmpty) queryParams['skill'] = skill;
    if (locationId != null) queryParams['location_id'] = locationId.toString();

    final uri = Uri.parse('${ApiConfig.baseUrl}/providers/').replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
    final res = await http.get(uri, headers: _headers);

    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((e) => Provider.fromJson(e)).toList();
    }
    throw Exception('Failed to browse providers: ${res.body}');
  }

  Future<ProviderWallet> getProviderWallet(int providerId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/providers/$providerId/wallet');
    final res = await http.get(uri, headers: _headers);

    if (res.statusCode == 200) {
      return ProviderWallet.fromJson(jsonDecode(res.body));
    }
    throw Exception('Failed to load wallet data');
  }

  // ---------- Provider Notifications & Jobs ----------

  Future<List<NotificationItem>> getProviderNotifications(int providerId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/providers/$providerId/notifications');
    final res = await http.get(uri, headers: _headers);

    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((item) => NotificationItem.fromJson(item)).toList();
    }
    throw Exception('Failed to load incoming requests');
  }

  Future<Map<String, dynamic>> acceptNotification(int providerId, int requestId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/providers/$providerId/notifications/$requestId/accept');
    final res = await http.post(uri, headers: _headers);

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    final err = jsonDecode(res.body)['detail'] ?? 'Failed to accept job';
    throw Exception(err);
  }

  Future<bool> declineNotification(int providerId, int requestId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/providers/$providerId/notifications/$requestId/decline');
    final res = await http.post(uri, headers: _headers);
    return res.statusCode == 200;
  }

  Future<List<ServiceRequest>> getProviderJobs(int providerId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/providers/$providerId/requests');
    final res = await http.get(uri, headers: _headers);

    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((item) => ServiceRequest.fromJson(item)).toList();
    }
    throw Exception('Failed to load provider jobs');
  }

  // ---------- Consumer Auth & Profile ----------

  Future<Consumer?> getConsumerByPhone(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('${ApiConfig.baseUrl}/consumers/by-phone/$cleanPhone');
    final res = await http.get(uri, headers: _headers);

    if (res.statusCode == 200) {
      return Consumer.fromJson(jsonDecode(res.body));
    } else if (res.statusCode == 404) {
      return null;
    }
    throw Exception('Failed to lookup consumer: ${res.body}');
  }

  Future<Consumer> loginConsumer(String phone, String? password) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('${ApiConfig.baseUrl}/consumers/login');
    final res = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({'phone': cleanPhone, 'password': password}),
    );

    if (res.statusCode == 200) {
      return Consumer.fromJson(jsonDecode(res.body));
    }
    final err = jsonDecode(res.body)['detail'] ?? 'Login failed';
    throw Exception(err);
  }

  Future<Consumer> registerConsumer({
    required String name,
    required String phone,
    String? password,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('${ApiConfig.baseUrl}/consumers/');
    final res = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'name': name.trim(),
        'phone': cleanPhone,
        'password': password,
      }),
    );

    if (res.statusCode == 201) {
      return Consumer.fromJson(jsonDecode(res.body));
    }
    final err = jsonDecode(res.body)['detail'] ?? 'Registration failed';
    throw Exception(err);
  }

  // ---------- Consumer Requests & Payments ----------

  Future<List<ServiceRequest>> getConsumerRequests(int consumerId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/consumers/$consumerId/requests');
    final res = await http.get(uri, headers: _headers);

    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body);
      return list.map((item) => ServiceRequest.fromJson(item)).toList();
    }
    throw Exception('Failed to load consumer requests');
  }

  Future<ServiceRequest> createServiceRequest({
    required String consumerPhone,
    required String skill,
    required int locationId,
    String? description,
    int? preferredProviderId,
  }) async {
    final cleanPhone = consumerPhone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('${ApiConfig.baseUrl}/requests/');
    final res = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'consumer_phone': cleanPhone,
        'skill_requested': skill.trim().toLowerCase(),
        'location_id': locationId,
        'description': description?.trim(),
        'preferred_provider_id': preferredProviderId,
      }),
    );

    if (res.statusCode == 201) {
      return ServiceRequest.fromJson(jsonDecode(res.body));
    }
    final err = jsonDecode(res.body)['detail'] ?? 'Failed to create service request';
    throw Exception(err);
  }

  Future<ServiceRequest> markRequestPaid(int requestId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/requests/$requestId/mark-paid');
    final res = await http.post(uri, headers: _headers);

    if (res.statusCode == 200) {
      return ServiceRequest.fromJson(jsonDecode(res.body));
    }
    throw Exception('Failed to mark request as paid');
  }

  Future<ServiceRequest> completeRequest(int requestId, int rating, String? comment) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/requests/$requestId/complete');
    final res = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'rating': rating,
        'rating_comment': comment?.trim(),
      }),
    );

    if (res.statusCode == 200) {
      return ServiceRequest.fromJson(jsonDecode(res.body));
    }
    final err = jsonDecode(res.body)['detail'] ?? 'Failed to complete request';
    throw Exception(err);
  }

  Future<Map<String, dynamic>> cancelRequest(int requestId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/requests/$requestId/cancel');
    final res = await http.post(uri, headers: _headers);

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    final err = jsonDecode(res.body)['detail'] ?? 'Failed to cancel request';
    throw Exception(err);
  }

  // ---------- Metadata / Dropdowns ----------

  Future<List<String>> getSkills() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/requests/meta/skills');
      final res = await http.get(uri, headers: _headers);
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return ['electrician', 'plumber', 'carpenter', 'painter', 'tailor', 'tutor'];
  }
}
