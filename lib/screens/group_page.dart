import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:anon_chat/custom_widgets/custom_drawer.dart';
import 'package:anon_chat/custom_widgets/custom_widgets.dart';
import 'package:anon_chat/firebase/firebase_services.dart';
import 'package:anon_chat/providers/theme_provider.dart';
import 'package:anon_chat/providers/user_provider.dart';
import 'package:anon_chat/screens/conversation_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GroupPage extends StatefulWidget {
  const GroupPage({super.key});

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  var db = FirebaseFirestore.instance;
  var auth = FirebaseAuth.instance;
  TextEditingController nameController = TextEditingController();
  TextEditingController groupNameController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  String groupNameValidate = "";

  bool isSearching = false;
  List<Map<String, dynamic>> groups = [];
  bool isRequested = false;

  bool isCreating = false;

  String chatID = "";

// changing group profile
  String groupProfile = "";
  bool isGroupProfileSelected = false;

  // storing imagebytes from file picker
  Uint8List? groupProfileSelectedFile;

  void createNewGroup({required Map<String, dynamic> data}) {
    bool isExist = false;
    try {
      isCreating = true;
      db.collection("groups").get().then((snapShot) {
        for (var group in snapShot.docs) {
          if (group.data()["name"] == data["name"]) {
            debugPrint("The group name '${data["name"]}' already exists");
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  content: Container(
                    height: 80,
                    width: double.maxFinite,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("The group name '${data["name"]}' already exists"),
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "Try again",
                            style: TextStyle(color: Colors.blue),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            );

            isCreating = false;
            isExist = true;
            setState(() {});
            return;
          }
        }
        if (!isExist) {
          db.collection("groups").add(data);
          Navigator.pop(context);
          retrieveData();
          isCreating = false;
          setState(() {});
        }
      });
    } on FirebaseAuthException catch (e) {
      isCreating = false;
      setState(() {});
      log(e.toString());
    } on FirebaseException catch (e) {
      isCreating = false;
      setState(() {});
      log(e.toString());
    } catch (e) {
      log(e.toString());
      isCreating = false;
      setState(() {});
    }
  }

  void retrieveData() {
    try {
      groups.clear();
      db
          .collection("groups")
          .orderBy("timestamp", descending: true)
          .get()
          .then((snapShot) {
        for (var group in snapShot.docs) {
          groups.add(group.data());

          isSearching = false;
          setState(() {});
        }
      });
    } catch (e) {
      log(e.toString());
    }
  }

  void searchGroup({required String groupName}) {
    try {
      bool isExist = false;
      isSearching = true;
      groups.clear();
      db
          .collection("groups")
          .orderBy("timestamp", descending: true)
          .get()
          .then((snapShot) {
        for (var group in snapShot.docs) {
          if (group.data()["name"].toString().toLowerCase() ==
              groupName.toLowerCase()) {
            debugPrint("The group name '$groupName' exists");
            groups.add(group.data());

            isSearching = false;
            isExist = true;
            setState(() {});
            return;
          }
        }
        if (!isExist) {
          isSearching = false;
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("The group name '$groupName' doesn't exists"),
            ),
          );
        }
      });
    } catch (e) {
      log(e.toString());
      isSearching = false;
      setState(() {});
    }
  }

  void createChatId({required Map<String, dynamic> data}) async {
    bool isExist = false;
    try {
      var db = FirebaseFirestore.instance;
      await db.collection("chats").get().then((dataSnapShots) {
        for (var userData in dataSnapShots.docs) {
          if (userData.data()["first_user"].toString().toLowerCase() ==
                  data["second_user"].toString().toLowerCase() ||
              userData.data()["second_user"].toString().toLowerCase() ==
                  data["second_user"].toString().toLowerCase()) {
            isExist = true;
            chatID = userData.id;
            setState(() {});
          }
        }
        if (!isExist) {
          db.collection("chats").add(data);
          db.collection("chats").get().then((dataSnapShots) {
            for (var userData in dataSnapShots.docs) {
              if (userData.data()["first_user"].toString().toLowerCase() ==
                      data["second_user"].toString().toLowerCase() ||
                  userData.data()["second_user"].toString().toLowerCase() ==
                      data["second_user"].toString().toLowerCase()) {
                isExist = true;
                chatID = userData.id;
                setState(() {});
              }
            }
          });
        }
      });
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> uploadFile(File file) async {
    try {
      final storage = FirebaseStorage.instance;
      final storageRef =
          storage.ref('group_images/${file.path.split('/').last}');

      UploadTask uploadTask = storageRef.putFile(file);

      uploadTask.snapshotEvents.listen((event) {
        final percent = (event.bytesTransferred / event.totalBytes) * 100;
        log('Upload is $percent% complete.');
      });

      await uploadTask;
      log('Upload complete!');

      final downloadUrl = await storageRef.getDownloadURL();
      log('Download URL: $downloadUrl');
    } catch (e) {
      log('Error uploading file: $e');
    }
  }

  @override
  void initState() {
    retrieveData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var provider = Provider.of<ThemeProvider>(context);
    var userProvider = Provider.of<UserProvider>(context);
    return Scaffold(
      drawer: CustomDrawer(context: context).drawer(),
      appBar: AppBar(
        title: const Text("Anon-Groups"),
        actions: [
          InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return BottomSheet(
                    shadowColor: Colors.white,
                    backgroundColor: provider.secondaryBg,
                    onClosing: () {},
                    builder: (context) {
                      return createGroup(bgColor: provider.secondaryBg);
                    },
                  );
                },
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                Icons.add_outlined,
                color: provider.primaryText,
              ),
            ),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          retrieveData();
          return;
        },
        child: Container(
          margin: const EdgeInsets.only(top: 8),
          height: double.infinity,
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
                            controller: nameController,
                            style: TextStyle(
                                color: provider.primaryText, fontSize: 14),
                            decoration: InputDecoration(
                                hintStyle: TextStyle(color: provider.thirdText),
                                border: InputBorder.none,
                                hintText: "Group Name"),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: isSearching
                            ? const CircularProgressIndicator()
                            : InkWell(
                                onTap: () {
                                  searchGroup(
                                      groupName: nameController.text.trim());
                                },
                                child: const Icon(
                                  Icons.search_rounded,
                                  color: Colors.white,
                                )),
                      )
                    ],
                  ),
                ),
              ),
              (groups.isNotEmpty)
                  ? Expanded(
                      child: ListView.builder(
                      itemCount: groups.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          minVerticalPadding: 5,
                          title: Text(
                            groups[index]["name"],
                            style: TextStyle(
                                color: provider.primaryText,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1),
                          ),
                          leading: CircleAvatar(
                            backgroundColor: provider.secondaryBg,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: (groups[index]["profile"] != "")
                                  ? Image.network(
                                      groups[index]["profile"],
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                    )
                                  : Icon(
                                      Icons.group,
                                      color: provider.primaryText,
                                    ),
                            ),
                          ),
                          trailing: InkWell(
                            onTap: () {
                              createChatId(data: {
                                "first_user": userProvider.username,
                                "second_user": groups[index]["name"],
                                "timestamp": FieldValue.serverTimestamp(),
                                "type": "group"
                              });
                              showDialog(
                                  context: context,
                                  builder: (context) {
                                    groupProfile = groups[index]['profile'];
                                    return AlertDialog(
                                      content: Container(
                                        height: 275,
                                        child: Column(
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                changeGroupProfile(
                                                    groupName: groups[index]
                                                        ["name"]);
                                              }, // callback changeGroupProfile function
                                              child: CircleAvatar(
                                                backgroundColor:
                                                    provider.secondaryBg,
                                                radius: 50,
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(50),
                                                  child: popUpProfileWidget(
                                                      onlinePath: groupProfile,
                                                      isSelected:
                                                          isGroupProfileSelected),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            Text(
                                              groups[index]['name'],
                                              style: TextStyle(
                                                color: provider.primaryText,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            Text(
                                              "Administrator: @${groups[index]['admin'].toString().toUpperCase()}",
                                              style: TextStyle(
                                                color: provider.thirdText,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            (groups[index]['timestamp'] != null)
                                                ? Text(
                                                    "Created at ${CustomWidgets(context: context).dataTimeFormat(dateFormat: "dd-MM-yyyy hh:mm a", timestamp: groups[index]['timestamp'] as Timestamp)}",
                                                    style: TextStyle(
                                                      color: provider.thirdText,
                                                      fontSize: 12,
                                                    ),
                                                  )
                                                : Text(
                                                    "Created at xx-xx-xxxx xx:xx ",
                                                    style: TextStyle(
                                                      color: provider.thirdText,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            OutlinedButton(
                                              onPressed: () {
                                                if (chatID != "") {
                                                  Navigator.push(
                                                    context,
                                                    (MaterialPageRoute(
                                                      builder: (context) =>
                                                          ConversationPage(
                                                        data: {
                                                          "first_user":
                                                              userProvider
                                                                  .username,
                                                          "second_user":
                                                              groups[index]
                                                                  ["name"],
                                                          "timestamp":
                                                              groups[index]
                                                                  ["timestamp"],
                                                          "chat_id": chatID,
                                                          "type": "group"
                                                        },
                                                      ),
                                                    )),
                                                  );
                                                } else {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      backgroundColor:
                                                          Colors.red,
                                                      content: Text(
                                                          "Something went wrong with group info..."),
                                                    ),
                                                  );
                                                }
                                              },
                                              style: ButtonStyle(
                                                side: WidgetStateProperty.all(
                                                  BorderSide(
                                                      color:
                                                          provider.primaryText),
                                                ),
                                              ),
                                              child: Text(
                                                "Chat",
                                                style: TextStyle(
                                                    color:
                                                        provider.primaryText),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  });
                            },
                            child: Icon(
                              Icons.arrow_forward_ios,
                              color: provider.primaryText,
                            ),
                          ),
                        );
                      },
                    ))
                  : const Expanded(
                      child: Center(
                        child: Text(
                          "There is no groups to be shown.",
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
              Text(
                "Swipe down to refresh",
                style: TextStyle(
                  color: provider.thirdText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget createGroup({required Color bgColor}) {
    var theme = Provider.of<ThemeProvider>(context, listen: false);
    var user_provider = Provider.of<UserProvider>(context, listen: false);
    return Container(
      width: double.maxFinite,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 20, bottom: 20),
            child: Text(
              "Create a new global chat room !",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              style: TextStyle(color: theme.primaryText),
              controller: groupNameController,
              maxLines: 1,
              decoration: InputDecoration(
                labelText: "Enter Group Name",
                labelStyle: TextStyle(color: theme.secondaryText),
                fillColor: theme.primaryBg,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide(
                    color: theme.primaryText,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: const BorderSide(
                    color: Colors.red,
                    width: 2.0,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(30.0),
            child: ElevatedButton(
                onPressed: () {
                  if (groupNameController.text.trim().length >= 4) {
                    createNewGroup(data: {
                      "profile": "",
                      "admin": user_provider.username,
                      "name": groupNameController.text.trim(),
                      "timestamp": FieldValue.serverTimestamp()
                    });

                    groupNameController.text = "";
                  }
                },
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.create_rounded,
                        color: theme.primaryBg,
                      ),
                      Text(
                        "Create",
                        style: TextStyle(
                          color: theme.primaryBg,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    ],
                  ),
                )),
          )
        ],
      ),
    );
  }

  void changeGroupProfile({required String groupName}) async {
    var provider = Provider.of<ThemeProvider>(context, listen: false);
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'jpeg'],
    );

    if (result != null) {
      print("opening image print");
      debugPrint("opening image");

      String fileName = result.files.first.name;

      setState(() {});
      Navigator.pop(context);
      showDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text(
                "Change Profile",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Cancel",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        if (kIsWeb) {
                          FirebaseServices(context: context).uploadGroupProfile(
                              groupName: groupName,
                              image: result.files.first.bytes!,
                              fileName: fileName);
                        } else {
                          FirebaseServices(context: context).uploadGroupProfile(
                              groupName: groupName,
                              imageFile: File(result.files.first.path!),
                              fileName: fileName);
                        }

                        retrieveData();
                      },
                      child: const Text(
                        "Confirm",
                        style: TextStyle(
                            color: Colors.blue, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                )
              ],
              content: Container(
                height: 140,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: provider.secondaryBg,
                      radius: 70,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(70),
                        child: (kIsWeb)
                            ? Image.memory(
                                fit: BoxFit.cover,
                                result.files.first.bytes!,
                                width: 140,
                                height: 140,
                              )
                            : Image.file(
                                File(result.files.first.path!),
                                fit: BoxFit.cover,
                                width: 140,
                                height: 140,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          });
    } else {
      // User canceled the picker
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You didn't pick any file !")));
    }
  }

  Widget popUpProfileWidget(
      {required String onlinePath, required bool isSelected}) {
    var provider = Provider.of<ThemeProvider>(context, listen: false);
    if (onlinePath != "" && !isSelected) {
      return Image.network(
        fit: BoxFit.cover,
        onlinePath,
        width: 100,
        height: 100,
      );
    } else if (onlinePath == "" && !isSelected) {
      return Icon(
        Icons.group,
        size: 80,
        color: provider.primaryText,
      );
    } else if (isSelected && groupProfileSelectedFile != null) {
      return Image.memory(
        fit: BoxFit.cover,
        groupProfileSelectedFile!,
        width: 100,
        height: 100,
      );
    } else {
      return Icon(
        Icons.group,
        size: 80,
        color: provider.primaryText,
      );
    }
  }
}
