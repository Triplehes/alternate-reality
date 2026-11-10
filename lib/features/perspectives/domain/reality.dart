enum RealityMode {
  pessimistic(
    'Pessimistic',
    'Consider a plausible setback or overlooked risk.',
  ),
  cynical('Cynical', 'Look at motives, incentives and appearances.'),
  darkHumor('Dark humor', 'Find a darkly funny irony in the situation.'),
  worstCase('Worst case', 'Explore what could go wrong without predicting it.'),
  uncomfortableTruth(
    'Uncomfortable truth',
    'Consider the tradeoffs you may prefer to avoid.',
  ),
  existential('Existential', 'Reflect on meaning, time and uncertainty.'),
  sarcastic('Sarcastic', 'See the situation through dry, playful irony.'),
  positive(
    'Positive',
    'Find a hopeful, realistic perspective and a way forward.',
  ),
  literalNegation(
    'Literal negation',
    'Express the opposite with correct grammar and the same tense.',
  );

  const RealityMode(this.label, this.description);
  final String label;
  final String description;
}

class RealityEntry {
  const RealityEntry({
    required this.id,
    required this.originalText,
    required this.alternateText,
    required this.mode,
    required this.createdAt,
    this.isCurrent = true,
  });
  final String id, originalText, alternateText;
  final RealityMode mode;
  final DateTime createdAt;
  final bool isCurrent;
  Map<String, Object?> toJson() => {
    'id': id,
    'originalText': originalText,
    'alternateText': alternateText,
    'mode': mode.name,
    'createdAt': createdAt.toIso8601String(),
    'isCurrent': isCurrent,
  };
  factory RealityEntry.fromJson(Map<String, Object?> json) => RealityEntry(
    id: json['id']! as String,
    originalText: json['originalText']! as String,
    alternateText: json['alternateText']! as String,
    mode: RealityMode.values.firstWhere(
      (m) => m.name == json['mode'],
      orElse: () => RealityMode.pessimistic,
    ),
    createdAt: DateTime.parse(json['createdAt']! as String),
    isCurrent: json['isCurrent'] as bool? ?? false,
  );
}
