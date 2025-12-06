// Logger utility for debugging and error tracking
class Logger {
  static const String _tag = 'DiaCare';
  static bool _isDebugMode = true;

  static void setDebugMode(bool enabled) {
    _isDebugMode = enabled;
  }

  static void log(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!_isDebugMode) return;
    print('[$_tag] [LOG] $message');
    if (error != null) {
      print('[$_tag] [ERROR] $error');
      if (stackTrace != null) {
        print('[$_tag] [STACK] $stackTrace');
      }
    }
  }

  static void info(String message) {
    if (!_isDebugMode) return;
    print('[$_tag] [INFO] $message');
  }

  static void warning(String message) {
    if (!_isDebugMode) return;
    print('[$_tag] [WARN] $message');
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    print('[$_tag] [ERROR] $message');
    if (error != null) {
      print('[$_tag] [DETAIL] $error');
      if (stackTrace != null) {
        print('[$_tag] [STACK] $stackTrace');
      }
    }
  }

  static void debug(String message, {Map<String, dynamic>? params}) {
    if (!_isDebugMode) return;
    print('[$_tag] [DEBUG] $message');
    if (params != null && params.isNotEmpty) {
      params.forEach((key, value) {
        print('[$_tag] [DEBUG]   $key: $value');
      });
    }
  }
}
