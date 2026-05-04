import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class ClarityApiService {
  static String get baseUrl {
    return 'https://synthora-backend-jncc.onrender.com';
  }

  final ImagePicker _picker = ImagePicker();

  Future<List<XFile>> pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    return images.take(10).toList(); // Max 10 per request
  }

  Future<int> fetchUserCredits() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 50; // default for guest
      final token = await user.getIdToken();
      final response = await http.get(
        Uri.parse('\$baseUrl/user-credits'),
        headers: {'Authorization': 'Bearer \$token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['credits'] ?? 50;
      }
    } catch (e) {
      print('Fetch credits error: \$e');
    }
    return 50;
  }

  Future<int?> verifyPayment() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      final token = await user.getIdToken();
      final response = await http.post(
        Uri.parse('\$baseUrl/verify-payment'),
        headers: {'Authorization': 'Bearer \$token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['new_balance'];
      }
    } catch (e) {
      print('Verify payment error: \$e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> enhanceImages(List<XFile> files, {double fidelityWeight = 0.5}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = user != null ? await user.getIdToken() : 'dummy-token';

      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload-images'));
      
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['fidelity_weight'] = fidelityWeight.toString();
      
      for (var file in files) {
        if (kIsWeb) {
          var bytes = await file.readAsBytes();
          var multipartFile = http.MultipartFile.fromBytes(
            'images',
            bytes,
            filename: file.name,
          );
          request.files.add(multipartFile);
        } else {
          var multipartFile = await http.MultipartFile.fromPath('images', file.path);
          request.files.add(multipartFile);
        }
      }
      
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var json = jsonDecode(responseData);
      
      if (response.statusCode == 200 && json['success'] == true) {
         return {
           'enhanced_url': '$baseUrl${json['enhanced_url']}',
           'extracted_features': json['extracted_features'],
           'overall_score': json['overall_score'],
         };
      } else {
         print("Error enhancing: ${json['error']}");
      }
    } catch (e) {
      print("Exception in enhanceImages: $e");
    }
    return null;
  }

  /// Multi-image feature synthesis: extract best features from each image
  /// and composite them into a single output.
  Future<Map<String, dynamic>?> synthesizeFeatures(List<XFile> files, {double fidelityWeight = 0.5}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = user != null ? await user.getIdToken() : 'dummy-token';

      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/synthesize-features'));
      
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['fidelity_weight'] = fidelityWeight.toString();
      
      for (var file in files) {
        if (kIsWeb) {
          var bytes = await file.readAsBytes();
          var multipartFile = http.MultipartFile.fromBytes(
            'images',
            bytes,
            filename: file.name,
          );
          request.files.add(multipartFile);
        } else {
          var multipartFile = await http.MultipartFile.fromPath('images', file.path);
          request.files.add(multipartFile);
        }
      }
      
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var json = jsonDecode(responseData);
      
      if (response.statusCode == 200 && json['success'] == true) {
         return {
           'enhanced_url': '$baseUrl${json['enhanced_url']}',
           'extracted_features': json['extracted_features'],
           'per_image_analysis': json['per_image_analysis'],
           'overall_score': json['overall_score'],
           'source_count': json['source_count'],
         };
      } else {
         print("Error synthesizing: ${json['detail'] ?? json['error']}");
      }
    } catch (e) {
      print("Exception in synthesizeFeatures: $e");
    }
    return null;
  }

  Future<List<dynamic>> fetchUserHistory() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = user != null ? await user.getIdToken() : 'dummy-token';

      final response = await http.get(
        Uri.parse('$baseUrl/user-history'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        if (json['success'] == true) {
          return json['history'] as List<dynamic>;
        }
      }
      print("Error fetching history: ${response.body}");
    } catch (e) {
      print("Exception in fetchUserHistory: $e");
    }
    return [];
  }

  Future<void> openUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      print('Could not launch $urlString');
    }
  }
}
