import 'package:flutter/material.dart';

/// A custom clipper that creates a parallelogram shape
class ParallelogramClipper extends CustomClipper<Path> {
  final double skewAmount;
  
  ParallelogramClipper({this.skewAmount = 15.0});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(skewAmount, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width - skewAmount, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}

/// A widget that creates a parallelogram shape button
class ParallelogramButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Color color;
  final double width;
  final double height;
  final double skewAmount;

  const ParallelogramButton({
    Key? key,
    required this.child,
    required this.onPressed,
    required this.color,
    this.width = 56.0,
    this.height = 56.0,
    this.skewAmount = 15.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width,
        height: height,
        child: ClipPath(
          clipper: ParallelogramClipper(skewAmount: skewAmount),
          child: Material(
            color: color,
            elevation: 6.0,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}