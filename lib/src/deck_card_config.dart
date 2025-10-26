import 'package:flutter/widgets.dart';

/// Configuration for a single placeholder card in the deck.
@immutable
class DeckCardConfig {
  /// The vertical offset from the top of the *second* card (index 1).
  final double topOffset;

  /// The horizontal padding for this card.
  final double horizontalPadding;

  /// The scale factor for this card.
  final double scale;

  const DeckCardConfig({
    required this.topOffset,
    required this.horizontalPadding,
    required this.scale,
  });

  /// The default configuration for the deck placeholders,
  /// matching your original app's style.
  static const List<DeckCardConfig> defaultDeckConfig = [
    DeckCardConfig(
      topOffset: 14,
      horizontalPadding: 8,
      scale: 0.97,
    ),
    DeckCardConfig(
      topOffset: 24, // 14 + 10
      horizontalPadding: 16,
      scale: 0.94,
    ),
    DeckCardConfig(
      topOffset: 34, // 24 + 10
      horizontalPadding: 24,
      scale: 0.91,
    ),
  ];
}