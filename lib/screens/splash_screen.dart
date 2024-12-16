
import 'package:anon_chat/providers/theme_provider.dart';
import 'package:anon_chat/providers/user_provider.dart';
import 'package:anon_chat/screens/home_page.dart';
import 'package:anon_chat/screens/sign_up_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  var auth = FirebaseAuth.instance;
  var db = FirebaseFirestore.instance;

  // to check if the user is already logged in or not
  void checkLoginStatus() {
    Future.delayed(const Duration(seconds: 2), () {
      if (auth.currentUser?.uid != null) {
        setState(() {});
        db
            .collection("users")
            .doc(auth.currentUser!.uid)
            .get()
            .then((snapshot) {
          var datas = snapshot.data();
          if (datas != null) {
            debugPrint("Current UserName => ${datas["username"]}");
            Provider.of<UserProvider>(context, listen: false)
                .updateUserCredentials(
                    name: datas["username"], profileUrl: datas["profile"]);
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const HomePage()));
          }
        });
      } else {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const SignUpPage()));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Color.fromARGB(255, 240, 151, 145),
            content: const Text(
                "No account information found. Please sign up here...")));
      }
      debugPrint("Current User Existance: UID => ${auth.currentUser?.uid} ");
    });
  }

  @override
  void initState() {
    checkLoginStatus();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 75,
                    backgroundColor: Colors.transparent,
                    child: ClipOval(
                      child: Image.asset(
                        "asset/images/chats.png",
                        fit: BoxFit.cover,
                        height: 150,
                        width: 150,
                      ),
                    ),
                  ),
                  const Text(
                    "AnonChat",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  const Text(
                    "Where privacy is at the top",
                    style: TextStyle(
                      fontSize: 08,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            LinearProgressIndicator(
              color: Colors.white,
              backgroundColor: Provider.of<ThemeProvider>(context).primaryBg,
            ),
          ],
        ),
      ),
    );
  }
}
