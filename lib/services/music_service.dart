import 'package:audioplayers/audioplayers.dart';

class MusicService {
  static final MusicService _instance = MusicService._internal();
  factory MusicService() => _instance;
  MusicService._internal();

  late AudioPlayer _audioPlayer;
  bool _isInitialized = false;
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _audioPlayer = AudioPlayer();

    // 监听播放状态变化
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      _isPlaying = state == PlayerState.playing;
      print('Music Service - Player state changed to: $state');
    });

    // 监听播放完成
    _audioPlayer.onPlayerComplete.listen((event) {
      _isPlaying = false;
      print('Music Service - Player completed');
    });

    _isInitialized = true;
  }

  Future<void> play() async {
    if (!_isInitialized) await initialize();

    try {
      if (!_isPlaying) {
        await _audioPlayer.play(AssetSource('images/bg_music.mp3'));
        await _audioPlayer.setVolume(0.7);
        await _audioPlayer.setReleaseMode(ReleaseMode.loop);
        print('Music Service - Started playing music');
      }
    } catch (e) {
      print('Music Service - Error playing music: $e');
    }
  }

  Future<void> pause() async {
    if (!_isInitialized) return;

    try {
      await _audioPlayer.pause();
      print('Music Service - Paused music');
    } catch (e) {
      print('Music Service - Error pausing music: $e');
    }
  }

  Future<void> stop() async {
    if (!_isInitialized) return;

    try {
      await _audioPlayer.stop();
      print('Music Service - Stopped music');
    } catch (e) {
      print('Music Service - Error stopping music: $e');
    }
  }

  Future<void> toggle() async {
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  void dispose() {
    if (_isInitialized) {
      _audioPlayer.dispose();
      _isInitialized = false;
    }
  }
}
