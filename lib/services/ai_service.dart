import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/reality.dart';

abstract interface class AIService {
  Future<String> generateAlternateReality(String input, RealityMode mode);
}

abstract final class AlternateRealityPrompt {
  static String system(RealityMode mode) =>
      '''You are the Alternate Reality engine. Turn the user's statement into its direct, literal negative opposite. Preserve the speaker, tense, meaning, clause order, and wording wherever possible. Negate confidence, success, ability, certainty, and positive outcomes instead of adding commentary. Example: "I will make it, I know I will make it" becomes "I will not make it, I know I won't make it." Return only the transformed statement. Never repeat or preface it with the original input. The selected tone is ${mode.label.toLowerCase()}, but literal negation is more important than creative interpretation. Do not insult the user or invent unrelated facts. Never encourage self-harm, suicide, violence, crime, abuse, threats, harassment, or dangerous activity. If the input indicates self-harm, suicide, imminent danger, or severe distress, do not negate it; respond supportively and encourage immediate contact with a trusted person or local emergency/crisis services. Keep the result concise, plain text, and under 70 words.''';
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
            'temperature': .2,
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
    return LiteralNegativeEngine.transform(input);
  }
}

/// A small, private, deterministic language layer for common positive clauses.
/// Complex statements can still use the configured AI provider, while ordinary
/// inputs are negated instantly without a network request or an embedded model.
abstract final class LiteralNegativeEngine {
  static String transform(String input) {
    var result = input.trim();
    if (result.isEmpty) return result;

    // If the user already used an explicit negation, invert that negation first.
    // This keeps the operation an actual opposite rather than creating doubles.
    final negativePatterns = <(RegExp, String)>[
      (RegExp(r"\bwon't\b", caseSensitive: false), 'will'),
      (RegExp(r"\bcan't\b|\bcannot\b", caseSensitive: false), 'can'),
      (RegExp(r"\bdon't\b", caseSensitive: false), 'do'),
      (RegExp(r"\bdoesn't\b", caseSensitive: false), 'does'),
      (RegExp(r"\bdidn't\b", caseSensitive: false), 'did'),
      (RegExp(r"\bisn't\b", caseSensitive: false), 'is'),
      (RegExp(r"\baren't\b", caseSensitive: false), 'are'),
      (RegExp(r"\bwasn't\b", caseSensitive: false), 'was'),
      (RegExp(r"\bweren't\b", caseSensitive: false), 'were'),
      (RegExp(r"\bhaven't\b", caseSensitive: false), 'have'),
      (RegExp(r"\bhasn't\b", caseSensitive: false), 'has'),
      (RegExp(r"\bhadn't\b", caseSensitive: false), 'had'),
      (RegExp(r'\bwill\s+not\b', caseSensitive: false), 'will'),
      (RegExp(r'\bnot\s+', caseSensitive: false), ''),
    ];
    for (final (pattern, replacement) in negativePatterns) {
      if (pattern.hasMatch(result)) {
        return result.replaceAll(pattern, replacement).trim();
      }
    }

    var changed = false;
    result = result.replaceAllMapped(
      RegExp(r'\b(I\s+know\s+I|i\s+know\s+i)\s+will\b'),
      (match) {
        changed = true;
        return '${match.group(1)} won\'t';
      },
    );
    result = result.replaceAllMapped(
      RegExp(r"\b(I|You|We|They|He|She|It|i|you|we|they|he|she|it)\s+will\b"),
      (match) {
        changed = true;
        return '${match.group(1)} will not';
      },
    );
    result = result.replaceAllMapped(RegExp(r"\b(I|i)'m\b"), (match) {
      changed = true;
      return "${match.group(1)}'m not";
    });
    result = result.replaceAllMapped(
      RegExp(
        r'\b(am|is|are|was|were|can|could|should|would)\b',
        caseSensitive: false,
      ),
      (match) {
        changed = true;
        return '${match.group(0)} not';
      },
    );
    if (changed) return result;

    final simpleClause = RegExp(
      r'^(I|You|We|They|i|you|we|they)\s+([A-Za-z]+)(\b.*)$',
    ).firstMatch(result);
    if (simpleClause != null) {
      return '${simpleClause.group(1)} do not ${simpleClause.group(2)}${simpleClause.group(3)}';
    }
    final thirdPerson = RegExp(r'^(He|She|It|he|she|it)\s+([A-Za-z]+)(\b.*)$')
        .firstMatch(result);
    if (thirdPerson != null) {
      return '${thirdPerson.group(1)} does not ${thirdPerson.group(2)}${thirdPerson.group(3)}';
    }

    return 'This will not happen: $result';
  }
}

class AIServiceException implements Exception {
  const AIServiceException();
}
