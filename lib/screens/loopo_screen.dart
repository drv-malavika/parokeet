

/////// New

import 'dart:math';
import 'package:flutter/material.dart';

class LoopoScreen extends StatefulWidget {
  const LoopoScreen({super.key});

  @override
  State<LoopoScreen> createState() => _LoopoScreenState();
}

// Enum to manage the different states of the screen
enum GamePhase { build, test, score }

class _LoopoScreenState extends State<LoopoScreen> {
  // --- Game Configuration ---
  final int _nodeCount = 10; // Total bubbles available
  final int _minWordsForTest = 5; // Minimum words required to start test
  final List<String> _words = List.filled(10, ''); // Pre-fill list for 10 nodes

  // --- UI & Game State ---
  GamePhase _phase = GamePhase.build;
  String _infoText = "Tap a bubble and enter a word to start your chain.";
  int _testStartIndex = -1;
  final Set<int> _revealedIndexes = {};
  int _score = 0;
  final TransformationController _transformationController = TransformationController();

  // --- Input Management ---
  final TextEditingController _wordController = TextEditingController();
  final FocusNode _wordFocusNode = FocusNode();
  int? _editingIndex;

  // --- Positioning for 2D canvas ---
  // Stores each node's top-left position on the canvas.
  final Map<int, Offset> _nodePositions = {};

  @override
  void initState() {
    super.initState();
    _initPositions(); // generate initial positions
    // subtle initial pan so things start slightly centered/visible
    _transformationController.value = Matrix4.identity()..translate(0.0, 80.0);
  }

  @override
  void dispose() {
    _wordController.dispose();
    _wordFocusNode.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _initPositions() {
    // Place nodes in a simple grid. Replace with any placement algorithm you like.
    // This ensures branching in both x and y directions.
    final int cols = (sqrt(_nodeCount)).ceil();
    final double spacingX = 240.0;
    final double spacingY = 200.0;
    final double startX = 120.0;
    final double startY = 120.0;

    _nodePositions.clear();
    for (int i = 0; i < _nodeCount; i++) {
      final int row = i ~/ cols;
      final int col = i % cols;
      // jitter a bit so they don't look too rigid
      final double jitterX = (Random(i).nextDouble() - 0.5) * 40;
      final double jitterY = (Random(i + 100).nextDouble() - 0.5) * 40;
      _nodePositions[i] = Offset(startX + col * spacingX + jitterX, startY + row * spacingY + jitterY);
    }
  }

  // --- CORE LOGIC METHODS ---

  void _startNewChain() {
    setState(() {
      _words.fillRange(0, _nodeCount, ''); // Clear all words
      _revealedIndexes.clear();
      _phase = GamePhase.build;
      _editingIndex = null;
      _score = 0;
      _infoText = "Tap a bubble to add a word.";
      _transformationController.value = Matrix4.identity(); // Reset zoom/pan
      _initPositions(); // reposition nodes (optional)
    });
  }

  void _startTest() {
    final filledWordCount = _words.where((word) => word.isNotEmpty).length;
    if (filledWordCount < _minWordsForTest) {
      _showInfoToast(
          "Need at least $_minWordsForTest continuous linked words (no gaps).");
      return;
    }

    setState(() {
      _phase = GamePhase.test;
      List<int> filledIndexes = [];
      for (int i = 0; i < _words.length; i++) {
        if (_words[i].isNotEmpty) filledIndexes.add(i);
      }
      _testStartIndex = filledIndexes[Random().nextInt(filledIndexes.length)];

      _revealedIndexes.clear();
      _revealedIndexes.add(_testStartIndex);
      _score = 1;
      _infoText =  "Continue the chain from the shown word.";
    });
  }

  void _handleBubbleTap(int index) {
    final filledWordCount = _words.where((w) => w.isNotEmpty).length;

    // If the test is complete (all words revealed), do nothing on tap.
    if (_phase == GamePhase.test && _revealedIndexes.length == filledWordCount) {
      return;
    }

    // If the word is already revealed in the test, do nothing.
    if (_phase == GamePhase.test && _revealedIndexes.contains(index)) {
      return;
    }

    _editingIndex = index;

    if (_phase == GamePhase.build) {
      // --- BUILD PHASE LOGIC ---
      _wordController.text = _words[index];
      _showWordInputDialog();
    } else if (_phase == GamePhase.test) {
      // --- TEST PHASE LOGIC ---
      _wordController.clear(); // Clear the controller for the user's guess
      _showWordInputDialog();
    }
  }


  void _saveWord(int index, String word) {
    Navigator.of(context).pop();
    if (_phase == GamePhase.build) {
      setState(() {
        _words[index] = word.trim();
        _editingIndex = null;
        final filledCount = _words.where((w) => w.isNotEmpty).length;
        final chainOk = _isChainContinuous();

        if (!chainOk) {
          _infoText =
          "$filledCount words added. Chain must be continuous (no gaps).";
        } else if (filledCount < _minWordsForTest) {
          _infoText =
          "$filledCount words added. Need $_minWordsForTest continuous words to start test.";
        } else {
          _infoText = "Chain ready. Tap test to begin.";
        }
      });
    } else if (_phase == GamePhase.test) {
      if (word.trim().toLowerCase() == _words[index].toLowerCase()) {
        setState(() {
          _revealedIndexes.add(index);
          _score++;
          _infoText = "Good! Keep going.";
          final filledWordCount = _words.where((w) => w.isNotEmpty).length;
          if (_revealedIndexes.length == filledWordCount) {
            _infoText = "Chain complete! Score: $_score";
          }
        });
      } else {
        setState(() {
          _infoText = "Try again.";
        });
      }
    }
  }

  void _revealWordOnDoubleTap(int index) {
    if (_phase != GamePhase.test || _revealedIndexes.contains(index)) return;

    setState(() {
      _revealedIndexes.add(index);
      final totalFilled = _words.where((w) => w.isNotEmpty).length;
      if (_revealedIndexes.length == totalFilled) {
        _infoText = "Chain complete! Score: $_score";
      } else {
        _infoText = ""; // silent for intermediate reveals
      }
    });
  }

  bool _isChainContinuous() {
    int lastFilled = -1;
    for (int i = 0; i < _words.length; i++) {
      if (_words[i].isNotEmpty) {
        if (lastFilled == -1) {
          lastFilled = i;
        } else if (i - lastFilled > 1) {
          // There is a gap between filled bubbles → orphan detected
          return false;
        }
        lastFilled = i;
      }
    }
    // Chain is valid if there are at least 5 filled and no gaps
    int filledCount = _words.where((w) => w.isNotEmpty).length;
    return filledCount >= _minWordsForTest;
  }

  @override
  Widget build(BuildContext context) {
    //final bool canStartTest = _words.where((word) => word.isNotEmpty).length >= _minWordsForTest;
    final bool canStartTest = _isChainContinuous();

    // Calculate which indexes should be shown on canvas
    List<int> indexesToShow;
    if (_phase == GamePhase.test) {
      indexesToShow = [];
      for (int i = 0; i < _words.length; i++) {
        if (_words[i].isNotEmpty) indexesToShow.add(i);
      }
      if (indexesToShow.isEmpty) {
        // nothing to show in test mode (shouldn't happen because startTest checks), fallback to all
        indexesToShow = List.generate(_nodeCount, (i) => i);
      }
    } else {
      indexesToShow = List.generate(_nodeCount, (i) => i);
    }

    // Determine canvas size based on node positions
    final double padding = 300.0;
    double maxX = 0.0, maxY = 0.0;
    _nodePositions.forEach((idx, pos) {
      maxX = max(maxX, pos.dx + 120); // account for bubble size
      maxY = max(maxY, pos.dy + 120);
    });
    final Size canvasSize = Size(maxX + padding, maxY + padding);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loopo Memory Chain'),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _startNewChain,
            tooltip: 'New Chain',
          ),
        ],
      ),
      body: Stack(
        children: [
          // InteractiveViewer for pan & zoom; child is free-sized (constrained: false)
          InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.2,
            maxScale: 4.0,
            boundaryMargin: const EdgeInsets.all(1000),
            constrained: false, // allow child to be larger than viewport

            child: SizedBox(
              width: canvasSize.width,
              height: canvasSize.height,
              child: Stack(
                children: [
                  // Optional background grid
                  CustomPaint(
                    size: canvasSize,
                    painter: GridPainter(),
                  ),

                  // Connections between visible nodes (drawn behind)
                  CustomPaint(
                    size: canvasSize,
                    painter: ConnectionPainter(
                      nodePositions: _nodePositions,
                      indexesToShow: indexesToShow,
                      nodeCount: _nodeCount,
                    ),
                  ),

                  // Bubbles (positioned)
                  ...indexesToShow.map((index) {
                    final pos = _nodePositions[index] ?? Offset(100, 100);
                    final isWordSet = _words[index].isNotEmpty;
                    final isVisibleInTest = _phase == GamePhase.test && _revealedIndexes.contains(index);

                    String displayWord;
                    if (_phase == GamePhase.build) {
                      displayWord = isWordSet ? _words[index] : '?';
                    } else if (isVisibleInTest) {
                      displayWord = _words[index];
                    } else if (_phase == GamePhase.score) {
                      displayWord = _words[index];
                    } else {
                      displayWord = '?';
                    }

                    return Positioned(
                      left: pos.dx,
                      top: pos.dy,
                      child: _WordBubble(
                        word: displayWord,
                        isFilled: isWordSet,
                        isRevealed: isVisibleInTest,
                        phase: _phase,
                        onTap: () => _handleBubbleTap(index),
                        onDoubleTap: () => _revealWordOnDoubleTap(index),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),

          // Info overlay (bottom)
          // Align(
          //   alignment: Alignment.bottomCenter,
          //   child: Container(
          //     width: double.infinity,
          //     color: Colors.black.withOpacity(0.5),
          //     padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          //     child: Text(
          //       _infoText,
          //       textAlign: TextAlign.center,
          //       style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.white),
          //     ),
          //   ),
          // ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(bottom: 60), // keeps away from FAB
              width: double.infinity,
              color: Colors.black.withOpacity(0.55),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: Text(
                _infoText,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _phase == GamePhase.build
          ? FloatingActionButton.small(
        onPressed: canStartTest ? _startTest : null,
        backgroundColor: canStartTest ? Colors.purple : Colors.grey,
        tooltip: 'Start Test',
        child: const Icon(Icons.psychology_outlined),
      )
          : null,
    );
  }

  void _showWordInputDialog() {
    showDialog(
      context: context,
      builder: (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _wordFocusNode.requestFocus());
        return AlertDialog(
          title: Text('Enter Word for Bubble #${_editingIndex! + 1}'),
          content: TextField(
            controller: _wordController,
            focusNode: _wordFocusNode,
            autofocus: true,
            onSubmitted: (value) => _saveWord(_editingIndex!, value),
            decoration: const InputDecoration(hintText: "Enter your word..."),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            TextButton(onPressed: () => _saveWord(_editingIndex!, _wordController.text), child: const Text('Save')),
          ],
        );
      },
    );
  }

  void _showInfoToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ));
  }
}

// --- Draw connecting lines between nodes. Simple straight lines for now. ---
class ConnectionPainter extends CustomPainter {
  final Map<int, Offset> nodePositions;
  final List<int> indexesToShow;
  final int nodeCount;

  ConnectionPainter({
    required this.nodePositions,
    required this.indexesToShow,
    required this.nodeCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade700.withOpacity(0.7)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    // Connect nodes in sequential order, but only if both nodes are in indexesToShow.
    // You can change this logic to reflect your actual "links".
    for (int i = 0; i < nodeCount - 1; i++) {
      if (!indexesToShow.contains(i) || !indexesToShow.contains(i + 1)) continue;
      final a = nodePositions[i];
      final b = nodePositions[i + 1];
      if (a == null || b == null) continue;
      final Offset aCenter = a + const Offset(40, 40); // center offset for circle radius 40
      final Offset bCenter = b + const Offset(40, 40);
      canvas.drawLine(aCenter, bCenter, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ConnectionPainter oldDelegate) {
    return oldDelegate.nodePositions != nodePositions || oldDelegate.indexesToShow != indexesToShow;
  }
}

// Optional grid painter (visual orientation)
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.12)
      ..strokeWidth = 1;

    const double step = 100;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom widget for the circular bubbles (unchanged visual style)
class _WordBubble extends StatelessWidget {
  final String word;
  final bool isFilled;
  final bool isRevealed;
  final GamePhase phase; // For color logic
  final VoidCallback onTap;
  final VoidCallback onDoubleTap; // For revealing word

  const _WordBubble({
    required this.word,
    required this.isFilled,
    required this.phase,
    this.isRevealed = false,
    required this.onTap,
    required this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    Color getBackgroundColor() {
      if (phase == GamePhase.test) {
        return isRevealed ? Colors.green.shade400 : Colors.blue.shade400;
      }
      if (isFilled) return Colors.purple.shade300;
      return Colors.grey.shade400;
    }

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: CircleAvatar(
        radius: 40,
        backgroundColor: getBackgroundColor(),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Text(
            word,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: (isFilled || isRevealed) ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}


