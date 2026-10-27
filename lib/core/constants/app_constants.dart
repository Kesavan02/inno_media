class AppConstants {
  static const String appName = 'InnoMedia';
  static const String appTagline = 'Connect, Share, and Create';

  // Rate Limiter defaults
  static const int maxLikeActionsPerWindow = 6;
  static const Duration likeRateLimitWindow = Duration(seconds: 4);

  static const int maxSubmissionsPerWindow = 1;
  static const Duration submissionRateLimitWindow = Duration(seconds: 3);

  // Pagination & Indexing defaults
  static const int defaultPageSize = 10;

  // Storage keys
  static const String keyCurrentUser = 'current_user_session';
  static const String keyUserDatabase = 'users_db';
  static const String keyReelInteractions = 'reel_interactions_db';
  static const String keyFeedInteractions = 'feed_interactions_db';
  static const String keySavedForms = 'saved_forms_history';
  static const String keyLastActiveTab = 'last_active_tab_index';
  static const String keyLastNavigationStack = 'last_navigation_stack';
}

