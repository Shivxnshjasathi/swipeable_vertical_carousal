# Stacked Card Carousel

A vertically-stacked card carousel with a delightful swipe and auto-scroll animation, perfect for displaying bills, notifications, or other summary cards.

<img width="342" height="244" alt="Screenshot 2025-10-27 at 2 44 54 AM" src="https://github.com/user-attachments/assets/e3580061-a8f5-4999-be10-2a3b885be12a" />

https://github.com/user-attachments/assets/c517c0d6-464c-490f-add7-5f83dbeeeadd


## Features

* **Vertical Stacking:** Cards are stacked vertically, with the front two items fully visible and a "deck" of cards peeking out from behind.
* **Swipe Gesture:** Users can swipe up to dismiss the front card and bring the next one into view.
* **Auto-Scroll:** Configure the carousel to automatically cycle through items.
* **Customizable:**
    * Works with any list of data (`List<T>`).
    * Use the `itemBuilder` to provide your own custom widget for each card.
    * Tweak animation durations, curves, card heights, and spacing.
    * Customize the look of the "deck" of placeholder cards.

## Installation

```yaml
dependencies:

  stacked_card_carousel: ^0.0.1


import 'package:flutter/material.dart';
import 'package:stacked_card_carousel/stacked_card_carousel.dart';

// 1. Your list of data
final List<MyItem> myItems = [ ... ];

StackedCardCarousel<MyItem>(
  items: myItems,
  cardHeight: 110.0,
  itemBuilder: (BuildContext context, MyItem item, int index, int visualPosition) {
    return MyCardWidget(
      item: item,
      // visualPosition == 0 is the front card
      // visualPosition == 1 is the second card
      // visualPosition >= 2 are cards in the deck
      isFrontCard: visualPosition <= 1,
    );
  },
),



Also create `stacked_card_carousel/LICENSE` (you can find MIT license text online) and a simple `stacked_card_carousel/CHANGELOG.md`:

```markdown
## 0.0.1

* Initial release of the stacked card carousel package.
