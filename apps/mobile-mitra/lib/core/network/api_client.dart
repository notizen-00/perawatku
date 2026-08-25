import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../config/api_config.dart';
import '../services/auth_session.dart';

class ApiClient {
  ApiClient(this._session, {HttpClient? httpClient})
    : _httpClient = httpClient ?? HttpClient();

  final AuthSession _session;
  final HttpClient _httpClient;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, Object?>? queryParameters,
  }) {
    return _request(
      method: 'GET',
      path: path,
      queryParameters: queryParameters,
    );
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) {
    return _request(method: 'POST', path: path, body: body);
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) {
    return _request(method: 'PATCH', path: path, body: body);
  }

  Future<Map<String, dynamic>> delete(String path) {
    return _request(method: 'DELETE', path: path);
  }

  Future<Map<String, dynamic>> postMultipartFile({
    required String path,
    required String fieldName,
    required String filePath,
    Map<String, String>? fields,
  }) async {
    final uri = Uri.parse('${ApiConfig.apiBaseUrl}$path');
    final boundary = '----mitra-perawatku-${DateTime.now().microsecondsSinceEpoch}';
    final file = File(filePath);
    final fileName = file.uri.pathSegments.isEmpty
        ? 'upload.jpg'
        : file.uri.pathSegments.last;

    try {
      final request = await _httpClient
          .postUrl(uri)
          .timeout(const Duration(seconds: 20));

      for (final header in _session.headers.entries) {
        if (header.key.toLowerCase() != 'content-type') {
          request.headers.set(header.key, header.value);
        }
      }
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'multipart/form-data; boundary=$boundary',
      );

      for (final entry in (fields ?? const <String, String>{}).entries) {
        request.write('--$boundary\r\n');
        request.write(
          'Content-Disposition: form-data; name="${entry.key}"\r\n\r\n',
        );
        request.write('${entry.value}\r\n');
      }

      request.write('--$boundary\r\n');
      request.write(
        'Content-Disposition: form-data; name="$fieldName"; filename="$fileName"\r\n',
      );
      request.write('Content-Type: ${_contentType(fileName)}\r\n\r\n');
      await request.addStream(file.openRead());
      request.write('\r\n--$boundary--\r\n');

      final response = await request.close().timeout(
        const Duration(seconds: 45),
      );
      final payload = await response.transform(utf8.decoder).join();
      final decoded = payload.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(payload);

      if (decoded is! Map<String, dynamic>) {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Format respons server tidak dikenali.',
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (response.statusCode == 401) {
          await _session.clear();
        }

        throw ApiException(
          statusCode: response.statusCode,
          message: _extractMessage(decoded),
          errors: decoded['errors'],
        );
      }

      return decoded;
    } on ApiException {
      rethrow;
    } on SocketException catch (error) {
      throw ApiException(statusCode: 0, message: error.message);
    } on TimeoutException {
      throw const ApiException(
        statusCode: 0,
        message: 'Koneksi ke server terlalu lama.',
      );
    } on FormatException {
      throw const ApiException(
        statusCode: 0,
        message: 'Respons server bukan JSON valid.',
      );
    }
  }

  /// Multipart POST supporting an optional single file plus scalar and
  /// list-typed fields (e.g. a checklist) in one request. Unlike
  /// [postMultipartFile], the file itself is optional here -- some callers
  /// (e.g. "tambah tindakan") only attach a checklist, only a photo, or both.
  Future<Map<String, dynamic>> postMultipart(
    String path, {
    Map<String, String>? fields,
    Map<String, List<String>>? listFields,
    String? fileFieldName,
    String? filePath,
  }) async {
    final uri = Uri.parse('${ApiConfig.apiBaseUrl}$path');
    final boundary = '----mitra-perawatku-${DateTime.now().microsecondsSinceEpoch}';

    try {
      final request = await _httpClient
          .postUrl(uri)
          .timeout(const Duration(seconds: 20));

      for (final header in _session.headers.entries) {
        if (header.key.toLowerCase() != 'content-type') {
          request.headers.set(header.key, header.value);
        }
      }
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'multipart/form-data; boundary=$boundary',
      );

      void writeField(String name, String value) {
        request.write('--$boundary\r\n');
        request.write(
          'Content-Disposition: form-data; name="$name"\r\n\r\n',
        );
        request.write('$value\r\n');
      }

      for (final entry in (fields ?? const <String, String>{}).entries) {
        writeField(entry.key, entry.value);
      }

      for (final entry in (listFields ?? const <String, List<String>>{}).entries) {
        for (final value in entry.value) {
          writeField('${entry.key}[]', value);
        }
      }

      if (fileFieldName != null && filePath != null) {
        final file = File(filePath);
        final fileName = file.uri.pathSegments.isEmpty
            ? 'upload.jpg'
            : file.uri.pathSegments.last;
        request.write('--$boundary\r\n');
        request.write(
          'Content-Disposition: form-data; name="$fileFieldName"; filename="$fileName"\r\n',
        );
        request.write('Content-Type: ${_contentType(fileName)}\r\n\r\n');
        await request.addStream(file.openRead());
        request.write('\r\n');
      }

      request.write('--$boundary--\r\n');

      final response = await request.close().timeout(
        const Duration(seconds: 45),
      );
      final payload = await response.transform(utf8.decoder).join();
      final decoded = payload.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(payload);

      if (decoded is! Map<String, dynamic>) {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Format respons server tidak dikenali.',
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (response.statusCode == 401) {
          await _session.clear();
        }

        throw ApiException(
          statusCode: response.statusCode,
          message: _extractMessage(decoded),
          errors: decoded['errors'],
        );
      }

      return decoded;
    } on ApiException {
      rethrow;
    } on SocketException catch (error) {
      throw ApiException(statusCode: 0, message: error.message);
    } on TimeoutException {
      throw const ApiException(
        statusCode: 0,
        message: 'Koneksi ke server terlalu lama.',
      );
    } on FormatException {
      throw const ApiException(
        statusCode: 0,
        message: 'Respons server bukan JSON valid.',
      );
    }
  }

  /// Multipart PATCH with one or more named files (e.g. `str_photo` +
  /// `ktp_photo` together). PHP never populates the request body for a real
  /// multipart PUT/PATCH, so this sends a POST with Laravel's `_method`
  /// override field instead -- the standard way to submit files to a PATCH
  /// route.
  Future<Map<String, dynamic>> patchMultipart(
    String path, {
    Map<String, String>? fields,
    Map<String, String>? files,
  }) async {
    final uri = Uri.parse('${ApiConfig.apiBaseUrl}$path');
    final boundary = '----mitra-perawatku-${DateTime.now().microsecondsSinceEpoch}';

    try {
      final request = await _httpClient
          .postUrl(uri)
          .timeout(const Duration(seconds: 20));

      for (final header in _session.headers.entries) {
        if (header.key.toLowerCase() != 'content-type') {
          request.headers.set(header.key, header.value);
        }
      }
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'multipart/form-data; boundary=$boundary',
      );

      void writeField(String name, String value) {
        request.write('--$boundary\r\n');
        request.write(
          'Content-Disposition: form-data; name="$name"\r\n\r\n',
        );
        request.write('$value\r\n');
      }

      writeField('_method', 'PATCH');
      for (final entry in (fields ?? const <String, String>{}).entries) {
        writeField(entry.key, entry.value);
      }

      for (final entry in (files ?? const <String, String>{}).entries) {
        final file = File(entry.value);
        final fileName = file.uri.pathSegments.isEmpty
            ? 'upload.jpg'
            : file.uri.pathSegments.last;
        request.write('--$boundary\r\n');
        request.write(
          'Content-Disposition: form-data; name="${entry.key}"; filename="$fileName"\r\n',
        );
        request.write('Content-Type: ${_contentType(fileName)}\r\n\r\n');
        await request.addStream(file.openRead());
        request.write('\r\n');
      }

      request.write('--$boundary--\r\n');

      final response = await request.close().timeout(
        const Duration(seconds: 45),
      );
      final payload = await response.transform(utf8.decoder).join();
      final decoded = payload.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(payload);

      if (decoded is! Map<String, dynamic>) {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Format respons server tidak dikenali.',
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (response.statusCode == 401) {
          await _session.clear();
        }

        throw ApiException(
          statusCode: response.statusCode,
          message: _extractMessage(decoded),
          errors: decoded['errors'],
        );
      }

      return decoded;
    } on ApiException {
      rethrow;
    } on SocketException catch (error) {
      throw ApiException(statusCode: 0, message: error.message);
    } on TimeoutException {
      throw const ApiException(
        statusCode: 0,
        message: 'Koneksi ke server terlalu lama.',
      );
    } on FormatException {
      throw const ApiException(
        statusCode: 0,
        message: 'Respons server bukan JSON valid.',
      );
    }
  }

  Future<Map<String, dynamic>> _request({
    required String method,
    required String path,
    Map<String, Object?>? queryParameters,
    Map<String, dynamic>? body,
  }) async {
    final filteredQuery = queryParameters == null
        ? null
        : Map.fromEntries(
            queryParameters.entries
                .where((entry) => entry.value != null)
                .map((entry) => MapEntry(entry.key, entry.value.toString())),
          );
    final uri = Uri.parse(
      '${ApiConfig.apiBaseUrl}$path',
    ).replace(queryParameters: filteredQuery);

    try {
      final request = await _httpClient
          .openUrl(method, uri)
          .timeout(const Duration(seconds: 20));

      for (final header in _session.headers.entries) {
        request.headers.set(header.key, header.value);
      }

      if (body != null) {
        request.write(jsonEncode(body));
      }

      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      final payload = await response.transform(utf8.decoder).join();
      final decoded = payload.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(payload);

      if (decoded is! Map<String, dynamic>) {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Format respons server tidak dikenali.',
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (response.statusCode == 401) {
          await _session.clear();
        }

        throw ApiException(
          statusCode: response.statusCode,
          message: _extractMessage(decoded),
          errors: decoded['errors'],
        );
      }

      return decoded;
    } on ApiException {
      rethrow;
    } on SocketException catch (error) {
      throw ApiException(statusCode: 0, message: error.message);
    } on TimeoutException {
      throw const ApiException(
        statusCode: 0,
        message: 'Koneksi ke server terlalu lama.',
      );
    } on FormatException {
      throw const ApiException(
        statusCode: 0,
        message: 'Respons server bukan JSON valid.',
      );
    }
  }

  /// Prefers `errors` (Laravel's per-field validation messages) over the
  /// top-level `message`, because Laravel's `ValidationException` summary
  /// only keeps the *first* field's message and truncates the rest into a
  /// vague "(and N more errors)" suffix -- that reads as a meaningless
  /// error to users when e.g. both email and phone are already taken.
  /// Joining every field's message instead shows the real, complete reason.
  String _extractMessage(Map<String, dynamic> json) {
    final errors = json['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final messages = <String>[];
      for (final value in errors.values) {
        if (value is List) {
          messages.addAll(value.map((item) => item.toString()));
        } else if (value != null) {
          messages.add(value.toString());
        }
      }
      if (messages.isNotEmpty) {
        return messages.join('\n');
      }
    }

    final message = json['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message;
    }

    return 'Request gagal diproses server.';
  }

  String _contentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'jpg' || 'jpeg' => 'image/jpeg',
      'pdf' => 'application/pdf',
      _ => 'application/octet-stream',
    };
  }
}

class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.message,
    this.errors,
  });

  final int statusCode;
  final String message;
  final Object? errors;

  @override
  String toString() => message;
}
