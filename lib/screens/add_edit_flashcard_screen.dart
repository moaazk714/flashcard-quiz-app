import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';

import '../models/flashcard.dart';
import '../providers/flashcard_provider.dart';

class AddEditFlashcardScreen extends StatefulWidget {
  final Flashcard? flashcard;
  final int? cardIndex;

  const AddEditFlashcardScreen({super.key, this.flashcard, this.cardIndex});

  bool get isEditing => flashcard != null && cardIndex != null;

  @override
  State<AddEditFlashcardScreen> createState() => _AddEditFlashcardScreenState();
}

class _AddEditFlashcardScreenState extends State<AddEditFlashcardScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _questionController;
  late final QuillController _answerController;
  late final FocusNode _answerFocusNode;

  bool _showTip = true;
  bool _isPreviewExpanded = true;

  String _selectedConfidence = 'New';
  String _selectedCategory = 'Flutter Basics';

  static const int _maxQuestionLength = 120;
  static const int _maxAnswerLength = 350;

  static const List<String> _categories = [
    'Flutter Basics',
    'Dart Programming',
    'OOP',
    'Widgets',
    'State Management',
    'Firebase',
    'API Integration',
    'Other',
  ];

  static const Color _primaryColor = Color(0xFF4338CA);
  static const Color _textColor = Color(0xFF0F172A);
  static const Color _mutedColor = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();

    _questionController = TextEditingController(
      text: widget.flashcard?.question ?? '',
    );

    _answerFocusNode = FocusNode();

    final savedAnswer = widget.flashcard?.answer ?? '';
    final document = _loadAnswerDocument(savedAnswer);

    _answerController = QuillController(
      document: document,
      selection: TextSelection.collapsed(offset: document.length - 1),
      readOnly: false,
    );

    if (widget.flashcard != null) {
      _selectedConfidence = widget.flashcard!.confidence;

      _selectedCategory = _categories.contains(widget.flashcard!.category)
          ? widget.flashcard!.category
          : 'Other';
    }

    _questionController.addListener(_onTextChanged);
    _answerController.addListener(_onTextChanged);
  }

  Document _loadAnswerDocument(String savedAnswer) {
    if (savedAnswer.isEmpty) {
      return Document();
    }

    try {
      final decoded = jsonDecode(savedAnswer);

      if (decoded is List) {
        return Document.fromJson(decoded);
      }
    } catch (_) {
      // Support previously saved plain-text answers.
    }

    final document = Document();
    document.insert(0, savedAnswer);

    return document;
  }

  void _onTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _questionController.removeListener(_onTextChanged);
    _answerController.removeListener(_onTextChanged);

    _questionController.dispose();
    _answerController.dispose();
    _answerFocusNode.dispose();

    super.dispose();
  }

  void _showFormattingOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Text Formatting',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  QuillSimpleToolbar(
                    controller: _answerController,
                    config: const QuillSimpleToolbarConfig(
                      showFontFamily: true,
                      buttonOptions: QuillSimpleToolbarButtonOptions(
                        fontFamily: QuillToolbarFontFamilyButtonOptions(
                          items: {
                            'Poppins': 'Poppins',
                            'Sans Serif': 'sans-serif',
                            'Serif': 'serif',
                            'Monospace': 'monospace',
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _saveFlashcard() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final question = _questionController.text.trim();

    final answer = _answerController.document.toPlainText().trim();

    if (answer.isEmpty) {
      _showMessage('Answer cannot be empty.');
      return;
    }

    if (answer.length > _maxAnswerLength) {
      _showMessage('Answer must be $_maxAnswerLength characters or fewer.');
      return;
    }

    final answerJson = jsonEncode(
      _answerController.document.toDelta().toJson(),
    );

    final provider = context.read<FlashcardProvider>();

    if (widget.isEditing) {
      final updatedCard = widget.flashcard!.copyWith(
        question: question,
        answer: answerJson,
        confidence: _selectedConfidence,
        category: _selectedCategory,
      );

      provider.editFlashcard(widget.cardIndex!, updatedCard);

      _showMessage('Flashcard updated successfully!', success: true);
    } else {
      final newCard = Flashcard(
        id: '${DateTime.now().microsecondsSinceEpoch}',
        question: question,
        answer: answerJson,
        category: _selectedCategory,
        confidence: _selectedConfidence,
        tags: ['Custom', 'Study'],
      );

      provider.addFlashcard(newCard);

      _showMessage('Flashcard created successfully!', success: true);
    }

    Navigator.pop(context);
  }

  void _showMessage(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success
            ? const Color(0xFF10B981)
            : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing ? 'Edit Flashcard' : 'Create Flashcard';

    final cardIdNumber = widget.isEditing
        ? (widget.cardIndex! + 1).toString()
        : (context.read<FlashcardProvider>().totalCards + 1).toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FLASHCARD QUIZ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
                letterSpacing: 0.6,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderBadges(cardIdNumber),
                const SizedBox(height: 14),

                if (_showTip) _buildProTipBanner(),
                if (_showTip) const SizedBox(height: 16),

                _buildQuestionField(),
                const SizedBox(height: 20),

                _buildCategoryField(),
                const SizedBox(height: 20),

                _buildAnswerField(),
                const SizedBox(height: 20),

                _buildConfidenceSection(),
                const SizedBox(height: 24),

                _buildActionButtons(),
                const SizedBox(height: 20),

                _buildLivePreviewCard(cardIdNumber),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBadges(String cardIdNumber) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.isEditing
                    ? Icons.edit_note_rounded
                    : Icons.folder_outlined,
                size: 16,
                color: _primaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                widget.isEditing
                    ? 'Editing Card #$cardIdNumber'
                    : 'Deck: Flutter Foundations',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _primaryColor,
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, size: 14, color: _primaryColor),
            const SizedBox(width: 4),
            Text(
              'Card #$cardIdNumber',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _primaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProTipBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              color: Color(0xFF2563EB),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pro Recall Tip',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _showTip = false;
                        });
                      },
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: _mutedColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Keep questions clear and answers concise '
                  'for effective active recall.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF3B82F6),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionField() {
    final currentLength = _questionController.text.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Question *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _textColor,
              ),
            ),
            Text(
              '$currentLength / $_maxQuestionLength',
              style: TextStyle(
                fontSize: 12,
                color: currentLength > _maxQuestionLength
                    ? Colors.red
                    : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _questionController,
          maxLength: _maxQuestionLength,
          style: const TextStyle(
            fontSize: 14.5,
            color: _textColor,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            hintText: 'e.g., What is state management in Flutter?',
            hintStyle: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13.5,
            ),
            prefixIcon: const Icon(
              Icons.help_outline_rounded,
              color: _mutedColor,
              size: 20,
            ),
            suffixIcon: _questionController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    color: const Color(0xFF94A3B8),
                    onPressed: _questionController.clear,
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _primaryColor, width: 1.8),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Question cannot be empty';
            }

            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCategoryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _textColor,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedCategory,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(Icons.category_outlined, color: _mutedColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _borderColor),
            ),
          ),
          items: _categories.map((category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedCategory = value;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildAnswerField() {
    final plainAnswer = _answerController.document.toPlainText().trim();

    final currentLength = plainAnswer.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Answer *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _textColor,
              ),
            ),
            Text(
              '$currentLength / $_maxAnswerLength',
              style: TextStyle(
                fontSize: 12,
                color: currentLength > _maxAnswerLength
                    ? Colors.red
                    : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderColor),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Text Styling',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Text Styles',
                icon: const Icon(Icons.text_format, color: _primaryColor),
                onPressed: _showFormattingOptions,
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderColor),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: QuillEditor.basic(
              controller: _answerController,
              focusNode: _answerFocusNode,
              config: const QuillEditorConfig(
                placeholder: 'Write your flashcard answer...',
                padding: EdgeInsets.all(16),
                autoFocus: false,
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        if (currentLength > _maxAnswerLength)
          const Text(
            'Answer is too long. Remove some text.',
            style: TextStyle(color: Colors.red, fontSize: 12),
          ),

        const SizedBox(height: 4),

        const Row(
          children: [
            Icon(Icons.info_outline, size: 15, color: Color(0xFF6366F1)),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'Tap the text styling button to format your answer.',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConfidenceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(
              child: Text(
                'Card Confidence Setting',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _textColor,
                ),
              ),
            ),
            Text(
              'Default: $_selectedConfidence',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6366F1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildConfidenceChip(
                label: 'New',
                icon: Icons.psychology_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildConfidenceChip(
                label: 'Review',
                icon: Icons.cached_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildConfidenceChip(
                label: 'Mastered',
                icon: Icons.verified_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConfidenceChip({required String label, required IconData icon}) {
    final isSelected = _selectedConfidence == label;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedConfidence = label;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _primaryColor : _borderColor,
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? _primaryColor : _mutedColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? _primaryColor : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final saveLabel = widget.isEditing ? 'Save Changes' : 'Save Flashcard';

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _saveFlashcard,
            icon: const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            label: Text(
              saveLabel,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B33D1),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFEEF2FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLivePreviewCard(String cardIdNumber) {
    final question = _questionController.text.trim();

    final previewQuestion = question.isEmpty ? 'Empty question...' : question;

    final answerDocument = _answerController.document;
    final plainAnswer = answerDocument.toPlainText().trim();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.style_outlined,
                      size: 16,
                      color: _primaryColor,
                    ),
                    Text(
                      '#$cardIdNumber',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PREVIEW CARD',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _primaryColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      previewQuestion,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: _textColor,
                      ),
                    ),
                    Text(
                      plainAnswer.isEmpty
                          ? 'Your answer will appear here.'
                          : plainAnswer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: _mutedColor,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  _isPreviewExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: _primaryColor,
                ),
                onPressed: () {
                  setState(() {
                    _isPreviewExpanded = !_isPreviewExpanded;
                  });
                },
              ),
            ],
          ),
          if (_isPreviewExpanded && plainAnswer.isNotEmpty) ...[
            const Divider(color: Color(0xFFC7D2FE), height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Full Answer Preview:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _primaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  QuillEditor.basic(
                    controller: QuillController(
                      document: Document.fromJson(
                        answerDocument.toDelta().toJson(),
                      ),
                      selection: const TextSelection.collapsed(offset: 0),
                      readOnly: true,
                    ),
                    config: const QuillEditorConfig(
                      padding: EdgeInsets.zero,
                      showCursor: false,
                      enableInteractiveSelection: false,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
