import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomWidgets {
  BuildContext context;
  CustomWidgets({required this.context});
  Future<dynamic> singleTextDialog({required String text}) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Container(
              height: 80,
              width: double.maxFinite,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(text),
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Ok",
                      style: TextStyle(color: Colors.blue),
                    ),
                  )
                ],
              ),
            ),
          );
        });
  }

  double width({required int width}) {
    return MediaQuery.of(context).size.width * width.toDouble();
  }

  double heigth({required int heigth}) {
    return MediaQuery.of(context).size.height * heigth.toDouble();
  }

  String dataTimeFormat(
      {required String dateFormat, required Timestamp timestamp}) {
    var format = new DateFormat(dateFormat); // <- use skeleton here
    return format.format(timestamp.toDate());
  }
}
