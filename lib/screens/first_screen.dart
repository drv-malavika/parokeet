import 'package:flutter/material.dart';
import 'package:parokeet/screens/second_screen.dart';

class FirstScreen extends StatelessWidget {
  const FirstScreen({super.key});

  void _navigate(BuildContext context, String categoryName) {
    // audioFile might still be used for background if you wish
    Navigator.push(
      context,
      MaterialPageRoute(
        // builder: (context) => SecondScreen(audioFile: audioFileForBackground), // Old
        builder: (context) =>
            SecondScreen(category: categoryName), // New: Pass category
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> buttonData = [
      // We now pass the category name for sentence generation
      // The 'filePath' could still be used if you want background audio *in addition* to TTS on SecondScreen
      {
        'label': 'Stories',
        'category': 'Stories'
      },
      {
        'label': 'Non-Fiction',
        'category': 'Non-Fiction'
      },
      {
        'label': 'Travel',
        'category': 'Travel'
      },
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
            return buildAudioTile(
              context,
              data['label']!,
              data['category']!, // This is the new category to pass
            );
          }).toList(),
        ),
      ),
    );
  }

  // Updated to accept and pass category
  Widget buildAudioTile(BuildContext context, String label,
      String category) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
      // Pass category to _navigate, filePath might be for background audio on SecondScreen or removed if only TTS
      onPressed: () => _navigate(context, category),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.menu_book, size: 40),
          // Changed icon to represent stories/categories
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