import 'package:flutter/material.dart';

class GameButton {
  int id;
  String text;
  Color color;
  bool enabled;

  GameButton(
      {required this.id,
      this.text = "",
      this.color = Colors.grey,
      this.enabled = true});

  void play(text, color, [enabled = false]) {
    this.text = text;
    this.color = color;
    this.enabled = enabled;
  }
}
