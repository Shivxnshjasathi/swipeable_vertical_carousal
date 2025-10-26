import 'package:flutter/material.dart';
import 'package:swipeable_vertical_carousal/src/deck_card_config.dart';

/// The default placeholder widget for cards in the deck.
class DeckPlaceholder extends StatelessWidget {
  /// The configuration for this placeholder.
  final DeckCardConfig config;

  /// The calculated top position for the card.
  final double topPosition;

  /// The duration of the animation.
  final Duration animationDuration;

  /// The curve of the animation.
  final Curve animationCurve;

  const DeckPlaceholder({
    super.key,
    required this.config,
    required this.topPosition,
    required this.animationDuration,
    required this.animationCurve,
  });

  @override
  Widget build(BuildContext context) {
    // This is your _buildDeckPlaceholder logic
    return AnimatedPositioned(
      key: ValueKey(config.topOffset),
      duration: animationDuration,
      curve: animationCurve,
      top: topPosition,
      left: config.horizontalPadding,
      right: config.horizontalPadding,
      child: Transform.scale(
        scale: config.scale,
        alignment: Alignment.topCenter,
        child: Container(
          height: 110.0, // We keep this height for the default style
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 1.0),
          ),
        ),
      ),
    );
  }
}
