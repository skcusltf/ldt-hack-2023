import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lodt_hack/providers/LocalStorageProvider.dart';
import 'package:lodt_hack/screens/account/account.dart';
import 'package:lodt_hack/screens/auth/auth.dart';
import 'package:lodt_hack/screens/auth/login.dart';
import 'package:lodt_hack/screens/info.dart';
import 'package:lodt_hack/styles/ColorResources.dart';
import 'package:lodt_hack/utils/widgets.dart';

import 'models/User.dart';
import 'screens/chat.dart';
import 'screens/dashboard.dart';
import 'screens/zoom.dart';
import 'styles/themes.dart';

import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  Intl.defaultLocale = 'ru_RU';
  initializeDateFormatting().then((_) => runApp(MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Открытый контроль',
      theme: light,
      home: MyHomePage(title: 'Открытый контроль'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  User? user;
  String? token;

  void fetchData() {
    storageProvider.getUser().then(
          (value) => setState(
            () {
              if (value == null) {
                Navigator.pushAndRemoveUntil(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => Auth(),
                  ),
                  (r) => false,
                );
              } else {
                user = value;
              }
              print(user);
            },
          ),
        );
    storageProvider.getToken().then(
          (value) => setState(
            () {
              if (value == null) {
                Navigator.pushAndRemoveUntil(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => Auth(),
                  ),
                  (r) => false,
                );
              } else {
                token = value;
              }
            },
          ),
        );
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<BottomNavigationBarItem> bottomNavBar() {
    var result = [
      const BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.square_list_fill),
        label: "Главная",
        backgroundColor: CupertinoColors.systemGrey6,
      )
    ];

    if (user != null && user!.isBusiness()) {
      result += [
        const BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.chat_bubble_text_fill),
          label: "Чат",
          backgroundColor: CupertinoColors.systemGrey6,
        ),
      ];
    }

    result += [
      const BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.videocam_fill),
        label: "Консультации",
        backgroundColor: CupertinoColors.systemGrey6,
      ),
      const BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.profile_circled),
        label: "Профиль",
        backgroundColor: CupertinoColors.systemGrey6,
      ),
    ];

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CupertinoColors.systemBackground,
      // appBar: AppBar(toolbarHeight: 32),
      body: SafeArea(
          child: [
        Dashboard(
          onSearch: () {
            setState(() {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => Info(
                    title: "Поиск по приложению",
                    subtitle:
                        "Ищите любую информацию из приложения в одном удобном месте",
                    description:
                        "",
                    externalLink: "https://google.com",
                    buttonLabel: "Найти",
                    customBody: searchBox(),
                  ),
                ),
              );
            });
          },
          onOpenZoom: () {
            setState(
              () {
                user != null && user!.isBusiness()
                    ? _selectedIndex = 2
                    : _selectedIndex = 1;
              },
            );
          },
        ),
        if (user != null && user!.isBusiness()) Chat(),
        const Zoom(),
        const Account()
      ][_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: ColorResources.accentRed,
        unselectedItemColor: CupertinoColors.systemGrey,
        items: bottomNavBar(),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
