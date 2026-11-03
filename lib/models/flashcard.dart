/// Represents a single flashcard with a question, answer, and optional metadata.
class Flashcard {
  final String id;
  final String question;
  final String answer;
  final String category;
  final List<String> tags;
  final String confidence; // 'New', 'Review', 'Mastered'

  const Flashcard({
    required this.id,
    required this.question,
    required this.answer,
    this.category = 'Flutter Basics',
    this.tags = const [],
    this.confidence = 'New',
  });

  /// Creates a copy of this Flashcard with updated fields.
  Flashcard copyWith({
    String? id,
    String? question,
    String? answer,
    String? category,
    List<String>? tags,
    String? confidence,
  }) {
    return Flashcard(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      confidence: confidence ?? this.confidence,
    );
  }
}
