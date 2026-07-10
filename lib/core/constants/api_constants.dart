class ApiConstants {
  ApiConstants._();

  static const String supabaseUrl =
      'https://buvcyaxgxrbjdikefsyq.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ1dmN5YXhneHJiamRpa2Vmc3lxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM1MjIxOTMsImV4cCI6MjA5OTA5ODE5M30.LjWQ-7DvXfuejOdVM6Ks13KCPn-sE_wgRgr0ES-TIOk';

  static const String avatarsBucket = 'avatars';
  static const String coversBucket = 'covers';
  static const String mediaBucket = 'media';
  static const String reelsBucket = 'reels';

  static String getAvatarUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$supabaseUrl/storage/v1/object/public/$avatarsBucket/$path';
  }

  static String getCoverUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$supabaseUrl/storage/v1/object/public/$coversBucket/$path';
  }

  static String getMediaUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$supabaseUrl/storage/v1/object/public/$mediaBucket/$path';
  }

  static String getReelUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$supabaseUrl/storage/v1/object/public/$reelsBucket/$path';
  }

  static const int feedPageSize = 20;
  static const int notificationsPageSize = 30;
  static const int messagesPageSize = 30;
  static const int reelsPageSize = 10;
  static const int searchPageSize = 20;
  static const int maxTweetLength = 500;
  static const int maxMediaCount = 4;
}