import 'package:alternate_reality/features/perspectives/data/ai_service.dart';
import 'package:alternate_reality/features/preview_access/application/access_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final aiConfigurationProvider = Provider((ref) {
  const builtIn = AIConfiguration();
  final invitation = ref.watch(accessProvider).value ?? '';
  return AIConfiguration(
    baseUrl: builtIn.baseUrl,
    accessToken: invitation.isEmpty ? builtIn.accessToken : invitation,
  );
});
final aiServiceProvider = Provider<AIService>((ref) {
  final service = BackendAIService(
    configuration: ref.watch(aiConfigurationProvider),
  );
  ref.onDispose(service.close);
  return service;
});
