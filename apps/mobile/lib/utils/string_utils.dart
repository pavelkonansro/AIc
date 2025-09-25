/// Утилиты для работы со строками
class StringUtils {
  /// Безопасно обрезает строку до указанной длины
  /// Если строка короче maxLength, возвращает исходную строку
  /// Если длиннее - обрезает и добавляет суффикс (по умолчанию "...")
  static String safeTruncate(String input, int maxLength, [String suffix = '...']) {
    if (input.length <= maxLength) {
      return input;
    }
    return input.substring(0, maxLength) + suffix;
  }

  /// Безопасно получает подстроку
  /// Проверяет границы и возвращает корректную подстроку
  static String safeSubstring(String input, int start, [int? end]) {
    if (start < 0) start = 0;
    if (start >= input.length) return '';
    
    if (end == null) {
      return input.substring(start);
    }
    
    if (end < start) end = start;
    if (end > input.length) end = input.length;
    
    return input.substring(start, end);
  }

  /// Проверяет, является ли строка пустой или содержит только пробелы
  static bool isBlank(String? input) {
    return input == null || input.trim().isEmpty;
  }

  /// Обрезает строку и показывает превью для логирования
  static String logPreview(String input, [int maxLength = 100]) {
    return safeTruncate(input, maxLength);
  }

  /// Форматирует размер строки для отображения
  static String formatLength(String input) {
    final length = input.length;
    if (length < 1000) return '$length символов';
    if (length < 1000000) return '${(length / 1000).toStringAsFixed(1)}K символов';
    return '${(length / 1000000).toStringAsFixed(1)}M символов';
  }
}