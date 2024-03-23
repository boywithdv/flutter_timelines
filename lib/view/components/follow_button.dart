import 'package:flutter/material.dart';

class FollowButton extends StatelessWidget {
  final bool isFollow;
  void Function()? followButtonOnTap;
  void Function()? onTap;
  FollowButton(
      {super.key,
      required this.isFollow,
      required this.onTap,
      this.followButtonOnTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: isFollow
          ? OutlinedButton.icon(
              icon: Icon(
                Icons.person_outline_outlined,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              label: Text(
                "Follow Now",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              onPressed: followButtonOnTap,
            )
          : Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextButton.icon(
                icon: Icon(
                  Icons.person_add_alt,
                  color: Theme.of(context).colorScheme.primary,
                ),
                label: Text(
                  "Follow",
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
                onPressed: followButtonOnTap,
              ),
            ),
    );
  }
}
