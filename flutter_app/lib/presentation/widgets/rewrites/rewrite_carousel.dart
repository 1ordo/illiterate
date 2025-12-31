import 'package:flutter/material.dart';
import '../../../data/models/rewrite_suggestion.dart';
import 'rewrite_card.dart';

/// Carousel for displaying rewrite suggestions.
class RewriteCarousel extends StatelessWidget {
  final List<RewriteSuggestion> rewrites;
  final int? selectedIndex;
  final ValueChanged<int?>? onRewriteSelected;
  final VoidCallback? onApply;

  const RewriteCarousel({
    super.key,
    required this.rewrites,
    this.selectedIndex,
    this.onRewriteSelected,
    this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    if (rewrites.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.edit_note,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                'No rewrite suggestions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Try using Style mode for rewrite suggestions.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // For single rewrite, show directly
    if (rewrites.length == 1) {
      return RewriteCard(
        rewrite: rewrites.first,
        isSelected: selectedIndex == 0,
        onTap: () {
          if (selectedIndex == 0) {
            onRewriteSelected?.call(null);
          } else {
            onRewriteSelected?.call(0);
          }
        },
        onApply: onApply,
      );
    }

    // For multiple rewrites, show as horizontal list
    return SizedBox(
      height: selectedIndex != null ? 320 : 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: rewrites.length,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemBuilder: (context, index) {
          return SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: RewriteCard(
                rewrite: rewrites[index],
                isSelected: selectedIndex == index,
                onTap: () {
                  if (selectedIndex == index) {
                    onRewriteSelected?.call(null);
                  } else {
                    onRewriteSelected?.call(index);
                  }
                },
                onApply: onApply,
              ),
            ),
          );
        },
      ),
    );
  }
}
