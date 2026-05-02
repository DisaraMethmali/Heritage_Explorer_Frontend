// frontend/lib/state/navigation_state.dart

import 'package:flutter/foundation.dart';

class NavigationState {
  // 0 = Home, 1 = Location, 2 = Recommendation, 3 = About
  static final ValueNotifier<int> selectedIndex =
      ValueNotifier<int>(0);

  static void switchToRecommendation() {
    selectedIndex.value = 3;
  }
}
