import 'package:flutter/material.dart';
import 'package:langpal_prototype/types/chatMessage.dart';
import 'package:langpal_prototype/services/supabase_service.dart';
import 'types/user.dart';
import 'types/aiPartner.dart';

//Notifier for managing state of user

class UserNotifier extends ChangeNotifier{

   
  User? _user;
  
  User? get user => _user;

  //Profile stats (queried frm DB)
  int _dayStreak = 7;
  int _totalXP = 1250;
  int _currentDailyXP = 10;
  int _dailyGoal = 50;

  int _gamesCompletedToday = 0;
  bool _dailyChallengeComplete = false;
  final int _gamesRequiredForChallenge = 3;
  final int _dailyChallengeBonus = 50;

  int get dayStreak => _dayStreak;
  int get totalXP => _totalXP;
  int get currentDailyXP => _currentDailyXP;
  int get dailyGoal => _dailyGoal;
  int get gamesCompletedToday => _gamesCompletedToday;
  bool get dailyChallengeComplete => _dailyChallengeComplete;
  int get gamesRequiredForChallenge => _gamesRequiredForChallenge;
  int get dailyChallengeBonus => _dailyChallengeBonus;


  // rest daily challange track (should be decided based on new day and DB data?)
  void resetDailyChallenge() {
    _gamesCompletedToday = 0;
    _dailyChallengeComplete = false;
    notifyListeners();
  }

  List<AiPartner> _aiPartners = [];
  Map<AiPartner, List<ChatMessage>> _conversations = {};
  bool _isLoading = true;
  String? _error;

  List<AiPartner> get aiPartners => _aiPartners;
  Map<AiPartner, List<ChatMessage>> get conversations => _conversations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => SupabaseService.isLoggedIn;

  UserNotifier() {
    _init();
  }


Future<void> _init() async {
    if (SupabaseService.isLoggedIn) {
      await loadUserData();
    } else {
      // Not logged in - show auth page
      _isLoading = false;
      
    }
    notifyListeners();
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
      //_conversations = {};
      for (final partner in _aiPartners) {
        final messages = await SupabaseService.fetchMessages(partner.id);
        conversations[partner] = messages;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }


//Dummy Data
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

  
 /// Sign up a new user
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    print("BUBBLES : BEOFRE SIGNUP CALL");
    try {
      final response = await SupabaseService.signUp(
        email: email,
        password: password,
        name: name,
      );
      print(response);
      print("BUBBLES --- signed up0");
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

  /* */
  // Method to increase daily progress
  void addXP(int xp) {
    _currentDailyXP += xp;
    _totalXP += xp;
    notifyListeners();
  }

  // Method called when a game is completed
  void completeGame(int gameXP) {
    // Add the game's XP
    addXP(gameXP);
    
    // Increment games completed counter
    if (!_dailyChallengeComplete && _gamesCompletedToday < _gamesRequiredForChallenge) {
      _gamesCompletedToday++;
      
      if (_gamesCompletedToday >= _gamesRequiredForChallenge) {
        _dailyChallengeComplete = true;
        // Award bonus XP for completing daily challenge
        addXP(_dailyChallengeBonus);
      }
      
      notifyListeners();
    }
  }


  void changeProfilePicture(String? path){
    if(_user !=null && path != null){
      _user!.profile_image_path = path;
      notifyListeners();
    }
  }
//fetch data from hypothetical database to bring stored data into state mangement
  void addPartner(AiPartner newPartner){
    if(_user != null && !_user!.conversations!.containsKey(newPartner)){
      _user!.conversations!.addAll({newPartner: []}); //add partner with no conversations
    //insert add to database function
    notifyListeners();
    }
  }
  void removePartner(AiPartner removePartner){
    if(_user != null && _user!.conversations!.containsKey(removePartner)){
      _user!.conversations!.remove(removePartner);
    }
    //insert remove from database relationship function
    notifyListeners();
  }

  void addMessage(AiPartner partner, ChatMessage message) { //adds a message to the users recorded conversation with AI partner
    if (_user == null) return;

    _user!.conversations ??= {};
    _user!.conversations!.putIfAbsent(partner, () => []);
    _user!.conversations![partner]!.add(message);

    notifyListeners();
}
  void addLanguage(String lang){ //Add a language to learn/user knows to their profile
    if(_user != null && !_user!.languages.contains(lang)){
      _user!.languages.add(lang);
    }
    //update user profile in remote database
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