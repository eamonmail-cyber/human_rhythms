class Outcome {
  final String id;
  final String userId;
  final String date;
  final int? mood, energy, sleepQuality, pain, focus;
  final String? notes;
  Outcome({
    required this.id, required this.userId, required this.date,
    this.mood, this.energy, this.sleepQuality, this.pain, this.focus, this.notes,
  });

  factory Outcome.fromMap(String id, Map<String,dynamic> m) => Outcome(
    id: id, userId: m['userId'], date: m['date'],
    mood: m['mood'], energy: m['energy'], sleepQuality: m['sleepQuality'],
    pain: m['pain'], focus: m['focus'], notes: m['notes'],
  );
  Map<String,dynamic> toMap() => {
    'userId': userId,'date': date,'mood': mood,'energy': energy,
    'sleepQuality': sleepQuality,'pain': pain,'focus': focus,'notes': notes,
  };
}
