import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../providers/current_directory_provider.dart';
import '../../providers/question_provider.dart';
import '../../service/api/models/question.dart';
import '../../theme/app_tokens.dart';

class QuestionOverlayCard extends StatelessWidget {
  const QuestionOverlayCard({super.key, required this.request});

  final QuestionRequest request;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardInset = mediaQuery.viewInsets.bottom;

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.fromLTRB(10, 28, 10, keyboardInset + 16),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = math.min<double>(constraints.maxWidth, 760);
                final maxHeight = math.max<double>(
                  320,
                  constraints.maxHeight * 0.7,
                );

                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxWidth,
                    maxHeight: maxHeight,
                  ),
                  child: QuestionRequestCard(request: request),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class QuestionRequestCard extends ConsumerStatefulWidget {
  const QuestionRequestCard({super.key, required this.request});

  final QuestionRequest request;

  @override
  ConsumerState<QuestionRequestCard> createState() =>
      _QuestionRequestCardState();
}

class _QuestionRequestCardState extends ConsumerState<QuestionRequestCard> {
  int _currentIndex = 0;
  late final List<List<String>> _answers;
  late final List<TextEditingController> _customControllers;
  late final List<bool> _customSelected;

  @override
  void initState() {
    super.initState();
    final count = widget.request.questions.length;
    _answers = List.generate(count, (_) => []);
    _customControllers = List.generate(count, (_) => TextEditingController());
    _customSelected = List.generate(count, (_) => false);
  }

  @override
  void dispose() {
    for (final c in _customControllers) {
      c.dispose();
    }
    super.dispose();
  }

  QuestionInfo get _currentQuestion => widget.request.questions[_currentIndex];

  bool get _isLastQuestion =>
      _currentIndex == widget.request.questions.length - 1;

  bool get _canGoBack => _currentIndex > 0;

  bool get _canProceed {
    final selected = _answers[_currentIndex];
    final hasCustomInput = _customControllers[_currentIndex].text
        .trim()
        .isNotEmpty;
    final hasSelectedCustom = _customSelected[_currentIndex] && hasCustomInput;
    return selected.isNotEmpty || hasSelectedCustom;
  }

  void _toggleOption(String label) {
    final current = _answers[_currentIndex];
    final isMultiple = _currentQuestion.multiple ?? false;
    if (!isMultiple) {
      FocusScope.of(context).unfocus();
    }

    setState(() {
      if (isMultiple) {
        if (current.contains(label)) {
          _answers[_currentIndex] = current.where((l) => l != label).toList();
        } else {
          _answers[_currentIndex] = [...current, label];
        }
      } else {
        _customSelected[_currentIndex] = false;
        _answers[_currentIndex] = [label];
      }
    });
  }

  void _selectCustomAnswer() {
    final isMultiple = _currentQuestion.multiple ?? false;
    setState(() {
      if (!isMultiple) {
        _answers[_currentIndex] = [];
      }
      _customSelected[_currentIndex] = true;
    });
  }

  void _toggleCustomAnswer() {
    final isMultiple = _currentQuestion.multiple ?? false;
    if (!isMultiple) {
      _selectCustomAnswer();
      return;
    }
    setState(() {
      _customSelected[_currentIndex] = !_customSelected[_currentIndex];
    });
  }

  void _onPrevious() {
    if (_canGoBack) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  Future<void> _onNext() async {
    if (_isLastQuestion) {
      await _submit();
    } else {
      setState(() {
        _currentIndex++;
      });
    }
  }

  Future<void> _submit() async {
    final directory = ref.read(currentDirectoryProvider);
    final answers = List.generate(widget.request.questions.length, (i) {
      final merged = List<String>.from(_answers[i]);
      final customText = _customControllers[i].text.trim();
      if (_customSelected[i] &&
          customText.isNotEmpty &&
          !merged.contains(customText)) {
        merged.add(customText);
      }
      return merged;
    });

    await ref
        .read(pendingQuestionsProvider.notifier)
        .reply(widget.request.id, answers: answers, directory: directory);
  }

  Future<void> _reject() async {
    final directory = ref.read(currentDirectoryProvider);
    await ref
        .read(pendingQuestionsProvider.notifier)
        .reject(widget.request.id, directory: directory);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tokens = context.tokens;
    final question = _currentQuestion;
    final total = widget.request.questions.length;
    final isMultiple = question.multiple ?? false;
    final hasCustom = question.custom ?? true;

    return Material(
      key: const Key('question_overlay.surface'),
      color: colorScheme.surface,
      elevation: 14,
      shadowColor: colorScheme.onSurface.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: tokens.border.withValues(alpha: 0.65)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.onSurface.withValues(alpha: 0.08),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      question.header.isNotEmpty
                          ? question.header
                          : 'Question ${_currentIndex + 1} / $total',
                      style: textTheme.labelLarge?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: tokens.accentForeground,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _StepDots(
                    total: total,
                    current: _currentIndex,
                    activeColor: colorScheme.primary,
                    inactiveColor: tokens.border,
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: tokens.border.withValues(alpha: 0.45)),
            Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                key: const Key('question_overlay.scroll'),
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Question ${_currentIndex + 1} / $total',
                      style: textTheme.labelMedium?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: tokens.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      question.question,
                      style: textTheme.titleMedium?.copyWith(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 18,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isMultiple
                          ? l10n.questionCardSelectOneOrMore
                          : l10n.questionCardSelectOne,
                      style: textTheme.labelMedium?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: tokens.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _OptionsList(
                      question: question,
                      selected: _answers[_currentIndex],
                      customController: _customControllers[_currentIndex],
                      onToggle: _toggleOption,
                      hasCustom: hasCustom,
                      onCustomChanged: (_) => setState(() {}),
                      onCustomSelected: _selectCustomAnswer,
                      onCustomToggled: _toggleCustomAnswer,
                      customSelected: _customSelected[_currentIndex],
                      isMultiple: isMultiple,
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: tokens.border.withValues(alpha: 0.45)),
            Padding(
              key: const Key('question_overlay.actions'),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _reject,
                    style: TextButton.styleFrom(
                      foregroundColor: tokens.mutedForeground,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      l10n.questionCardIgnore,
                      style: textTheme.labelLarge?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (_canGoBack) ...[
                    OutlinedButton(
                      onPressed: _onPrevious,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        side: BorderSide(color: tokens.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l10n.questionCardPrevious,
                        style: textTheme.labelLarge?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: tokens.accentForeground,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  FilledButton(
                    onPressed: _canProceed ? _onNext : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _isLastQuestion
                          ? l10n.questionCardSubmit
                          : l10n.questionCardNext,
                      style: textTheme.labelLarge?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({
    required this.total,
    required this.current,
    required this.activeColor,
    required this.inactiveColor,
  });

  final int total;
  final int current;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final isActive = i == current;
        return Container(
          margin: EdgeInsets.only(left: i == 0 ? 0 : 6),
          width: isActive ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _OptionsList extends StatelessWidget {
  const _OptionsList({
    required this.question,
    required this.selected,
    required this.customController,
    required this.onToggle,
    required this.hasCustom,
    required this.onCustomChanged,
    required this.onCustomSelected,
    required this.onCustomToggled,
    required this.customSelected,
    required this.isMultiple,
  });

  final QuestionInfo question;
  final List<String> selected;
  final TextEditingController customController;
  final void Function(String label) onToggle;
  final bool hasCustom;
  final void Function(String) onCustomChanged;
  final VoidCallback onCustomSelected;
  final VoidCallback onCustomToggled;
  final bool customSelected;
  final bool isMultiple;

  @override
  Widget build(BuildContext context) {
    final options = <Widget>[
      for (final opt in question.options) ...[
        _OptionTile(
          label: opt.label,
          description: opt.description,
          isSelected: selected.contains(opt.label),
          isMultiple: isMultiple,
          onTap: () => onToggle(opt.label),
        ),
        const SizedBox(height: 8),
      ],
    ];

    if (hasCustom) {
      options.add(
        _CustomInputTile(
          controller: customController,
          onChanged: onCustomChanged,
          onSelected: onCustomSelected,
          onToggled: onCustomToggled,
          isSelected: customSelected,
          isMultiple: isMultiple,
        ),
      );
    } else if (options.isNotEmpty) {
      options.removeLast();
    }

    return Column(children: options);
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.description,
    required this.isSelected,
    required this.isMultiple,
    required this.onTap,
  });

  final String label;
  final String description;
  final bool isSelected;
  final bool isMultiple;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tokens = context.tokens;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? colorScheme.primary : tokens.border,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 18,
              height: 18,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                shape: isMultiple ? BoxShape.rectangle : BoxShape.circle,
                borderRadius: isMultiple ? BorderRadius.circular(5) : null,
                color: isSelected ? colorScheme.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary
                      : tokens.mutedForeground.withValues(alpha: 0.6),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 12, color: colorScheme.onPrimary)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: textTheme.labelLarge?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        height: 1.35,
                        color: tokens.mutedForeground,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomInputTile extends StatefulWidget {
  const _CustomInputTile({
    required this.controller,
    required this.onChanged,
    required this.onSelected,
    required this.onToggled,
    required this.isSelected,
    required this.isMultiple,
  });

  final TextEditingController controller;
  final void Function(String) onChanged;
  final VoidCallback onSelected;
  final VoidCallback onToggled;
  final bool isSelected;
  final bool isMultiple;

  @override
  State<_CustomInputTile> createState() => _CustomInputTileState();
}

class _CustomInputTileState extends State<_CustomInputTile> {
  bool _focused = false;
  late final FocusNode _focusNode;

  bool get _isSelected => widget.isSelected;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tokens = context.tokens;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.isMultiple
          ? () {
              widget.onToggled();
              if (widget.isSelected) {
                _focusNode.unfocus();
              } else {
                _focusNode.requestFocus();
              }
            }
          : () {
              widget.onSelected();
              _focusNode.requestFocus();
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _focused ? colorScheme.primary : tokens.border,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: widget.isMultiple ? BoxShape.rectangle : BoxShape.circle,
                borderRadius: widget.isMultiple
                    ? BorderRadius.circular(5)
                    : null,
                color: _isSelected ? colorScheme.primary : Colors.transparent,
                border: Border.all(
                  color: _isSelected
                      ? colorScheme.primary
                      : tokens.mutedForeground.withValues(alpha: 0.6),
                  width: 2,
                ),
              ),
              child: _isSelected
                  ? Icon(Icons.check, size: 12, color: colorScheme.onPrimary)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Focus(
                onFocusChange: (v) {
                  if (v && !_isSelected) {
                    widget.onSelected();
                  }
                  setState(() => _focused = v);
                },
                child: TextField(
                  focusNode: _focusNode,
                  controller: widget.controller,
                  onChanged: (value) {
                    if (value.trim().isNotEmpty) {
                      widget.onSelected();
                    }
                    setState(() {});
                    widget.onChanged(value);
                  },
                  style: textTheme.labelLarge?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: context.l10n.questionCardCustomAnswerHint,
                    hintStyle: textTheme.labelLarge?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: tokens.mutedForeground.withValues(alpha: 0.6),
                    ),
                    filled: false,
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
