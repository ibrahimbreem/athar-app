import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // ─── Cloudinary Config ─────────────────────────────────────────────────────
  // 1. سجّل في cloudinary.com (مجاني)
  // 2. انسخ Cloud Name من Dashboard
  // 3. اذهب Settings → Upload → Upload Presets → أضف preset بـ Signing Mode: Unsigned
  static const String _cloudName = 'dn3epbdrh';
  static const String _uploadPreset = 'athar-app';
  // ──────────────────────────────────────────────────────────────────────────

  static String get _uploadUrl =>
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  final ImagePicker _picker = ImagePicker();
  final _uuid = const Uuid();

  Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  Future<List<File>> pickMultipleImages({int max = 5}) async {
    final picked = await _picker.pickMultiImage(
      imageQuality: 80,
      maxWidth: 1200,
    );
    return picked.map((x) => File(x.path)).take(max).toList();
  }

  Future<String> _uploadToCloudinary(
    File file, {
    String? folder,
    Function(double)? onProgress,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
    request.fields['upload_preset'] = _uploadPreset;
    request.fields['public_id'] = _uuid.v4();
    if (folder != null) request.fields['folder'] = folder;

    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw Exception('فشل رفع الصورة: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['secure_url'] as String;
  }

  Future<String> uploadCampaignImage(
    File file,
    String organizationId, {
    Function(double)? onProgress,
  }) async {
    return _uploadToCloudinary(
      file,
      folder: 'athar/campaigns/$organizationId',
      onProgress: onProgress,
    );
  }

  Future<String> uploadUserAvatar(File file, String userId) async {
    return _uploadToCloudinary(file, folder: 'athar/avatars');
  }

  Future<List<String>> uploadMultipleImages(
    List<File> files,
    String organizationId, {
    Function(double)? onProgress,
  }) async {
    final urls = <String>[];
    for (int i = 0; i < files.length; i++) {
      final url = await uploadCampaignImage(
        files[i],
        organizationId,
        onProgress: onProgress != null
            ? (p) => onProgress((i + p) / files.length)
            : null,
      );
      urls.add(url);
    }
    return urls;
  }

  Future<void> deleteFile(String url) async {
    // الحذف يتم من Cloudinary Dashboard مباشرة
    // (يحتاج API Secret غير آمن وضعه في التطبيق)
  }
}
