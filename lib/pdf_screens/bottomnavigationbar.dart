import 'package:aichat/page/ChatHistoryPage.dart';
import 'package:aichat/page/HomePage.dart';
import 'package:aichat/pdf_screens/chat_screen.dart';
import 'package:aichat/pdf_screens/profile_screen.dart';
import 'package:flutter/material.dart';

class Bottomnavigationbar extends StatefulWidget {
  const Bottomnavigationbar({super.key});

  @override
  State<Bottomnavigationbar> createState() => _BottomnavigationbarState();
}

class _BottomnavigationbarState extends State<Bottomnavigationbar> {
  int index = 0;
  final Screens = [
    ChatScreen(),
    HomePage(),
    ChatHistoryPage(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Screens[index],
      bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
              indicatorColor: Colors.blue.shade100,
              labelTextStyle: MaterialStateProperty.all(
                TextStyle(fontSize: 14,fontWeight: FontWeight.w500),)
          ),
          child: NavigationBar(
              height: 60,
              backgroundColor: Color(0xFFf1f5fb),
              labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
              selectedIndex: index,
              animationDuration: Duration(seconds: 1),
              onDestinationSelected: (index)=>
                  setState(() =>this.index=index),
              destinations:[
                NavigationDestination(
                    icon:Icon(Icons.chat),
                    selectedIcon: Icon(Icons.chat),
                    label:'Chat'
                ),
                NavigationDestination(
                    icon:Icon(Icons.home),
                    selectedIcon: Icon(Icons.home),
                    label:'Home'
                ),
                NavigationDestination(
                    icon:Icon(Icons.history),
                    selectedIcon: Icon(Icons.history),
                    label:'History'
                ),
                NavigationDestination(
                    icon:Icon(Icons.person),
                    selectedIcon: Icon(Icons.person),
                    label:'Profile'
                ),
              ]
          ),
          ),);
    }

}
