import 'dart:io';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  late Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: {'Accept': 'application/json'},
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          String? token = prefs.getString('token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  // LOGIN
  Future<Response> login(String emailOrUsername, String password) async {
    try {
      return await _dio.post(
        '/login',
        data: {'email': emailOrUsername, 'password': password},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // KIRIM OTP
  Future<Response> sendOtp(String email) async {
    try {
      return await _dio.post('/send-otp', data: {'email': email});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // REGISTER DENGAN UPLOAD KTM
  Future<Response> register({
    required String username,
    required String email,
    required String password,
    required String otp,
    required String nim,
    required PlatformFile ktmFile,
  }) async {
    try {
      MultipartFile multipartFile;

      // Handle beda web vs mobile
      if (kIsWeb) {
        // Di Web, baca bytes pake readAsBytes()
        final bytes = await ktmFile.readAsBytes();
        multipartFile = MultipartFile.fromBytes(bytes, filename: ktmFile.name);
      } else {
        // Di mobile (Android/iOS), pake path
        if (ktmFile.path != null) {
          multipartFile = await MultipartFile.fromFile(
            ktmFile.path!,
            filename: ktmFile.name,
          );
        } else {
          // Fallback kalau path null tapi bytes ada
          final bytes = await ktmFile.readAsBytes();
          multipartFile = MultipartFile.fromBytes(
            bytes,
            filename: ktmFile.name,
          );
        }
      }

      FormData formData = FormData.fromMap({
        'username': username,
        'email': email,
        'password': password,
        'otp': otp,
        'nim': nim,
        'ktm_file': multipartFile,
      });

      return await _dio.post('/register', data: formData);
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw e.toString();
    }
  }

  // FORGOT PASSWORD - KIRIM OTP
  Future<Response> forgotPasswordSendOtp(String email) async {
    try {
      return await _dio.post(
        '/forgot-password/send-otp',
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // FORGOT PASSWORD - RESET
  Future<Response> forgotPasswordReset({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      return await _dio.post(
        '/forgot-password/reset',
        data: {
          'email': email,
          'otp': otp,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // LOGOUT
  Future<Response> logout() async {
    try {
      return await _dio.post('/logout');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // GET PROFILE
  Future<Response> getProfile() async {
    try {
      return await _dio.get('/profile');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // UPDATE PROFILE
  Future<Response> updateProfile({
    required String name,
    String? phone,
    bool isRunner = false,
    String? vehicleType,
    String? vehiclePlate,
    PlatformFile? profilePhoto,
  }) async {
    try {
      Map<String, dynamic> map = {
        'name': name,
        'phone': phone ?? '',
        'is_runner': isRunner ? '1' : '0',
        '_method': 'POST', // Biar Laravel detect sebagai POST
      };

      if (isRunner) {
        map['vehicle_type'] = vehicleType ?? '';
        map['vehicle_plate'] = vehiclePlate ?? '';
      }

      // Kalau ada foto, kirim sebagai multipart
      if (profilePhoto != null) {
        MultipartFile multipartFile;
        if (kIsWeb) {
          final bytes = await profilePhoto.readAsBytes();
          multipartFile = MultipartFile.fromBytes(
            bytes,
            filename: profilePhoto.name,
          );
        } else {
          if (profilePhoto.path != null) {
            multipartFile = await MultipartFile.fromFile(
              profilePhoto.path!,
              filename: profilePhoto.name,
            );
          } else {
            final bytes = await profilePhoto.readAsBytes();
            multipartFile = MultipartFile.fromBytes(
              bytes,
              filename: profilePhoto.name,
            );
          }
        }
        map['profile_photo'] = multipartFile;
      }

      FormData formData = FormData.fromMap(map);
      return await _dio.post('/profile/update', data: formData);
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw e.toString();
    }
  }

  String _handleError(DioException e) {
    if (e.response != null && e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      if (data is Map && data['error'] != null) {
        return data['error'].toString();
      }
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Koneksi timeout. Cek jaringan & IP server.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Gagal konek ke server. Pastikan Laravel jalan & IP benar.';
    }
    if (e.type == DioExceptionType.badResponse) {
      return 'Server error (${e.response?.statusCode}). Coba lagi nanti.';
    }
    return 'Terjadi kesalahan: ${e.message}';
  }

  // ============================================
  // JASTIP
  // ============================================
  Future<Response> getJastips({String? status}) async {
    try {
      final query = status != null ? {'status': status} : null;
      return await _dio.get('/jastips', queryParameters: query);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> createJastip({
    required String itemName,
    String? itemDescription,
    required String buyLocation,
    required String deliveryLocation,
    required double budget,
    double fee = 0,
    required String whatsappNumber,
  }) async {
    try {
      return await _dio.post(
        '/jastips',
        data: {
          'item_name': itemName,
          'item_description': itemDescription,
          'buy_location': buyLocation,
          'delivery_location': deliveryLocation,
          'budget': budget,
          'fee': fee,
          'whatsapp_number': whatsappNumber,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> takeJastip(int id) async {
    try {
      return await _dio.post('/jastips/$id/take');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> getMyJastips() async {
    try {
      return await _dio.get('/jastips/my-orders');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================
  // HELPER: Ambil user data dari cache
  // ============================================
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData == null) return null;
    try {
      return jsonDecode(userData) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ============================================
  // UPDATE JASTIP STATUS (buat runner/requester)
  // ============================================
  Future<Response> updateJastipStatus(int id, String status) async {
    try {
      return await _dio.post('/jastips/$id/status', data: {'status': status});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================
  // RATING
  // ============================================
  Future<Response> submitRating({
    required String rateableType,
    required int rateableId,
    required int stars,
    String? review,
  }) async {
    try {
      return await _dio.post(
        '/ratings',
        data: {
          'rateable_type': rateableType,
          'rateable_id': rateableId,
          'stars': stars,
          'review': review,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> checkRatingStatus(String type, int id) async {
    try {
      return await _dio.get('/ratings/status/$type/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================
  // JASTIP HISTORY
  // ============================================
  Future<Response> getHistory() async {
    try {
      return await _dio.get('/jastips/history');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================
  // TEBENGAN
  // ============================================
  Future<Response> getTebengans({String? status}) async {
    try {
      final query = status != null ? {'status': status} : null;
      return await _dio.get('/tebengans', queryParameters: query);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> createTebengan({
    required String pickupLocation,
    required String destination,
    required String departureTime, // ISO 8601 string
    required double budget,
    double fee = 0,
    required String whatsappNumber,
  }) async {
    try {
      return await _dio.post(
        '/tebengans',
        data: {
          'pickup_location': pickupLocation,
          'destination': destination,
          'departure_time': departureTime,
          'budget': budget,
          'fee': fee,
          'whatsapp_number': whatsappNumber,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> takeTebengan(int id) async {
    try {
      return await _dio.post('/tebengans/$id/take');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> updateTebenganStatus(int id, String status) async {
    try {
      return await _dio.post('/tebengans/$id/status', data: {'status': status});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> getMyTebengans() async {
    try {
      return await _dio.get('/tebengans/my-orders');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> getTebenganHistory() async {
    try {
      return await _dio.get('/tebengans/history');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}
