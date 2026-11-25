
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:agrismart/models/alerte.dart';
import 'package:agrismart/providers/alerte_provider.dart';

class AlertesPage extends StatelessWidget {
  const AlertesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AlerteProvider>();
    final alertes = provider.alertes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes alertes'),
        actions: [
          if (provider.nombreNonLues > 0)
            IconButton(
              tooltip: 'Tout marquer comme lu',
              icon: const Icon(Icons.done_all),
              onPressed: provider.marquerToutesCommeLues,
            ),
        ],
      ),
      body: alertes.isEmpty
          ? const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none,
              size: 70,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Text(
              'Aucune alerte pour le moment',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: alertes.length,
        itemBuilder: (context, index) {
          final alerte = alertes[index];

          return _AlerteCard(
            alerte: alerte,
            onTap: () {
              provider.marquerCommeLue(alerte.id);
            },
          );
        },
      ),
    );
  }
}

class _AlerteCard extends StatelessWidget {
  final Alerte alerte;
  final VoidCallback onTap;

  const _AlerteCard({
    required this.alerte,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final estHumidite = alerte.type == TypeAlerte.humidite;

    final couleur = estHumidite
        ? Colors.orange
        : Colors.blue;

    final icone = estHumidite
        ? Icons.water_drop
        : Icons.cloud;

    final date = alerte.date;

    final dateFormatee =
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} à '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: couleur.withValues(alpha: 0.15),
          child: Icon(icone, color: couleur),
        ),
        title: Text(
          alerte.titre,
          style: TextStyle(
            fontWeight:
            alerte.lue ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(alerte.message),
              const SizedBox(height: 6),
              Text(
                dateFormatee,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        trailing: alerte.lue
            ? const Icon(Icons.check_circle_outline)
            : Icon(Icons.circle, color: couleur, size: 12),
      ),
    );
  }
}
