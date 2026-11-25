class MesureHumidite {
  final double humidite;
  final DateTime date;
  final String? source;

  MesureHumidite({
    required this.humidite,
    DateTime? date,
    this.source,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'humidite': humidite,
      'date': date.toIso8601String(),
      if (source != null) 'source': source,
    };
  }

  factory MesureHumidite.fromJson(Map<String, dynamic> json) {
    return MesureHumidite(
      humidite: (json['humidite'] as num).toDouble(),
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      source: json['source'] as String?,
    );
  }
}

class Zone {
  final String nom;
  final String culture;
  double humidite;
  final double seuil;
  bool vanneOuverte;
  final List<MesureHumidite> historique;

  Zone(
      this.nom,
      this.culture,
      this.humidite,
      this.seuil, {
        this.vanneOuverte = false,
        List<MesureHumidite>? historique,
      }) : historique = historique != null
      ? List<MesureHumidite>.from(historique)
      : <MesureHumidite>[
    MesureHumidite(humidite: humidite, source: 'Initiale'),
  ];

  // Vrai si l'humidité est sous le seuil
  bool get besoinIrrigation => humidite < seuil;

  void enregistrerMesure(double valeur, {String? source, DateTime? date}) {
    final borne = valeur.clamp(0.0, 100.0).toDouble();
    humidite = borne;
    historique.add(
      MesureHumidite(
        humidite: borne,
        date: date,
        source: source,
      ),
    );
  }

  Zone copyWith({
    String? nom,
    String? culture,
    double? humidite,
    double? seuil,
    bool? vanneOuverte,
    List<MesureHumidite>? historique,
  }) {
    return Zone(
      nom ?? this.nom,
      culture ?? this.culture,
      humidite ?? this.humidite,
      seuil ?? this.seuil,
      vanneOuverte: vanneOuverte ?? this.vanneOuverte,
      historique: historique ?? this.historique,
    );
  }

  // Conversion de Zone vers JSON
  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'culture': culture,
      'humidite': humidite,
      'seuil': seuil,
      'vanneOuverte': vanneOuverte,
      'historique': historique.map((m) => m.toJson()).toList(),
    };
  }

  // Reconstruction d'une Zone depuis JSON
  factory Zone.fromJson(Map<String, dynamic> json) {
    final humiditeInitiale = (json['humidite'] as num).toDouble();
    final rawHistorique = json['historique'] as List<dynamic>?;

    final mesures = rawHistorique != null
        ? rawHistorique
        .map(
          (item) => MesureHumidite.fromJson(
        Map<String, dynamic>.from(item as Map),
      ),
    )
        .toList()
        : <MesureHumidite>[
      MesureHumidite(humidite: humiditeInitiale, source: 'Initiale'),
    ];

    return Zone(
      json['nom'] as String,
      json['culture'] as String,
      humiditeInitiale,
      (json['seuil'] as num).toDouble(),
      vanneOuverte: json['vanneOuverte'] as bool? ?? false,
      historique: mesures,
    );
  }
}

// Humidité moyenne d'une liste de zones (0 si vide)
double humiditeMoyenne(List<Zone> zones) {
  if (zones.isEmpty) return 0;

  double somme = 0;
  for (final z in zones) {
    somme += z.humidite;
  }

  return somme / zones.length;
}

// Message de diagnostic pour une zone
String diagnostic(Zone zone) {
  if (zone.besoinIrrigation) {
    return "Besoin d'irrigation";
  }

  return 'Sol correct';
}