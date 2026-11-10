import 'dart:async';
import 'dart:convert';

import 'package:alternate_reality/features/perspectives/data/ai_service.dart';
import 'package:alternate_reality/features/perspectives/domain/reality.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const config = AIConfiguration(
  baseUrl: 'https://ai.example.com/api',
  accessToken: 'test-token-at-least-32-characters-long',
);
void main() {
  test(
    'each mode travels to the backend without provider credentials',
    () async {
      for (final mode in RealityMode.values) {
        final client = MockClient((request) async {
          expect(request.url.toString(), 'https://ai.example.com/api/reality');
          expect(jsonDecode(request.body), {
            'input': 'She enjoys her job.',
            'mode': mode.name,
          });
          expect(
            request.headers['Authorization'],
            'Bearer ${config.accessToken}',
          );
          return http.Response(
            jsonEncode({'text': 'She does not enjoy her job.'}),
            200,
          );
        });
        final service = BackendAIService(client: client, configuration: config);
        expect(
          await service.generateAlternateReality(' She enjoys her job. ', mode),
          'She does not enjoy her job.',
        );
        service.close();
      }
    },
  );
  test('missing config never returns a fake transformation', () async {
    final service = BackendAIService(
      client: MockClient((_) async => throw StateError('must not call')),
      configuration: const AIConfiguration(),
    );
    await expectLater(
      service.generateAlternateReality('I feel ready', RealityMode.pessimistic),
      throwsA(
        isA<AIServiceException>().having(
          (e) => e.message,
          'message',
          contains('not connected'),
        ),
      ),
    );
  });
  test('configuration allows HTTP only for local debug connections', () {
    for (final url in [
      'http://example.com',
      'file:///tmp/model',
      'https://user:pass@example.com',
      'https://example.com?key=secret',
    ]) {
      expect(
        AIConfiguration(
          baseUrl: url,
          accessToken: config.accessToken,
        ).isConfigured,
        isFalse,
      );
    }
    expect(
      AIConfiguration(
        baseUrl: 'http://127.0.0.1:8787',
        accessToken: config.accessToken,
        allowLocalHttp: true,
      ).isConfigured,
      isTrue,
    );
    expect(
      AIConfiguration(
        baseUrl: 'http://127.0.0.1:8787',
        accessToken: config.accessToken,
        allowLocalHttp: false,
      ).isConfigured,
      isFalse,
    );
  });
  test('new and old history modes round trip without index migration', () {
    for (final mode in RealityMode.values) {
      final entry = RealityEntry(
        id: '1',
        originalText: 'Thought',
        alternateText: 'Perspective',
        mode: mode,
        createdAt: DateTime.utc(2026),
      );
      expect(RealityEntry.fromJson(entry.toJson()).mode, mode);
    }
  });
  test(
    'provider errors, invalid JSON and malformed results are rejected',
    () async {
      for (final response in [
        http.Response('private upstream details', 502),
        http.Response('invalid json', 200),
        http.Response('[]', 200),
        http.Response('{"text":""}', 200),
        http.Response('{"text":42}', 200),
        http.Response('{"text":"{debug}"}', 200),
      ]) {
        final service = BackendAIService(
          client: MockClient((_) async => response),
          configuration: config,
        );
        await expectLater(
          service.generateAlternateReality('Hello', RealityMode.positive),
          throwsA(isA<AIServiceException>()),
        );
      }
    },
  );
  test(
    'known backend errors are actionable without revealing server response',
    () async {
      for (final item in {
        401: 'invitation',
        429: 'Wait a minute',
        503: 'temporarily unavailable',
        504: 'too long',
      }.entries) {
        final service = BackendAIService(
          client: MockClient(
            (_) async => http.Response('private details', item.key),
          ),
          configuration: config,
        );
        await expectLater(
          service.generateAlternateReality('Hello', RealityMode.positive),
          throwsA(
            isA<AIServiceException>().having(
              (e) => e.message,
              'message',
              contains(item.value),
            ),
          ),
        );
      }
    },
  );
  test('network and timeout errors are actionable', () async {
    final network = BackendAIService(
      client: MockClient(
        (_) async => throw http.ClientException('private host'),
      ),
      configuration: config,
    );
    await expectLater(
      network.generateAlternateReality('Hello', RealityMode.positive),
      throwsA(
        isA<AIServiceException>().having(
          (e) => e.message,
          'message',
          contains('Cannot reach'),
        ),
      ),
    );
    final timeout = BackendAIService(
      client: MockClient((_) => Completer<http.Response>().future),
      configuration: config,
      timeout: const Duration(milliseconds: 1),
    );
    await expectLater(
      timeout.generateAlternateReality('Hello', RealityMode.positive),
      throwsA(
        isA<AIServiceException>().having(
          (e) => e.message,
          'message',
          contains('too long'),
        ),
      ),
    );
  });
  test('supportive safeguard works in every mode even before setup', () async {
    final service = BackendAIService(
      client: MockClient((_) async => throw StateError('must not call')),
    );
    for (final mode in RealityMode.values) {
      expect(
        await service.generateAlternateReality('I want to kill myself', mode),
        contains('someone you trust'),
      );
    }
  });
  test('empty and overlong input is rejected before network use', () async {
    final service = BackendAIService(
      client: MockClient((_) async => throw StateError('must not call')),
    );
    for (final input in ['', 'x' * 601]) {
      await expectLater(
        service.generateAlternateReality(input, RealityMode.literalNegation),
        throwsA(isA<AIServiceException>()),
      );
    }
  });
}
