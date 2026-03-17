import 'package:dio/dio.dart';


//local host the backend by:
//navigating to AITutorBackend in terminal and running "uvicorn main:app"

class BackendService{

  final String baseUrl = "http://localhost:8000"; //change for server
  final dio = Dio();

  Future<Map<String, dynamic>?> postWordleGame(String userId) async {
    try{
      final response = await dio.post('$baseUrl/games/wordle/start', data: {"user_id": userId});
      for(Object o in response.data)
        print(o.toString());
      return response.data;
    }catch(e){
      print("API connection error: $e");
      return null;
    }
  }


}

void main() async { //dart run lib/services/backendService.dart 
  final service = BackendService();
  final result = await service.postWordleGame("970405a7-3259-411d-9c57-17f6562ece33");
  print("Response: $result");
}