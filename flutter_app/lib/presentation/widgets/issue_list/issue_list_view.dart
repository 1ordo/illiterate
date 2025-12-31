import 'package:flutter/material.dart';
import '../../../data/models/grammar_issue.dart';
import 'issue_card.dart';

/// List view for displaying grammar issues.
class IssueListView extends StatelessWidget {
  final List<GrammarIssue> issues;
  final GrammarIssue? selectedIssue;
  final ValueChanged<GrammarIssue?>? onIssueSelected;

  const IssueListView({
    super.key,
    required this.issues,
    this.selectedIssue,
    this.onIssueSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (issues.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'No issues found!',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Your text looks great.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: issues.map((issue) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: IssueCard(
            issue: issue,
            isSelected: issue == selectedIssue,
            onTap: () {
              if (issue == selectedIssue) {
                onIssueSelected?.call(null);
              } else {
                onIssueSelected?.call(issue);
              }
            },
          ),
        );
      }).toList(),
    );
  }
}
