// frontend/lib/state/session_state.dart

class SessionState {
  static final List<Map<String, dynamic>> visitedSites = [];
  static final List<Map<String, dynamic>> selectedEvents = [];
  static final List<Map<String, dynamic>> yearSelections = [];
  static final List<Map<String, dynamic>> questionsAsked = [];

  static void clearSession() {
    visitedSites.clear();
    selectedEvents.clear();
    yearSelections.clear();
    questionsAsked.clear();
  }
}
