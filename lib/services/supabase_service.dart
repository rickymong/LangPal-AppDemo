import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../types/user.dart' as app_user;
import '../types/aiPartner.dart';
import '../types/chatMessage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Supabase configuration and service layer for LangPal
class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  /// Initialize Supabase - call this in main() before runApp()
   static Future<void> initialize() async {
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseKey = dotenv.env['SUPABASE_PUB_KEY'];

    if (supabaseUrl == null || supabaseKey == null) {
      throw Exception('Supabase environment variables not found');
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );
  }
  /// Get the currently logged in user's ID
  static String? get currentUserId => client.auth.currentUser?.id;

  /// Check if user is logged in
  static bool get isLoggedIn => client.auth.currentUser != null;

  // ============================================
  // AUTH METHODS
  // ============================================

  /// Sign up with email and password
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );
  }

  /// Sign in with email and password
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    print("in supabase service sign in");
    final response = client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if(response == null){
      print("NULL SIGNINWITHPASSWORD RESPONSE");
      print(response.toString());
    }
    return response;
  }

  /// Sign out
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  //SSO Methods
  static Future<AuthResponse> googleSignIn() async {

  /// Web Client ID that you registered with Google Cloud.
  const webClientId = '435981250230-imcjnk5arlhb9bh4g74l99988t1c7e2a.apps.googleusercontent.com';

  /// iOS Client ID that you registered with Google Cloud.
  const iosClientId = '435981250230-1aisj7gkplg30mdhqi86gg53gqr91e1h.apps.googleusercontent.com';



  final GoogleSignIn signIn = GoogleSignIn.instance;
  unawaited(
    signIn.initialize(clientId: iosClientId, serverClientId: webClientId));

  // Perform the sign in
  final googleAccount = await signIn.authenticate();
final googleAuthorization = await googleAccount.authorizationClient.authorizationForScopes([
    'email',
    'profile',
  ]);  final googleAuthentication = googleAccount.authentication;
  final idToken = googleAuthentication.idToken;
  final accessToken = googleAuthorization?.accessToken;

  if (idToken == null) {
    throw 'No ID Token found.';
  }

  return await client.auth.signInWithIdToken(
    provider: OAuthProvider.google,
    idToken: idToken,
    accessToken: accessToken,
  );
}

  // ============================================
  // USER PROFILE METHODS
  // ============================================

  /// Fetch user profile from database
  static Future<app_user.User?> fetchUserProfile() async {
    print("in fetchUserProfile");
    final userId = currentUserId;
    if (userId == null) return null;
    var response;
    var languages;
    var languagesResponse;
    try{
     response = await client
        .from('user_profiles')
        .select()
        .eq('id', userId)
        .single();

    // Fetch user's languages
     languagesResponse = await client
        .from('user_languages')
        .select('language')
        .eq('user_id', userId);

     languages = (languagesResponse as List)
        .map((e) => e['language'] as String)
        .toList();    
    }catch(e){
      print("error caught in fetchUserProfile");
      print(e);
    }
    return app_user.User(
      id: response['id'],
      name: response['name'],
      email: response['email'],
      createdAt: DateTime.parse(response['created_at']),
      languages: languages,
      profile_image_path: response['profile_image_url'],
      streak: response["streak"],
      streak_updated: DateTime.parse(response["streak_updated"]),
      timezone: response["timezone"]
    );
  }

  /// Update user profile
  static Future<void> updateUserProfile({
    String? name,
    String? profileImageUrl,
    String? currentLanguage,
  }) async {
    final userId = currentUserId;
    if (userId == null) return;

    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (profileImageUrl != null) updates['profile_image_url'] = profileImageUrl;
    if (currentLanguage != null) updates['current_language'] = currentLanguage;

    if (updates.isNotEmpty) {
      await client.from('user_profiles').update(updates).eq('id', userId);
    }
  }

 static Future<Map<String, dynamic>> completeActivity(String userId) async {
  print("running completeActivity");
  final timezone = DateTime.now().timeZoneName;
  return await client.rpc('complete_activity', params: {
    'user_id': userId,
    'user_timezone': timezone,
  });
}

static Future<Map<String, dynamic>> checkStreakOnOpen(String userId) async {
  final timezone = DateTime.now().timeZoneName;
  return await client.rpc('check_streak_on_open', params: {
    'user_id': userId,
    'user_timezone': timezone,
  });
}

  // ============================================
  // LANGUAGE METHODS
  // ============================================

  /// Add a language to user's learning list
  static Future<void> addLanguage(String language) async {
    final userId = currentUserId;
    if (userId == null) return;

    await client.from('user_languages').insert({
      'user_id': userId,
      'language': language,
    });
  }

  /// Remove a language from user's learning list
  static Future<void> removeLanguage(String language) async {
    final userId = currentUserId;
    if (userId == null) return;

    await client
        .from('user_languages')
        .delete()
        .eq('user_id', userId)
        .eq('language', language);
  }



  // ============================================
  // AI PARTNER METHODS
  // ============================================

  /// Fetch all available AI partners
  static Future<List<AiPartner>> fetchAllAiPartners() async {
    final response = await client.from('ai_partners').select();

    return (response as List).map((e) => AiPartner(
      id: e['id'],
      name: e['name'],
      language: e['language'],
      flag_path: e['flag_path'],
    )).toList();
  }

  /// Fetch user's AI partners (the ones they've added)
  static Future<List<AiPartner>> fetchUserAiPartners() async {
    final userId = currentUserId;
    if (userId == null) return [];

    final response = await client
        .from('user_ai_partners')
        .select('ai_partners(*)')
        .eq('user_id', userId);

    return (response as List).map((e) {
      final partner = e['ai_partners'];
      return AiPartner(
        id: partner['id'],
        name: partner['name'],
        language: partner['language'],
        flag_path: partner['flag_path'],
      );
    }).toList();
  }

  /// Add an AI partner to user's list
  static Future<void> addAiPartner(String aiPartnerId) async {
    final userId = currentUserId;
    if (userId == null) return;

    await client.from('user_ai_partners').insert({
      'user_id': userId,
      'ai_partner_id': aiPartnerId,
    });
  }

  /// Remove an AI partner from user's list
  static Future<void> removeAiPartner(String aiPartnerId) async {
    final userId = currentUserId;
    if (userId == null) return;

    await client
        .from('user_ai_partners')
        .delete()
        .eq('user_id', userId)
        .eq('ai_partner_id', aiPartnerId);
  }

  // ============================================
  // CHAT MESSAGE METHODS
  // ============================================

  /// Fetch chat messages with an AI partner
  static Future<List<ChatMessage>> fetchMessages(String aiPartnerId) async {
    final userId = currentUserId;
    if (userId == null) return [];

    final response = await client
        .from('chat_messages')
        .select()
        .eq('user_id', userId)
        .eq('ai_partner_id', aiPartnerId)
        .order('created_at', ascending: true);

    return (response as List).map((e) => ChatMessage(
      id: e['id'],
      userId: e['user_id'],
      aiID: e['ai_partner_id'],
      text: e['text'],
      isFromUser: e['is_from_user'],
      timestamp: DateTime.parse(e['created_at']),
    )).toList();
  }

  /// Send a message (insert into database)
  static Future<ChatMessage?> sendMessage({
    required String aiPartnerId,
    required String text,
    required bool isFromUser,
  }) async {
    final userId = currentUserId;
    if (userId == null) return null;

    final response = await client.from('chat_messages').insert({
      'user_id': userId,
      'ai_partner_id': aiPartnerId,
      'text': text,
      'is_from_user': isFromUser,
    }).select().single();

    return ChatMessage(
      id: response['id'],
      userId: response['user_id'],
      aiID: response['ai_partner_id'],
      text: response['text'],
      isFromUser: response['is_from_user'],
      timestamp: DateTime.parse(response['created_at']),
    );
  }

  /// Subscribe to real-time messages for a conversation
  static RealtimeChannel subscribeToMessages({
    required String aiPartnerId,
    required void Function(ChatMessage) onMessage,
  }) {
    final userId = currentUserId;
    
    return client
        .channel('chat_messages:$aiPartnerId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'ai_partner_id',
            value: aiPartnerId,
          ),
          callback: (payload) {
            final data = payload.newRecord;
            // Only process messages for current user
            if (data['user_id'] == userId) {
              onMessage(ChatMessage(
                id: data['id'],
                userId: data['user_id'],
                aiID: data['ai_partner_id'],
                text: data['text'],
                isFromUser: data['is_from_user'],
                timestamp: DateTime.parse(data['created_at']),
              ));
            }
          },
        )
        .subscribe();
  }

  // ============================================
  // CONVERSATION SUMMARY METHODS
  // ============================================

  /// Fetch conversations with last message info
  static Future<List<Map<String, dynamic>>> fetchConversations() async {
    final userId = currentUserId;
    if (userId == null) return [];

    final response = await client
        .from('user_conversations')
        .select()
        .eq('user_id', userId);

    return List<Map<String, dynamic>>.from(response);
  }
}

