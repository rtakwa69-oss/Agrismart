import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/models/zone.dart';
import 'package:agrismart/providers/zones_provider.dart';
import 'package:agrismart/screens/zone_form_page.dart';
import 'package:agrismart/theme/app_theme.dart';

class ZoneDetailPage extends StatelessWidget {
  final Zone zone;
  final List<String> nomsAutres;

  const ZoneDetailPage({
    super.key,
    required this.zone,
    this.nomsAutres = const [],
  });

  String _deuxChiffres(int n) => n.toString().padLeft(2, '0');

  String _formaterDate(DateTime d) {
    return '${_deuxChiffres(d.day)}/${_deuxChiffres(d.month)}/${d.year} à ${_deuxChiffres(d.hour)}:${_deuxChiffres(d.minute)}';
  }

  String _formaterHeure(DateTime d) {
    return '${_deuxChiffres(d.hour)}:${_deuxChiffres(d.minute)}';
  }

  String _formaterDuree(Duration d) {
    final totalSecondes = d.inSeconds < 0 ? 0 : d.inSeconds;
    final heures = totalSecondes ~/ 3600;
    final minutes = (totalSecondes % 3600) ~/ 60;
    final secondes = totalSecondes % 60;

    if (heures > 0) {
      return '${heures}h ${_deuxChiffres(minutes)}min';
    }
    if (minutes > 0) {
      return '${minutes}min ${_deuxChiffres(secondes)}s';
    }
    return '${secondes}s';
  }

  Future<void> _choisirDureeEtOuvrir(BuildContext context) async {
    final provider = context.read<ZonesProvider>();
    Duration? dureeChoisie;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Programmer l\'ouverture de la vanne'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Choisissez une durée ou une heure de fermeture :'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: const Text('15 min'),
                  onPressed: () {
                    dureeChoisie = const Duration(minutes: 15);
                    Navigator.pop(dialogContext);
                  },
                ),
                ActionChip(
                  label: const Text('30 min'),
                  onPressed: () {
                    dureeChoisie = const Duration(minutes: 30);
                    Navigator.pop(dialogContext);
                  },
                ),
                ActionChip(
                  label: const Text('1 heure'),
                  onPressed: () {
                    dureeChoisie = const Duration(hours: 1);
                    Navigator.pop(dialogContext);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.schedule),
              label: const Text('Choisir l\'heure de fermeture'),
              onPressed: () async {
                final maintenant = DateTime.now();
                final heureSelectionnee = await showTimePicker(
                  context: dialogContext,
                  initialTime: TimeOfDay.fromDateTime(
                    maintenant.add(const Duration(minutes: 30)),
                  ),
                );
                if (heureSelectionnee == null || !dialogContext.mounted) return;

                var cible = DateTime(
                  maintenant.year,
                  maintenant.month,
                  maintenant.day,
                  heureSelectionnee.hour,
                  heureSelectionnee.minute,
                );
                if (!cible.isAfter(maintenant)) {
                  cible = cible.add(const Duration(days: 1));
                }

                dureeChoisie = cible.difference(maintenant);
                Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );

    if (dureeChoisie == null || !context.mounted) return;
    provider.ouvrirIrrigation(zone, dureeChoisie!);
  }

  Future<void> _modifier(BuildContext context) async {
    final nouvelleZone = await Navigator.push<Zone>(
      context,
      MaterialPageRoute(
        builder: (_) => ZoneFormPage(
          zone: zone,
          nomsExistants: nomsAutres,
        ),
      ),
    );

    if (nouvelleZone == null || !context.mounted) return;

    Navigator.pop(context, nouvelleZone);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ZonesProvider>();
    final estAutorise = provider.contientZone(zone);
    if (!estAutorise) {
      return Scaffold(
        appBar: AppBar(title: const Text('Accès refusé')),
        body: const Center(
          child: Text('Cette zone n’appartient pas au compte actif.'),
        ),
      );
    }

    final couleur =
    zone.besoinIrrigation ? AppTheme.echec : AppTheme.succes;
    final longueur = zone.culture.length < 4 ? zone.culture.length : 4;
    final texte = Theme.of(context).textTheme;
    final mesuresRecentes = zone.historique.reversed.toList();
    final sessionsRecentes = zone.historiqueIrrigation.reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(zone.nom),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                child: Text(zone.culture.substring(0, longueur)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(zone.nom, style: texte.headlineSmall),
                    Text(zone.culture, style: texte.bodyLarge),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '${zone.humidite.toStringAsFixed(0)} %',
              style: texte.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (zone.humidite / 100).clamp(0.0, 1.0),
            color: couleur,
            minHeight: 10,
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              diagnostic(zone),
              style: texte.titleMedium?.copyWith(
                color: couleur,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.water_drop),
                  title: const Text('Humidité actuelle'),
                  trailing: Text(
                    '${zone.humidite.toStringAsFixed(0)} %',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.flag),
                  title: const Text('Seuil d’irrigation'),
                  trailing: Text(
                    '${zone.seuil.toStringAsFixed(0)} %',
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: Icon(
                    zone.vanneOuverte ? Icons.toggle_on : Icons.toggle_off,
                  ),
                  title: const Text('Vanne'),
                  subtitle: Text(
                    zone.vanneOuverte && zone.finPrevueIrrigation != null
                        ? 'Ouverte • Fermeture prévue à ${_formaterHeure(zone.finPrevueIrrigation!)}'
                        : (zone.vanneOuverte ? 'Ouverte' : 'Fermée'),
                  ),
                  value: zone.vanneOuverte,
                  onChanged: (valeur) {
                    if (valeur) {
                      _choisirDureeEtOuvrir(context);
                    } else {
                      provider.fermerIrrigation(zone);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (!zone.vanneOuverte)
            FilledButton.tonalIcon(
              onPressed: () => _choisirDureeEtOuvrir(context),
              icon: const Icon(Icons.timer),
              label: const Text('Programmer durée / heure de fermeture'),
            )
          else
            OutlinedButton.icon(
              onPressed: () => provider.fermerIrrigation(zone),
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('Fermer la vanne maintenant'),
            ),
          const SizedBox(height: 20),
          Text('Historique d\'irrigation', style: texte.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: sessionsRecentes.isEmpty
                ? const ListTile(
              title: Text('Aucune session d\'irrigation enregistrée'),
            )
                : Column(
              children: [
                for (var i = 0; i < sessionsRecentes.length; i++) ...[
                  ListTile(
                    leading: Icon(
                      sessionsRecentes[i].estEnCours
                          ? Icons.timelapse
                          : Icons.check_circle_outline,
                    ),
                    title: Text(
                      sessionsRecentes[i].estEnCours
                          ? 'Ouverte à ${_formaterHeure(sessionsRecentes[i].debut)} • Durée : ${_formaterDuree(sessionsRecentes[i].dureeReelle)}'
                          : 'De ${_formaterHeure(sessionsRecentes[i].debut)} à ${_formaterHeure(sessionsRecentes[i].fin!)} • Restée ouverte : ${_formaterDuree(sessionsRecentes[i].dureeReelle)}',
                    ),
                    subtitle: Text(
                      '${sessionsRecentes[i].motifFermeture} (prévu : ${_formaterDuree(sessionsRecentes[i].dureePrevue)})',
                    ),
                  ),
                  if (i < sessionsRecentes.length - 1)
                    const Divider(height: 1),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Historique des mesures', style: texte.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: mesuresRecentes.isEmpty
                ? const ListTile(
              title: Text('Aucune mesure enregistrée'),
            )
                : Column(
              children: [
                for (var i = 0; i < mesuresRecentes.length; i++) ...[
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(
                      '${mesuresRecentes[i].humidite.toStringAsFixed(0)} %',
                    ),
                    subtitle: Text(
                      mesuresRecentes[i].source ?? 'Mesure',
                    ),
                    trailing: Text(
                      _formaterDate(mesuresRecentes[i].date),
                      style: texte.bodySmall,
                    ),
                  ),
                  if (i < mesuresRecentes.length - 1)
                    const Divider(height: 1),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _modifier(context),
            icon: const Icon(Icons.edit),
            label: const Text('Modifier cette zone'),
          ),
        ],
      ),
    );
  }
}