import 'dart:developer';

import 'package:anon_chat/providers/theme_provider.dart';
import 'package:anon_chat/providers/user_provider.dart';
import 'package:anon_chat/screens/home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  var auth = FirebaseAuth.instance;
  var db = FirebaseFirestore.instance;
  bool isLoading = false;

  TextEditingController userController = TextEditingController();

  void checkLoginStatus() {
    if (auth.currentUser?.uid != null) {
      isLoading = true;
      setState(() {});
      db.collection("users").doc(auth.currentUser!.uid).get().then((snapshot) {
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
    }
    debugPrint("Current User Existance: UID => ${auth.currentUser?.uid} ");
  }

  @override
  void initState() {
    checkLoginStatus();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var provider = Provider.of<ThemeProvider>(context);
    var userProvider = Provider.of<UserProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Create an Account",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // CircleAvatar(
              //   radius: 70,
              //   backgroundImage: ExactAssetImage("asset/images/logo.png"),
              // ),
              const SizedBox(
                height: 80,
              ),
              CircleAvatar(
                radius: 70,
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
                "Have Fun Anonymously",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(
                height: 35,
              ),
              Container(
                padding: const EdgeInsets.only(left: 15, right: 10),
                margin: const EdgeInsets.only(left: 25, right: 25),
                decoration: BoxDecoration(
                  color: provider.secondaryBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextFormField(
                  style: TextStyle(color: provider.primaryText, fontSize: 14),
                  controller: userController,
                  autocorrect: true,
                  decoration: InputDecoration(
                      icon: Icon(
                        Icons.person_2_rounded,
                        color: provider.primaryText,
                      ),
                      labelText: "Username",
                      labelStyle: TextStyle(color: provider.thirdText),
                      border: InputBorder.none),
                ),
              ),

              //button
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ButtonStyle(
                          backgroundColor:
                              WidgetStateProperty.all(Colors.blue[400])),
                      onPressed: () async {
                        // check username
                        bool isExist = false;
                        if (userController.text.trim() != "" &&
                            userController.text.trim().length >= 4) {
                          try {
                            isLoading = true;
                            setState(() {});

                            await db.collection("users").get().then((snapshot) {
                              for (var user in snapshot.docs) {
                                if (user.data()["username"] ==
                                    userController.text.trim()) {
                                  isLoading = false;
                                  setState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          "Username already been taken. Try again."),
                                    ),
                                  );
                                  isExist = true;
                                }
                              }
                            });

                            if (!isExist) {
                              debugPrint("Username is valid: ${userController.text}");
                              await auth.signInAnonymously();
                              debugPrint("Is current User NotNull: ${auth.currentUser != null}");
                              if (auth.currentUser != null) {
                                Map<String, dynamic> data = {
                                  "profile": "",
                                  "username": userController.text,
                                  "uid": auth.currentUser!.uid,
                                  "timestamp": FieldValue.serverTimestamp()
                                };
                                db
                                    .collection("users")
                                    .doc(auth.currentUser!.uid)
                                    .set(data);
                                userProvider.updateUserCredentials(
                                    name: userController.text);
                                Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const HomePage()));
                              } else {
                                isLoading = false;
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text("Registration failed")));
                              }
                            }

                            // ... use user data
                          } on FirebaseAuthException catch (e) {
                            isLoading = false;
                            setState(() {});
                            // Handle errors during sign-in
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "Something went wrong with authentication")));
                            log(e.toString());
                          } on FirebaseException catch (e) {
                            isLoading = false;
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "Something went wrong with data saving")));
                            log(e.toString());
                          } catch (e) {
                            isLoading = false;
                            setState(() {});
                            log(e.toString());
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "$e",
                                ),
                              ),
                            );
                          }
                        } else {
                          isLoading = false;
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Colors.red,
                              content:
                                  Text("Something went wrong with data saving"),
                            ),
                          );
                        }
                      },
                      child: (isLoading)
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(10.0),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            )
                          : const Padding(
                              padding: EdgeInsets.only(
                                top: 10,
                                right: 30,
                                bottom: 10,
                                left: 30,
                              ),
                              child: Text(
                                "Sign Up",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
