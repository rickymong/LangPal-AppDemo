import 'package:langpal_prototype/types/chatMessage.dart';

import 'aiPartner.dart';

class User {
  final String id;
  String name;
  String email;
  List<String> languages;
  Map<AiPartner,List<ChatMessage>>? conversations; //maps each user's AI partners to their coversations (stored in an ordered List)
  final DateTime createdAt;
  String? profile_image_path; //currently locally stored -- should we store the profile picture on server side?
  int streak;
  DateTime? streak_updated;
  String timezone;
  User({
    required this.id,
    required this.email,
    required this.name,
    required this.createdAt,
    required this.languages,
    required this.streak,
    required this.timezone,
    this.profile_image_path,
    this.conversations,
    this.streak_updated
  });

  @override
  String toString() {
    return '''
User(
  id: $id,
  name: $name,
  email: $email,
  languages: $languages,
  conversations: ${conversations?.length ?? 0} partners,
  createdAt: $createdAt,
  profile_image_path: ${profile_image_path ?? "null"},
  streak: $streak,
  streak_updated_at: ${streak_updated ?? "null"},
  timezone: $timezone
)
''';
  }
}
