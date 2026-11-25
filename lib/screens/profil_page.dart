import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:agrismart/providers/auth_provider.dart';
import 'package:agrismart/providers/zones_provider.dart';
import 'package:agrismart/providers/reglages_provider.dart';

class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    final texte = Theme.of(context).textTheme;

    final nombreZones = context.select<ZonesProvider, int>(
          (provider) => provider.nombre,
    );

    final email = context.select<AuthProvider, String>(
          (a) => a.utilisateur?.email ?? '',
    );

    final themeMode = context.select<ReglagesProvider, ThemeMode>(
          (r) => r.themeMode,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
        Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Profil'),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),

          const Center(
            child: CircleAvatar(
              radius: 40,
              child: Icon(Icons.agriculture, size: 40),
            ),
          ),

          const SizedBox(height: 12),

          Center(
            child: Text(
              'Exploitation AgriSmart',
              style: texte.titleLarge,
            ),
          ),

          Center(
            child: Text(
              email,
              style: texte.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),

          const SizedBox(height: 16),

          const Divider(),

          // Nombre de zones
          ListTile(
            leading: const Icon(Icons.grass),
            title: const Text('Zones suivies'),
            trailing: Text('$nombreZones'),
          ),

          const Divider(),

          // Nouveau : choix du thème
          const ListTile(
            leading: Icon(Icons.brightness_6),
            title: Text('Apparence'),
            subtitle: Text('Choisir le thème de l’application'),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.system,
                  label: Text('Système'),
                  icon: Icon(Icons.settings_brightness),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.light,
                  label: Text('Clair'),
                  icon: Icon(Icons.light_mode),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.dark,
                  label: Text('Sombre'),
                  icon: Icon(Icons.dark_mode),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (selection) {
                context
                    .read<ReglagesProvider>()
                    .changerTheme(selection.first);
              },
            ),
          ),

          const Divider(),

          // Déconnexion
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Se déconnecter'),
            onTap: () => _confirmerDeconnexion(context),
          ),

          const Divider(),

          // À propos
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text(
              'À propos',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text(
              'Découvrir l’application AgriSmart',
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
            ),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'AgriSmart',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(
                  Icons.agriculture,
                  size: 40,
                ),
                children: [
                  const Text(
                    'AgriSmart est une application mobile '
                        'de gestion et de suivi des exploitations agricoles.',
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Elle permet de gérer les zones agricoles, '
                        'surveiller l’humidité du sol et suivre '
                        'les besoins en irrigation.',
                  ),
                  const SizedBox(height: 10),
                  const Text('Localisation : Kébili, Tunisie'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmerDeconnexion(
      BuildContext context,
      ) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text(
          'Voulez-vous vraiment vous déconnecter ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );

    if (confirme != true || !context.mounted) return;

    await context.read<AuthProvider>().deconnexion();
  }
}
