import 'dart:developer';

import 'package:anon_chat/custom_widgets/custom_drawer.dart';
import 'package:anon_chat/custom_widgets/custom_widgets.dart';
import 'package:anon_chat/providers/theme_provider.dart';
import 'package:anon_chat/providers/user_provider.dart';
import 'package:anon_chat/screens/conversation_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FindUserPage extends StatefulWidget {
  const FindUserPage({super.key});

  @override
  State<FindUserPage> createState() => _FindUserPageState();
}

class _FindUserPageState extends State<FindUserPage> {
  bool isSearching = false;
  bool isRequested = false;

  TextEditingController userController = TextEditingController();

  List<Map<String, dynamic>> users = [];
  String id = "";

  void getUserData({required String username}) async {
    try {
      var provider = Provider.of<UserProvider>(context, listen: false);
      isSearching = true;
      setState(() {});
      users.clear();

      var db = FirebaseFirestore.instance;
      await db.collection("users").get().then((snapshots) {
        if (snapshots.docs.isNotEmpty) {
          for (var singleUser in snapshots.docs) {
            debugPrint("Current User Comparison: $username == ${singleUser.data()["username"].toString().toLowerCase()} result: ${singleUser.data()["username"].toString().toLowerCase() == username.toLowerCase()}");
            if (singleUser.data()["username"].toString().toLowerCase() ==
                username.toLowerCase()) {
              users.add(singleUser.data());

              db.collection("chats").get().then((dataSnapshots) {
                debugPrint("got dataSnapshots");
                for (var user in dataSnapshots.docs) {
                  String first =
                      user.data()["first_user"].toString().toLowerCase();
                  String second =
                      user.data()["second_user"].toString().toLowerCase();
                  if (first == username.toLowerCase() &&
                      second == provider.username.toLowerCase()) {
                    setState(() {
                      debugPrint("Chat ID already exist");
                      id = user.id;
                      isRequested = true;
                    });
                  } else if (second == username.toLowerCase() &&
                      first == provider.username.toLowerCase()) {
                    setState(() {
                      debugPrint("Chat ID already exist");
                      id = user.id;
                      isRequested = true;
                    });
                  }
                }
              });
            }
            debugPrint("Current User Obj Lenght: ${users.length}\n");
          }
          isSearching = false;
          setState(() {});
          debugPrint("Current User Obj Lenght: ${users.length}\n");
        } else {
          isSearching = false;
          setState(() {});
        }
      });

    } catch (e) {
      log(e.toString());
    }
  }

  void createChatId({required Map<String, dynamic> data}) async {
    bool isExist = false;
    try {
      var db = FirebaseFirestore.instance;
      await db.collection("chats").get().then((dataSnapShots) {
        for (var userData in dataSnapShots.docs) {
          if (userData.data()["first_user"] == data["first_user"] &&
              userData.data()["second_user"] == data["second_user"]) {
            id = userData.id;
            isExist = true;
            setState(() {});
          } else if (userData.data()["first_user"] == data["second_user"] &&
              userData.data()["second_user"] == data["first_user"]) {
            id = userData.id;
            isExist = true;
            setState(() {});
          }
        }
      });

      if (!isExist) {
        await db.collection("chats").add(data);
        await db.collection("chats").get().then((dataSnapShots) {
          for (var userData in dataSnapShots.docs) {
            if (userData.data()["first_user"] == data["first_user"] &&
                userData.data()["second_user"] == data["second_user"]) {
              id = userData.id;
              isExist = true;
              setState(() {});
            } else if (userData.data()["first_user"] == data["second_user"] &&
                userData.data()["second_user"] == data["first_user"]) {
              id = userData.id;
              isExist = true;
              setState(() {});
            }
          }
        });
        isRequested = true;
        setState(() {});
      }
    } catch (e) {
      log(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    var provider = Provider.of<ThemeProvider>(context);
    var user_provider = Provider.of<UserProvider>(context);
    return Scaffold(
      drawer: CustomDrawer(context: context).drawer(),
      appBar: AppBar(
        title: const Text("Search Friend"),
      ),
      body: Container(
        margin: const EdgeInsets.only(top: 8),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, bottom: 5),
              child: Container(
                decoration: BoxDecoration(
                    color: provider.secondaryBg,
                    borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 15),
                        child: TextField(
                          controller: userController,
                          style: TextStyle(
                              color: provider.primaryText, fontSize: 14),
                          decoration: InputDecoration(
                              hintStyle: TextStyle(color: provider.thirdText),
                              border: InputBorder.none,
                              hintText: "Username"),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: isSearching
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: provider.primaryText,
                              ),
                            )
                          : InkWell(
                              onTap: () {
                                getUserData(username: userController.text);
                              },
                              child: const Icon(
                                Icons.search_rounded,
                                color: Colors.white,
                              ),
                            ),
                    )
                  ],
                ),
              ),
            ),
            (users.isNotEmpty)
                ? Expanded(
                    child: ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          onTap: () {},
                          minVerticalPadding: 5,
                          title: Text(
                            "@${users[index]["username"]}",
                            style: TextStyle(
                                color: provider.primaryText,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1),
                          ),
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundColor: provider.thirdBg,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: (users[index]["profile"] != "")
                                  ? Image.network(
                                      users[index]["profile"],
                                      fit: BoxFit.cover,
                                    )
                                  : Icon(
                                      Icons.person,
                                      color: provider.primaryBg,
                                    ),
                            ),
                          ),
                          subtitle: Text(
                            "Joined at ${CustomWidgets(context: context).dataTimeFormat(dateFormat: "dd-MM-yyyy", timestamp: users[index]['timestamp'] as Timestamp)}",
                            style: TextStyle(
                              color: provider.thirdText,
                              fontSize: 10,
                            ),
                          ),
                          trailing: (isRequested)
                              ? InkWell(
                                  onTap: () {
                                    if (id != "") {
                                      Navigator.push(
                                        context,
                                        (MaterialPageRoute(
                                          builder: (context) =>
                                              ConversationPage(
                                            data: {
                                              "first_user":
                                                  user_provider.username,
                                              "second_user": users[index]
                                                  ["username"],
                                              "timestamp": users[index]
                                                  ["timestamp"],
                                              "chat_id": id,
                                              "type": "user"
                                            },
                                          ),
                                        )),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              backgroundColor: Colors.red,
                                              content: Text(
                                                  "Unable to open chat !")));
                                    }
                                  },
                                  child: const Icon(
                                    Icons.chat_rounded,
                                    color: Colors.green,
                                  ),
                                )
                              : IconButton(
                                  icon: Icon(
                                    Icons.add,
                                    size: 30,
                                    color: provider.primaryText,
                                  ),
                                  onPressed: () {
                                    createChatId(data: {
                                      "first_user": user_provider.username,
                                      "second_user": users[index]["username"],
                                      "timestamp": FieldValue.serverTimestamp(),
                                      "type": "user"
                                    });
                                  },
                                ),
                        );
                      },
                    ),
                  )
                : const Expanded(
                    child: Center(
                      child: Text(
                        "There is no user to be shown.",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
