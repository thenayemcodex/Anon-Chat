import 'dart:developer';
import 'dart:io';

import 'package:anon_chat/custom_widgets/custom_widgets.dart';
import 'package:anon_chat/firebase/firebase_services.dart';
import 'package:anon_chat/providers/theme_provider.dart';
import 'package:anon_chat/providers/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:saver_gallery/saver_gallery.dart';

// ignore: must_be_immutable
class ConversationPage extends StatefulWidget {
  Map<String, dynamic> data;
  ConversationPage({super.key, required this.data});

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  // necessary variables
  TextEditingController messageController = TextEditingController();
  var db = FirebaseFirestore.instance;
  List<Map<String, dynamic>> messagesList = [];

  double inputHeight = 60;
  String convType = "";
  bool imgVisible = true;
  String chatingWith = "";
  String oppositionsProfile = "";

  void checkPoint() {
    try {
      var provider = Provider.of<UserProvider>(context, listen: false);
      debugPrint("Conversation Type: ${widget.data["type"]}");
      if (widget.data.isNotEmpty) {
        if (widget.data["chat_id"] == null) {
          Navigator.pop(context);
        } else {
          if (widget.data["first_user"] == provider.username) {
            chatingWith = widget.data["second_user"];
          } else if (widget.data["second_user"] == provider.username) {
            chatingWith = widget.data["first_user"];
          }
          getConvType(chatId: widget.data["chat_id"]);
        }
      } else {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showMaterialBanner(MaterialBanner(
            content: const Text(
              "Conversation not found !",
              style: TextStyle(color: Colors.red),
            ),
            actions: [
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).clearMaterialBanners;
                  Navigator.pop(context);
                },
                child: const Icon(
                  Icons.close,
                  color: Colors.red,
                ),
              )
            ]));
      }
      debugPrint("Data: ${widget.data.toString()}");
    } catch (e) {
      debugPrint(
          "Data List Error: ${e.toString()}\n Data: ${widget.data.toString()}");
    }
  }

  Future<void> getConvType({required String chatId}) async {
    await db.collection("chats").doc(chatId).get().then((data) {
      if (data.data() != null) {
        convType = data.data()!["type"];
        // "first_user":user_provider.username,"second_user": users[index]["username"],
        if (convType == "user") {
          db
              .collection("users")
              .where("username", isEqualTo: chatingWith)
              .get()
              .then((dataSnapshot) {
            if (dataSnapshot.docs.isNotEmpty) {
              var value = dataSnapshot.docs.first;
              log(value.data().toString());
              oppositionsProfile = value.data()["profile"];
            }
          });
        } else if (convType == "group") {
          db
              .collection("groups")
              .where("name", isEqualTo: chatingWith)
              .get()
              .then((dataSnapshot) {
            if (dataSnapshot.docs.isNotEmpty) {
              var value = dataSnapshot.docs.first;
              log(value.data().toString());
              oppositionsProfile = value.data()["profile"];
            }
          });
        } else {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showMaterialBanner(MaterialBanner(
              content: const Text(
                "Conversation not found !",
                style: TextStyle(color: Colors.red),
              ),
              actions: [
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).clearMaterialBanners;
                    Navigator.pop(context);
                  },
                  child: const Icon(
                    Icons.close,
                    color: Colors.red,
                  ),
                )
              ]));
        }
      }
    });
  }

  @override
  void initState() {
    checkPoint();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var provider = Provider.of<ThemeProvider>(context);
    var userProvider = Provider.of<UserProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(chatingWith),
        actions: [
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: PopupMenuButton(
              color: provider.thirdBg,
              icon: const Icon(Icons.info), // Replace with your desired icon
              itemBuilder: (context) => [
                (convType == "user")
                    ? PopupMenuItem(
                        value: 1,
                        child: Text(
                          "Delete $chatingWith ",
                          style: TextStyle(color: provider.primaryText),
                        ),
                      )
                    : PopupMenuItem(
                        value: 2,
                        child: Text(
                          "Leave $chatingWith",
                          style: TextStyle(color: provider.primaryText),
                        ),
                      ),
              ],
              onSelected: (value) {
                if (value == 1) {
                  showDialog(
                      context: context,
                      builder: (context) {
                        log('user delete');
                        return AlertDialog(
                          title: const Text(
                            "Do you want to delete this chat ?",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          content: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                  onTap: () => Navigator.pop(context),
                                  child: const Text(
                                    "No",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                                InkWell(
                                    onTap: () {
                                      if (widget.data["chat_id"] != "") {
                                        Navigator.pop(context);
                                        FirebaseServices(context: context)
                                            .deleteChat(
                                                chatId: widget.data["chat_id"]);
                                      }
                                    },
                                    child: const Text("Yes"))
                              ]),
                        );
                      });
                } else if (value == 2) {
                  showDialog(
                      context: context,
                      builder: (context) {
                        log('user delete');
                        return AlertDialog(
                          title: const Text(
                            "Do you want to leave this group ?",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          content: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                  onTap: () => Navigator.pop(context),
                                  child: const Text(
                                    "No",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                                InkWell(
                                    onTap: () {
                                      Navigator.pop(context);
                                      FirebaseServices(context: context)
                                          .leaveGroup(
                                              username: userProvider.username,
                                              groupName: chatingWith);
                                    },
                                    child: const Text("Yes"))
                              ]),
                        );
                      });
                }
              },
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: db
                  .collection("messages")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, dataSnapshots) {
                try {
                  messagesList.clear();
                  var allMessages = dataSnapshots.data?.docs ?? [];
                  if (allMessages.isNotEmpty) {
                    // debugPrint("allMessages ${allMessages.length}\n ${allMessages.first.data().toString()}");
                    for (var message in allMessages) {
                      if (message.data()["chat_id"] == widget.data["chat_id"] &&
                          message.data()["delete"] != userProvider.username) {
                        // get all reactor and filtering all react to show below text
                        // debugPrint("message and delete condition passed");
                        String showReact = "";

                        // debugPrint("Check React: ${message.data()["react"]} ${message.data()["react"].runtimeType}");
                        if (message.data()["react"] != null) {
                          Map<String, dynamic> reactMap =
                              message.data()["react"];
                          List<dynamic> reacts =
                              reactMap.values.toSet().toList();
                          for (String value in reacts) {
                            showReact += value;
                          }
                        }

                        Map<String, dynamic> msgWithID = {
                          "id": message.id,
                          "showReact": showReact
                        };
                        msgWithID.addAll(message.data());
                        // debugPrint("message: ${msgWithID.toString()}");
                        messagesList.add(msgWithID);
                        // debugPrint("MessagesList Length: ${messagesList.length}");
                      } else {
                        debugPrint(
                            "chatid and delete condition:  ${message.data()["chat_id"] == widget.data["chat_id"] && message.data()["delete"] != userProvider.username}");
                      }
                    }
                  }
                } catch (e) {
                  debugPrint("Error: ${e}");
                }

                return (messagesList.isEmpty)
                    ? const Center(
                        child: Text(
                          "No message to show or check your internet connection and try again",
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        reverse: true,
                        itemCount: messagesList.length,
                        itemBuilder: (context, index) {
                          return Column(
                            crossAxisAlignment: (messagesList[index]
                                        ["sender"] !=
                                    userProvider.username)
                                ? CrossAxisAlignment.start
                                : CrossAxisAlignment.end,
                            children: [
                              GestureDetector(
                                onDoubleTap: () {
                                  try {
                                    if (messagesList[index]["id"] != null) {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            content: SizedBox(
                                              height: 107,
                                              child: Column(
                                                children: [
                                                  reactionBar(
                                                      messageID:
                                                          messagesList[index]
                                                              ["id"]),
                                                  const SizedBox(
                                                    height: 10,
                                                  ),
                                                  InkWell(
                                                    onTap: () async {
                                                      try {
                                                        bool everyone = false;
                                                        await db
                                                            .collection(
                                                                "messages")
                                                            .doc(messagesList[
                                                                index]["id"])
                                                            .get()
                                                            .then(
                                                                (getData) async {
                                                          if (getData.data() !=
                                                              null) {
                                                            if (getData.data()![
                                                                    "delete"] ==
                                                                "") {
                                                              db
                                                                  .collection(
                                                                      "messages")
                                                                  .doc(messagesList[
                                                                          index]
                                                                      ["id"])
                                                                  .update({
                                                                "delete":
                                                                    userProvider
                                                                        .username
                                                              });
                                                            } else {
                                                              everyone = true;
                                                              db
                                                                  .collection(
                                                                      "messages")
                                                                  .doc(messagesList[
                                                                          index]
                                                                      ["id"])
                                                                  .delete();
                                                            }
                                                          }
                                                          if (messagesList[
                                                                          index]
                                                                      [
                                                                      "txtType"] ==
                                                                  "img" &&
                                                              everyone) {
                                                            await FirebaseServices(
                                                                    context:
                                                                        context)
                                                                .deleteFile(
                                                                    storagePath:
                                                                        messagesList[index]
                                                                            [
                                                                            "path"]);
                                                          }
                                                        });
                                                        Navigator.pop(context);
                                                      } catch (e) {
                                                        log(e.toString());
                                                      }
                                                    },
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.person,
                                                          color: provider
                                                              .primaryText,
                                                        ),
                                                        const SizedBox(
                                                          width: 10,
                                                        ),
                                                        Text(
                                                          "Delete for me",
                                                          style: TextStyle(
                                                              color: provider
                                                                  .primaryText),
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    height: 10,
                                                  ),
                                                  (messagesList[index]
                                                              ["sender"] ==
                                                          userProvider.username)
                                                      ? InkWell(
                                                          onTap: () async {
                                                            try {
                                                              Navigator.pop(
                                                                  context);
                                                              if (messagesList[
                                                                          index]
                                                                      [
                                                                      "txtType"] ==
                                                                  "img") {
                                                                await FirebaseServices(
                                                                        context:
                                                                            context)
                                                                    .deleteFile(
                                                                        storagePath:
                                                                            messagesList[index]["path"]);
                                                              }
                                                              await db
                                                                  .collection(
                                                                      "messages")
                                                                  .doc(messagesList[
                                                                          index]
                                                                      ["id"])
                                                                  .delete();
                                                            } catch (e) {
                                                              debugPrint(
                                                                  "File deletation failed: $e");
                                                            }
                                                          },
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                Icons.delete,
                                                                color: provider
                                                                    .primaryText,
                                                              ),
                                                              const SizedBox(
                                                                width: 10,
                                                              ),
                                                              Text(
                                                                "Delete for everyone",
                                                                style: TextStyle(
                                                                    color: provider
                                                                        .primaryText),
                                                              )
                                                            ],
                                                          ),
                                                        )
                                                      : const SizedBox(),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    }
                                  } catch (e) {
                                    log(e.toString());
                                  }
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    (messagesList[index]["sender"] !=
                                            userProvider.username)
                                        ? CircleAvatar(
                                            radius: 15,
                                            backgroundColor: provider.thirdBg,
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              child: (messagesList[index]
                                                          ["profile"] !=
                                                      "")
                                                  ? Image.network(
                                                      fit: BoxFit.cover,
                                                      messagesList[index]
                                                          ["profile"])
                                                  : Icon(
                                                      color:
                                                          provider.primaryText,
                                                      Icons.person,
                                                    ),
                                            ),
                                          )
                                        : const SizedBox(),
                                    Container(
                                      margin: (messagesList[index]["sender"] !=
                                              userProvider.username)
                                          ? const EdgeInsets.only(
                                              left: 5,
                                              top: 5,
                                              bottom: 1,
                                              right: 38)
                                          : const EdgeInsets.only(
                                              left: 38,
                                              top: 5,
                                              bottom: 5,
                                              right: 5),
                                      padding: const EdgeInsets.all(5),
                                      constraints: BoxConstraints(
                                          maxWidth:
                                              CustomWidgets(context: context)
                                                  .width(width: 50)),
                                      decoration: BoxDecoration(
                                          color: (messagesList[index]
                                                      ["sender"] !=
                                                  userProvider.username)
                                              ? provider.secondaryBg
                                              : provider.primaryText,
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      child: Column(
                                        crossAxisAlignment: (messagesList[index]
                                                    ["sender"] !=
                                                userProvider.username)
                                            ? CrossAxisAlignment.start
                                            : CrossAxisAlignment.end,
                                        children: [
                                          (widget.data["type"] != "" &&
                                                  widget.data["type"] ==
                                                      "group")
                                              ? SelectableText(
                                                  "@${messagesList[index]["sender"]}",
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w100,
                                                    color: (messagesList[index]
                                                                ["sender"] !=
                                                            userProvider
                                                                .username)
                                                        ? Colors.blue
                                                        : Colors.green,
                                                  ),
                                                )
                                              : const SizedBox(),
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 1),
                                            child:
                                                (messagesList[index]["txtType"]
                                                            .toString() ==
                                                        "txt")
                                                    ? GestureDetector(
                                                        onLongPress: () async {
                                                          await Clipboard.setData(
                                                              ClipboardData(
                                                                  text: messagesList[
                                                                          index]
                                                                      [
                                                                      'message']));
                                                        },
                                                        child: ConstrainedBox(
                                                          // expanded widget
                                                          constraints: BoxConstraints(
                                                              maxWidth: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width *
                                                                  0.7),
                                                          child: Text(
                                                            messagesList[index]
                                                                    ['message']
                                                                .toString(),
                                                            textAlign:
                                                                TextAlign.left,
                                                            style: TextStyle(
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w100,
                                                              color: messagesList[
                                                                              index]
                                                                          [
                                                                          'sender'] !=
                                                                      userProvider
                                                                          .username
                                                                  ? provider
                                                                      .primaryText
                                                                  : provider
                                                                      .primaryBg,
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                    : GestureDetector(
                                                        onTap: () {
                                                          showDialog(
                                                              context: context,
                                                              builder:
                                                                  (context) {
                                                                return AlertDialog(
                                                                  content: (messagesList[index]
                                                                              [
                                                                              'message'] !=
                                                                          null)
                                                                      ? Image.network(
                                                                          messagesList[index]
                                                                              [
                                                                              'message'])
                                                                      : const Text(
                                                                          "Failed to load image"),
                                                                );
                                                              });
                                                        },
                                                        onLongPress: () {
                                                          showDialog(
                                                              context: context,
                                                              builder:
                                                                  (context) {
                                                                return AlertDialog(
                                                                  title:
                                                                      const Text(
                                                                    "Save this image ?",
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .white),
                                                                  ),
                                                                  actions: [
                                                                    Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .spaceBetween,
                                                                      children: [
                                                                        InkWell(
                                                                            onTap: () =>
                                                                                Navigator.pop(context),
                                                                            child: const Text(
                                                                              "No",
                                                                              style: TextStyle(color: Colors.red),
                                                                            )),
                                                                        InkWell(
                                                                            onTap:
                                                                                () async {
                                                                              Navigator.pop(context);
                                                                              await downloadImage(url: messagesList[index]['message'], path: messagesList[index]['path']);
                                                                            },
                                                                            child:
                                                                                const Text(
                                                                              "Save",
                                                                              style: TextStyle(color: Colors.blue),
                                                                            )),
                                                                      ],
                                                                    )
                                                                  ],
                                                                );
                                                              });
                                                        },
                                                        child: SizedBox(
                                                          width: 200,
                                                          height: 200,
                                                          child: Image.network(
                                                            messagesList[index]
                                                                    ['message']
                                                                .toString(),
                                                            fit: BoxFit.cover,
                                                          ),
                                                        )),
                                          ),
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 3),
                                            child: (messagesList[index]
                                                        ['timestamp'] !=
                                                    null)
                                                ? Text(
                                                    (CustomWidgets(context: context).dataTimeFormat(
                                                                dateFormat:
                                                                    "MM",
                                                                timestamp: messagesList[index]
                                                                        ['timestamp']
                                                                    as Timestamp) ==
                                                            DateFormat('MM').format(
                                                                DateTime.now()))
                                                        ? CustomWidgets(context: context)
                                                            .dataTimeFormat(
                                                                dateFormat:
                                                                    "hh:mm a",
                                                                timestamp: messagesList[index]
                                                                        ['timestamp']
                                                                    as Timestamp)
                                                        : CustomWidgets(context: context)
                                                            .dataTimeFormat(
                                                                dateFormat:
                                                                    "dd-MM-yyyy hh:mm a",
                                                                timestamp: messagesList[index]
                                                                        ['timestamp']
                                                                    as Timestamp),
                                                    textAlign: TextAlign.right,
                                                    style: TextStyle(
                                                      fontSize: 8,
                                                      fontWeight:
                                                          FontWeight.w100,
                                                      color: (messagesList[
                                                                      index]
                                                                  ["sender"] !=
                                                              userProvider
                                                                  .username)
                                                          ? provider.thirdText
                                                          : provider.thirdBg,
                                                    ),
                                                  )
                                                : const SizedBox(
                                                    width: 5,
                                                    height: 5,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 1,
                                                      color: Colors.green,
                                                    )),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              if (messagesList[index]
                                                      ["showReact"] !=
                                                  "") {
                                                Map<String, dynamic> reactMap =
                                                    messagesList[index]
                                                        ["react"];
                                                List<dynamic> reactorsName =
                                                    reactMap.keys.toList();
                                                List<dynamic> reactorsValue =
                                                    reactMap.values.toList();
                                                if (reactorsName.isNotEmpty &&
                                                    reactorsValue.isNotEmpty &&
                                                    reactorsName.length ==
                                                        reactorsValue.length) {
                                                  showModalBottomSheet(
                                                      context: context,
                                                      builder: (context) {
                                                        return BottomSheet(
                                                            backgroundColor:
                                                                provider
                                                                    .secondaryBg,
                                                            onClosing: () =>
                                                                debugPrint(
                                                                    "Closing"),
                                                            builder: (context) {
                                                              return Container(
                                                                height: 350,
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(
                                                                        10.0),
                                                                child: Column(
                                                                  children: [
                                                                    const Text(
                                                                      "All Reactors",
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .white,
                                                                          fontSize:
                                                                              18),
                                                                    ),
                                                                    Container(
                                                                      height: 2,
                                                                      margin: const EdgeInsets
                                                                          .only(
                                                                          top:
                                                                              8),
                                                                      decoration:
                                                                          BoxDecoration(
                                                                              color: provider.primaryBg),
                                                                    ),
                                                                    Expanded(
                                                                      child: ListView
                                                                          .builder(
                                                                        itemCount:
                                                                            reactorsValue.length,
                                                                        itemBuilder:
                                                                            (context,
                                                                                index) {
                                                                          return ListTile(
                                                                            title:
                                                                                Text(
                                                                              reactorsName[index],
                                                                              style: const TextStyle(color: Colors.white, fontSize: 13),
                                                                            ),
                                                                            trailing:
                                                                                Text(
                                                                              reactorsValue[index],
                                                                              style: const TextStyle(color: Colors.white, fontSize: 13),
                                                                            ),
                                                                          );
                                                                        },
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            });
                                                      });
                                                }
                                              }
                                            },
                                            child: (messagesList[index]
                                                        ["showReact"] !=
                                                    "")
                                                ? Text(
                                                    textAlign: TextAlign.end,
                                                    messagesList[index]
                                                        ["showReact"],
                                                    style: const TextStyle(
                                                        fontSize: 10),
                                                  )
                                                : const SizedBox(),
                                          )
                                        ],
                                      ),
                                    ),
                                    (messagesList[index]["sender"] ==
                                            userProvider.username)
                                        ? CircleAvatar(
                                            radius: 15,
                                            backgroundColor: provider.thirdBg,
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              child: (messagesList[index]
                                                          ["profile"] !=
                                                      "")
                                                  ? Image.network(
                                                      messagesList[index]
                                                          ["profile"])
                                                  : Icon(
                                                      color:
                                                          provider.primaryText,
                                                      Icons.person,
                                                    ),
                                            ),
                                          )
                                        : const SizedBox(),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      );
              },
            ),
          ),
          Container(
            height: inputHeight,
            decoration:
                const BoxDecoration(color: Color.fromARGB(95, 22, 22, 22)),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                      padding: const EdgeInsets.only(
                          left: 10, right: 10, top: 8, bottom: 10),
                      child: TextField(
                        onTapOutside: (pointerDownEvent) {
                          setState(() {
                            imgVisible = true;
                          });
                        },
                        onChanged: (value) {
                          setState(() {
                            imgVisible = false;
                            if (value.isEmpty) {
                              imgVisible = true;
                            }
                            if (value.length > 15) {
                              inputHeight = 100;
                            } else {
                              inputHeight = 60;
                            }
                          });
                        },
                        onEditingComplete: () async {
                          if (messageController.text.trim() != "") {
                            String msg = messageController.text.trim();
                            messageController.text = "";
                            try {
                              String sentTo = "";
                              if (widget.data["first_user"] ==
                                  userProvider.username) {
                                sentTo = widget.data["second_user"];
                              } else {
                                widget.data["first_user"];
                              }

                              if (sentTo != "" && convType != "") {
                                await db.collection("messages").add({
                                  "type": convType,
                                  "sender": userProvider.username,
                                  "profile": userProvider.profile,
                                  "sentTo": sentTo,
                                  "message": msg,
                                  "txtType": "txt",
                                  "path": "",
                                  "chat_id": widget.data["chat_id"].toString(),
                                  "delete": "",
                                  "timestamp": FieldValue.serverTimestamp(),
                                  "isSeen": false,
                                  "react": {}
                                });
                                setState(() {
                                  imgVisible = true;
                                });
                              }
                            } catch (e) {
                              log(e.toString());
                            }
                          }
                        },
                        controller: messageController,
                        autofocus: true,
                        maxLines: null,
                        scrollController:
                            ScrollController(keepScrollOffset: true),
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                            hintText: "Type here ...",
                            hintStyle: TextStyle(color: provider.thirdText),
                            fillColor: provider.secondaryBg,
                            focusColor: provider.primaryBg,
                            contentPadding: const EdgeInsets.only(
                                left: 10, top: 5, right: 10, bottom: 5),
                            focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: provider.primaryText),
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(25))),
                            border: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: provider.primaryText, width: 1),
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(25)))),
                        style: TextStyle(
                            color: provider.primaryText,
                            fontWeight: FontWeight.w100),
                      )),
                ),
                (imgVisible)
                    ? InkWell(
                        onTap: () async {
                          debugPrint("Imge select click");
                          await sendImage();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Icon(
                            Icons.image_rounded,
                            color: provider.primaryText,
                            size: 38,
                          ),
                        ),
                      )
                    : const SizedBox(),
                InkWell(
                  onTap: () async {
                    try {
                      if (messageController.text.trim() != "") {
                        debugPrint("Sent btn clicked");
                        String sentTo = "";
                        if (widget.data["first_user"] ==
                            userProvider.username) {
                          sentTo = widget.data["second_user"];
                        } else {
                          sentTo = widget.data["first_user"];
                        }

                        if (sentTo != "") {
                          await db.collection("messages").add({
                            "type": widget.data["type"],
                            "sender": userProvider.username,
                            "sentTo": sentTo,
                            "profile": userProvider.profile,
                            "message": messageController.text.trim().toString(),
                            "txtType": "txt",
                            "path": "",
                            "chat_id": widget.data["chat_id"].toString(),
                            "delete": "",
                            "timestamp": FieldValue.serverTimestamp(),
                            "isSeen": false,
                            "react": {}
                          });
                          messageController.text = "";
                          setState(() {
                            imgVisible = true;
                          });
                        } else {
                          debugPrint("sending: $sentTo");
                        }
                      } else {
                        log(messageController.text.trim());
                      }
                    } catch (e) {
                      debugPrint("Failed to Send Messages: ${e.toString()}");
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Icon(
                      Icons.send_rounded,
                      color: provider.primaryText,
                      size: 38,
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> sendImage() async {
    try {
      String downloadUrl = "";
      var userProvider = Provider.of<UserProvider>(context, listen: false);
      var provider = Provider.of<ThemeProvider>(context, listen: false);

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'jpeg'],
      );

      if (result != null) {
        double size = result.files.first.size / 1024;
        if (size <= 5120) {
          ScaffoldMessenger.of(context).showMaterialBanner(MaterialBanner(
            backgroundColor: provider.thirdBg,
            content: const Row(
              children: [
                SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Text("Please wait, sending file...")
              ],
            ),
            actions: [const Text("")],
          ));

          Uint8List? image = result.files.first.bytes;
          String fileName = result.files.first.name;
          String childPath =
              'chat_images/${userProvider.username + DateTime.now().microsecondsSinceEpoch.toString()}${p.extension(fileName)}';
          debugPrint("childPath: $childPath  ");
          final storageRef = FirebaseStorage.instance.ref().child(childPath);

          // Upload the file to Firebase Storage
          if (image != null) {
            UploadTask uploadTask =
                storageRef.putData(Uint8List.fromList(image));
            uploadTask.whenComplete(() async {
              downloadUrl = await storageRef.getDownloadURL();
              debugPrint(
                  "Image shared successfully and Download URL: $downloadUrl");
              if (downloadUrl != "") {
                await updateImageUrlInDataBase(
                    uploadResultUrl: downloadUrl, path: childPath);
              } else {
                ScaffoldMessenger.of(context).showMaterialBanner(MaterialBanner(
                    backgroundColor: Colors.red[50],
                    content: const Text("Failed to upload image"),
                    actions: [
                      InkWell(
                          onTap: () => ScaffoldMessenger.of(context)
                              .clearMaterialBanners(),
                          child: const Icon(Icons.cancel_presentation_rounded,
                              color: Colors.red))
                    ]));
              }
            });
          } else if (image == null) {
            File imageFile = File(result.files.first.path!);
            UploadTask uploadTask = storageRef.putFile(imageFile);
            uploadTask.whenComplete(() async {
              downloadUrl = await storageRef.getDownloadURL();
              debugPrint(
                  "Image shared successfully and Download URL: $downloadUrl");
              if (downloadUrl != "") {
                await updateImageUrlInDataBase(
                    uploadResultUrl: downloadUrl, path: childPath);
              } else {
                ScaffoldMessenger.of(context).showMaterialBanner(MaterialBanner(
                    backgroundColor: Colors.red[50],
                    content: const Text("Failed to upload image"),
                    actions: [
                      InkWell(
                          onTap: () => ScaffoldMessenger.of(context)
                              .clearMaterialBanners(),
                          child: const Icon(Icons.cancel_presentation_rounded,
                              color: Colors.red))
                    ]));

                ScaffoldMessenger.of(context).clearMaterialBanners();
              }
            });
          } else {
            ScaffoldMessenger.of(context).showMaterialBanner(MaterialBanner(
                backgroundColor: Colors.red[50],
                content: const Text("Failed to upload image"),
                actions: [
                  InkWell(
                      onTap: () =>
                          ScaffoldMessenger.of(context).clearMaterialBanners(),
                      child: const Icon(Icons.cancel_presentation_rounded,
                          color: Colors.red))
                ]));

            ScaffoldMessenger.of(context).clearMaterialBanners();
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              backgroundColor: Color.fromARGB(255, 241, 78, 78),
              content: Text("File is too large. please select below 5MB")));
        }
      }
    } catch (e) {
      debugPrint("ImageShare Error: ${e.toString()}");
    }
  }

  Future<void> updateImageUrlInDataBase(
      {required String uploadResultUrl, required String path}) async {
    var userProvider = Provider.of<UserProvider>(context, listen: false);
    if (uploadResultUrl != "") {
      // upload downloadUrl to the firebaseFirestore database
      String sentTo = "";
      if (widget.data["first_user"] == userProvider.username) {
        sentTo = widget.data["second_user"];
      } else {
        sentTo = widget.data["first_user"];
      }
      debugPrint(
          "Condition: ${sentTo != "" && convType != ""}  sentTo: $sentTo convType: $convType");
      if (sentTo != "" && convType != "") {
        await db.collection("messages").add({
          "type": convType,
          "sender": userProvider.username,
          "profile": userProvider.profile,
          "sentTo": sentTo,
          "message": uploadResultUrl,
          "txtType": "img",
          "path": path,
          "chat_id": widget.data["chat_id"].toString(),
          "timestamp": FieldValue.serverTimestamp(),
          "isSeen": false,
          "delete": "",
          "react": {}
        });
        setState(() {
          imgVisible = true;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showMaterialBanner(MaterialBanner(
          backgroundColor: Colors.red[50],
          content: const Text("Failed to send image"),
          actions: [
            InkWell(
                onTap: () =>
                    ScaffoldMessenger.of(context).clearMaterialBanners(),
                child: const Icon(Icons.cancel_presentation_rounded,
                    color: Colors.red))
          ]));
    }
    ScaffoldMessenger.of(context).clearMaterialBanners();
  }

  Future<void> downloadImage(
      {required String url, required String path}) async {
    try {
      // comment this if condition before building apk. this only support on web browsers.
      // if (kIsWeb) {
      //   WebImageDownloader(context: context).download(url: url, path: path);
      // }

      if (!kIsWeb) {
        var response = await Dio()
            .get(url, options: Options(responseType: ResponseType.bytes));
        String picturesPath = path.split("/").last;
        debugPrint(picturesPath);
        final result = await SaverGallery.saveImage(
          Uint8List.fromList(response.data),
          quality: 60,
          name: picturesPath,
          androidRelativePath: "Pictures/AnonChat",
          androidExistNotSave: false,
        );
        debugPrint(result.toString());
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Color.fromARGB(255, 97, 238, 92),
            content: Text("Image saved !")));
      }
    } catch (e) {
      debugPrint("Failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Color.fromARGB(255, 243, 92, 92),
          content: Text("Failed to save !")));
    }
  }

  Widget reactionBar({required String messageID}) {
    Map<String, dynamic> reaction = {
      "love": "❤️",
      "haha": "😂",
      "angry": "😡",
      "sad": "😢",
      "wow": "😱",
      "dislike": "👎",
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 38,
          width: 38,
          child: InkWell(
            onTap: () {
              debugPrint("Emoji Clicked: ${reaction["love"]}");
              reactOnText(reactMsgID: messageID, react: reaction["love"]);
              Navigator.pop(context);
            },
            child: Text(
              reaction["love"],
              style: const TextStyle(
                fontSize: 27,
              ),
            ),
          ),
        ),
        SizedBox(
          height: 38,
          width: 38,
          child: InkWell(
            onTap: () {
              debugPrint("Emoji Clicked: ${reaction["haha"]}");
              reactOnText(reactMsgID: messageID, react: reaction["haha"]);
              Navigator.pop(context);
            },
            child: Text(
              reaction["haha"],
              style: const TextStyle(
                fontSize: 27,
              ),
            ),
          ),
        ),
        SizedBox(
          height: 38,
          width: 38,
          child: InkWell(
            onTap: () {
              debugPrint("Emoji Clicked: ${reaction["angry"]}");
              reactOnText(reactMsgID: messageID, react: reaction["angry"]);
              Navigator.pop(context);
            },
            child: Text(
              reaction["angry"],
              style: const TextStyle(
                fontSize: 27,
              ),
            ),
          ),
        ),
        SizedBox(
          height: 38,
          width: 38,
          child: InkWell(
            onTap: () {
              debugPrint("Emoji Clicked: ${reaction["sad"]}");
              reactOnText(reactMsgID: messageID, react: reaction["sad"]);
              Navigator.pop(context);
            },
            child: Text(
              reaction["sad"],
              style: const TextStyle(
                fontSize: 27,
              ),
            ),
          ),
        ),
        SizedBox(
          height: 38,
          width: 38,
          child: InkWell(
            onTap: () {
              debugPrint("Emoji Clicked: ${reaction["wow"]}");
              reactOnText(reactMsgID: messageID, react: reaction["wow"]);
              Navigator.pop(context);
            },
            child: Text(
              reaction["wow"],
              style: const TextStyle(
                fontSize: 27,
              ),
            ),
          ),
        ),
        SizedBox(
          height: 38,
          width: 38,
          child: InkWell(
            onTap: () {
              debugPrint("Emoji Clicked: ${reaction["dislike"]}");
              reactOnText(reactMsgID: messageID, react: reaction["dislike"]);
              Navigator.pop(context);
            },
            child: Text(
              reaction["dislike"],
              style: const TextStyle(
                fontSize: 27,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void reactOnText({required String reactMsgID, required String react}) async {
    try {
      var provider = Provider.of<UserProvider>(context, listen: false);

      await db.collection('messages').doc(reactMsgID).get().then((reactResp) {
        if (reactResp.data() != null) {
          Map<String, dynamic> allReact = reactResp.data()!["react"];
          allReact[provider.username] = react;
          db.collection("messages").doc(reactMsgID).update({"react": allReact});
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("React failed. Try again !")));
      log(e.toString());
    }
  }
}
