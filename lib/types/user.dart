import 'ai_partner.dart';

class User {
  final String id;
  String name;
  String email;
  List<String> languages;
  Map<AiPartner,List<String>>? conversations; //maps each user's AI partners to their coversations (stored in an ordered List)
  final DateTime createdAt;
  String? profile_image_path; //currently locally stored -- should we store the profile picture on server side?
  User({
    required this.id,
    required this.email,
    required this.name,
    required this.createdAt,
    required this.languages,
    this.profile_image_path,
    this.conversations
  });
}
