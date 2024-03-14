import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CustomTextBox extends StatelessWidget {
  final String text;
  final String sectionName;
  final void Function()? onPressed;
  final String? email;
  CustomTextBox(
      {super.key,
      required this.text,
      required this.sectionName,
      required this.onPressed,
      this.email});
  final currentUser = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.only(left: 15, bottom: 15),
      margin: const EdgeInsets.only(left: 20, right: 20, top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              //section name
              Text(
                sectionName,
                style: TextStyle(
                  color: Colors.grey[500],
                ),
              ),
              //edit button
              currentUser.email == email
                  ? IconButton(
                      onPressed: onPressed,
                      icon: Icon(
                        Icons.settings,
                        color: Colors.grey[400],
                      ),
                    )
                  : SizedBox()
            ],
          ),
          // text
          Padding(
            padding: EdgeInsets.only(right: 15),
            child: Text(text),
          ),
        ],
      ),
    );
  }
}
