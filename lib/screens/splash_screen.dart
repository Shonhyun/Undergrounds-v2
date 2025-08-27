import 'dart:async';
import 'package:flutter/material.dart';
import 'package:native_video_player/native_video_player.dart';
import 'auth_pages/login_screen.dart';

enum SplashState { playingVideo1, playingVideo2, completed }

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  NativeVideoPlayerController? _controller1;
  NativeVideoPlayerController? _controller2;

  StreamSubscription<void>? _eventsSubscription1;
  StreamSubscription<void>? _eventsSubscription2;

  SplashState _currentState = SplashState.playingVideo1;
  bool _isSkipping = false;
  bool _disposed = true;

  @override
  void initState() {
    super.initState();
    _disposed = false;
  }

  @override
  void dispose() {
    _disposed = true;

    _eventsSubscription1?.cancel();
    _eventsSubscription2?.cancel();
    _controller1?.dispose();
    _controller2?.dispose();
    super.dispose();
  }

  void _onView1Ready(NativeVideoPlayerController controller) async {
    if (_isSkipping) return;
    _controller1 = controller;
    await _controller1!.loadVideo(
      VideoSource(
        path: 'assets/videos/splash_screen/splash_video1.mp4',
        type: VideoSourceType.asset,
      ),
    );
    await _controller1!.play();

    _eventsSubscription1 = _controller1!.events.listen((event) {
      if (_isSkipping || _disposed || !mounted) return;
      if (event is PlaybackEndedEvent && mounted) {
        setState(() {
          _currentState = SplashState.playingVideo2;
        });
      }
    });
  }

  void _onView2Ready(NativeVideoPlayerController controller) async {
    if (_isSkipping) return;
    _controller2 = controller;
    await _controller2!.loadVideo(
      VideoSource(
        path: 'assets/videos/splash_screen/splash_video2.mp4',
        type: VideoSourceType.asset,
      ),
    );
    await _controller2!.play();

    _eventsSubscription2 = _controller2!.events.listen((event) {
      if (_isSkipping || _disposed || !mounted) return;
      if (event is PlaybackEndedEvent && mounted) {
        skipSplashScreen();
      }
    });
  }

  void skipSplashScreen() async {
    if (_isSkipping || !mounted) return;
    _isSkipping = true;

    // Cancel subscriptions to prevent further state changes
    await _eventsSubscription1?.cancel();
    await _eventsSubscription2?.cancel();

    // Dispose of controllers to free up resources
    try {
      await _controller1?.pause();
      await _controller2?.pause();

      await Future.delayed(const Duration(milliseconds: 100));

      _controller1?.dispose();
      _controller2?.dispose();

    } catch (e) {
      debugPrint("Error during video controller cleanup: $e");
    }

    await Future.delayed(const Duration(milliseconds: 100));
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget splashContent;

    switch (_currentState) {
      case SplashState.playingVideo1:
        splashContent = AspectRatio(
          aspectRatio: 16 / 9,
          child: NativeVideoPlayerView(
            key: const ValueKey('video1'),
            onViewReady: _onView1Ready,
          ),
        );
        break;
      case SplashState.playingVideo2:
        splashContent = AspectRatio(
          aspectRatio: 16 / 9,
          child: NativeVideoPlayerView(
            key: const ValueKey('video2'),
            onViewReady: _onView2Ready,
          ),
        );
        break;
      case SplashState.completed:
        splashContent = const SizedBox.shrink();
        break;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: skipSplashScreen,
        child: Stack(
          children: [
            Center(child: splashContent),
            Container(color: Colors.transparent),
          ],
        ),
      ),
    );
  }
}
