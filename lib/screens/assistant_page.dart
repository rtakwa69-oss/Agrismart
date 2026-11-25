import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/providers/assistant_provider.dart';

class AssistantPage extends StatefulWidget {
  const AssistantPage({super.key});

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  final _controleur = TextEditingController();

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  Future<void> _envoyer([String? texteForce]) async {
    final texte = texteForce ?? _controleur.text;
    if (texte.trim().isEmpty) return;
    if (texteForce == null) {
      _controleur.clear();
    }
    await context.read<AssistantProvider>().envoyerMessage(texte);
  }

  @override
  Widget build(BuildContext context) {
    final assistant = context.watch<AssistantProvider>();
    final messages = assistant.messages;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant AgriSmart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Nouvelle discussion',
            onPressed: assistant.effacerConversation,
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                ActionChip(
                  label: const Text('Zones à irriguer'),
                  onPressed: () => _envoyer('Quelles zones ont besoin d\'irrigation ?'),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text('État des vannes'),
                  onPressed: () => _envoyer('Quelles vannes sont ouvertes ?'),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text('Résumé'),
                  onPressed: () => _envoyer('Donne-moi un résumé de mes parcelles'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final alignement =
                msg.estUtilisateur ? Alignment.centerRight : Alignment.centerLeft;
                final couleur = msg.estUtilisateur
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest;

                return Align(
                  alignment: alignement,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 320),
                    decoration: BoxDecoration(
                      color: couleur,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(msg.texte),
                  ),
                );
              },
            ),
          ),
          if (assistant.enCours) const LinearProgressIndicator(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controleur,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _envoyer(),
                      decoration: const InputDecoration(
                        hintText: 'Posez une question sur vos zones...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: assistant.enCours ? null : () => _envoyer(),
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}