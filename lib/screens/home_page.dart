import 'package:anon_chat/custom_widgets/custom_drawer.dart';
import 'package:anon_chat/providers/theme_provider.dart';
import 'package:anon_chat/providers/user_provider.dart';
import 'package:anon_chat/screens/conversation_page.dart';
import 'package:anon_chat/screens/find_user_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // var auth = FirebaseAuth.instance;
  var db = FirebaseFirestore.instance;
  // var fStorage = FirebaseStorage.instance;

  List<Map<String, dynamic>> chatList = [];
  Map<String, dynamic> chatLastMessages = {};
  bool isChatEmpty = true;
  Map<String, dynamic> usersProfile = {};

  void getLastMessages({required List<String> chatID}) async {
    for (String index in chatID) {
      await db
          .collection("messages")
          .where("chat_id", isEqualTo: index)
          .orderBy("timestamp", descending: true)
          .get()
          .then((lastMessage) {
        var lastMsg = lastMessage.docs;
        if (lastMsg.isNotEmpty) {
          chatLastMessages[index] = lastMsg.first["message"];
        } else {
          chatLastMessages[index] = "...";
        }
      });
    }
    setState(() {});
  }

  Future<void> onChatListRefresh() async {
    var userProvider = Provider.of<UserProvider>(context);
    await db
        .collection("messages")
        .orderBy("timestamp", descending: true)
        .where('sender', isEqualTo: userProvider.username)
        .where('sentTo', isEqualTo: userProvider.username)
        .get()
        .then((onSnapshot) {
      List<String> ids = [];
      if (onSnapshot.docs.isNotEmpty) {
        chatList.clear();
        for (var singleChat in onSnapshot.docs) {
          if (!ids.any((value) => value == singleChat.id)) {
            chatList.add(singleChat.data());
            ids.add(singleChat.id);
          }
        }
        setState(() {});
      }
    });
  }

  Future<List<Map<String, dynamic>>> getProfileImages(
      {required var snapshotDocs}) async {
    var userProvider = Provider.of<UserProvider>(context, listen: false);
    String chatWith = "";
    List<String> ids = [];
    chatList.clear();

    for (var singleChat in snapshotDocs) {
      if (singleChat.data()["sender"] == userProvider.username ||
          singleChat.data()["sentTo"] == userProvider.username) {
        //debugPrint("Matching ID: ${singleChat.id} isExist: ${ids.contains(singleChat.data()["chat_id"])}");
        if (ids.any((element) => element == singleChat.data()["chat_id"])) {
          continue;
        } else {
          ids.add(singleChat.data()["chat_id"]);

          var user = singleChat.data();
          if (user['sender'] == userProvider.username) {
            chatWith = user["sentTo"];
          } else if (user['sentTo'] == userProvider.username) {
            chatWith = user["sender"];
          }

          if (user['type'] == "user") {
            await db
                .collection("users")
                .where("username", isEqualTo: chatWith)
                .get()
                .then((snapshot) {
              singleChat.data()["profile"] =
                  snapshot.docs.first.data()["profile"];
              setState(() {});
            });
          } else if (user['type'] == "group") {
            await db
                .collection("groups")
                .where("name", isEqualTo: chatWith)
                .get()
                .then((snapshot) {
              singleChat.data()["profile"] =
                  snapshot.docs.first.data()["profile"];
              setState(() {});
            });
          }
          chatList.add(singleChat.data());
        }
      }
    }
    return chatList;
  }

  Future<void> getAllProfileImages() async {
    var userProvider = Provider.of<UserProvider>(context, listen: false);
    String chatWith = "";
    List<String> ids = [];
    usersProfile.clear();
    //debugPrint("getAllProfileImages executed");
    try {
      await db
          .collection("messages")
          .orderBy("timestamp", descending: true)
          .get()
          .then((snapshot) {
        for (var singleChat in snapshot.docs) {
          if (singleChat.data()["sender"] == userProvider.username ||
              singleChat.data()["sentTo"] == userProvider.username) {
            if (ids.any((element) => element == singleChat.data()["chat_id"])) {
              continue;
            } else {
              ids.add(singleChat.data()["chat_id"]);

              var user = singleChat.data();
              if (user['sender'] == userProvider.username) {
                chatWith = user["sentTo"];
              } else if (user['sentTo'] == userProvider.username) {
                chatWith = user["sender"];
              }
              getProfile(name: chatWith, type: user["type"]);
            }
          }
        }
      });
      //debugPrint("getAllProfileImages List: ${usersProfile.toString()}");
    } catch (e) {
      //debugPrint("getAllProfileImages Profile Error: ${e.toString()}");
    }
  }

  void getProfile({required String name, required String type}) async {
    if (type == "user") {
      await db
          .collection("users")
          .where("username", isEqualTo: name)
          .get()
          .then((userSnapshot) {
        if (userSnapshot.docs.first.data().isNotEmpty) {
          usersProfile[name] = userSnapshot.docs.first.data()["profile"] ?? "";
          //debugPrint("getAllProfileImages adding user: {$name: ${userSnapshot.docs.first.data()["profile"] ?? ""}}");
        } else {
          //debugPrint("getAllProfileImages User data empty");
        }
      });
    } else if (type == "group") {
      await db
          .collection("groups")
          .where("name", isEqualTo: name)
          .get()
          .then((userSnapshot) {
        if (userSnapshot.docs.first.data().isNotEmpty) {
          usersProfile[name] = userSnapshot.docs.first.data()["profile"] ?? "";
          //debugPrint("getAllProfileImages adding group: {$name: ${userSnapshot.docs.first.data()["profile"] ?? ""}}");
        } else {
          //debugPrint("getAllProfileImages User data empty");
        }
        // usersProfile[name] =
        // userSnapshot.docs.first.data()["profile"] ?? "";
      });
    }
    // //debugPrint("getAllProfileImages UserProfile list: ${usersProfile.toString()}");
    setState(() {});
  }

  @override
  void initState() {
    getAllProfileImages();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var provider = Provider.of<ThemeProvider>(context);
    var userProvider = Provider.of<UserProvider>(context);
    return Scaffold(
      drawerEnableOpenDragGesture: true,
      drawer: CustomDrawer(context: context).drawer(),
      appBar: AppBar(
        title: const Text(
          "Anon-Chat",
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const FindUserPage()));
        },
        backgroundColor: provider.primaryText,
        foregroundColor: provider.primaryBg,
        mini: true,
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await getAllProfileImages();
          return;
        },
        child: StreamBuilder(
          stream: db
              .collection("messages")
              .orderBy("timestamp", descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            // processing data
            List<String> ids = [];
            chatList.clear();

            if (snapshot.data != null) {
              for (var singleChat in snapshot.data!.docs) {
                if (singleChat.data()["sender"] == userProvider.username ||
                    singleChat.data()["sentTo"] == userProvider.username) {
                  // //debugPrint("Matching ID: ${singleChat.id} isExist: ${ids.contains(singleChat.data()["chat_id"])}");
                  if (ids.any(
                      (element) => element == singleChat.data()["chat_id"])) {
                    continue;
                  } else {
                    ids.add(singleChat.data()["chat_id"]);
                    chatList.add(singleChat.data());
                    // //debugPrint("getAllProfileImages Profile Counts: ${usersProfile.length} \nChatList Counts: ${chatList.length}");
                  }
                }
              }
            }
            // //debugPrint("getAllProfileImages Profile count: ${usersProfile.length}.............. Chats count: ${chatList.length}");
            if (usersProfile.length != chatList.length) {
              getAllProfileImages();
            }

            return (chatList.isEmpty)
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: provider.primaryText,
                        ),
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("Find some friend globally !"),
                        )
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: chatList.length,
                    itemBuilder: (context, index) {
                      String name = "";
                      if (chatList[index]["sender"] == userProvider.username) {
                        name = chatList[index]["sentTo"];
                      } else if (chatList[index]["sentTo"] ==
                          userProvider.username) {
                        name = chatList[index]["sender"];
                      }

                      // //debugPrint("getAllProfileImages Name>> : $name Profile: ${usersProfile[name]}");

                      return ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            (MaterialPageRoute(
                              builder: (context) => ConversationPage(
                                data: {
                                  "first_user": chatList[index]["sender"],
                                  "second_user": chatList[index]["sentTo"],
                                  "timestamp": chatList[index]["timestamp"],
                                  "chat_id": chatList[index]["chat_id"],
                                  "type": chatList[index]["type"]
                                },
                              ),
                            )),
                          );
                        },
                        leading: (usersProfile.isNotEmpty)
                            ? CircleAvatar(
                                backgroundColor: provider.secondaryBg,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(25),
                                  child: (usersProfile[name].toString() != "")
                                      ? Image.network(
                                          usersProfile[name].toString(),
                                          fit: BoxFit.cover,
                                        )
                                      : Icon(
                                          color: provider.primaryText,
                                          Icons.person,
                                        ),
                                ),
                              )
                            : const SizedBox(),
                        title: Text(
                          name.toString().toUpperCase(),
                          style: TextStyle(
                              fontSize: 16, color: provider.primaryText),
                        ),
                        subtitle: SizedBox(
                          height: 16,
                          child: (chatList[index]["txtType"] == "txt")
                              ? Text(
                                  chatList[index]["message"].toString(),
                                  //chatList[index]["message"],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: provider.thirdText,
                                  ),
                                )
                              : Text(
                                  'attachment ',
                                  //chatList[index]["message"],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: provider.thirdText,
                                  ),
                                ),
                        ),
                      );
                    },
                  );
          },
        ),
      ),
    );
  }

  // this function will be call from customer widget to update profile image in provider
  void updateProfile({required String profile}) {
    var provider = Provider.of<UserProvider>(context, listen: false);
    provider.updateUserCredentials(profileUrl: profile);
  }
}
