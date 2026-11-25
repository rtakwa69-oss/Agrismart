
enum TypeAlerte {
  humidite,
  pluie,
}

class Alerte {
  final String id;
  final String titre;
  final String message;
  final TypeAlerte type;
  final DateTime date;
  bool lue;

  Alerte({
    required this.id,
    required this.titre,
    required this.message,
    required this.type,
    DateTime? date,
    this.lue = false,
  }) : date = date ?? DateTime.now();

  Alerte copyWith({
    String? titre,
    String? message,
    bool? lue,
  }) {
    return Alerte(
      id: id,
      titre: titre ?? this.titre,
      message: message ?? this.message,
      type: type,
      date: date,
      lue: lue ?? this.lue,
    );
  }
}
