import 'package:flutter/material.dart';
import 'package:langpal_prototype/userNotifier.dart';
import 'package:provider/provider.dart';

//UI and logic to allow user to select new languages to add to their profile (is not currently connected (12/11/25) to what AI partners they have)

class LanguageSelector extends StatefulWidget {
  const LanguageSelector({super.key});

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  // Example language list
  final List<String> _availableLanguages = [ //should obtain available languages from the database to make it dynamic
    "English",
    "Spanish",
    "German",
    "Japanese"
  ];

  // User’s selected languages
  final List<String> _selectedLanguages = ["English"]; //default language (can be changed or perhaps selected at sign up)

  void _openLanguagePicker() async {
    // Show a modal bottom sheet with checkboxes
    await showModalBottomSheet(
      context: context,
      backgroundColor: Color.fromARGB(255, 255, 248, 233),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Consumer<UserNotifier>( //access user state notifier
              builder: (context, userNotifier, child) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Select Languages",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            ..._availableLanguages.map((lang) { //creates the scrollable list of available languages
                              final selected = _selectedLanguages.contains(lang);
                              return CheckboxListTile(
                                title: Text(lang),
                                value: selected,
                                onChanged: (bool? checked) {
                                  setModalState(() {
                                    if (checked == true) {
                                      userNotifier.addLanguage(lang);
                                      setState(() {
                                        _selectedLanguages.add(lang);
                                      });
                                    } else {
                                      userNotifier.removeLanguage(lang);
                                      setState(() {
                                      _selectedLanguages.remove(lang);
                                      });
                                    }
                                  });
                                },
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Done"),
                      )
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );

  }

  @override
  Widget build(BuildContext context) {
    final displayed = _selectedLanguages.join(", ");
    return GestureDetector(
      onTap: _openLanguagePicker,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Languages:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              Text( //shows what languages are attached to the user
                displayed.isEmpty ? "None" : displayed,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.edit, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}
