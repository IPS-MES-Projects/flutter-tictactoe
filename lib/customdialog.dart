import 'package:flutter/material.dart';

class CustomDialog extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback? callback;
  final String actionText;

  const CustomDialog(
      {Key? key,
      this.title = "",
      this.content = "",
      this.callback,
      this.actionText = "New Game"})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: <Widget>[
        TextButton(
          onPressed: callback,
          style: TextButton.styleFrom(primary: Colors.white),
          child: Text(
            actionText,
            style: const TextStyle(color: Colors.blue),
          ),
        )
      ],
    );
  }
}
