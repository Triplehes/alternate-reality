import 'package:alternate_reality/features/perspectives/data/ai_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

final invitationClientProvider = Provider<http.Client Function()>(
  (ref) => http.Client.new,
);

final accessProvider = AsyncNotifierProvider<AccessController, String>(
  AccessController.new,
);

class AccessController extends AsyncNotifier<String> {
  static const _storage = FlutterSecureStorage();
  static const _key = 'preview_invitation_v2';
  @override
  Future<String> build() async {
    // Browser invitations last only for this session. Never store bearer codes
    // in localStorage, where any script on the origin can read them.
    if (kIsWeb) return '';
    return await _storage.read(key: _key) ?? '';
  }

  Future<void> join(String code, AIConfiguration config) async {
    final token = code.trim();
    final endpoint = config.endpoint;
    if (endpoint == null ||
        token.length < 32 ||
        token.length > 256 ||
        RegExp(r'\s').hasMatch(token)) {
      throw const AIServiceException('Enter the invitation code you received.');
    }
    final client = ref.read(invitationClientProvider)();
    try {
      final response = await client
          .post(
            endpoint.replace(
              path: endpoint.path.replaceFirst(RegExp(r'/reality$'), '/access'),
            ),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 204) {
        throw const AIServiceException(
          'This invitation could not be verified. Check the code or ask for a new invitation.',
        );
      }
      if (!kIsWeb) await _storage.write(key: _key, value: token);
      state = AsyncData(token);
    } on AIServiceException {
      rethrow;
    } catch (_) {
      throw const AIServiceException(
        'Could not activate your invitation. Check your connection and try again.',
      );
    } finally {
      client.close();
    }
  }

  Future<void> leave() async {
    if (!kIsWeb) await _storage.delete(key: _key);
    state = const AsyncData('');
  }
}
