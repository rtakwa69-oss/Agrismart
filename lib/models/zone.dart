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

class SessionIrrigation {
  final String id;
  final DateTime debut;
  final DateTime? fin;
  final Duration dureePrevue;
  final String motifFermeture;

  SessionIrrigation({
    required this.id,
    required this.debut,
    this.fin,
    required this.dureePrevue,
    this.motifFermeture = 'En cours',
  });

  bool get estEnCours => fin == null;

  Duration get dureeReelle {
    final borneFin = fin ?? DateTime.now();
    final diff = borneFin.difference(debut);
    return diff.isNegative ? Duration.zero : diff;
  }

  SessionIrrigation fermer({
    required DateTime dateFin,
    required String motif,
  }) {
    final finValide = dateFin.isBefore(debut) ? debut : dateFin;
    return SessionIrrigation(
      id: id,
      debut: debut,
      fin: finValide,
      dureePrevue: dureePrevue,
      motifFermeture: motif,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'debut': debut.toIso8601String(),
      'fin': fin?.toIso8601String(),
      'dureePrevueSecondes': dureePrevue.inSeconds,
      'motifFermeture': motifFermeture,
    };
  }

  factory SessionIrrigation.fromJson(Map<String, dynamic> json) {
    return SessionIrrigation(
      id: json['id'] as String? ?? '',
      debut: DateTime.tryParse(json['debut'] as String? ?? '') ?? DateTime.now(),
      fin: json['fin'] != null
          ? DateTime.tryParse(json['fin'] as String)
          : null,
      dureePrevue: Duration(
        seconds: (json['dureePrevueSecondes'] as num?)?.toInt() ?? 0,
      ),
      motifFermeture: json['motifFermeture'] as String? ?? 'En cours',
    );
  }
}

class Zone {
  final String nom;
  final String culture;
  double humidite;
  final double seuil;
  bool vanneOuverte;
  DateTime? finPrevueIrrigation;
  final List<MesureHumidite> historique;
  final List<SessionIrrigation> historiqueIrrigation;

  Zone(
      this.nom,
      this.culture,
      this.humidite,
      this.seuil, {
        this.vanneOuverte = false,
        this.finPrevueIrrigation,
        List<MesureHumidite>? historique,
        List<SessionIrrigation>? historiqueIrrigation,
      })  : historique = historique != null
      ? List<MesureHumidite>.from(historique)
      : <MesureHumidite>[
    MesureHumidite(humidite: humidite, source: 'Initiale'),
  ],
        historiqueIrrigation = historiqueIrrigation != null
            ? List<SessionIrrigation>.from(historiqueIrrigation)
            : <SessionIrrigation>[];

  // Vrai si l'humidité est sous le seuil
  bool get besoinIrrigation => humidite < seuil;

  SessionIrrigation? get sessionActive {
    for (final s in historiqueIrrigation.reversed) {
      if (s.estEnCours) return s;
    }
    return null;
  }

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

  void ouvrirVanneAvecDuree(Duration duree, {DateTime? maintenant}) {
    final debut = maintenant ?? DateTime.now();
    final dureeValide =
    duree.inSeconds <= 0 ? const Duration(minutes: 15) : duree;
    final finPrevue = debut.add(dureeValide);

    final active = sessionActive;
    if (active != null) {
      final idx = historiqueIrrigation.indexOf(active);
      if (idx != -1) {
        historiqueIrrigation[idx] = active.fermer(
          dateFin: debut,
          motif: 'Remplacée',
        );
      }
    }

    vanneOuverte = true;
    finPrevueIrrigation = finPrevue;
    historiqueIrrigation.add(
      SessionIrrigation(
        id: debut.microsecondsSinceEpoch.toString(),
        debut: debut,
        dureePrevue: dureeValide,
        motifFermeture: 'En cours',
      ),
    );
  }

  void fermerVanne({
    DateTime? dateFin,
    String motif = 'Fermée manuellement',
  }) {
    final fin = dateFin ?? DateTime.now();
    final active = sessionActive;
    if (active != null) {
      final idx = historiqueIrrigation.indexOf(active);
      if (idx != -1) {
        historiqueIrrigation[idx] = active.fermer(
          dateFin: fin,
          motif: motif,
        );
      }
    }
    vanneOuverte = false;
    finPrevueIrrigation = null;
  }

  Zone copyWith({
    String? nom,
    String? culture,
    double? humidite,
    double? seuil,
    bool? vanneOuverte,
    DateTime? finPrevueIrrigation,
    bool effacerFinPrevue = false,
    List<MesureHumidite>? historique,
    List<SessionIrrigation>? historiqueIrrigation,
  }) {
    return Zone(
      nom ?? this.nom,
      culture ?? this.culture,
      humidite ?? this.humidite,
      seuil ?? this.seuil,
      vanneOuverte: vanneOuverte ?? this.vanneOuverte,
      finPrevueIrrigation: effacerFinPrevue
          ? null
          : (finPrevueIrrigation ?? this.finPrevueIrrigation),
      historique: historique ?? this.historique,
      historiqueIrrigation: historiqueIrrigation ?? this.historiqueIrrigation,
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
      'finPrevueIrrigation': finPrevueIrrigation?.toIso8601String(),
      'historique': historique.map((m) => m.toJson()).toList(),
      'historiqueIrrigation':
      historiqueIrrigation.map((s) => s.toJson()).toList(),
    };
  }

  // Reconstruction d'une Zone depuis JSON
  factory Zone.fromJson(Map<String, dynamic> json) {
    final humiditeInitiale = (json['humidite'] as num).toDouble();
    final rawHistorique = json['historique'] as List<dynamic>?;
    final rawSessions = json['historiqueIrrigation'] as List<dynamic>?;

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

    final sessions = rawSessions != null
        ? rawSessions
        .map(
          (item) => SessionIrrigation.fromJson(
        Map<String, dynamic>.from(item as Map),
      ),
    )
        .toList()
        : <SessionIrrigation>[];

    return Zone(
      json['nom'] as String,
      json['culture'] as String,
      humiditeInitiale,
      (json['seuil'] as num).toDouble(),
      vanneOuverte: json['vanneOuverte'] as bool? ?? false,
      finPrevueIrrigation: json['finPrevueIrrigation'] != null
          ? DateTime.tryParse(json['finPrevueIrrigation'] as String)
          : null,
      historique: mesures,
      historiqueIrrigation: sessions,
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