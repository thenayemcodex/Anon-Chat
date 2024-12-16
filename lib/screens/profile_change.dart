import 'dart:io';
import 'dart:typed_data';

import 'package:anon_chat/custom_widgets/custom_drawer.dart';
import 'package:anon_chat/firebase/firebase_services.dart';
import 'package:anon_chat/providers/theme_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';

class ProfileChange extends StatefulWidget {
  const ProfileChange({super.key});

  @override
  State<ProfileChange> createState() => _ProfileChangeState();
}

class _ProfileChangeState extends State<ProfileChange> {
  void changeUserProfile() async {
    var provider = Provider.of<ThemeProvider>(context, listen: false);
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'jpeg'],
    );

    if (result != null) {
      print("Result: $result");

      String fileName = result.files.first.name;
      print("file selected $fileName");
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
                      onTap: () async {
                        Navigator.pop(context);
                        String uploadResult = "";
                        if (kIsWeb) {
                          Uint8List selectedFile = result.files.first.bytes!;
                          uploadResult =
                              await FirebaseServices(context: context)
                                  .uploadUserProfile(
                                      username: Provider.of<UserProvider>(
                                              context,
                                              listen: false)
                                          .username,
                                      image: selectedFile,
                                      fileName: fileName);
                        } else {
                          File selectedFile = File(result.files.first.path!);
                          uploadResult =
                              await FirebaseServices(context: context)
                                  .uploadUserProfile(
                                      username: Provider.of<UserProvider>(
                                              context,
                                              listen: false)
                                          .username,
                                      imageFile: selectedFile,
                                      fileName: fileName);
                        }

                        if (uploadResult != "") {
                          updateProfile(profile: uploadResult);
                        } else {
                          debugPrint(
                              "Couldn't update profile Result: $uploadResult");
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                            content: Text(
                              "Profile upload failed",
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.red,
                          ));
                        }
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

  @override
  void initState() {
    changeUserProfile();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var themeProvider = Provider.of<ThemeProvider>(context);
    // var userProvider = Provider.of<UserProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Change profile"),
      ),
      drawer: CustomDrawer(context: context).drawer(),
      body: Container(
        width: double.maxFinite,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "To change the selected image click on the image.\nNote: please select squer size image for better view. Other images also supported.",
              style: TextStyle(fontSize: 10, color: themeProvider.thirdText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: 10,
            ),
            ElevatedButton(
                onPressed: changeUserProfile,
                child: const Text(
                  "Choose Profile",
                ))
          ],
        ),
      ),
    );
  }

  void updateProfile({required String profile}) {
    var provider = Provider.of<UserProvider>(context, listen: false);
    try {
      provider.updateUserCredentials(profileUrl: profile);
      debugPrint("Could update profile Result: $profile");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          "Profile upload successfull",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
