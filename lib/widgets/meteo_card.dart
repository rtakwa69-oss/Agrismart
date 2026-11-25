
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:agrismart/models/meteo.dart';
import 'package:agrismart/providers/meteo_provider.dart';

class MeteoCard extends StatelessWidget {
  const MeteoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MeteoProvider>();

    final Widget contenu;

    switch (provider.etat) {
      case EtatMeteo.chargement:
        contenu = const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Chargement de la météo...'),
              ],
            ),
          ),
        );

      case EtatMeteo.erreur:
        contenu = Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 40),
              const SizedBox(height: 8),
              Text(provider.erreur),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () =>
                    context.read<MeteoProvider>().charger(),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        );

      case EtatMeteo.succes:
        contenu = Contenu(
          meteo: provider.meteo!,
          horsLigne: provider.horsLigne,
          miseAJour: provider.miseAJour,
        );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: contenu,
    );
  }
}

class Contenu extends StatelessWidget {
  final Meteo meteo;
  final bool horsLigne;
  final DateTime? miseAJour;

  const Contenu({
    super.key,
    required this.meteo,
    this.horsLigne = false,
    this.miseAJour,
  });

  static const _jours = [
    'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'
  ];

  String _dateMiseAJour() {
    if (miseAJour == null) return 'Date inconnue';

    final d = miseAJour!;

    final jour = d.day.toString().padLeft(2, '0');
    final mois = d.month.toString().padLeft(2, '0');
    final heure = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');

    return '$jour/$mois/${d.year} à $heure:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final texte = Theme.of(context).textTheme;
    final pluie = meteo.pluieTotale;

    final conseil = pluie >= 5
        ? "Pluie prévue (${pluie.toStringAsFixed(1)} mm) : repoussez l'irrigation"
        : 'Pas de pluie significative prévue';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Météo à Kébili', style: texte.titleMedium),

          const SizedBox(height: 8),

          Row(
            children: [
              Text(
                '${meteo.temperature.toStringAsFixed(0)} °C',
                style: texte.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Humidité de l'air : ${meteo.humiditeAir} %"),
                  Text('Vent : ${meteo.vent.toStringAsFixed(0)} km/h'),
                ],
              ),
            ],
          ),

          const Divider(height: 24),

          for (final p in meteo.previsions)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    child: Text(_jours[p.date.weekday - 1]),
                  ),
                  Expanded(
                    child: Text(
                      '${p.tMin.toStringAsFixed(0)}° / '
                          '${p.tMax.toStringAsFixed(0)}°',
                    ),
                  ),
                  const Icon(
                    Icons.water_drop_outlined,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text('${p.pluie.toStringAsFixed(1)} mm'),
                ],
              ),
            ),

          const SizedBox(height: 8),

          Text(
            conseil,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          const Divider(),

          Row(
            children: [
              Icon(
                horsLigne ? Icons.cloud_off : Icons.cloud_done,
                size: 18,
                color: horsLigne ? Colors.orange : Colors.green,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  horsLigne
                      ? 'Hors ligne : données du ${_dateMiseAJour()}'
                      : 'Mis à jour le ${_dateMiseAJour()}',
                  style: texte.bodySmall,
                ),
              ),
            ],
          ),

          if (horsLigne)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () =>
                    context.read<MeteoProvider>().charger(),
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ),
        ],
      ),
    );
  }
}
