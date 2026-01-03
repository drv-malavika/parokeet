import 'package:flutter/material.dart';
import 'package:Parokeet/screens/loopo_screen.dart'; // Import LoopoScreen
import 'package:Parokeet/screens/second_screen.dart';

class FirstScreen extends StatelessWidget {
  const FirstScreen({super.key});

  // Updated to handle both category and Loopo navigation
  void _navigate(BuildContext context, String categoryName) {
    if (categoryName == 'loopo') {
      // If the special category 'loopo' is passed, go to LoopoScreen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoopoScreen()),
      );
    } else {
      // Otherwise, go to SecondScreen with the given category
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SecondScreen(category: categoryName),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> buttonData = [
      {'label': 'Stories', 'category': 'Stories'},
      {'label': 'Non-Fiction', 'category': 'Non-Fiction'},
      {'label': 'Travel', 'category': 'Travel'},
      // v-- ADD THIS NEW ENTRY FOR LOOPO --v
      {
        'label': 'Loopo',
        'category': 'loopo' // Special identifier
      },
      // ^-- END OF NEW ENTRY --^
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parokeet'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 1.5,
          children: buttonData.map((data) {
            // Updated to handle custom styling for the Loopo button
            return buildAudioTile(
              context,
              data['label']!,
              data['category']!,
            );
          }).toList(),
        ),
      ),
    );
  }

  // Updated to accept category and apply conditional logic/styling
  Widget buildAudioTile(BuildContext context, String label, String category) {
    // Determine if this tile is the Loopo button
    final bool isLoopo = category == 'loopo';

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        // Use a different color for the Loopo button to make it stand out
        backgroundColor: isLoopo ? Colors.purple : Colors.deepPurple,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
      onPressed: () => _navigate(context, category),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Use a different icon for Loopo
          Icon(isLoopo ? Icons.sync_alt : Icons.menu_book, size: 40),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}

// Ensure MyApp is defined as before
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Audio Navigation Demo',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFF121212),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 24, color: Colors.white),
          titleMedium: TextStyle(fontSize: 18, color: Colors.white70),
        ),
      ),
      home: const FirstScreen(),
    );
  }
}