class Breed {
  const Breed({
    required this.id,
    required this.name,
    this.nameIt,
  });

  final String id;
  final String name;
  final String? nameIt;
}
