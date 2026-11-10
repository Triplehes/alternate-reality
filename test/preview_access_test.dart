import 'package:alternate_reality/features/perspectives/data/ai_service.dart';
import 'package:alternate_reality/features/preview_access/application/access_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const code = 'a-personal-invitation-with-at-least-32-characters';
  const config = AIConfiguration(baseUrl: 'https://preview.example/api');
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test('verified invitation persists securely and can be removed', () async {
    final container = ProviderContainer(
      overrides: [
        invitationClientProvider.overrideWithValue(
          () => MockClient((request) async {
            expect(
              request.url.toString(),
              'https://preview.example/api/access',
            );
            expect(request.headers['Authorization'], 'Bearer $code');
            return http.Response('', 204);
          }),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(accessProvider.future);
    await container.read(accessProvider.notifier).join(code, config);
    expect(container.read(accessProvider).value, code);
    final restarted = ProviderContainer();
    addTearDown(restarted.dispose);
    expect(await restarted.read(accessProvider.future), code);
    await restarted.read(accessProvider.notifier).leave();
    expect(restarted.read(accessProvider).value, '');
    expect(
      await const FlutterSecureStorage().read(key: 'preview_invitation_v2'),
      isNull,
    );
  });
  test(
    'rejected invitation preserves existing access and never saves replacement',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        'preview_invitation_v2': code,
      });
      final container = ProviderContainer(
        overrides: [
          invitationClientProvider.overrideWithValue(
            () => MockClient(
              (_) async => http.Response('private server details', 401),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(accessProvider.future);
      await expectLater(
        container
            .read(accessProvider.notifier)
            .join('another-personal-invitation-with-32-characters', config),
        throwsA(isA<AIServiceException>()),
      );
      expect(container.read(accessProvider).value, code);
      expect(
        await const FlutterSecureStorage().read(key: 'preview_invitation_v2'),
        code,
      );
    },
  );
}
