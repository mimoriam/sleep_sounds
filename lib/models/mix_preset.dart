class LayerConfig {
  final String soundId;
  final double volume;

  const LayerConfig({
    required this.soundId,
    this.volume = 0.70,
  });

  Map<String, dynamic> toJson() => {
        'soundId': soundId,
        'volume': volume,
      };

  factory LayerConfig.fromJson(Map<String, dynamic> json) {
    return LayerConfig(
      soundId: json['soundId'] as String,
      volume: (json['volume'] as num).toDouble(),
    );
  }
}

class MixPreset {
  final String id;
  final String name;
  final String mainSoundId;
  final List<LayerConfig> layers;
  final double masterVolume;

  const MixPreset({
    required this.id,
    required this.name,
    required this.mainSoundId,
    required this.layers,
    this.masterVolume = 0.70,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'mainSoundId': mainSoundId,
        'layers': layers.map((l) => l.toJson()).toList(),
        'masterVolume': masterVolume,
      };

  factory MixPreset.fromJson(Map<String, dynamic> json) {
    return MixPreset(
      id: json['id'] as String,
      name: json['name'] as String,
      mainSoundId: json['mainSoundId'] as String,
      layers: (json['layers'] as List<dynamic>)
          .map((l) => LayerConfig.fromJson(l as Map<String, dynamic>))
          .toList(),
      masterVolume: (json['masterVolume'] as num?)?.toDouble() ?? 0.70,
    );
  }
}
