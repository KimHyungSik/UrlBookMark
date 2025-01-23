import 'package:flutter/material.dart';
import 'package:url_book_marker/screens/bookmark_list_screen.dart';

void main() {
  runApp(const MainScreen());
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const BookmarkListScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
