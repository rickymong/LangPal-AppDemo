//Class to represent Ai chat bot partners and their relevant data
class AiPartner{
  final String name;
  final String id;
  final String language;
  final String flag_path;

  AiPartner({
    required this.name,
    required this.id,
    required this.language,
    required this.flag_path
  });

  @override
  bool operator ==(Object other){
    if(identical(this, other)){
      return true;
    }
    return other is AiPartner && other.id == id; //AiPartners can now be compared based off id 
    //(used in user_notifier.dart)

  }

  @override
  int get hashCode => id.hashCode;

}