import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';

/// Chip-based tone selector.
class ToneSelector extends StatelessWidget {
  final Tone selectedTone;
  final ValueChanged<Tone>? onToneChanged;

  const ToneSelector({
    super.key,
    required this.selectedTone,
    this.onToneChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: Tone.values.map((tone) {
          final isSelected = tone == selectedTone;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getToneIcon(tone),
                    size: 16,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(tone.displayName),
                ],
              ),
              selected: isSelected,
              onSelected: (_) => onToneChanged?.call(tone),
              visualDensity: VisualDensity.compact,
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _getToneIcon(Tone tone) {
    switch (tone) {
      case Tone.neutral:
        return Icons.balance;
      case Tone.formal:
        return Icons.business;
      case Tone.casual:
        return Icons.chat_bubble_outline;
      case Tone.academic:
        return Icons.school;
    }
  }
}

/// Dropdown-style tone selector.
class ToneDropdown extends StatelessWidget {
  final Tone selectedTone;
  final ValueChanged<Tone>? onToneChanged;

  const ToneDropdown({
    super.key,
    required this.selectedTone,
    this.onToneChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Tone>(
      value: selectedTone,
      decoration: const InputDecoration(
        labelText: 'Tone',
        prefixIcon: Icon(Icons.tune),
        border: OutlineInputBorder(),
      ),
      items: Tone.values.map((tone) {
        return DropdownMenuItem<Tone>(
          value: tone,
          child: Row(
            children: [
              Icon(_getToneIcon(tone), size: 20),
              const SizedBox(width: 12),
              Text(tone.displayName),
            ],
          ),
        );
      }).toList(),
      onChanged: (tone) {
        if (tone != null) {
          onToneChanged?.call(tone);
        }
      },
    );
  }

  IconData _getToneIcon(Tone tone) {
    switch (tone) {
      case Tone.neutral:
        return Icons.balance;
      case Tone.formal:
        return Icons.business;
      case Tone.casual:
        return Icons.chat_bubble_outline;
      case Tone.academic:
        return Icons.school;
    }
  }
}
