import 'package:flutter/material.dart';
import 'package:my_first_game/theme/app_theme.dart';

class LivesIndicator extends StatelessWidget {
  final int lives;

  const LivesIndicator({super.key, required this.lives});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        lives,
        (index) => Padding(
          key: ValueKey('life-icon-$index'),
          padding: const EdgeInsets.only(left: 4),
          child: ClipPath(
            clipper: _TriangleClipper(),
            child: Container(
              width: 14,
              height: 14,
              color: AppTheme.pink,
              key: const ValueKey('life-icon'),
            ),
          ),
        ),
      ),
    );
  }
}

class _TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
