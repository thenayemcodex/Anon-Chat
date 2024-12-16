import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  String username = "Anonymous";
  String profile = "";

  void updateUserCredentials({String? name, String? profileUrl}) {
    if (name != null) {
      username = name;
    }

    if (profileUrl != null) {
      profile = profileUrl;
    }
    notifyListeners();
  }
}
