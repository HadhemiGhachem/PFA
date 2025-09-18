import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';

class MyConvexBottomBar extends StatefulWidget {
  const MyConvexBottomBar({super.key});

  @override
  State<MyConvexBottomBar> createState() => _MyConvexBottomBarState();
}

class _MyConvexBottomBarState extends State<MyConvexBottomBar> {
  int _currentIndex = 0 ; 

  // Screens with icons and text
  final List<Map<String, dynamic >> _screens = [
    {'icon': Icons.home , 'text': 'Welcome to the code Flicks'},
    {'icon': Icons.directions_car , 'text': 'car'},
    {'icon': Icons.gavel , 'text': 'Bid...'},
    {'icon': Icons.notifications , 'text': 'notifications'},
    {'icon': Icons.person , 'text': 'your profile'},




  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'C o n v e x B o t t o m B a r',
          style: TextStyle(fontSize: 24),
          ),
          backgroundColor: Colors.indigo.shade200,
      ),

      body: SafeArea(child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_screens[_currentIndex] ['icon'],
            size: 80,
            color: Colors.indigo[600],
            ),
            const SizedBox(height: 20,),
            Text(
              _screens[_currentIndex] ['text'],
              style: const TextStyle(
                fontSize: 24,
                fontWeight:  FontWeight.w500
              ),
            )
          ],
        ),
      ),
      ),




      
      bottomNavigationBar: ConvexAppBar(
        backgroundColor: Colors.indigo[200],
        color: Colors.white,
        activeColor: Colors.indigo[800],
        style: TabStyle.flip,
        curveSize: 70,
        items: const[
          TabItem(icon: Icons.home  , title: 'Home'),
          TabItem(icon: Icons.directions_car  , title: 'car'),
          TabItem(icon: Icons.gavel  , title: 'gavel'),
          TabItem(icon: Icons.notifications  , title: 'notifications'),
          TabItem(icon: Icons.person  , title: 'profile'),

        ],
        initialActiveIndex: 0,
        onTap: (int index){
          setState(() {
            _currentIndex = index;
          });
        }
        ) ,
    );

  }
}