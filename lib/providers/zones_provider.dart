import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agrismart/data/jeu_de_donnees.dart';
import 'package:agrismart/models/zone.dart';
import 'package:agrismart/providers/auth_provider.dart';

class ZonesProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  final AuthProvider _auth;

  final List<Zone> _zones = [];
  String? _uid;
  Timer? _minuteur;

  ZonesProvider(this._prefs, this._auth) {
    _auth.addListener(_surChangementUtilisateur);
    _actualiser();
    _demarrerMinuteur();
  }

  String? get uid => _uid;
  bool get estConnecte => _uid != null && _uid!.isNotEmpty;

  List<Zone> get zones => estConnecte ? List.unmodifiable(_zones) : const [];

  int get nombre => zones.length;

  int get nombreAIrriguer =>
      zones.where((zone) => zone.besoinIrrigation).length;

  bool contientZone(Zone zone) => estConnecte && _zones.contains(zone);

  List<String> noms({Zone? sauf}) {
    return zones
        .where((zone) => zone != sauf)
        .map((zone) => zone.nom)
        .toList();
  }

  // Une clé différente pour chaque utilisateur
  String _cle(String uid) => 'zones_$uid';

  void _demarrerMinuteur() {
    _minuteur?.cancel();
    _minuteur = Timer.periodic(const Duration(seconds: 1), (_) {
      verifierEcheancesIrrigation();
    });
  }

  void verifierEcheancesIrrigation() {
    if (!estConnecte) return;
    final maintenant = DateTime.now();
    var modifie = false;

    for (final zone in _zones) {
      final finPrevue = zone.finPrevueIrrigation;
      if (zone.vanneOuverte &&
          finPrevue != null &&
          !maintenant.isBefore(finPrevue)) {
        zone.fermerVanne(
          dateFin: finPrevue,
          motif: 'Automatique (minuteur)',
        );
        modifie = true;
      }
    }

    if (modifie) {
      _sauvegarder();
      notifyListeners();
    }
  }

  // Lecture des zones sauvegardées
  List<Zone> _lire(String uid) {
    final texte = _prefs.getString(_cle(uid));
    if (texte == null) {
      return jeuDeDonnees();
    }

    try {
      final liste = jsonDecode(texte) as List<dynamic>;
      return liste.map((element) {
        return Zone.fromJson(
          Map<String, dynamic>.from(element as Map),
        );
      }).toList();
    } catch (e) {
      debugPrint('Erreur lecture zones: $e');
      return jeuDeDonnees();
    }
  }

  // Sauvegarde des zones
  Future<void> _sauvegarder() async {
    final currentUid = _uid;
    if (currentUid == null || currentUid.isEmpty) return;

    final texte = jsonEncode(
      _zones.map((zone) => zone.toJson()).toList(),
    );
    await _prefs.setString(_cle(currentUid), texte);
  }

  // Actualisation lors du changement de compte
  bool _actualiser() {
    final nouveauUid = _auth.utilisateur?.uid;
    if (nouveauUid == _uid) return false;

    _uid = nouveauUid;
    _zones.clear();

    if (nouveauUid != null && nouveauUid.isNotEmpty) {
      _zones.addAll(_lire(nouveauUid));
      verifierEcheancesIrrigation();
    }

    return true;
  }

  void _surChangementUtilisateur() {
    if (_actualiser()) {
      notifyListeners();
    }
  }

  bool ouvrirIrrigation(Zone zone, Duration duree) {
    if (!estConnecte) return false;
    final index = _zones.indexOf(zone);
    if (index == -1) return false;

    _zones[index].ouvrirVanneAvecDuree(duree);
    _sauvegarder();
    notifyListeners();
    return true;
  }

  bool fermerIrrigation(Zone zone) {
    if (!estConnecte) return false;
    final index = _zones.indexOf(zone);
    if (index == -1) return false;

    _zones[index].fermerVanne(motif: 'Fermée manuellement');
    _sauvegarder();
    notifyListeners();
    return true;
  }

  // Ouvrir ou fermer la vanne d'une zone
  bool basculerVanne(Zone zone, [bool? etatForce]) {
    if (!estConnecte) return false;
    final index = _zones.indexOf(zone);
    if (index == -1) return false;

    final cible = etatForce ?? !_zones[index].vanneOuverte;
    if (cible) {
      _zones[index].ouvrirVanneAvecDuree(const Duration(minutes: 30));
    } else {
      _zones[index].fermerVanne(motif: 'Fermée manuellement');
    }
    _sauvegarder();
    notifyListeners();
    return true;
  }

  // Modifier l'humidité et enregistrer dans l'historique
  bool modifierHumidite(Zone zone, double delta) {
    if (!estConnecte) return false;
    final index = _zones.indexOf(zone);
    if (index == -1) return false;

    final nouvelleHumidite =
    (_zones[index].humidite + delta).clamp(0.0, 100.0).toDouble();
    final signe =
    delta >= 0 ? '+${delta.toStringAsFixed(0)}%' : '${delta.toStringAsFixed(0)}%';
    _zones[index].enregistrerMesure(
      nouvelleHumidite,
      source: 'Ajustement ($signe)',
    );

    _sauvegarder();
    notifyListeners();
    return true;
  }

  // Ajouter une zone
  bool ajouter(Zone zone) {
    if (!estConnecte) return false;

    if (zone.historique.isEmpty) {
      zone.enregistrerMesure(zone.humidite, source: 'Initiale');
    }
    _zones.add(zone);
    _sauvegarder();
    notifyListeners();
    return true;
  }

  // Remplacer une zone en conservant l'historique
  bool remplacer(Zone ancienne, Zone nouvelle) {
    if (!estConnecte) return false;
    final index = _zones.indexOf(ancienne);
    if (index == -1) return false;

    final historiqueFusionne = <MesureHumidite>[
      ...ancienne.historique,
      if ((nouvelle.humidite - ancienne.humidite).abs() > 0.001)
        MesureHumidite(
          humidite: nouvelle.humidite,
          source: 'Modification zone',
        ),
    ];

    _zones[index] = nouvelle.copyWith(
      historique: historiqueFusionne,
      historiqueIrrigation: ancienne.historiqueIrrigation,
    );
    _sauvegarder();
    notifyListeners();
    return true;
  }

  // Supprimer une zone
  bool supprimer(Zone zone) {
    if (!estConnecte) return false;
    final supprimee = _zones.remove(zone);
    if (!supprimee) return false;

    _sauvegarder();
    notifyListeners();
    return true;
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    _auth.removeListener(_surChangementUtilisateur);
    super.dispose();
  }
}