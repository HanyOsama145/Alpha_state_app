import 'package:alpha_state_app/auth_service.dart';
import 'package:alpha_state_app/wordle_game/Controller.dart';
import 'package:alpha_state_app/wordle_game/WordList.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:alpha_state_app/wordle_game/screen_wordle.dart';
import 'dart:ui' as ui;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // await WordList.loadWords();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_)=>Controller())
    ],
    
    child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(  
      debugShowCheckedModeBanner: false,
      home: const login_page(),
    );
  }
}

class login_page extends StatefulWidget {
  const login_page({super.key});

  @override
  State<login_page> createState() => _LoginPageState();
}

class _LoginPageState extends State<login_page> {
  bool secure_pass = true;
  final TextEditingController email_controller = TextEditingController();
  final TextEditingController passwordd = TextEditingController();

  Future<void> signUser() async {
    final regNumber = email_controller.text.trim();
    final password = passwordd.text.trim();

    // Convert reg number to Firebase-compatible email
    final email = regNumber;

    try {
      await authService.value.signIn(email: email, password: password);

      final uid = authService.value.currentUser?.uid;
      // print("hey");
      // print(authService.value.currentUser?.uid);
      // print("now");

      if (uid != null) {
        final doc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();

        if (doc.exists && doc.data()!.containsKey('name')) {
          final name = doc['name'];

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              content: Text("Welcome $name!"),
              actions: [
                TextButton(
                  onPressed: ()  async {
                    Navigator.of(context, rootNavigator: true).pop(); // close dialog
                    //await context.read<Controller>().loadProgress();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const Main_page()),
                    );
                  },
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'user-not-found') {
        errorMessage = 'No account found for that registration number.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Incorrect password.';
      } else {
        errorMessage = e.message ?? 'Login failed.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('CPC'),
          backgroundColor: Colors.blue[900],
          shape: const RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(25)))),
      body: Center(
        child: Container(
          width: 300,
          height: 350,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  spreadRadius: 2,
                )
              ]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/logo.png',
                height: 80,
                width: 100,
              ),
              const SizedBox(height: 5),
              TextField(
                controller: email_controller,
                decoration: const InputDecoration(
                  labelText: "Username",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordd,
                obscureText: secure_pass,
                decoration: InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        secure_pass ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          secure_pass = !secure_pass;
                        });
                      },
                    )),
              ),
              const SizedBox(
                height: 20,
              ),
              ElevatedButton(onPressed: signUser, child: const Text("login")),
            ],
          ),
        ),
      ),
    );
  }
}

class Main_page extends StatelessWidget {
  const Main_page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          
            onPressed:  () async {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const WordleLoader()));
            },
            child: const Text("go to codele")),
      ),
    );
  }
}

class WordleLoader extends StatefulWidget {
  const WordleLoader({super.key});

  @override
  State<WordleLoader> createState() => _WordleLoaderState();
}

class _WordleLoaderState extends State<WordleLoader> with SingleTickerProviderStateMixin {
  String? _error;
  late final AnimationController _progressController;
  late final Animation<double> _progress;

  Widget _tile(String ch, Color bg) {
    return Container(
      width: 42,
      height: 42,
      margin: const EdgeInsets.all(4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.2),
      ),
      child: Text(
        ch,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 18,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _progress = CurvedAnimation(parent: _progressController, curve: Curves.linear);
    _progressController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = context.read<Controller>();
      try {
        // Enforce a minimum loading duration of 2 seconds
        final List<Future<void>> tasks = [];

        tasks.add(() async {
          final loaded = await controller.loadGameState();
          if (!loaded) {
            final todaysWord = await controller.getTodaysWord();
            if (todaysWord != null) {
              controller.setCorrectWord(word: todaysWord);
              await controller.saveGameState();
            }
          }
        }());

        tasks.add(Future.delayed(const Duration(seconds: 2)));

        await Future.wait(tasks);

        if (!mounted) return;
        // Immediate navigation without custom transitions
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const screen_wordle()),
        );
      } catch (e) {
        setState(() {
          _error = 'Failed to restore game: $e';
        });
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(color: const Color(0xFFF5F6F8)),
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
              child: CustomPaint(
                painter: _WordleGridBackground(
                  tile: 56,
                  gap: 10,
                  strokeColor: Colors.black.withOpacity(0.08),
                  letters: 'COMPETITIVEPROGRAMMINGCLUB'.split(''),
                  letterPalette: [
                    const Color(0xFF6AAA64).withOpacity(0.35), // green (light)
                    const Color(0xFFC9B458).withOpacity(0.30), // yellow (light)
                    Colors.black.withOpacity(0.12),            // neutral
                    const Color(0xFF878A8C).withOpacity(0.18), // gray
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.90),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withOpacity(0.08)),
                boxShadow: const [
                  BoxShadow(blurRadius: 20, color: Colors.black12, offset: Offset(0, 8)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'CODELE',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Wordle-like grid
                  Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _tile('C', const Color(0xFF3A3A3C)),
                          _tile('O', const Color(0xFF3A3A3C)),
                          _tile('D', const Color(0xFF3A3A3C)),
                          _tile('E', const Color(0xFF3A3A3C)),
                          _tile('L', const Color(0xFF3A3A3C)),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _tile('T', const Color(0xFF3A3A3C)),
                          _tile('O', const Color(0xFFB59F3B)),
                          _tile('D', const Color(0xFF3A3A3C)),
                          _tile('A', const Color(0xFFB59F3B)),
                          _tile('Y', const Color(0xFF3A3A3C)),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _tile('D', const Color(0xFF538D4E)),
                          _tile('A', const Color(0xFF538D4E)),
                          _tile('I', const Color(0xFF538D4E)),
                          _tile('L', const Color(0xFF3A3A3C)),
                          _tile('Y', const Color(0xFF538D4E)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, _) {
                          return SizedBox(
                            width: 220,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                minHeight: 6,
                                value: _progress.value,
                                backgroundColor: Colors.black.withOpacity(0.12),
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error ?? 'Preparing your daily puzzle...'
                      ,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.75),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WordleGridBackground extends CustomPainter {
  _WordleGridBackground({
    required this.tile,
    required this.gap,
    required this.strokeColor,
    this.letters,
    this.letterPalette,
  });
  final double tile;
  final double gap;
  final Color strokeColor;
  final List<String>? letters; // e.g., characters to cycle per tile
  final List<Color>? letterPalette; // optional palette cycling

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = strokeColor;

    const radius = 6.0;
    final drawLetters = letters != null && letters!.isNotEmpty;
    final tpCache = <String, TextPainter>{};
    for (double y = gap; y < size.height; y += tile + gap) {
      for (double x = gap; x < size.width; x += tile + gap) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, tile, tile),
          const Radius.circular(radius),
        );
        canvas.drawRRect(rect, paint);
        if (drawLetters) {
          final ix = ((x - gap) / (tile + gap)).round();
          final iy = ((y - gap) / (tile + gap)).round();
          final letterIndex = (ix + iy) % letters!.length;
          final letter = letters![letterIndex];
          final color = (letterPalette != null && letterPalette!.isNotEmpty)
              ? letterPalette![(letterIndex) % letterPalette!.length]
              : Colors.white.withOpacity(0.22);
          var tp = tpCache[letter];
          if (tp == null) {
            tp = TextPainter(
              text: TextSpan(
                text: letter,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: tile * 0.54,
                  letterSpacing: 1.0,
                ),
              ),
              textDirection: TextDirection.ltr,
            )..layout();
            tpCache[letter] = tp;
          }
          final dx = x + (tile - tp.width) / 2;
          final dy = y + (tile - tp.height) / 2;
          tp.paint(canvas, Offset(dx, dy));
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WordleGridBackground oldDelegate) {
    return oldDelegate.tile != tile || oldDelegate.gap != gap || oldDelegate.strokeColor != strokeColor;
  }
}

// Removed unused _BackdropWordsPainter
