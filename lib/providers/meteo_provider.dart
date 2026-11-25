
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agrismart/models/meteo.dart';
import 'package:agrismart/services/meteo_service.dart';

enum EtatMeteo {
  chargement,
  succes,
  erreur,
}

class MeteoProvider extends ChangeNotifier {
  static const String _cleMeteo = 'meteo_json';
  static const String _cleDate = 'meteo_date';

  final MeteoService _service;
  final SharedPreferences _prefs;

  MeteoProvider(
      this._prefs, {
        MeteoService? service,
      }) : _service = service ?? MeteoService();

  EtatMeteo _etat = EtatMeteo.chargement;

  Meteo? _meteo;
  String _erreur = '';
  bool _horsLigne = false;
  DateTime? _miseAJour;

  EtatMeteo get etat => _etat;
  Meteo? get meteo => _meteo;
  String get erreur => _erreur;
  bool get horsLigne => _horsLigne;
  DateTime? get miseAJour => _miseAJour;

  // Charger le cache local
  void _chargerCache() {
    final texte = _prefs.getString(_cleMeteo);

    if (texte == null) return;

    try {
      final json = jsonDecode(texte) as Map<String, dynamic>;

      _meteo = Meteo.fromJson(json);

      _miseAJour = DateTime.tryParse(
        _prefs.getString(_cleDate) ?? '',
      );

      _etat = EtatMeteo.succes;
      _horsLigne = true;
    } catch (e) {
      debugPrint('Erreur lecture cache météo: $e');
    }
  }

  // Sauvegarder la météo
  Future<void> _enregistrer(Meteo meteo) async {
    final date = DateTime.now();

    await _prefs.setString(
      _cleMeteo,
      jsonEncode(meteo.toJson()),
    );

    await _prefs.setString(
      _cleDate,
      date.toIso8601String(),
    );

    _miseAJour = date;
  }

  // Charger la météo depuis Internet
  Future<void> charger() async {
    _chargerCache();

    if (_meteo == null) {
      _etat = EtatMeteo.chargement;
    }

    _erreur = '';
    notifyListeners();

    try {
      final nouvelleMeteo = await _service.charger();

      _meteo = nouvelleMeteo;
      _etat = EtatMeteo.succes;
      _horsLigne = false;

      await _enregistrer(nouvelleMeteo);
    } on MeteoException catch (e) {
      _erreur = e.message;

      if (_meteo != null) {
        _etat = EtatMeteo.succes;
        _horsLigne = true;
      } else {
        _etat = EtatMeteo.erreur;
      }
    } catch (e) {
      _erreur = 'Erreur inattendue';

      if (_meteo != null) {
        _etat = EtatMeteo.succes;
        _horsLigne = true;
      } else {
        _etat = EtatMeteo.erreur;
      }
    }

    notifyListeners();
  }
}
