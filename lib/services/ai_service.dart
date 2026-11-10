import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../domain/reality.dart';

abstract interface class AIService {
  Future<String> generateAlternateReality(String input, RealityMode mode);
}

/// The provider API key is loaded exclusively by server/server.mjs.
class AIConfiguration {
  const AIConfiguration({
    this.baseUrl = const String.fromEnvironment('AI_BACKEND_URL'),
    this.accessToken = kReleaseMode
        ? ''
        : const String.fromEnvironment('AI_BACKEND_TOKEN'),
    this.allowLocalHttp = !kReleaseMode,
  });
  final String baseUrl;
  final String accessToken;
  final bool allowLocalHttp;

  Uri? get endpoint {
    final uri = Uri.tryParse(baseUrl.trim());
    if (uri == null ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      return null;
    }
    final local = [
      'localhost',
      '127.0.0.1',
      '::1',
      '10.0.2.2',
    ].contains(uri.host);
    if (uri.scheme != 'https' &&
        !(allowLocalHttp && local && uri.scheme == 'http')) {
      return null;
    }
    return uri.replace(
      path: '${uri.path.replaceFirst(RegExp(r'/+$'), '')}/reality',
    );
  }

  bool get isConfigured =>
      endpoint != null &&
      accessToken.length >= 32 &&
      !accessToken.startsWith('replace_');
}

class BackendAIService implements AIService {
  BackendAIService({
    http.Client? client,
    this.configuration = const AIConfiguration(),
    this.timeout = const Duration(seconds: 35),
  }) : client = client ?? http.Client();
  final http.Client client;
  final AIConfiguration configuration;
  final Duration timeout;
  void close() => client.close();

  @override
  Future<String> generateAlternateReality(
    String input,
    RealityMode mode,
  ) async {
    final clean = input.trim();
    if (clean.isEmpty || clean.length > 600) {
      throw const AIServiceException(
        'Enter a thought between 1 and 600 characters.',
      );
    }
    // This limited offline safeguard provides support, never a fake AI rewrite.
    if (RegExp(
      r'\b(kill myself|suicide|end my life|hurt myself|harm myself|take my own life)\b',
      caseSensitive: false,
    ).hasMatch(clean)) {
      return 'This thought deserves care. Please contact someone you trust now. If you may act on it or are in immediate danger, contact local emergency or crisis support.';
    }
    if (!configuration.isConfigured) {
      throw const AIServiceException(
        'AI is not connected yet. Please try again later.',
      );
    }
    try {
      final response = await client
          .post(
            configuration.endpoint!,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${configuration.accessToken}',
            },
            body: jsonEncode({'input': clean, 'mode': mode.name}),
          )
          .timeout(timeout);
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const AIServiceException(
          'Your preview access could not be verified. Check your invitation in Settings or contact the person who invited you.',
        );
      }
      if (response.statusCode == 429) {
        throw const AIServiceException(
          'You have reached a preview limit. Wait a minute and try again. Daily limits reset tomorrow (UTC).',
        );
      }
      if (response.statusCode == 503) {
        throw const AIServiceException(
          'Perspectives are temporarily unavailable. Please try again later.',
        );
      }
      if (response.statusCode == 504) {
        throw const AIServiceException(
          'The AI took too long to respond. Please try again.',
        );
      }
      if (response.statusCode != 200) throw const AIServiceException();
      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic> || data['text'] is! String) {
        throw const AIServiceException();
      }
      return validate(data['text'] as String);
    } on AIServiceException {
      rethrow;
    } on TimeoutException {
      throw const AIServiceException(
        'The AI took too long to respond. Please try again.',
      );
    } on http.ClientException {
      throw const AIServiceException(
        'Cannot reach perspectives right now. Check your internet connection and try again.',
      );
    } catch (_) {
      throw const AIServiceException();
    }
  }

  static String validate(String value) {
    final text = value.trim();
    if (text.isEmpty ||
        text.length > 600 ||
        RegExp(r'^[{\[]|^```').hasMatch(text)) {
      throw const AIServiceException();
    }
    return text;
  }
}

class AIServiceException implements Exception {
  const AIServiceException([
    this.message =
        'The AI could not create a perspective this time. Please try again.',
  ]);
  final String message;
}
