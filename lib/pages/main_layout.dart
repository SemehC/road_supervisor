import 'package:flutter/material.dart';
import 'package:bottom_navy_bar/bottom_navy_bar.dart';
import 'package:road_supervisor/pages/map_page.dart';
import 'package:road_supervisor/pages/my_account.dart';

import 'settings.dart';

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
        "Road Supervisor",
        style: TextStyle(),
      ),
    );
  }

  buildBottomNavBar() {
    return BottomNavyBar(
      selectedIndex: _currentIndex,
      onItemSelected: (index) {
        setState(() => _currentIndex = index);
        _pageController.jumpToPage(index);
      },
      items: <BottomNavyBarItem>[
        BottomNavyBarItem(title: Text('Map'), icon: Icon(Icons.map)),
        BottomNavyBarItem(
            title: Text('My Account'), icon: Icon(Icons.account_box_rounded)),
        BottomNavyBarItem(title: Text('About'), icon: Icon(Icons.info)),
        BottomNavyBarItem(title: Text('Settings'), icon: Icon(Icons.settings)),
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
            Container(
              color: Colors.green,
            ),
            MySettingsWidget(),
          ],
        ),
      ),
      bottomNavigationBar: buildBottomNavBar(),
    );
  }
}
