class User {
  final String id;
  final String nick;
  final String ageGroup;
  final String locale;
  final String country;
  final DateTime createdAt;

  User({
    required this.id,
    required this.nick,
    required this.ageGroup,
    required this.locale,
    required this.country,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      nick: json['nick'],
      ageGroup: json['ageGroup'],
      locale: json['locale'],
      country: json['country'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nick': nick,
      'ageGroup': ageGroup,
      'locale': locale,
      'country': country,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class ChatMessage {
  final String id;
  final String role; // 'user' | 'assistant' | 'system'
  final String content;
  final DateTime createdAt;
  final String? safetyFlag;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.safetyFlag,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      role: json['role'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      safetyFlag: json['safetyFlag'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'safetyFlag': safetyFlag,
    };
  }
}

class ChatSession {
  final String id;
  final String userId;
  final DateTime startedAt;
  final String status;
  final List<ChatMessage> messages;

  ChatSession({
    required this.id,
    required this.userId,
    required this.startedAt,
    required this.status,
    required this.messages,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'],
      userId: json['userId'],
      startedAt: DateTime.parse(json['startedAt']),
      status: json['status'],
      messages: (json['messages'] as List<dynamic>?)
              ?.map((m) => ChatMessage.fromJson(m))
              .toList() ??
          [],
    );
  }
}

class SosContact {
  final String id;
  final String country;
  final String locale;
  final String type;
  final String name;
  final String? phone;
  final String? url;
  final String? hours;

  SosContact({
    required this.id,
    required this.country,
    required this.locale,
    required this.type,
    required this.name,
    this.phone,
    this.url,
    this.hours,
  });

  factory SosContact.fromJson(Map<String, dynamic> json) {
    return SosContact(
      id: json['id'],
      country: json['country'],
      locale: json['locale'],
      type: json['ctype'],
      name: json['name'],
      phone: json['phone'],
      url: json['url'],
      hours: json['hours'],
    );
  }
}

enum AppTheme { light, dark, system }

class AppSettings {
  final AppTheme theme;
  final bool notificationsEnabled;
  final bool dailyRemindersEnabled;
  final int reminderHour;
  final int reminderMinute;

  AppSettings({
    this.theme = AppTheme.system,
    this.notificationsEnabled = true,
    this.dailyRemindersEnabled = false,
    this.reminderHour = 20,
    this.reminderMinute = 0,
  });

  AppSettings copyWith({
    AppTheme? theme,
    bool? notificationsEnabled,
    bool? dailyRemindersEnabled,
    int? reminderHour,
    int? reminderMinute,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      dailyRemindersEnabled:
          dailyRemindersEnabled ?? this.dailyRemindersEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
    );
  }
}
