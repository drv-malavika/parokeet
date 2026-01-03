import 'dart:math';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io'; // For File operations
import 'package:flutter/material.dart';
import 'package:Parokeet/services/sentence_service.dart';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // To check if we are on the web
import 'package:universal_html/html.dart' as html; // For web-specific download logic

class SecondScreen extends StatefulWidget {
  final String category;
  const SecondScreen({super.key, required this.category});

  @override
  _SecondScreenState createState() => _SecondScreenState();
}

class _SecondScreenState extends State<SecondScreen> {
  // State for data management
  bool _isLoading = true;
  List<Map<String, dynamic>> _quoteCache = []; // Holds all fetched quotes (e.g., 100)
  List<int> _seenQuoteIds = []; // Tracks IDs of all quotes ever shown
  int _currentBatchPage = 0; // Tracks which set of 5 we are on (0, 1, 2...)

  // State for UI and interaction
  List<String> _sentences = []; // The current set of 5 sentences being displayed
  int _currentSentenceIndex = 0;
  late FlutterTts _flutterTts;
  bool _isPlayingSpeech = false;
  bool _showHint = false;
  String _hintText = "";
  Timer? _hintTimer;
  //Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _fetchInitialBatch(); // Fetch the first 100 quotes
  }

  /// Fetches a large batch of quotes from Supabase and displays the first page.
  Future<void> _fetchInitialBatch() async {
    // Only show the full-screen loading spinner on the very first fetch.
    if (_quoteCache.isEmpty) {
      setState(() { _isLoading = true; });
    }

    final newQuotes = await SentenceService.getQuotesForCategory(
      category: widget.category,
      excludedIds: _seenQuoteIds,
    );

    if (mounted) {
      if (newQuotes.isNotEmpty) {
        // If we got new quotes, add them to the cache and display them.
        _quoteCache = newQuotes;
        _currentBatchPage = 0;
        _displayCurrentBatch();
      } else {
        // If NO new quotes were found, show a SnackBar and stay on the current screen.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No new set available.'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating, // Makes it look nicer
          ),
        );
        // If this was the very first load, we need to stop the loading spinner.
        if (_isLoading) {
          setState(() {
            _isLoading = false;
            // Optionally, set a message if the screen would otherwise be blank
            if (_sentences.isEmpty) {
              _sentences = ["No quotes found for this category."];
            }
          });
        }
      }
    }
  }

  // Takes the next 5 quotes from the cache and updates the UI.
  void _displayCurrentBatch() {
    int batchSize = 5;
    int startIndex = _currentBatchPage * batchSize;

    // Check if we have enough quotes in the cache for the next batch
    if (startIndex >= _quoteCache.length) {
      // We've exhausted the cache, time to fetch more
      _fetchInitialBatch();
      return;
    }

    int endIndex = startIndex + batchSize;
    if (endIndex > _quoteCache.length) {
      endIndex = _quoteCache.length; // Handle the last, possibly smaller, batch
    }

    final newBatch = _quoteCache.sublist(startIndex, endIndex);

    setState(() {
      _sentences = newBatch.map((q) => q['text'].toString()).toList();
      _seenQuoteIds.addAll(newBatch.map((q) => q['id'] as int)); // Mark as seen
      _currentSentenceIndex = 0;
      _hintText = _sentences.first;
      _isLoading = false;
    });
  }

  // The "Refresh" button action
  void _handleRefresh() {
    int nextBatchPage = _currentBatchPage + 1;
    int nextIndex = nextBatchPage * 5;

    if (nextIndex < _quoteCache.length) {
      // If the next batch is available in memory, just display it
      setState(() {
        _currentBatchPage++;
        _displayCurrentBatch();
      });
    } else {
      // If not, fetch a new batch from Supabase
      _showInfoToast("Fetching new set...");
      _fetchInitialBatch();
    }
  }

  // Helper to show temporary info messages
  void _showInfoToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
    ));
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

  // Future<void> _downloadTraceablePdf() async {
  //   if (_sentences.isEmpty) return;
  //
  //   final pdf = pw.Document();
  //   final sentence = _sentences[_currentSentenceIndex];
  //
  //   // Basic tracing font (you might need to embed a proper dashed font for real tracing)
  //   // final pw.Font ttf = pw.Font.ttf(await rootBundle.load("assets/fonts/YourTracingFont.ttf"));
  //
  //   pdf.addPage(
  //     pw.Page(
  //       pageFormat: PdfPageFormat.a4,
  //       build: (pw.Context context) {
  //         return pw.Center(
  //           child: pw.Padding(
  //             padding: const pw.EdgeInsets.all(30),
  //             child: pw.Text(
  //               sentence,
  //               // style: pw.TextStyle(font: ttf, fontSize: 30, lineSpacing: 20), // Example with custom font
  //               style: pw.TextStyle(fontSize: 28,
  //                   lineSpacing: 15,
  //                   color: PdfColors.grey700), // Basic style
  //             ),
  //           ),
  //         );
  //       },
  //     ),
  //   );
  //
  //   try {
  //     final Directory? dir = await getDownloadsDirectory(); // More reliable for downloads
  //     if (dir == null) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Could not get downloads directory.')),
  //       );
  //       return;
  //     }
  //     final String path = '${dir.path}/traceable_sentence_${DateTime
  //         .now()
  //         .millisecondsSinceEpoch}.pdf';
  //     final File file = File(path);
  //     await file.writeAsBytes(await pdf.save());
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('PDF Downloaded to: $path'),
  //         action: SnackBarAction(
  //           label: 'Open',
  //           onPressed: () {
  //             OpenFilex.open(path);
  //           },
  //         ),
  //       ),
  //     );
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Failed to save PDF: $e')),
  //     );
  //   }
  // }

  // Future<void> _downloadTraceablePdf() async {
  //   // Show a "generating" message to the user
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(content: Text('Generating PDF...')),
  //   );
  //
  //   final pdf = pw.Document();
  //
  //   // 1. Load the dotted font from assets
  //   final fontData = await rootBundle.load("assets/fonts/memory.ttf");
  //   final ttf = pw.Font.ttf(fontData);
  //
  //   // ---> ADD THIS: Load the trace font
  //   final fontDataTrace = await rootBundle.load("assets/fonts/trace.ttf");
  //   final ttfTrace = pw.Font.ttf(fontDataTrace);
  //
  //   // 2. Prepare sentences with randomly missing words (This logic is the same)
  //   final List<List<pw.Widget>> sentencesForPdf = [];
  //   final random = Random();
  //
  //   for (String sentence in _sentences) {
  //     List<String> words = sentence.split(' ');
  //     List<pw.Widget> sentenceWidgets = [];
  //     int wordsToRemoveCount = 1 + (words.length > 5 ? random.nextInt(2) : 0);
  //     if (wordsToRemoveCount > words.length / 2) wordsToRemoveCount = 1;
  //
  //     Set<int> removedIndexes = {};
  //     while (removedIndexes.length < wordsToRemoveCount && words.length > 1) {
  //       removedIndexes.add(random.nextInt(words.length));
  //     }
  //
  //     for (int i = 0; i < words.length; i++) {
  //       if (removedIndexes.contains(i)) {
  //         sentenceWidgets.add(pw.Container(
  //           width: 80,
  //           height: 20,
  //           margin: const pw.EdgeInsets.symmetric(horizontal: 4.0),
  //           decoration: const pw.BoxDecoration(
  //             border: pw.Border(
  //                 bottom: pw.BorderSide(color: PdfColors.grey, width: 1.0)),
  //           ),
  //         ));
  //       } else {
  //         sentenceWidgets.add(pw.Text(
  //             '${words[i]} ', style: pw.TextStyle(font: ttf, fontSize: 22)));
  //       }
  //     }
  //     sentencesForPdf.add(sentenceWidgets);
  //   }
  //
  //   // 3. Add content to the PDF (This logic is the same)
  //   pdf.addPage(
  //     pw.Page(
  //       build: (pw.Context context) {
  //         return pw.ListView(
  //           children: sentencesForPdf.map((sentenceLine) {
  //             return pw.Padding(
  //               padding: const pw.EdgeInsets.symmetric(vertical: 20.0),
  //               child: pw.Wrap(
  //                 children: sentenceLine,
  //                 alignment: pw.WrapAlignment.start,
  //                 crossAxisAlignment: pw.WrapCrossAlignment.center,
  //               ),
  //             );
  //           }).toList(),
  //         );
  //       },
  //     ),
  //   );
  //
  //   // 4. SAVE THE FILE - PLATFORM-AWARE LOGIC
  //   final pdfBytes = await pdf.save();
  //   final fileName = "traceable_sentences_${DateTime
  //       .now()
  //       .millisecondsSinceEpoch}.pdf";
  //
  //   if (kIsWeb) {
  //     // --- WEB ---
  //     // Create an "anchor" element in the browser's HTML
  //     final anchor = html.AnchorElement(
  //         href: Uri
  //             .dataFromBytes(pdfBytes, mimeType: 'application/pdf')
  //             .toString())
  //       ..setAttribute("download", fileName);
  //
  //     // Trigger the download
  //     anchor.click();
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('PDF download started in browser.')),
  //     );
  //   } else {
  //     // --- MOBILE / DESKTOP ---
  //     try {
  //       final Directory? directory = await getDownloadsDirectory();
  //       if (directory == null) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //               content: Text("Could not find downloads directory.")),
  //         );
  //         return;
  //       }
  //       final path = "${directory.path}/$fileName";
  //       final file = File(path);
  //       await file.writeAsBytes(pdfBytes);
  //
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('PDF Downloaded to: $path')),
  //       );
  //
  //       OpenFilex.open(path);
  //     } catch (e) {
  //       print("Error saving or opening PDF: $e");
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text("Failed to save or open PDF: $e")),
  //       );
  //     }
  //   }
  // }

  // In C:/Users/svrvs/src/parokeet/lib/screens/second_screen.dart

  Future<void> _downloadTraceablePdf() async {
    // Show a "generating" message to the user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating PDF...')),
    );

    final pdf = pw.Document();

    // 1. Load BOTH fonts from assets
    final fontData = await rootBundle.load("assets/fonts/memory.ttf");
    final ttfMemory = pw.Font.ttf(fontData);
    final fontDataTrace = await rootBundle.load("assets/fonts/trace.ttf"); // Load the new font
    final ttfTrace = pw.Font.ttf(fontDataTrace);

    // 2. Prepare sentences with randomly missing words for the FIRST page
    final List<List<pw.Widget>> sentencesForPdf = [];
    final random = Random();

    for (String sentence in _sentences) {
      List<String> words = sentence.split(' ');
      List<pw.Widget> sentenceWidgets = [];
      int wordsToRemoveCount = 1 + (words.length > 5 ? random.nextInt(2) : 0);
      if (wordsToRemoveCount > words.length / 2) wordsToRemoveCount = 1;

      Set<int> removedIndexes = {};
      while (removedIndexes.length < wordsToRemoveCount && words.length > 1) {
        removedIndexes.add(random.nextInt(words.length));
      }

      for (int i = 0; i < words.length; i++) {
        if (removedIndexes.contains(i)) {
          sentenceWidgets.add(pw.Container(
            width: 80,
            height: 20,
            margin: const pw.EdgeInsets.symmetric(horizontal: 4.0),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey, width: 1.0)),
            ),
          ));
        } else {
          sentenceWidgets.add(pw.Text(
              '${words[i]} ', style: pw.TextStyle(font: ttfMemory, fontSize: 22)));
        }
      }
      sentencesForPdf.add(sentenceWidgets);
    }

    // 3. Add the FIRST page (Fill-in-the-blanks)
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.ListView(
            children: sentencesForPdf.map((sentenceLine) {
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 20.0),
                child: pw.Wrap(
                  children: sentenceLine,
                  alignment: pw.WrapAlignment.start,
                  crossAxisAlignment: pw.WrapCrossAlignment.center,
                ),
              );
            }).toList(),
          );
        },
      ),
    );

    // ---> 4. ADD THE SECOND PAGE (Full Tracing) <---
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.ListView(
            children: _sentences.map((sentence) {
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),
                child: pw.Text(
                  sentence,
                  style: pw.TextStyle(font: ttfTrace, fontSize: 28, lineSpacing: 20),
                ),
              );
            }).toList(),
          );
        },
      ),
    );

    // 5. SAVE THE FILE (No changes needed here)
    final pdfBytes = await pdf.save();
    final fileName = "traceable_sentences_${DateTime.now().millisecondsSinceEpoch}.pdf";

    if (kIsWeb) {
      // --- WEB ---
      final anchor = html.AnchorElement(
          href: Uri.dataFromBytes(pdfBytes, mimeType: 'application/pdf').toString())
        ..setAttribute("download", fileName);
      anchor.click();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF download started in browser.')),
      );
    } else {
      // --- MOBILE / DESKTOP ---
      try {
        //final Directory? directory = await getDownloadsDirectory();
        final Directory? directory = await getExternalStorageDirectory();
        if (directory == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not find downloads directory.")),
          );
          return;
        }
        final path = "${directory.path}/$fileName";
        final file = File(path);
        await file.writeAsBytes(pdfBytes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF Downloaded to: $path')),
        );

        OpenFilex.open(path);
      } catch (e) {
        print("Error saving or opening PDF: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save or open PDF: $e")),
        );
      }
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _hintTimer?.cancel();
    super.dispose();
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
        centerTitle: true,
        actions: [
          // Refresh Button added to the AppBar
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _handleRefresh,
            tooltip: 'Next Set',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : buildContent(), // Extracted content to a separate method
    );
  }

  Widget buildContent() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Sentence ${_currentSentenceIndex + 1} of ${_sentences.length}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 30),
          // Player Controls Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(icon: const Icon(Icons.skip_previous), iconSize: 36.0, onPressed: _previousSentence),
              IconButton(
                icon: Icon(_isPlayingSpeech ? Icons.pause_circle_filled : Icons.play_circle_filled),
                iconSize: 64.0,
                onPressed: _speak,
              ),
              IconButton(icon: const Icon(Icons.skip_next), iconSize: 36.0, onPressed: _nextSentence),
            ],
          ),
          const SizedBox(height: 40),
          // Hint Button
          TextButton(onPressed: _toggleHint, child: const Text('Hint')),
          const SizedBox(height: 10),
          // Animated Opacity for Hint
          AnimatedOpacity(
            opacity: _showHint ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
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
                    _hintText, // The state variable holding the hint text
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          // Download PDF Button
          ElevatedButton.icon(
            onPressed: _downloadTraceablePdf,
            icon: const Icon(Icons.download_for_offline),
            label: const Text('Download PDF'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );
  }
}