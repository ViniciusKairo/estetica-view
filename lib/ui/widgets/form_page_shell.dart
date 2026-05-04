import 'package:flutter/material.dart';

import 'app_page_header.dart';

class FormPageShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const FormPageShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        AppPageHeader(title: title, subtitle: subtitle, icon: icon),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}
