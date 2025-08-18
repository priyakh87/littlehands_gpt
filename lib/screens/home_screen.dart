import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lottie/lottie.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/ai_service.dart';
import 'animal_screen.dart';

/// Home screen of LittlehandsGPT.
/// Displays an animated mascot and four primary actions: animal sounds,
/// bedtime stories, alphabet rhymes and color games. It also supports
/// speech input via a microphone button and outputs responses via
/// text‑to‑speech. The app operates in offline mode by default, but can
/// optionally call the OpenAI API if a valid API key is provided in
/// `.env` and [_isOnline] is set to true.
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final stt.SpeechToText _speech;
  final FlutterTts _flutterTts = FlutterTts();

  bool _speechEnabled = false;
  bool _isListening = false;
  String _lastWords = '';
  bool _isOnline = false;

  Map<String, dynamic> _offlineData = {};
  String? _currentAnimalImage;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
    _loadOfflineData();
  }

  /// Initialise the speech recogniser. Checks if speech input is
  /// available on the device and sets [_speechEnabled] accordingly.
  void _initSpeech() async {
    try {
      _speechEnabled = await _speech.initialize();
    } catch (e) {
      _speechEnabled = false;
      debugPrint('Speech initialization error: $e');
    }
    setState(() {});
  }

  /// Load offline prompts and responses from local JSON file. The file
  /// resides in assets/data/offline_prompts.json and defines a set of
  /// static examples for each category. This enables the app to work
  /// fully offline without an API key.
  Future<void> _loadOfflineData() async {
    final data = await rootBundle.loadString('assets/data/offline_prompts.json');
    setState(() {
      _offlineData = jsonDecode(data) as Map<String, dynamic>;
    });
  }

  /// Start listening for voice input and convert speech to text.
  void _startListening() async {
    if (!_speechEnabled) return;
    try {
      await _speech.listen(onResult: _onSpeechResult);
      setState(() => _isListening = true);
    } catch (e) {
      debugPrint('Speech listening error: $e');
      setState(() => _isListening = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Speech recognition failed: $e')),
        );
      }
    }
  }

  /// Stop listening for voice input.
  void _stopListening() async {
    try {
      await _speech.stop();
      setState(() => _isListening = false);
    } catch (e) {
      debugPrint('Speech stop error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to stop listening: $e')),
        );
      }
    }
  }

  /// Speak a given message aloud using the TTS engine.
  Future<void> _speak(String message) async {
    try {
      await _flutterTts.stop();
      await _flutterTts.speak(message);
    } catch (e) {
      debugPrint('TTS error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Text-to-speech failed: $e')),
        );
      }
    }
  }

  /// Handle the 'Animal Sounds' button. If offline, randomly select an
  /// animal from the local JSON and speak its sound. When online,
  /// delegate to [AiService] to generate a fresh response via GPT.
  Future<void> _handleAnimalSounds() async {
    if (!_isOnline) {
      final animals = _offlineData['animal_sounds'] as Map<String, dynamic>? ?? {};
      if (animals.isEmpty) {
        await _speak('I don\'t know any animals yet.');
        return;
      }
      final animalName = animals.keys.first;
      final animal = animals[animalName];
      final sound = animal['sound'];
      setState(() {
        _currentAnimalImage = animal['image'];
      });
      await _speak('$animalName goes $sound');
    } else {
      final response = await AiService.sendMessage(
        'You are teaching a toddler about animal sounds. Describe an animal and imitate its sound in a fun way.',
      );
      await _speak(response);
    }
  }

  /// Handle the 'Story Time' button. Uses offline story or GPT.
  Future<void> _handleStoryTime() async {
    if (!_isOnline) {
      final stories = _offlineData['stories'] as Map<String, dynamic>?;
      final story = stories?.values.first ?? 'Once upon a time...';
      await _speak(story);
    } else {
      final response = await AiService.sendMessage(
        'Tell a short, engaging bedtime story suitable for a 3‑year‑old child.',
      );
      await _speak(response);
    }
  }

  /// Handle the 'ABC Rhymes' button. Uses offline rhyme or GPT.
  Future<void> _handleAbc() async {
    if (!_isOnline) {
      final abc = _offlineData['abc'] as Map<String, dynamic>?;
      final rhyme = abc?.values.first ?? 'A is for apple. B is for ball.';
      await _speak(rhyme);
    } else {
      final response = await AiService.sendMessage(
        'Teach the alphabet with a fun rhyme for toddlers.',
      );
      await _speak(response);
    }
  }

  /// Handle the 'Color Game' button. Uses offline color prompt or GPT.
  Future<void> _handleColors() async {
    if (!_isOnline) {
      final colors = _offlineData['colors'] as Map<String, dynamic>?;
      final entry = colors?.entries.first;
      if (entry != null) {
        await _speak('Can you find something that is ${entry.key}? ${entry.value}');
      } else {
        await _speak('Let\'s play a color game next time.');
      }
    } else {
      final response = await AiService.sendMessage(
        'Let\'s play a color guessing game with a toddler.',
      );
      await _speak(response);
    }
  }

  /// Callback when speech recognition yields a result. The recognised
  /// words are stored in [_lastWords] and could be used to trigger
  /// corresponding actions or passed to the AI service.
  void _onSpeechResult(dynamic result) {
    debugPrint('Speech result type: \'${result.runtimeType}\'');
    setState(() {
      _lastWords = result.recognizedWords;
    });
  }

  /// Interpret the last recognised words from the microphone and map
  /// them to one of the app's core functions. For a real product,
  /// consider implementing a more robust intent classifier.
  Future<void> _handleVoiceCommand() async {
    final command = _lastWords.toLowerCase();
    if (command.contains('animal')) {
      await _handleAnimalSounds();
    } else if (command.contains('story')) {
      await _handleStoryTime();
    } else if (command.contains('abc') || command.contains('alphabet')) {
      await _handleAbc();
    } else if (command.contains('color')) {
      await _handleColors();
    } else if (command.isNotEmpty) {
      // If not recognised, ask GPT to reply generically when online
      if (_isOnline) {
        final response = await AiService.sendMessage(
          'Respond to a toddler who said: "$command". Keep it safe, short and educational.',
        );
        await _speak(response);
      } else {
        await _speak('I\'m sorry, I didn\'t catch that. Let\'s try tapping a button instead.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LittlehandsGPT'),
        actions: [
          Row(
            children: [
              const Text('Offline'),
              Switch(
                value: _isOnline,
                onChanged: (value) => setState(() => _isOnline = value),
              ),
              const Text('Online'),
              const SizedBox(width: 12),
            ],
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Mascot animation
              SizedBox(
                height: 200,
                child: Lottie.asset('assets/animations/mascot.json', fit: BoxFit.contain),
              ),
              const SizedBox(height: 16),

               // Animal image (add here)
              if (_currentAnimalImage != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Image.asset(_currentAnimalImage!, height: 150),
                ),
              // Buttons
              _buildActionButton('Animal Sounds', Icons.pets,  () async {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AnimalScreen()),
              );
            },),
              _buildActionButton('Story Time', Icons.book, _handleStoryTime),
              _buildActionButton('ABC Rhymes', Icons.sort_by_alpha, _handleAbc),
              _buildActionButton('Color Game', Icons.color_lens, _handleColors),
              const SizedBox(height: 24),
              // Voice control button
              ElevatedButton.icon(
                icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                label: Text(_isListening ? 'Listening...' : 'Tap to Talk'),
                onPressed: _speechEnabled
                    ? () {
                        if (_isListening) {
                          _stopListening();
                          _handleVoiceCommand();
                        } else {
                          _startListening();
                        }
                      }
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper to build a large button with icon and label.
  Widget _buildActionButton(String label, IconData icon, Future<void> Function() onPressed) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 28),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            label,
            style: const TextStyle(fontSize: 18),
          ),
        ),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () async {
          try {
            await onPressed();
          } catch (e) {
            debugPrint('Error in $label button: $e');
            // Optional: show a snackbar or alert
          }
        },
      ),
    ),
  );
}
}