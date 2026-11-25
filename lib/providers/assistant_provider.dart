import 'package:flutter/foundation.dart';
import 'package:agrismart/models/message_chat.dart';
import 'package:agrismart/providers/auth_provider.dart';
import 'package:agrismart/providers/zones_provider.dart';
import 'package:agrismart/services/assistant_service.dart';

class AssistantProvider extends ChangeNotifier {
  final AssistantService _service;
  final AuthProvider _auth;
  final ZonesProvider _zonesProvider;

  final List<MessageChat> _messages = [];
  bool _enCours = false;
  String? _uidCourant;

  AssistantProvider(this._service, this._auth, this._zonesProvider) {
    _uidCourant = _auth.utilisateur?.uid;
    _initialiserAccueil();
    _auth.addListener(_surChangementCompte);
  }

  List<MessageChat> get messages => List.unmodifiable(_messages);
  bool get enCours => _enCours;

  void _initialiserAccueil() {
    _messages
      ..clear()
      ..add(
        MessageChat(
          texte: "Bonjour ! Je suis l'assistant AgriSmart. Posez-moi une question sur l'humidité, les seuils ou les vannes de vos parcelles.",
          estUtilisateur: false,
        ),
      );
  }

  void _surChangementCompte() {
    final nouveauUid = _auth.utilisateur?.uid;
    if (nouveauUid == _uidCourant) return;
    _uidCourant = nouveauUid;
    _initialiserAccueil();
    notifyListeners();
  }

  Future<void> envoyerMessage(String texte) async {
    final propre = texte.trim();
    if (propre.isEmpty || _enCours) return;

    _messages.add(MessageChat(texte: propre, estUtilisateur: true));
    _enCours = true;
    notifyListeners();

    try {
      final reponse = await _service.repondre(
        question: propre,
        zonesUtilisateur: _zonesProvider.zones,
        uid: _auth.utilisateur?.uid,
      );
      _messages.add(MessageChat(texte: reponse, estUtilisateur: false));
    } catch (e) {
      _messages.add(
        MessageChat(
          texte: "Erreur lors de l'analyse : $e",
          estUtilisateur: false,
        ),
      );
    } finally {
      _enCours = false;
      notifyListeners();
    }
  }

  void effacerConversation() {
    _initialiserAccueil();
    notifyListeners();
  }

  @override
  void dispose() {
    _auth.removeListener(_surChangementCompte);
    super.dispose();
  }
}