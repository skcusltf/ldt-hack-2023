import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'ColorResources.dart';

import 'ColorResources.dart';
import 'TextStyles.dart';

MaterialColor black = const MaterialColor(
  0xFF000000,
  <int, Color>{
    50: Colors.black,
    100: Colors.black,
    200: Colors.black,
    300: Colors.black,
    400: Colors.black,
    500: Colors.black,
    600: Colors.black,
    700: Colors.black,
    800: Colors.black,
    900: Colors.black,
  },
);

final light = ThemeData(
  splashColor: Colors.transparent,
  highlightColor: Colors.transparent,
  primaryColorDark: ColorResources.accentRed,
  primarySwatch: black,
  appBarTheme: const AppBarTheme(
    backgroundColor: ColorResources.lightGrey,
    foregroundColor: ColorResources.black,
    iconTheme: IconThemeData(color: Colors.black),
  ),
  primaryColor: ColorResources.lightGrey,
  backgroundColor: ColorResources.lightGrey,
);
