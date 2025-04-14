import 'package:flutter/material.dart';

/// A custom clipper that creates a parallelogram shape with rounded corners
class ParallelogramClipper extends CustomClipper<Path> {
  final double skewAmount;
  final double radius;
  
  ParallelogramClipper({this.skewAmount = 15.0, this.radius = 8.0});

  @override
  Path getClip(Size size) {
    final path = Path();
    
    // Define the corner points
    final topLeft = Offset(0, 0);
    final topRight = Offset(size.width - skewAmount, 0);
    final bottomRight = Offset(size.width, size.height);
    final bottomLeft = Offset(skewAmount, size.height);
    
    // Start at the top left plus radius to the right
    path.moveTo(topLeft.dx + radius, topLeft.dy);
    
    // Top edge
    path.lineTo(topRight.dx - radius, topRight.dy);
    // Top-right corner
    path.arcToPoint(
      Offset(topRight.dx, topRight.dy + radius),
      radius: Radius.circular(radius),
      clockwise: true
    );
    
    // Right edge
    path.lineTo(bottomRight.dx, bottomRight.dy - radius);
    // Bottom-right corner
    path.arcToPoint(
      Offset(bottomRight.dx - radius, bottomRight.dy),
      radius: Radius.circular(radius),
      clockwise: true
    );
    
    // Bottom edge
    path.lineTo(bottomLeft.dx + radius, bottomLeft.dy);
    // Bottom-left corner
    path.arcToPoint(
      Offset(bottomLeft.dx, bottomLeft.dy - radius),
      radius: Radius.circular(radius),
      clockwise: true
    );
    
    // Left edge
    path.lineTo(topLeft.dx, topLeft.dy + radius);
    // Top-left corner
    path.arcToPoint(
      Offset(topLeft.dx + radius, topLeft.dy),
      radius: Radius.circular(radius),
      clockwise: true
    );
    
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
  final double cornerRadius;

  const ParallelogramButton({
    Key? key,
    required this.child,
    required this.onPressed,
    required this.color,
    this.width = 56.0,
    this.height = 56.0,
    this.skewAmount = 15.0,
    this.cornerRadius = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width,
        height: height,
        child: ClipPath(
          clipper: ParallelogramClipper(
            skewAmount: skewAmount,
            radius: cornerRadius,
          ),
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