import 'package:flutter/material.dart';
import 'package:langpal_prototype/services/supabase_service.dart';
import 'user.dart';
import 'ai_partner.dart';
import 'chat_message.dart';

class UserNotifier extends ChangeNotifier {
  User? _user;
  List<AiPartner> _aiPartners = [];
  Map<AiPartner, List<ChatMessage>> _conversations = {};
  bool _isLoading = true;
  String? _error;

  User? get user => _user;
  List<AiPartner> get aiPartners => _aiPartners;
  Map<AiPartner, List<ChatMessage>> get conversations => _conversations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => SupabaseService.isLoggedIn;

  UserNotifier() {
    _init();
  }

  /// Initialize - check if user is logged in and load their data
  Future<void> _init() async {
    if (SupabaseService.isLoggedIn) {
      await loadUserData();
    } else {
      // Not logged in - show auth page
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Continue without account (demo/guest mode)
  void continueAsGuest() {
    _initMockData();
  }

  /// Load user data from Supabase
  Future<void> loadUserData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch user profile
      _user = await SupabaseService.fetchUserProfile();

      // Fetch user's AI partners
      _aiPartners = await SupabaseService.fetchUserAiPartners();

      // Fetch conversations for each AI partner
      _conversations = {};
      for (final partner in _aiPartners) {
        final messages = await SupabaseService.fetchMessages(partner.id);
        _conversations[partner] = messages;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mock data for development/testing when not logged in
  void _initMockData() {
    final ai = AiPartner(
      name: "Sophia",
      id: "ai_001",
      language: "Spanish",
      flag_path: "images/flags/spain_flag.jpg",
    );

    final List<ChatMessage> convo = [
      ChatMessage(
        id: 1,
        userId: "user_001",
        aiID: "ai_001",
        text: "Hi Sophia! How are you today?",
        isFromUser: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      ChatMessage(
        id: 2,
        userId: "user_001",
        aiID: "ai_001",
        text: "I'm doing great, thanks for asking!",
        isFromUser: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
      ),
      ChatMessage(
        id: 3,
        userId: "user_001",
        aiID: "ai_001",
        text: "What's the weather like in London?",
        isFromUser: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      ),
      ChatMessage(
        id: 4,
        userId: "user_001",
        aiID: "ai_001",
        text: "A bit cloudy, but perfect for tea time ☕️",
        isFromUser: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
    ];

    _aiPartners = [ai];
    _conversations = {ai: convo};
    
    _user = User(
      id: "user_001",
      name: "Adam Hirshson",
      email: "Adam@Hirshson.com",
      createdAt: DateTime.now(),
      languages: ["English", "Chinese"],
    );

    _isLoading = false;
    notifyListeners();
  }

  // ============================================
  // AUTH METHODS
  // ============================================

  /// Sign up a new user
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      await SupabaseService.signUp(
        email: email,
        password: password,
        name: name,
      );
      await loadUserData();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Sign in existing user
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await SupabaseService.signIn(email: email, password: password);
      await loadUserData();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await SupabaseService.signOut();
    _user = null;
    _aiPartners = [];
    _conversations = {};
    notifyListeners();
  }

  // ============================================
  // PROFILE METHODS
  // ============================================

  Future<void> changeProfilePicture(String? path) async {
    if (_user != null && path != null) {
      _user!.profile_image_path = path;
      await SupabaseService.updateUserProfile(profileImageUrl: path);
      notifyListeners();
    }
  }

  // ============================================
  // AI PARTNER METHODS
  // ============================================

  /// Add a new AI partner
  Future<void> addPartner(AiPartner newPartner) async {
    if (_user != null && !_conversations.containsKey(newPartner)) {
      // Add to local state
      _aiPartners.add(newPartner);
      _conversations[newPartner] = [];

      // Add to database
      if (SupabaseService.isLoggedIn) {
        await SupabaseService.addAiPartner(newPartner.id);
      }

      notifyListeners();
    }
  }

  /// Remove an AI partner
  Future<void> removePartner(AiPartner removePartner) async {
    if (_user != null && _conversations.containsKey(removePartner)) {
      // Remove from local state
      _aiPartners.remove(removePartner);
      _conversations.remove(removePartner);

      // Remove from database
      if (SupabaseService.isLoggedIn) {
        await SupabaseService.removeAiPartner(removePartner.id);
      }

      notifyListeners();
    }
  }

  // ============================================
  // MESSAGE METHODS
  // ============================================

  /// Add a message to a conversation
  Future<void> addMessage(AiPartner partner, String message, {bool isFromUser = true}) async {
    if (_user == null) return;

    // Ensure conversation exists
    _conversations.putIfAbsent(partner, () => []);

    if (SupabaseService.isLoggedIn) {
      // Send to database and get back the full message
      final chatMessage = await SupabaseService.sendMessage(
        aiPartnerId: partner.id,
        text: message,
        isFromUser: isFromUser,
      );
      if (chatMessage != null) {
        _conversations[partner]!.add(chatMessage);
      }
    } else {
      // Mock mode - create local message
      final chatMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch,
        userId: _user!.id,
        aiID: partner.id,
        text: message,
        isFromUser: isFromUser,
        timestamp: DateTime.now(),
      );
      _conversations[partner]!.add(chatMessage);
    }

    notifyListeners();
  }

  /// Get messages for a specific AI partner
  List<ChatMessage> getMessages(AiPartner partner) {
    return _conversations[partner] ?? [];
  }

  // ============================================
  // LANGUAGE METHODS
  // ============================================

  Future<void> addLanguage(String lang) async {
    if (_user != null && !_user!.languages.contains(lang)) {
      _user!.languages.add(lang);

      if (SupabaseService.isLoggedIn) {
        await SupabaseService.addLanguage(lang);
      }

      notifyListeners();
    }
  }

  Future<void> removeLanguage(String lang) async {
    if (_user != null && _user!.languages.contains(lang)) {
      _user!.languages.remove(lang);

      if (SupabaseService.isLoggedIn) {
        await SupabaseService.removeLanguage(lang);
      }

      notifyListeners();
    }
  }

  /// Fetch all available AI partners (for adding new ones)
  Future<List<AiPartner>> fetchAvailablePartners() async {
    if (SupabaseService.isLoggedIn) {
      return await SupabaseService.fetchAllAiPartners();
    }
    // Return mock data
    return [
      AiPartner(
        name: "Sophia",
        id: "ai_001",
        language: "Spanish",
        flag_path: "images/flags/spain_flag.jpg",
      ),
      AiPartner(
        name: "Yuki",
        id: "ai_002",
        language: "Japanese",
        flag_path: "images/flags/japan_flag.png",
      ),
      AiPartner(
        name: "Hans",
        id: "ai_003",
        language: "German",
        flag_path: "images/flags/german_flag.jpg",
      ),
    ];
  }
}
