enum RealityMode {
  pessimistic('Pessimistic'),
  cynical('Cynical'),
  darkHumor('Dark humor'),
  worstCase('Worst case'),
  uncomfortableTruth('Uncomfortable truth'),
  existential('Existential'),
  sarcastic('Sarcastic');

  const RealityMode(this.label);
  final String label;
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
