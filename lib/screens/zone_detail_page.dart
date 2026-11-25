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

  String _formaterDate(DateTime d) {
    final jour = d.day.toString().padLeft(2, '0');
    final mois = d.month.toString().padLeft(2, '0');
    final heure = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$jour/$mois/${d.year} à $heure:$min';
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
                    zone.vanneOuverte ? 'Ouverte' : 'Fermée',
                  ),
                  value: zone.vanneOuverte,
                  onChanged: (valeur) {
                    provider.basculerVanne(zone, valeur);
                  },
                ),
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