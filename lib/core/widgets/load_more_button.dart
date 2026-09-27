import 'package:flutter/material.dart';

import '../localization/l10n.dart';

/// Last row of a paged list: fetches the next page when tapped.
class LoadMoreButton extends StatelessWidget {
  const LoadMoreButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.expand_more_rounded),
          label: Text(context.l10n.loadMore),
        ),
      ),
    );
  }
}
