import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:bottom_navy_bar/bottom_navy_bar.dart';
import 'package:road_supervisor/models/user_manager.dart';
import 'package:road_supervisor/pages/map_page.dart';
import 'package:road_supervisor/pages/my_account.dart';
import 'package:road_supervisor/pages/about.dart';
import 'settings.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:road_supervisor/generated/codegen_loader.g.dart';

class MainLayout extends StatefulWidget {
  MainLayout({Key? key}) : super(key: key);

  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    UserManager.getLocalSettings(this);
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  buildAppBar() {
    return AppBar(
      title: Text(
        LocaleKeys.AppName.tr(),
        style: TextStyle(),
      ),
    );
  }

  buildBottomNavBar() {
    return BottomNavyBar(
      selectedIndex: _currentIndex,
      onItemSelected: (index) {
        setState(() => _currentIndex = index);
        _pageController.animateToPage(index,
            duration: Duration(milliseconds: 500), curve: Curves.easeInOut);
      },
      items: <BottomNavyBarItem>[
        BottomNavyBarItem(
            title: Text(LocaleKeys.Map.tr()), icon: Icon(Icons.map)),
        BottomNavyBarItem(
            title: Text(LocaleKeys.MyAccount.tr()),
            icon: Icon(Icons.account_box_rounded)),
        BottomNavyBarItem(
            title: Text(LocaleKeys.Settings.tr()), icon: Icon(Icons.settings)),
        BottomNavyBarItem(
            title: Text(LocaleKeys.About.tr()), icon: Icon(Icons.info)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      body: SizedBox.expand(
        child: PageView(
          physics: NeverScrollableScrollPhysics(),
          controller: _pageController,
          onPageChanged: (index) {
            setState(() => _currentIndex = index);
          },
          children: <Widget>[
            MapPage(),
            MyAccoutWidget(),
            MySettingsWidget(),
            AboutWidget(),
          ],
        ),
      ),
      bottomNavigationBar: buildBottomNavBar(),
    );
  }
}
