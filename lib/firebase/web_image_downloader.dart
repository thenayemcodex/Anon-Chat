// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'dart:html';

class WebImageDownloader {
  BuildContext context;
  WebImageDownloader({required this.context});

  // to download image / video from the firebase storage. only support on web browsers
  // comment this function before building apk
  // void download({required String url, required String path}) async {
  //   try {
  //     if (kIsWeb) {
  //       // For web, you can trigger a browser download directly
  //       final anchor = AnchorElement(href: url)
  //         ..download = path.split("/").last;
  //       document.body!.append(anchor);
  //       anchor.click();
  //       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  //           backgroundColor: Color.fromARGB(255, 97, 238, 92),
  //           content: Text("Image saved !")));
  //     } else {
  //       debugPrint("Unknown platform");
  //       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  //           backgroundColor: Color.fromARGB(255, 243, 92, 92),
  //           content: Text("Unknown platform")));
  //     }
  //   } catch (e) {
  //     debugPrint(e.toString());
  //   }
  // }
}
