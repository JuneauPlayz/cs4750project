import 'package:flutter/material.dart';

class RatingWidget extends StatelessWidget {
  final double rating;
  final double maxRating;
  final ValueChanged<double>? onChanged;
  final double starSize;
  final Color activeColor;
  final Color inactiveColor;

  const RatingWidget({
    super.key,
    this.rating = 0.0,
    this.maxRating = 5.0,
    this.onChanged,
    this.starSize = 32.0,
    this.activeColor = Colors.amber,
    this.inactiveColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    final int starCount = maxRating.toInt();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(starCount, (index) {
        final starValue = index + 1.0;
        IconData icon;
        Color color;

        if (rating >= starValue) {
          icon = Icons.star_rounded;
          color = activeColor;
        } else if (rating >= starValue - 0.5) {
          icon = Icons.star_half_rounded;
          color = activeColor;
        } else {
          icon = Icons.star_outline_rounded;
          color = inactiveColor;
        }

        return GestureDetector(
          onTap: onChanged != null ? () => onChanged!(starValue) : null,
          child: Icon(icon, size: starSize, color: color),
        );
      }),
    );
  }
}
