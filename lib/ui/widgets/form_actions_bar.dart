import 'package:flutter/material.dart';

class FormActionsBar extends StatelessWidget {
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String secondaryLabel;
  final VoidCallback? onSecondary;
  final bool loading;

  const FormActionsBar({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 760;

    final primaryChild = loading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(primaryLabel);

    if (isWide) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: loading ? null : onSecondary,
              child: Text(secondaryLabel),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: loading ? null : onPrimary,
              child: primaryChild,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        OutlinedButton(
          onPressed: loading ? null : onSecondary,
          child: Text(secondaryLabel),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: loading ? null : onPrimary,
          child: primaryChild,
        ),
      ],
    );
  }
}
