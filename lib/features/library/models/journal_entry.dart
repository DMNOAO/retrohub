class JournalEntry {
  final int? id;
  final int gameId;
  final String content;
  final DateTime createdAt;

  const JournalEntry({
    this.id,
    required this.gameId,
    required this.content,
    required this.createdAt,
  });
}