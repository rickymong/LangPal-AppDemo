import 'package:flutter/material.dart';
import 'package:langpal_prototype/profile/languageSelector.dart';
import 'package:langpal_prototype/types/aiPartner.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../types/user.dart';
import '../userNotifier.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';



class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  
  final ImagePicker imgPicker = ImagePicker(); //allows profile photo upload
  Future<dynamic> pickImage() async {
    final XFile? image = await imgPicker.pickImage(source: ImageSource.gallery); 
    //In production, would upload this to a database so 
    //it doesn't depend on the user keeping the image 

    if(image != null) {
      print('Selected image path: ${image.path}');
      return image.path;
    }
    return null;
  }


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    //load data from user state
    User user = context.watch<UserNotifier>().user!;
    String languages = "";
    for(int i = 0; i < user.languages.length; i++){ //Turn user's languages into a visual list -- How they are displayed should probably be changed
      if(i < user.languages.length - 1){
        languages += "${user.languages[i]} | ";
      }
      else{
        languages = languages + user.languages[i]; //makes it so last item doesn't have '|'"
      }
    }

    return Scaffold(

      body: SingleChildScrollView(
        child: Container(
          width: width,
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.08,
            vertical: height * 0.04,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile image
              Consumer<UserNotifier>(
                builder: (context, user, child) {  
                  return GestureDetector( //tap profile picture to change
                    onTap: () async {
                      String? newImagePath = await pickImage() as String?;
                      user.changeProfilePicture(newImagePath);
                      print("profile path: ${user.user!.profile_image_path}");
                    },
                    child: CircleAvatar(
                      radius: width * 0.18,
                      backgroundImage: user.user!.profile_image_path != null
                        ? FileImage(File(user.user!.profile_image_path!))
                        : const AssetImage('images/profile_placeholder.png') as ImageProvider,

                    ),
                  );
                },

              ),
              SizedBox(height: height * 0.03),

              // Make name editable?
              Text(
                user.name,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              SizedBox(height: height * 0.02),

              // Joined Date - gotten from user state
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Joined:"),
                  Text(DateFormat('MM/dd/yyyy').format(user.createdAt)),
                ],
              ),
              SizedBox(height: height * 0.015),

              // Editable Languages
              LanguageSelector(),
    
              SizedBox(height: height * 0.04),
              // Settings Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    //Just for show
                  },
                  icon: const Icon(Icons.settings, color: Color.fromARGB(255, 0, 0, 0)),
                  label: Text(
                     "Settings", style: TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: height * 0.018),
                    backgroundColor: Color.fromARGB(255, 7, 172, 190),
                  ),
                ),
              ),
              
              SizedBox(height: height * 0.02),
              
              // Sign Out Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    // Show confirmation dialog
                    final shouldSignOut = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Sign Out'),
                        content: const Text('Are you sure you want to sign out?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    
                    if (shouldSignOut == true && context.mounted) {
                      await context.read<UserNotifier>().signOut();
                    }
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text("Sign Out", style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: height * 0.018),
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Color.fromARGB(255, 255, 248, 233),
    );
  } //end Widget build
}