import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Widget searchBox() {
  return TextFormField(
    cursorColor: Colors.black,
    obscureText:  false,
    inputFormatters: [],
    decoration: InputDecoration(
      hintText: "Поиск",
      hintStyle: const TextStyle(color: Colors.grey),
      fillColor: CupertinoColors.extraLightBackgroundGray,
      filled: true,
      border: OutlineInputBorder(
        borderSide: const BorderSide(width: 0, style: BorderStyle.none),
        borderRadius: BorderRadius.circular(10.0),
      ),
    ),
  );
}

Widget input(String hint) {
  return TextFormField(
    cursorColor: Colors.black,
    obscureText:  false,
    inputFormatters: [],
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      fillColor: CupertinoColors.extraLightBackgroundGray,
      filled: true,
      border: OutlineInputBorder(
        borderSide: const BorderSide(width: 0, style: BorderStyle.none),
        borderRadius: BorderRadius.circular(10.0),
      ),
    ),
  );
}