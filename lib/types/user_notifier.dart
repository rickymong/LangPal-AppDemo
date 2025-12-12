import 'package:flutter/material.dart';
import 'user.dart';
import 'ai_partner.dart';

//Notifier for managing state of user

class UserNotifier extends ChangeNotifier{
   
  User? _user;
  
  User? get user => _user;

  UserNotifier(){
    _initObjects();
  }

//Dummy Data
  void _initObjects(){ //initialize a User and AI partners into state (we'd normally query from database here)
    final ai = AiPartner(
      name: "Sophia",
      id: "ai_001",
      language: "Spanish",
      flag_path: "images/flags/spain_flag.jpg",
    );

  final List<String> convo = [
    "Hi Sophia! How are you today?",
    "I'm doing great, thanks for asking!",
    "What’s the weather like in London?",
    "A bit cloudy, but perfect for tea time ☕️"
  ];

  Map<AiPartner, List<String>> map = {ai: convo};
  _user = User(
    id: "user_001",
    name: "Adam Hirshson",
    email: "Adam@Hirshson.com", //NOT REAL EMAIL - dont use for the purpose of the application
    createdAt: DateTime.now(),
    conversations: map,
    languages: ["English", "Chinese"]
  );
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

  void addMessage(AiPartner partner, String message) { //adds a message to the users recorded conversation with AI partner
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