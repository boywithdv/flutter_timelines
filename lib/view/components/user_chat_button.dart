import 'package:flutter/material.dart';

class UserChatButton extends StatelessWidget {
  void Function()? onTap;
  UserChatButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onPrimary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: TextButton.icon(
          icon: Icon(
            Icons.chat_bubble_outline,
            color: Theme.of(context).colorScheme.primary,
          ),
          label: Text(
            "チャット",
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          onPressed: onTap,
        ),
      ),
    );
  }
}
