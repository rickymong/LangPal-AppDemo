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
  DateTime? streak_updated_at;
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
    this.streak_updated_at
  });
}
