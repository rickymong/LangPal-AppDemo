import 'package:flutter/material.dart';
import 'package:langpal_prototype/types/chatMessage.dart';
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


  UserNotifier(){
    //_initObjects();
  }

//Dummy Data
  void _initObjects(){ //initialize a User and AI partners into state (we'd normally query from database here)
    final ai = AiPartner(
      name: "Sophia",
      id: "ai_001",
      language: "Spanish",
      flag_path: "assets/flags/spain_flag.jpg",
    );
//for when conversations was AI, List<String>
  // final List<String> convo = [
  //   "Hi Sophia! How are you today?",
  //   "I'm doing great, thanks for asking!",
  //   "What’s the weather like in London?",
  //   "A bit cloudy, but perfect for tea time ☕️"
  // ];

  //dummy data
  final sampleMessages = [
    ChatMessage(
      id: 1,
      userId: 'user_123',
      aiID: 'claude_sonnet_4',
      text: 'Hello! Can you help me with a Flutter question?',
      isFromUser: true,
      timestamp: DateTime(2024, 12, 14, 10, 30, 0),
    ),
    ChatMessage(
      id: 2,
      userId: 'user_123',
      aiID: 'claude_sonnet_4',
      text: 'Of course! I\'d be happy to help with your Flutter question. What would you like to know?',
      isFromUser: false,
      timestamp: DateTime(2024, 12, 14, 10, 30, 15),
    ),
    ChatMessage(
      id: 3,
      userId: 'user_123',
      aiID: 'claude_sonnet_4',
      text: 'How do I access a ChangeNotifier outside of a build method?',
      isFromUser: true,
      timestamp: DateTime(2024, 12, 14, 10, 31, 0),
    )
  ];
  Map<AiPartner, List<ChatMessage>> map = {ai: sampleMessages};
  _user = User(
    id: "user_001",
    name: "Adam Hirshson",
    email: "Adam@Hirshson.com", //NOT REAL EMAIL - dont use for the purpose of the application
    createdAt: DateTime.now(),
    conversations: map,
    languages: ["English", "Chinese"]
  );
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
    void removeLanguage(String lang){ //Remove a language/stop learning it
    if(_user != null && _user!.languages.contains(lang)){
      _user!.languages.remove(lang);
    }
    //update user profile in database
  }

}