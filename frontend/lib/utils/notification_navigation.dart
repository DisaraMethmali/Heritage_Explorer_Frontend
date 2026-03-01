// frontend/lib/utils/notification_navigation.dart

import '../state/navigation_state.dart';

class NotificationNavigation {
  static void handleRecommendationTap() {
    NavigationState.switchToRecommendation();
  }
}
