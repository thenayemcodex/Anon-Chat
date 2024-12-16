import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;


class FirebaseServices {
  BuildContext context;
  FirebaseServices({required this.context});

  var auth = FirebaseAuth.instance;
  var db = FirebaseFirestore.instance;
  FirebaseStorage storage = FirebaseStorage.instance;

  // to upload the user profile image
  Future<String> uploadUserProfile(
      {required String username,
      Uint8List? image,
      File? imageFile,
      required String fileName}) async {
    String returnValue = "";
    try {
      // Create a reference to the storage location
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_images/$username${p.extension(fileName)}');

      try {
        // Check if the file exists
        await storageRef.getDownloadURL();
        // File exists, delete it
        await storageRef.delete();
      } catch (e) {
        debugPrint("If Exist: ${e.toString()}");
      }

      // Upload the file to Firebase Storage
      if (image != null) {
        UploadTask uploadTask = storageRef.putData(Uint8List.fromList(image));
        uploadTask.whenComplete(() {
          debugPrint("User Profile Upload complete  ");
        });

        // Handle the upload progress if needed
        uploadTask.snapshotEvents.listen((event) {
          // You can track upload progress here
          double percentage = 100 * (event.bytesTransferred / event.totalBytes);
          debugPrint("The percentage $percentage");
        });

        // Get the download URL of the uploaded image
        returnValue =
            await uploadTask.then((snapshot) => snapshot.ref.getDownloadURL());
      } else if (imageFile != null) {
        UploadTask uploadTask = storageRef.putFile(imageFile);
        uploadTask.whenComplete(() {
          debugPrint("User Profile Upload complete  ");
        });

        // Handle the upload progress if needed
        uploadTask.snapshotEvents.listen((event) {
          // You can track upload progress here
          double percentage = 100 * (event.bytesTransferred / event.totalBytes);
          debugPrint("The percentage $percentage");
        });

        // Get the download URL of the uploaded image
        returnValue =
            await uploadTask.then((snapshot) => snapshot.ref.getDownloadURL());
      }

      await db
          .collection("users")
          .doc(auth.currentUser!.uid)
          .update({"profile": returnValue}).then((dataSnapshot) {
        debugPrint("Profile updated");
        db
            .collection("messages")
            .where("sender", isEqualTo: username)
            .get()
            .then((messageShot) {
          for (var firstData in messageShot.docs) {
            db
                .collection("messages")
                .doc(firstData.id)
                .update({"profile": returnValue});
          }
        });
      });
    } catch (e) {
      debugPrint("UploadUserProfile: ${e.toString()}");
      // Handle the error appropriately, e.g., show an error message to the user
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          "Profile upload failed",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
      ));
    }
    return returnValue;
  }

  // to upload the group profile image
  Future<void> uploadGroupProfile(
      {required String groupName,
      Uint8List? image,
      File? imageFile,
      required String fileName}) async {
    try {
      String downloadUrl = "";
      // Create a reference to the storage location
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('group_images/$groupName${p.extension(fileName)}');

      try {
        // Check if the file exists
        await storageRef.getDownloadURL();
        // File exists, delete it
        await storageRef.delete();
      } catch (e) {
        debugPrint("If Exist: ${e.toString()}");
      }

      // Upload the file to Firebase Storage
      if (image != null) {
        UploadTask uploadTask = storageRef.putData(Uint8List.fromList(image));
        uploadTask.whenComplete(() {
          debugPrint("Group Profile Upload complete  ");
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
              "Profile upload has been completed ",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ));
        });

        // Handle the upload progress if needed
        uploadTask.snapshotEvents.listen((event) {
          // You can track upload progress here
          double percentage = 100 * (event.bytesTransferred / event.totalBytes);
          debugPrint("The percentage $percentage");
        });

        // Get the download URL of the uploaded image
        downloadUrl =
            await uploadTask.then((snapshot) => snapshot.ref.getDownloadURL());
      } else if (imageFile != null) {
        UploadTask uploadTask = storageRef.putFile(imageFile);
        uploadTask.whenComplete(() {
          debugPrint("Group Profile Upload complete  ");
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
              "Profile upload has been completed ",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ));
        });

        // Handle the upload progress if needed
        uploadTask.snapshotEvents.listen((event) {
          // You can track upload progress here
          double percentage = 100 * (event.bytesTransferred / event.totalBytes);
          debugPrint("The percentage $percentage");
        });

        // Get the download URL of the uploaded image
        downloadUrl =
            await uploadTask.then((snapshot) => snapshot.ref.getDownloadURL());
      }
      if (downloadUrl != "") {
        await db
            .collection("groups")
            .where("name", isEqualTo: groupName)
            .get()
            .then((dataSnapshot) {
          var single = dataSnapshot.docs.first;
          if (single.data()["name"] == groupName) {
            db
                .collection("groups")
                .doc(single.id)
                .update({"profile": downloadUrl});
            return;
          }
        });
      }
    } catch (e) {
      debugPrint("UploadGroupProfile: ${e.toString()}");
      // Handle the error appropriately, e.g., show an error message to the user
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          "Profile upload failed",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
      ));
    }
  }

  // to leave from the global chat room
  void leaveGroup({required String username, required String groupName}) async {
    try {
      await db
          .collection("messages")
          .where("sender", isEqualTo: username)
          .where("sentTo", isEqualTo: groupName)
          .get()
          .then((snapshot) {
        for (var singleDoc in snapshot.docs) {
          db.collection("messages").doc(singleDoc.id).delete();
          if (singleDoc.data()["txtType"] == "img") {
            FirebaseStorage.instance
                .ref()
                .child(singleDoc.data()["path"])
                .delete()
                .then((value) => debugPrint("File deleted successfully !"));
          }
        }
      });
    } catch (e) {
      debugPrint("Error: ${e.toString()}");
    }
  }

  // to delete any induvisual chat
  void deleteChat({required String chatId}) async {
    try {
      await db
          .collection("messages")
          .where("chat_id", isEqualTo: chatId)
          .get()
          .then((snapshot) {
        for (var singleDoc in snapshot.docs) {
          db.collection("messages").doc(singleDoc.id).delete();
          for (var singleDoc in snapshot.docs) {
            db.collection("messages").doc(singleDoc.id).delete();
            if (singleDoc.data()["txtType"] == "img") {
              FirebaseStorage.instance
                  .ref()
                  .child(singleDoc.data()["path"])
                  .delete()
                  .then((value) => debugPrint("File deleted successfully !"));
            }
          }
        }
      });
    } catch (e) {
      debugPrint("Error: ${e.toString()}");
    }
  }

  // to delete any image or video from the conversations
  Future<void> deleteFile({required String storagePath}) async {
    try {
      await FirebaseStorage.instance
          .ref()
          .child(storagePath)
          .delete()
          .then((value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: Colors.green[200],
              content: const Text(
                "File deleted successfully !",
              ))));
    } catch (e) {
      debugPrint('Error deleting file: $e');
    }
  }

  
}
