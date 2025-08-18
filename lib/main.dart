import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Audio Navigation Demo',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Color(0xFF121212),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          ),
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
      home: FirstScreen(),
    );
  }
}

class FirstScreen extends StatelessWidget {
  void _navigate(BuildContext context, String audioFile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SecondScreen(audioFile: audioFile),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Parokeet'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              buildAudioButton(context, 'Stories', 'audio/basic_audio.mp3'),
              SizedBox(height: 20),
              buildAudioButton(context, 'Non-Fiction', 'audio/basic_audio2.mp3'),
              SizedBox(height: 20),
              buildAudioButton(context, 'Travel', 'audio/basic_audio3.mp3'),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildAudioButton(BuildContext context, String label, String filePath) {
    return ElevatedButton.icon(
      onPressed: () => _navigate(context, filePath),
      icon: Icon(Icons.play_arrow),
      label: Text(label),
    );
  }
}

class SecondScreen extends StatefulWidget {
  final String audioFile;
  SecondScreen({required this.audioFile});

  @override
  _SecondScreenState createState() => _SecondScreenState();
}

class _SecondScreenState extends State<SecondScreen> {
  late AudioPlayer _player;
  bool _isPlaying = false;
  bool _showText = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
  }

  Future<void> _toggleAudio() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play(AssetSource(widget.audioFile));
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _showTemporaryText() {
    setState(() {
      _showText = true;
    });
    Timer(Duration(seconds: 1), () {
      setState(() {
        _showText = false;
      });
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(''),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isPlaying ? Icons.graphic_eq : Icons.music_note,
                size: 60,
                color: Colors.deepPurpleAccent,
              ),
              SizedBox(height: 16),
              Text(
                _isPlaying ? 'Playing Audio' : 'Audio Paused',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _toggleAudio,
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                label: Text(_isPlaying ? 'Pause' : 'Play'),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _showTemporaryText,
                child: Text('Hint'),
              ),
              SizedBox(height: 10),
              AnimatedOpacity(
                opacity: _showText ? 1.0 : 0.0,
                duration: Duration(milliseconds: 200),
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '🎉 Hello! This will disappear soon.',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
