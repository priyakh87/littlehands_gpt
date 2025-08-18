import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lottie/lottie.dart';

class AnimalScreen extends StatefulWidget {
  const AnimalScreen({Key? key}) : super(key: key);

  @override
  State<AnimalScreen> createState() => _AnimalScreenState();
}

class _AnimalScreenState extends State<AnimalScreen> {
    int _currentIndex = 0;
  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String _currentAnimal = 'lion';
  bool _isPlaying = false;

  final List<String> _animals = [
    'lion', 'dog', 'elephant', 'cow', 'duck', 'tiger', 'jaguar', 'cat'
  ];

  Future<void> _playAnimalSound(String animal) async {
    setState(() => _isPlaying = true);
    await _flutterTts.speak(animal);
    // Wait for TTS to finish before playing sound
    await Future.delayed(const Duration(seconds: 2));
    await _audioPlayer.play(AssetSource('sounds/${animal}_sound.mp3'));
    // Wait for sound to finish (adjust duration as needed)
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isPlaying = false);
  }

  Future<void> _onAnimalTap(int index) async {
    setState(() => _currentIndex = index);
    await _playAnimalSound(_animals[index]);
  }

  bool _isAutoPlaying = false;

  Future<void> startAutoPlay() async {
    _isAutoPlaying = true;
    while (_isAutoPlaying && mounted) {
      await _onAnimalTap(_currentIndex);
      await Future.delayed(const Duration(seconds: 10));
      if (!mounted) break;
      setState(() {
        _currentIndex = (_currentIndex + 1) % _animals.length;
      });
    }
  }

  void stopAutoPlay() {
    _isAutoPlaying = false;
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animal Sounds'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/animal_bg.png',
            fit: BoxFit.cover,
          ),
          Column(
            children: [
              if (_isPlaying)
                SizedBox(
                  height: 150,
                  child: Lottie.asset('assets/animations/mascot.json'),
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Image.asset(
                  'assets/animals/${_currentAnimal}.jpeg',
                  height: 180,
                ),
              ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _isAutoPlaying ? null : () => startAutoPlay(),
                      child: const Text('Auto Play'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isAutoPlaying ? () => stopAutoPlay() : null,
                      child: const Text('Stop Auto Play'),
                    ),
                  ],
                ),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 3,
                    padding: const EdgeInsets.all(12),
                    children: List<Widget>.generate(_animals.length, (index) {
                      final animal = _animals[index];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentIndex = index;
                            _currentAnimal = animal;
                          });
                          _playAnimalSound(animal);
                        },
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/animals/$animal.jpeg',
                              height: 64,
                            ),
                            const SizedBox(height: 8),
                            Text(animal, style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}