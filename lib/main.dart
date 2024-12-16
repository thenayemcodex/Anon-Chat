

import 'package:anon_chat/firebase_options.dart';
import 'package:anon_chat/providers/theme_provider.dart';
import 'package:anon_chat/providers/user_provider.dart';
import 'package:anon_chat/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: ChangeNotifierProvider(
        create: (_) => UserProvider(),
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    var provider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Anon-Chat',
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: Colors.white,
        scaffoldBackgroundColor: Colors.black,
        dialogTheme: DialogTheme(backgroundColor: provider.thirdBg),

        bottomSheetTheme:
            const BottomSheetThemeData(backgroundColor: Colors.black45),
        fontFamily: 'roboto',
        textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.white)),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(95, 22, 22, 22),
          foregroundColor: Colors.white, // Text color for app bar in dark mode
        ),
        // You can add other theme customizations for dark mode here
      ),
      home: const SplashScreen(),
    );
  }

  
}
