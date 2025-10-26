import 'dart:async';
import 'package:flutter/material.dart';
import 'package:swipeable_vertical_carousal/src/deck_card_config.dart';
import 'package:swipeable_vertical_carousal/src/deck_placeholder.dart';

/// A vertically-stacked card carousel with a delightful swipe and
/// auto-scroll animation.
///
/// This widget takes a list of items [T] and a builder function [itemBuilder]
/// to render each card.
class StackedCardCarousel<T> extends StatefulWidget {
  // *** CHANGED ***
  // Now accepts a generic list of items
  final List<T> items;

  // *** NEW ***
  // A builder function, just like ListView.builder
  final Widget Function(
    BuildContext context,
    T item,
    int index,
    int visualPosition,
  ) itemBuilder;

  // *** NEW ***
  // The height of a single card. This is crucial for layout calculations.
  final double cardHeight;

  // *** NEW ***
  // Configurable parameters that were hard-coded before
  final double frontCardGap;
  final bool autoScroll;
  final Duration autoScrollDuration;
  final Duration animationDuration;
  final Curve animationCurve;
  final List<DeckCardConfig> deckCardConfig;
  final Widget Function(
    BuildContext,
    DeckCardConfig config,
    double topPosition,
    Duration animationDuration,
    Curve animationCurve,
  )? deckPlaceholderBuilder;

  const StackedCardCarousel({
    super.key,
    required this.items, // was 'bills'
    required this.itemBuilder,
    required this.cardHeight,
    this.frontCardGap = 12.0, // was 'gap'
    this.autoScroll = true,
    this.autoScrollDuration = const Duration(seconds: 3),
    this.animationDuration = const Duration(milliseconds: 700),
    this.animationCurve = Curves.easeInOutCubic,
    this.deckCardConfig = DeckCardConfig.defaultDeckConfig,
    this.deckPlaceholderBuilder,
  });

  @override
  State<StackedCardCarousel<T>> createState() => _StackedCardCarouselState<T>();
}

class _StackedCardCarouselState<T> extends State<StackedCardCarousel<T>> {
  int _currentIndex = 0;
  double _dragStartY = 0;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  void _startAutoScroll() {
    // *** CHANGED ***
    // Uses widget.autoScroll, widget.items, and widget.autoScrollDuration
    if (!widget.autoScroll || widget.items.length <= 1) return;
    _autoScrollTimer?.cancel();
    _autoScrollTimer =
        Timer.periodic(widget.autoScrollDuration, (timer) {
      if (mounted) {
        _onSwipeUp();
      }
    });
  }

  void _onSwipeUp() {
    if (widget.items.isEmpty) return;
    setState(() {
      // *** CHANGED ***
      // Uses widget.items.length
      _currentIndex = (_currentIndex + 1) % widget.items.length;
    });
  }

  // --- This gesture logic is unchanged ---
  void _onVerticalDragStart(DragStartDetails details) {
    _dragStartY = details.globalPosition.dy;
    _autoScrollTimer?.cancel();
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final dragDistance = _dragStartY - details.globalPosition.dy;
    final velocity = details.primaryVelocity ?? 0;
    if (dragDistance > 50 || velocity < -500) {
      _onSwipeUp();
    }
    _startAutoScroll();
  }
  // --- End of unchanged logic ---

  @override
  Widget build(BuildContext context) {
    // *** CHANGED ***
    // Calculate total height based on parameters
    double stackHeight = widget.cardHeight;
    if (widget.items.length > 1) {
      stackHeight += widget.frontCardGap;
    }
    if (widget.deckCardConfig.isNotEmpty) {
      // Find the largest offset
      final maxOffset = widget.deckCardConfig.fold<double>(
        0.0,
        (max, config) => config.topOffset > max ? config.topOffset : max,
      );
      stackHeight += maxOffset;
    }
    stackHeight += 20; // Buffer

    return GestureDetector(
      onVerticalDragStart: _onVerticalDragStart,
      onVerticalDragEnd: _onVerticalDragEnd,
      child: SizedBox(
        height: stackHeight, // Use calculated height
        child: ClipRect(
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: _buildStackedCards(),
          ),
        ),
      ),
    );
  }

  // This is your _buildDeckPlaceholder, moved to its own widget
  // and now called in _buildStackedCards

  List<Widget> _buildStackedCards() {
    // *** CHANGED ***
    if (widget.items.isEmpty) return [];

    List<Widget> stackedCards = [];
    // *** CHANGED ***
    final totalItems = widget.items.length;

    // --- Calculate card positions ---
    // *** CHANGED ***
    // Uses parameters instead of consts
    final double pos0Top = 0;
    final double pos1Top = widget.cardHeight + widget.frontCardGap;
    final double posOutTop = -widget.cardHeight - 20;

    // 1. Add deck placeholders
    // *** CHANGED ***
    // Loops over the config
    for (final config in widget.deckCardConfig) {
      final double top = pos1Top + config.topOffset;
      stackedCards.add(
        // Calls the new placeholder builder
        widget.deckPlaceholderBuilder?.call(
              context,
              config,
              top,
              widget.animationDuration,
              widget.animationCurve,
            ) ??
            DeckPlaceholder(
              key: ValueKey('deck_${config.topOffset}'),
              config: config,
              topPosition: top,
              animationDuration: widget.animationDuration,
              animationCurve: widget.animationCurve,
            ),
      );
    }

    // --- Get config for the *first hidden card* ---
    // This is where cards at visualPosition 2+ will live
    final DeckCardConfig hiddenCardConfig;
    if (widget.deckCardConfig.isNotEmpty) {
      hiddenCardConfig = widget.deckCardConfig.first;
    } else {
      // Fallback if no deck config is provided
      hiddenCardConfig = const DeckCardConfig(
        topOffset: 14,
        horizontalPadding: 8,
        scale: 0.97,
      );
    }
    final double hiddenTop = pos1Top + hiddenCardConfig.topOffset;
    final double hiddenScale = hiddenCardConfig.scale;
    final double hiddenPadding = hiddenCardConfig.horizontalPadding;

    // 2. Add real item cards
    // *** CHANGED ***
    for (int index = 0; index < totalItems; index++) {
      final item = widget.items[index];
      final int visualPosition =
          (index - _currentIndex + totalItems) % totalItems;

      double top;
      double opacity;
      double scale = 1.0;
      double horizontalPadding = 0;

      // This logic is mostly the same, just uses the new variables
      if (visualPosition == 0) {
        top = pos0Top;
        opacity = 1.0;
      } else if (visualPosition == 1) {
        top = pos1Top;
        opacity = 1.0;
      } else if (visualPosition == totalItems - 1) {
        top = posOutTop;
        opacity = 0.0;
      } else {
        // All other cards are hidden at the first deck position
        top = hiddenTop;
        opacity = 0.0;
        scale = hiddenScale;
        horizontalPadding = hiddenPadding;
      }

      stackedCards.add(
        AnimatedPositioned(
          key: ValueKey(index), // Use index for a stable key
          duration: widget.animationDuration,
          curve: widget.animationCurve,
          top: top,
          left: horizontalPadding,
          right: horizontalPadding,
          child: AnimatedOpacity(
            duration: widget.animationDuration, // Use parameter
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topCenter,
              // *** THE MOST IMPORTANT CHANGE ***
              // Instead of calling BillCard(...), we call the itemBuilder
              child: widget.itemBuilder(
                context,
                item,
                index,
                visualPosition,
              ),
            ),
          ),
        ),
      );
    }

    return stackedCards;
  }
}