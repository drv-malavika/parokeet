import 'dart:async';
import 'dart:io'; // For File operations
import 'package:flutter/material.dart';

// import 'package:audioplayers/audioplayers.dart'; // We'll replace audioplayers with TTS for this screen's primary function
import 'package:flutter_tts/flutter_tts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
// import 'package:permission_handler/permission_handler.dart'; // For permission handling

class SecondScreen extends StatefulWidget {
  final String category; // Changed from audioFile, assuming category dictates sentences

  const SecondScreen({super.key, required this.category});

  @override
  _SecondScreenState createState() => _SecondScreenState();
}

class _SecondScreenState extends State<SecondScreen> {
  late FlutterTts _flutterTts;
  List<String> _sentences = [];
  int _currentSentenceIndex = 0;
  bool _isPlayingSpeech = false;
  bool _showHint = false;
  String _hintText = "";
  Timer? _hintTimer;

  // Example sentences - replace with your generation logic
  final Map<String, List<String>> _storySentences = {
    "Stories": [
      "The quick brown fox jumps over the lazy dog.",
      "A journey of a thousand miles begins with a single step.",
      "To be or not to be, that is the question.",
      "All that glitters is not gold.",
      "The cat sat on the mat, watching the rain fall softly."
    ],
    "Non-Fiction": [ // Add sentences for other categories if needed
      "The mitochondria is the powerhouse of the cell.",
      "Water boils at 100 degrees Celsius at sea level.",
      "The Earth revolves around the Sun.",
      "Gravity is the force that attracts a body toward the center of the earth.",
      "Photosynthesis is the process used by plants to convert light energy into chemical energy."
    ],
    "Travel": [
      "The Eiffel Tower is located in Paris, France.",
      "The Great Wall of China is one of the New Seven Wonders of the World.",
      "Machu Picchu is an Incan citadel set high in the Andes Mountains in Peru.",
      "The Colosseum in Rome could hold an estimated 50,000 to 80,000 spectators.",
      "Mount Everest is Earth's highest mountain above sea level."
    ]
    // Add more categories and their sentences
  };

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _loadSentences();
  }

  void _initializeTts() {
    _flutterTts = FlutterTts();
    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isPlayingSpeech = false;
        });
      }
    });
    // You can set language, pitch, rate here if needed
    // _flutterTts.setLanguage("en-US");
    // _flutterTts.setPitch(1.0);
    // _flutterTts.setSpeechRate(0.5);
  }

  void _loadSentences() {
    // In a real app, you might fetch these based on widget.category
    setState(() {
      _sentences =
          _storySentences[widget.category] ?? // Use category from widget
              _storySentences["Stories"]!; // Default to "Stories" if category not found
      if (_sentences.isNotEmpty) {
        _hintText = _sentences[_currentSentenceIndex];
      } else {
        _hintText = "No sentences available for this category.";
      }
    });
  }

  Future<void> _speak() async {
    if (_sentences.isNotEmpty && _currentSentenceIndex < _sentences.length) {
      if (_isPlayingSpeech) {
        await _flutterTts.stop();
        setState(() {
          _isPlayingSpeech = false;
        });
      } else {
        setState(() {
          _isPlayingSpeech = true;
        });
        await _flutterTts.speak(_sentences[_currentSentenceIndex]);
      }
    }
  }

  void _nextSentence() {
    if (_sentences.isNotEmpty) {
      setState(() {
        _currentSentenceIndex = (_currentSentenceIndex + 1) % _sentences.length;
        _hintText = _sentences[_currentSentenceIndex];
        _isPlayingSpeech = false; // Stop speech when changing sentence
        _flutterTts.stop();
      });
    }
  }

  void _previousSentence() {
    if (_sentences.isNotEmpty) {
      setState(() {
        _currentSentenceIndex =
            (_currentSentenceIndex - 1 + _sentences.length) % _sentences.length;
        _hintText = _sentences[_currentSentenceIndex];
        _isPlayingSpeech = false; // Stop speech when changing sentence
        _flutterTts.stop();
      });
    }
  }

/*  void _toggleHint() {
    setState(() {
      _showHint = !_showHint;
    });
  }
*/
  void _toggleHint() {
    setState(() {
      if (_sentences.isNotEmpty) {
        if (_showHint) {
          // If hint is currently shown and button is pressed again, hide it immediately
          _showHint = false;
          _hintTimer?.cancel(); // Cancel any existing timer
        } else {
          // If hint is not shown, show it
          _showHint = true;
          _hintText = _sentences[_currentSentenceIndex]; // Ensure hintText is up-to-date

          // Cancel any previous timer before starting a new one
          _hintTimer?.cancel();
          _hintTimer = Timer(const Duration(seconds: 2), () {
            // This code runs after 5 seconds
            if (mounted && _showHint) { // Check if widget is still mounted and hint is still visible
              setState(() {
                _showHint = false;
              });
            }
          });
        }
      }
    });
  }

  Future<void> _downloadTraceablePdf() async {
    if (_sentences.isEmpty) return;

    // --- Basic Permission Check (Illustrative - needs robust handling) ---
    // if (Platform.isAndroid) {
    //   var status = await Permission.storage.status;
    //   if (!status.isGranted) {
    //     status = await Permission.storage.request();
    //     if (!status.isGranted) {
    //       ScaffoldMessenger.of(context).showSnackBar(
    //         SnackBar(content: Text('Storage permission is required to download PDF.')),
    //       );
    //       return;
    //     }
    //   }
    // }
    // --- End Basic Permission Check ---


    final pdf = pw.Document();
    final sentence = _sentences[_currentSentenceIndex];

    // Basic tracing font (you might need to embed a proper dashed font for real tracing)
    // final pw.Font ttf = pw.Font.ttf(await rootBundle.load("assets/fonts/YourTracingFont.ttf"));

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(30),
              child: pw.Text(
                sentence,
                // style: pw.TextStyle(font: ttf, fontSize: 30, lineSpacing: 20), // Example with custom font
                style: pw.TextStyle(fontSize: 28,
                    lineSpacing: 15,
                    color: PdfColors.grey700), // Basic style
              ),
            ),
          );
        },
      ),
    );

    try {
      final Directory? dir = await getDownloadsDirectory(); // More reliable for downloads
      if (dir == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get downloads directory.')),
        );
        return;
      }
      final String path = '${dir.path}/traceable_sentence_${DateTime
          .now()
          .millisecondsSinceEpoch}.pdf';
      final File file = File(path);
      await file.writeAsBytes(await pdf.save());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF Downloaded to: $path'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () {
              OpenFilex.open(path);
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save PDF: $e')),
      );
    }
  }


/*  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }*/
  @override
  void dispose() {
    _flutterTts.stop();
    _hintTimer?.cancel(); // Important: Cancel the timer when the widget is disposed
    super.dispose();
  }


/*  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category), // Show category in AppBar
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Sentence Display Area (not directly visible, but provides content for TTS and Hint)
              if (_sentences.isNotEmpty)
                Text(
                  'Sentence ${_currentSentenceIndex + 1} of ${_sentences
                      .length}',
                  style: Theme
                      .of(context)
                      .textTheme
                      .titleMedium,
                ),
              const SizedBox(height: 20),

              // Play/Pause Speech Button
              ElevatedButton.icon(
                onPressed: _sentences.isEmpty ? null : _speak,
                icon: Icon(_isPlayingSpeech ? Icons.stop_circle_outlined : Icons
                    .play_circle_filled),
                label: Text(_isPlayingSpeech ? 'Stop' : 'Play Sentence'),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 50)),
              ),
              const SizedBox(height: 20),

              // Navigation Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(onPressed: _previousSentence,
                      child: const Text('Previous')),
                  ElevatedButton(
                      onPressed: _nextSentence, child: const Text('Next')),
                ],
              ),
              const SizedBox(height: 30),

              // Hint Button
              ElevatedButton(
                onPressed: _sentences.isEmpty ? null : _toggleHint,
                child: const Text('Hint'),
              ),
              const SizedBox(height: 10),

              // Animated Opacity for Hint
              AnimatedOpacity(
                opacity: _showHint && _sentences.isNotEmpty ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: _showHint && _sentences.isNotEmpty
                    ? Container(
                  height: 100, // Fixed height for the hint box
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blueGrey),
                  ),
                  child: Scrollbar( // Makes it scrollable
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(right: 8.0),
                      // Padding so scrollbar doesn't overlap text
                      child: Text(
                        _hintText,
                        style: const TextStyle(color: Colors.white,
                            fontSize: 16),
                      ),
                    ),
                  ),
                )
                    : const SizedBox(
                    height: 100), // Keep space when hidden to avoid layout jumps
              ),
              const SizedBox(height: 30),

              // Download PDF Button
              ElevatedButton.icon(
                onPressed: _sentences.isEmpty ? null : _downloadTraceablePdf,
                icon: const Icon(Icons.download_for_offline),
                label: const Text('Download Traceable PDF'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ... (Sentence Display, Play/Pause, Navigation Buttons) ...
              // These remain the same
              if (_sentences.isNotEmpty)
                Text(
                  'Sentence ${_currentSentenceIndex + 1} of ${_sentences.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: _sentences.isEmpty ? null : _speak,
                icon: Icon(_isPlayingSpeech ? Icons.stop_circle_outlined : Icons.play_circle_filled),
                label: Text(_isPlayingSpeech ? 'Stop' : 'Play Sentence'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(onPressed: _previousSentence, child: const Text('Previous')),
                  ElevatedButton(onPressed: _nextSentence, child: const Text('Next')),
                ],
              ),
              const SizedBox(height: 30),

              // Hint Button - No changes here
              ElevatedButton(
                onPressed: _sentences.isEmpty ? null : _toggleHint,
                child: const Text('Hint'),
              ),
              const SizedBox(height: 10),

              // Animated Opacity for Hint - No changes needed here, it reacts to _showHint
              AnimatedOpacity(
                opacity: _showHint && _sentences.isNotEmpty ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: _showHint && _sentences.isNotEmpty
                    ? Container(
                  height: 100,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blueGrey),
                  ),
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        _hintText,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                )
                    : const SizedBox(height: 100),
              ),
              const SizedBox(height: 30),

              // Download PDF Button - No changes here
              ElevatedButton.icon(
                onPressed: _sentences.isEmpty ? null : _downloadTraceablePdf,
                icon: const Icon(Icons.download_for_offline),
                label: const Text('Download Traceable PDF'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ],
          ),
        ),
      ),
    );
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Sentence Information
              if (_sentences.isNotEmpty)
                Text(
                  'Sentence ${_currentSentenceIndex + 1} of ${_sentences.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              const SizedBox(height: 30), // Increased spacing

              // Player Controls Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Previous Button
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    iconSize: 36.0, // Adjust size as needed
                    onPressed: _sentences.isEmpty ? null : _previousSentence,
                    tooltip: 'Previous Sentence',
                  ),

                  // Play/Pause Button
                  IconButton(
                    icon: Icon(
                      _isPlayingSpeech ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    ),
                    iconSize: 64.0, // Make Play/Pause button larger
                    onPressed: _sentences.isEmpty ? null : _speak,
                    tooltip: _isPlayingSpeech ? 'Pause' : 'Play Sentence',
                  ),

                  // Next Button
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    iconSize: 36.0, // Adjust size as needed
                    onPressed: _sentences.isEmpty ? null : _nextSentence,
                    tooltip: 'Next Sentence',
                  ),
                ],
              ),
              const SizedBox(height: 40), // Increased spacing

              // Hint Button - Smaller
              TextButton( // Using TextButton for a less prominent look
                onPressed: _sentences.isEmpty ? null : _toggleHint,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  // You can also add side: BorderSide(color: Theme.of(context).colorScheme.outline) for an OutlinedButton feel
                ),
                child: const Text('Hint'),
              ),
              const SizedBox(height: 10),

              // Animated Opacity for Hint (remains the same)
              AnimatedOpacity(
                opacity: _showHint && _sentences.isNotEmpty ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: _showHint && _sentences.isNotEmpty
                    ? Container(
                  height: 100, // Fixed height for the hint box
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blueGrey),
                  ),
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        _hintText,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                )
                    : const SizedBox(height: 100),
              ),
              const SizedBox(height: 30),

              // Download PDF Button (remains the same)
              ElevatedButton.icon(
                onPressed: _sentences.isEmpty ? null : _downloadTraceablePdf,
                icon: const Icon(Icons.download_for_offline),
                label: const Text('Download Traceable PDF'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ],
          ),
        ),
      ),
    );
  }
}