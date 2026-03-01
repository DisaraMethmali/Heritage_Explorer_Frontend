// frontend/lib/state/recommendation_state.dart
// Global shared recommendation state
//  Holds latest intelligent recommendation results from backend

class RecommendationState {

  // Top 3 nearest heritage sites (with weather, disaster, safety_status)
  static List<Map<String, dynamic>> recommendedSites = [];

  // Intelligent recommendation message from backend
  static String? recommendationMessage;

  // Site ID that should be highlighted in UI
  static int? highlightSiteId;

  // Alternative site suggestion if all 3 are unsafe
  static Map<String, dynamic>? alternativeSite;

  // Convenience getter
  static bool get hasRecommendation =>
      recommendedSites.isNotEmpty;
    
  // UPDATE STATE FROM API RESPONSE
  static void updateFromResponse(Map<String, dynamic> response) {

    // Store top 3 recommended sites
    recommendedSites = List<Map<String, dynamic>>.from(
      response["recommended"] ?? [],
    );

    // Store intelligent decision fields
    recommendationMessage = response["recommendation_message"];
    highlightSiteId = response["highlight_site_id"];
    alternativeSite = response["alternative_site"];
  }

  // Clear all stored recommendations (CLEAR STATE)
  static void clear() {
    recommendedSites.clear();
    recommendationMessage = null;
    highlightSiteId = null;
    alternativeSite = null;
  }
}
