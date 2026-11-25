class MessageChat {
  final String texte;
  final bool estUtilisateur;
  final DateTime date;

  MessageChat({
    required this.texte,
    required this.estUtilisateur,
    DateTime? date,
  }) : date = date ?? DateTime.now();
}