import 'package:flutter/material.dart';

class UserTile extends StatelessWidget {
  final String text;
  final String timestamp;  // Add a field to accept formatted timestamp
  final void Function()? onTap;

  const UserTile({
    super.key,
    required this.text,
    required this.onTap,
    required this.timestamp,  // Accept the timestamp as an argument
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 25),
        padding: EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,  // Added to position text and timestamp
          children: [
            Row(
              children: [
                Icon(Icons.person),
                const SizedBox(width: 20),
                Text(text),
              ],
            ),
            Text(  // Displaying the timestamp on the right
              timestamp,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
