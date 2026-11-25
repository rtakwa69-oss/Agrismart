import 'package:agrismart/models/zone.dart';

class AssistantService {
  Future<String> repondre({
    required String question,
    required List<Zone> zonesUtilisateur,
    String? uid,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (uid == null || uid.isEmpty) {
      return "Connectez-vous d'abord pour que je puisse analyser vos parcelles.";
    }

    if (zonesUtilisateur.isEmpty) {
      return "Vous n'avez encore aucune zone enregistrée sur ce compte. Ajoutez une zone pour commencer.";
    }

    final q = question.toLowerCase().trim();
    final aIrriguer = zonesUtilisateur.where((z) => z.besoinIrrigation).toList();
    final vannesOuvertes = zonesUtilisateur.where((z) => z.vanneOuverte).toList();
    final moyenne = humiditeMoyenne(zonesUtilisateur);

    if (q.contains('irrig') || q.contains('eau') || q.contains('ma') || q.contains('seuil')) {
      if (aIrriguer.isEmpty) {
        return "Toutes vos zones (${zonesUtilisateur.length}) sont au-dessus de leur seuil d'humidité. Aucune irrigation urgente.";
      }
      final noms = aIrriguer.map((z) => "${z.nom} (${z.humidite.toStringAsFixed(0)}% / seuil ${z.seuil.toStringAsFixed(0)}%)").join(', ');
      return "Zones à irriguer en priorité (${aIrriguer.length}) : $noms.";
    }

    if (q.contains('vanne')) {
      if (vannesOuvertes.isEmpty) {
        return "Toutes les vannes sont actuellement fermées.";
      }
      final noms = vannesOuvertes.map((z) => z.nom).join(', ');
      return "Vannes actuellement ouvertes (${vannesOuvertes.length}) : $noms.";
    }

    if (q.contains('moyenne') || q.contains('resume') || q.contains('résumé') || q.contains('stat')) {
      return "Résumé de vos ${zonesUtilisateur.length} zone(s) : "
          "humidité moyenne ${moyenne.toStringAsFixed(1)}%, "
          "${aIrriguer.length} zone(s) sous le seuil, "
          "${vannesOuvertes.length} vanne(s) ouverte(s).";
    }

    final details = zonesUtilisateur
        .map((z) => "• ${z.nom} (${z.culture}) : ${z.humidite.toStringAsFixed(0)}% — ${diagnostic(z)}")
        .join('\n');

    return "Voici l'état de vos parcelles :\n$details\n\nDemandez-moi par exemple : « Quelles zones irriguer ? » ou « Résumé ».";
  }
}