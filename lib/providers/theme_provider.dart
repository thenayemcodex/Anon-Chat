import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  // conts global colors
  Color primaryText = const Color.fromARGB(255, 255, 255, 255);
  Color secondaryText = const Color.fromARGB(255, 225, 225, 225);
  Color thirdText = const Color.fromARGB(255, 205, 205, 205);

  Color primaryBg = const Color.fromARGB(255, 0, 0, 0);
  Color secondaryBg = const Color.fromARGB(255, 20, 20, 20);
  Color thirdBg = const Color.fromARGB(255, 30, 30, 30);
}
