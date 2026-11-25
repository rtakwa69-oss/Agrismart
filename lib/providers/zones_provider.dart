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

  ZonesProvider(this._prefs, this._auth) {
    _auth.addListener(_surChangementUtilisateur);
    _actualiser();
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

  String _cle(String uid) => 'zones_$uid';

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

  Future<void> _sauvegarder() async {
    final currentUid = _uid;
    if (currentUid == null || currentUid.isEmpty) return;

    final texte = jsonEncode(
      _zones.map((zone) => zone.toJson()).toList(),
    );
    await _prefs.setString(_cle(currentUid), texte);
  }

  bool _actualiser() {
    final nouveauUid = _auth.utilisateur?.uid;
    if (nouveauUid == _uid) return false;

    _uid = nouveauUid;
    _zones.clear();

    if (nouveauUid != null && nouveauUid.isNotEmpty) {
      _zones.addAll(_lire(nouveauUid));
    }

    return true;
  }

  void _surChangementUtilisateur() {
    if (_actualiser()) {
      notifyListeners();
    }
  }

  bool modifierHumidite(Zone zone, double delta) {
    if (!estConnecte) return false;
    final index = _zones.indexOf(zone);
    if (index == -1) return false;

    final nouvelleHumidite =
    (_zones[index].humidite + delta).clamp(0.0, 100.0).toDouble();
    _zones[index].humidite = nouvelleHumidite;

    _sauvegarder();
    notifyListeners();
    return true;
  }

  bool ajouter(Zone zone) {
    if (!estConnecte) return false;

    _zones.add(zone);
    _sauvegarder();
    notifyListeners();
    return true;
  }

  bool remplacer(Zone ancienne, Zone nouvelle) {
    if (!estConnecte) return false;
    final index = _zones.indexOf(ancienne);
    if (index == -1) return false;

    _zones[index] = nouvelle;
    _sauvegarder();
    notifyListeners();
    return true;
  }

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
    _auth.removeListener(_surChangementUtilisateur);
    super.dispose();
  }
}