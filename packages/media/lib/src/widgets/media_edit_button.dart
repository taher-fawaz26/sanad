import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The small circular edit affordance shown over a cover or avatar image.
class MediaEditButton extends StatelessWidget {
  const MediaEditButton({required this.onTap, this.semanticLabel, super.key});

  final VoidCallback onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel ?? 'media.edit_button_a11y'.tr(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.edit_outlined,
              size: 14,
              color: Color(0xFF101828),
            ),
          ),
        ),
      ),
    );
  }
}
