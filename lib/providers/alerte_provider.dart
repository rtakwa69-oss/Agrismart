
import 'package:flutter/foundation.dart';

import 'package:agrismart/models/alerte.dart';
import 'package:agrismart/providers/zones_provider.dart';
import 'package:agrismart/providers/meteo_provider.dart';
import 'package:agrismart/services/notification_service.dart';

class AlerteProvider extends ChangeNotifier {
  final ZonesProvider _zonesProvider;
  final MeteoProvider _meteoProvider;
  final NotificationService _notificationService;

  final Map<String, Alerte> _alertes = {};
  final Set<String> _notificationsEnvoyees = {};

  late final Future<void> _initialisationNotifications;

  String? _dernierUid;

  AlerteProvider(
      this._zonesProvider,
      this._meteoProvider,
      this._notificationService,
      ) {
    _dernierUid = _zonesProvider.uid;

    _initialisationNotifications =
        _notificationService.initialiser();

    _zonesProvider.addListener(_actualiser);
    _meteoProvider.addListener(_actualiser);

    _actualiser();
  }

  List<Alerte> get alertes {
    final resultat = _alertes.values.toList();

    resultat.sort((a, b) => b.date.compareTo(a.date));

    return resultat;
  }

  int get nombre => _alertes.length;

  int get nombreNonLues =>
      _alertes.values.where((alerte) => !alerte.lue).length;

  // Actualiser les alertes selon les données disponibles
  void _actualiser() {
    final uidActuel = _zonesProvider.uid;

    // Réinitialiser les alertes lors d'un changement de compte
    if (uidActuel != _dernierUid) {
      _alertes.clear();
      _notificationsEnvoyees.clear();
      _dernierUid = uidActuel;
    }

    final nouvellesCles = <String>{};

    // 1. Détection de l'humidité du sol
    if (uidActuel != null && uidActuel.isNotEmpty) {
      for (final zone in _zonesProvider.zones) {
        if (zone.besoinIrrigation) {
          final cle = 'humidite_${zone.nom}';
          nouvellesCles.add(cle);

          final message =
              'La zone ${zone.nom} est trop sèche. '
              'Humidité : ${zone.humidite.toStringAsFixed(1)}%. '
              'Seuil : ${zone.seuil.toStringAsFixed(1)}%.';

          _ajouterAlerte(
            cle: cle,
            titre: 'Besoin d’irrigation',
            message: message,
            type: TypeAlerte.humidite,
          );
        }
      }
    }

    // 2. Détection des prévisions de pluie
    final meteo = _meteoProvider.meteo;

    if (meteo != null) {
      for (final prevision in meteo.previsions) {
        if (prevision.pluie > 0) {
          final date = prevision.date;
          final dateFormatee =
              '${date.day.toString().padLeft(2, '0')}/'
              '${date.month.toString().padLeft(2, '0')}/'
              '${date.year}';

          final cle = 'pluie_$dateFormatee';
          nouvellesCles.add(cle);

          _ajouterAlerte(
            cle: cle,
            titre: 'Pluie prévue',
            message:
            'Une pluie de ${prevision.pluie.toStringAsFixed(1)} mm '
                'est prévue le $dateFormatee.',
            type: TypeAlerte.pluie,
          );
        }
      }
    }

    // Supprimer les alertes dont les conditions ne sont plus présentes
    _alertes.removeWhere(
          (cle, alerte) => !nouvellesCles.contains(cle),
    );

    notifyListeners();
  }

  // Ajouter une alerte et envoyer une notification une seule fois
  void _ajouterAlerte({
    required String cle,
    required String titre,
    required String message,
    required TypeAlerte type,
  }) {
    final ancienneAlerte = _alertes[cle];

    _alertes[cle] = Alerte(
      id: cle,
      titre: titre,
      message: message,
      type: type,
      lue: ancienneAlerte?.lue ?? false,
    );

    if (!_notificationsEnvoyees.contains(cle)) {
      _notificationsEnvoyees.add(cle);
      _envoyerNotification(cle, titre, message);
    }
  }

  Future<void> _envoyerNotification(
      String cle,
      String titre,
      String message,
      ) async {
    try {
      await _initialisationNotifications;

      await _notificationService.afficher(
        id: cle.hashCode & 0x7fffffff,
        titre: titre,
        message: message,
      );
    } catch (e) {
      debugPrint('Erreur notification : $e');
    }
  }

  // Marquer une alerte comme lue
  void marquerCommeLue(String id) {
    final alerte = _alertes[id];

    if (alerte == null || alerte.lue) return;

    _alertes[id] = alerte.copyWith(lue: true);

    notifyListeners();
  }

  // Marquer toutes les alertes comme lues
  void marquerToutesCommeLues() {
    for (final entree in _alertes.entries.toList()) {
      entree.value.lue = true;
    }

    notifyListeners();
  }

  // Supprimer toutes les alertes affichées
  void effacerAlertes() {
    _alertes.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _zonesProvider.removeListener(_actualiser);
    _meteoProvider.removeListener(_actualiser);
    super.dispose();
  }
}
