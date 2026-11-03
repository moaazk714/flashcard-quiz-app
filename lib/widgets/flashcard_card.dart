import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/flashcard.dart';

class FlashcardCard extends StatefulWidget {
  final Flashcard card;
  final bool isAnswerVisible;
  final VoidCallback onShowAnswer;
  final VoidCallback onHideAnswer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(String rating)? onRate;

  const FlashcardCard({
    super.key,
    required this.card,
    required this.isAnswerVisible,
    required this.onShowAnswer,
    required this.onHideAnswer,
    required this.onEdit,
    required this.onDelete,
    this.onRate,
  });

  @override
  State<FlashcardCard> createState() => _FlashcardCardState();
}

class _FlashcardCardState extends State<FlashcardCard> {
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    setupTts();
  }

  Future<void> setupTts() async {
    await flutterTts.setLanguage('en-US');
    await flutterTts.setSpeechRate(0.45);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
  }

  Future<void> speakAnswer() async {
    String answer = widget.card.answer.trim();

    if (answer.isEmpty) return;

    try {
      await flutterTts.stop();
      await flutterTts.speak(answer);
    } catch (e) {
      if (!mounted) return;
      showMessage('Unable to read the answer aloud.');
    }
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: widget.isAnswerVisible
            ? _buildAnswerView()
            : _buildQuestionView(),
      ),
    );
  }

  // Question View
  Widget _buildQuestionView() {
    return Column(
      key: const ValueKey('question'),
      children: [
        _buildTopBar(),
        const SizedBox(height: 32),

        const CircleAvatar(
          radius: 32,
          backgroundColor: Color(0xFFEEF2FF),
          child: Icon(
            Icons.psychology_outlined,
            color: Color(0xFF4338CA),
            size: 32,
          ),
        ),

        const SizedBox(height: 20),

        Text(
          widget.card.question,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Think about your answer, then reveal it.',
          style: TextStyle(color: Color(0xFF64748B)),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 36),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: widget.onShowAnswer,
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('Show Answer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B33D1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Answer View
  Widget _buildAnswerView() {
    return Column(
      key: const ValueKey('answer'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTopBar(),
        const SizedBox(height: 14),

        Text(
          widget.card.question,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),

        const SizedBox(height: 4),

        Text(
          widget.card.category,
          style: const TextStyle(color: Color(0xFF64748B)),
        ),

        const SizedBox(height: 16),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildBadge('ANSWER'),

                  Row(
                    children: [
                      IconButton(
                        onPressed: speakAnswer,
                        icon: const Icon(Icons.volume_up_outlined),
                        tooltip: 'Read Answer Aloud',
                      ),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: widget.card.answer),
                          );
                          showMessage('Answer copied to clipboard!');
                        },
                        icon: const Icon(Icons.copy_rounded),
                        tooltip: 'Copy Answer',
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                widget.card.answer,
                style: const TextStyle(
                  fontSize: 14.5,
                  height: 1.55,
                  color: Color(0xFF1E293B),
                ),
              ),

              if (widget.card.tags.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: widget.card.tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      backgroundColor: const Color(0xFFEEF2FF),
                      labelStyle: const TextStyle(
                        color: Color(0xFF4338CA),
                        fontSize: 11,
                      ),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 18),

        const Center(
          child: Text(
            'Did you recall this correctly?',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            _ratingButton(
              'Hard',
              Icons.sentiment_dissatisfied_outlined,
              const Color(0xFFEF4444),
            ),
            const SizedBox(width: 8),
            _ratingButton(
              'Good',
              Icons.sentiment_neutral_outlined,
              const Color(0xFF3B82F6),
            ),
            const SizedBox(width: 8),
            _ratingButton(
              'Easy',
              Icons.sentiment_very_satisfied_outlined,
              const Color(0xFF8B5CF6),
            ),
          ],
        ),

        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: widget.onHideAnswer,
            icon: const Icon(Icons.visibility_off_outlined),
            label: const Text('Hide Answer'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF3B33D1),
              backgroundColor: const Color(0xFFEEF2FF),
              side: const BorderSide(color: Color(0xFFC7D2FE)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Top Bar with Edit and Delete
  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildBadge('QUESTION'),
        Row(
          children: [
            IconButton(
              onPressed: widget.onEdit,
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Flashcard',
            ),
            IconButton(
              onPressed: widget.onDelete,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFDC2626),
              ),
              tooltip: 'Delete Flashcard',
            ),
          ],
        ),
      ],
    );
  }

  // Reusable Badge
  Widget _buildBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4338CA),
        ),
      ),
    );
  }

  // Recall Rating Button
  Widget _ratingButton(String label, IconData icon, Color color) {
    return Expanded(
      child: InkWell(
        onTap: () {
          widget.onRate?.call(label);
          showMessage('Marked as $label!');
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
