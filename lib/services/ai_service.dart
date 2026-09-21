import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/reality.dart';

abstract interface class AIService {
  Future<String> generateAlternateReality(String input, RealityMode mode);
}

abstract final class AlternateRealityPrompt {
  static String system(RealityMode mode) =>
      '''You are the Alternate Reality engine. Reinterpret the user's statement through a ${mode.label.toLowerCase()} lens. Do not insult the user or blindly predict failure. Identify a connected disappointment, uncomfortable possibility, cynical interpretation, or thing that could go wrong. Be intelligent, human, concise, memorable, slightly unsettling, and occasionally darkly funny. Preserve the subject. Never encourage self-harm, suicide, violence, crime, abuse, threats, harassment, or dangerous activity. If the user indicates self-harm, suicide, imminent danger, or severe distress, respond supportively and encourage immediate contact with a trusted person or local emergency/crisis services. Return only one plain-text transformed statement, under 70 words.''';
}

class OpenAICompatibleService implements AIService {
  OpenAICompatibleService({http.Client? client})
    : client = client ?? http.Client();
  final http.Client client;
  static const apiKey = String.fromEnvironment('AI_API_KEY');
  static const baseUrl = String.fromEnvironment(
    'AI_BASE_URL',
    defaultValue: 'https://api.openai.com/v1',
  );
  static const model = String.fromEnvironment(
    'AI_MODEL',
    defaultValue: 'gpt-4.1-mini',
  );
  @override
  Future<String> generateAlternateReality(
    String input,
    RealityMode mode,
  ) async {
    if (apiKey.isEmpty) {
      return LocalFallbackAIService().generateAlternateReality(input, mode);
    }
    final response = await client
        .post(
          Uri.parse('$baseUrl/chat/completions'),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': model,
            'temperature': .9,
            'messages': [
              {
                'role': 'system',
                'content': AlternateRealityPrompt.system(mode),
              },
              {'role': 'user', 'content': input},
            ],
          }),
        )
        .timeout(const Duration(seconds: 25));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const AIServiceException();
    }
    final data = jsonDecode(response.body) as Map<String, Object?>;
    final choices = data['choices'] as List<Object?>?;
    final first = choices == null || choices.isEmpty
        ? null
        : choices.first as Map<String, Object?>;
    return validate(
      (first?['message'] as Map<String, Object?>?)?['content'] as String?,
    );
  }

  static String validate(String? value) {
    final text = value?.trim().replaceAll(RegExp(r'^```|```$'), '');
    if (text == null ||
        text.isEmpty ||
        text.length > 600 ||
        text.startsWith('{')) {
      throw const AIServiceException();
    }
    return text;
  }
}

class LocalFallbackAIService implements AIService {
  @override
  Future<String> generateAlternateReality(
    String input,
    RealityMode mode,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (RegExp(
      r'kill myself|suicide|end my life|hurt myself',
      caseSensitive: false,
    ).hasMatch(input)) {
      return 'This thought deserves attention, not punishment. Please contact someone you trust now, and reach local emergency or crisis support if you may be in immediate danger.';
    }
    final subject = input.trim().replaceFirst(RegExp(r'[.!?]+$'), '');
    return switch (mode) {
      RealityMode.cynical =>
        '$subject — because even good news eventually finds someone willing to profit from it.',
      RealityMode.darkHumor =>
        '$subject. At least the plot is giving future you something complicated to laugh about.',
      RealityMode.worstCase =>
        '$subject. Now imagine every small warning you ignored arriving at once.',
      RealityMode.uncomfortableTruth =>
        '$subject. Wanting it badly does not make you ready for what it asks in return.',
      RealityMode.existential =>
        '$subject. For a moment it matters completely; eventually, not even the memory will notice.',
      RealityMode.sarcastic =>
        '$subject. Surely reality has never punished confidence delivered that early.',
      RealityMode.pessimistic =>
        '$subject. Enjoy the certainty while it lasts; reality usually waits until you relax.',
    };
  }
}

class AIServiceException implements Exception {
  const AIServiceException();
}
