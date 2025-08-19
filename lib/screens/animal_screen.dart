import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lottie/lottie.dart';

class AnimalScreen extends StatefulWidget {
  const AnimalScreen({Key? key}) : super(key: key);

  @override
  State<AnimalScreen> createState() => _AnimalScreenState();
}

class _AnimalScreenState extends State<AnimalScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isAutoPlaying = false;
  bool _isBgMusicOn = false;

  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _bgPlayer = AudioPlayer();

  final List<String> _animals = [
    'lion', 'dog', 'elephant', 'cow', 'duck', 'tiger', 'jaguar', 'cat', 'sheep'
  ];

  late AnimationController _bgController;
  late Animation<double> _bgAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20), // slower, smoother
    )..repeat(); // loop in one direction
    _bgAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _bgController.dispose();
    _audioPlayer.dispose();
    _bgPlayer.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _playAnimalSound(String animal) async {
    if (_isBgMusicOn) {
      await _bgPlayer.pause();
    }
    setState(() => _isPlaying = true);
    await _flutterTts.speak(animal);
    await Future.delayed(const Duration(seconds: 2));
    await _audioPlayer.play(
      AssetSource('sounds/${animal}_sound.mp3'),
      volume: 1.0,
    );
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isPlaying = false);
    if (_isBgMusicOn) {
      await _bgPlayer.resume();
    }
  }

  Future<void> _onAnimalTap(int index) async {
    setState(() => _currentIndex = index);
    await _playAnimalSound(_animals[index]);
  }

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
    setState(() => _isAutoPlaying = false);
  }

  Future<void> _toggleBackgroundMusic() async {
    if (_isBgMusicOn) {
      await _bgPlayer.stop();
    } else {
      await _bgPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgPlayer.play(AssetSource('sounds/bg_music.mp3'));
    }
    setState(() => _isBgMusicOn = !_isBgMusicOn);
  }

  @override
  Widget build(BuildContext context) {
    final String selectedAnimal = _animals[_currentIndex];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animal Screen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Lottie.asset(
              'assets/animations/jungle.json', // Replace with your background Lottie file
              fit: BoxFit.cover,
              repeat: true,
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text("Music", style: TextStyle(fontSize: 14)),
                    Switch(
                      value: _isBgMusicOn,
                      onChanged: (val) => _toggleBackgroundMusic(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: Image.asset(
                    'assets/animals/$selectedAnimal.jpeg',
                    key: ValueKey(selectedAnimal),
                    width: 160,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
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
              const SizedBox(height: 8),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  padding: const EdgeInsets.all(12),
                  children: List.generate(_animals.length, (index) {
                    final animal = _animals[index];
                    return GestureDetector(
                      onTap: () => _onAnimalTap(index),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.all(8),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 500),
                                child: Image.asset(
                                  'assets/animals/$animal.jpeg',
                                  key: ValueKey(animal),
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                animal.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3B3B3B),
                                  letterSpacing: 1.1,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      offset: Offset(1, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
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