import 'package:flutter/material.dart';
import 'package:learningexamapp/utils/common_widgets/NoScreenshotWrapper.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

class VideoPlayerPage extends StatefulWidget {
  final String fileUrl;
  final String fileName;

  const VideoPlayerPage({
    Key? key,
    required this.fileUrl,
    required this.fileName,
  }) : super(key: key);

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;
  bool _isLoading = true;
  bool _controlsVisible = true;
  bool _isDimming = false;
  bool _isBackButtonVisible = false;
  Timer? _timer;
  Timer? _controlVisibilityTimer;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.fileUrl))
      ..initialize().then((_) {
        setState(() {
          _isLoading = false;
          _controller.play();
        });
        _startTimer();
        _startControlVisibilityTimer();
      });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controlVisibilityTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_controller.value.isPlaying) {
        setState(() {});
      }
    });
  }

  void _startControlVisibilityTimer() {
    _controlVisibilityTimer?.cancel();
    _controlVisibilityTimer = Timer(Duration(seconds: 3), () {
      setState(() {
        _controlsVisible = false;
        _isBackButtonVisible = false;
      });
    });
  }

  void _toggleControlsVisibility() {
    setState(() {
      _controlsVisible = !_controlsVisible;
      _isDimming = true;
      _isBackButtonVisible = _controlsVisible;
    });
    if (_controlsVisible) {
      _startControlVisibilityTimer();
    }
    Timer(Duration(milliseconds: 200), () {
      setState(() {
        _isDimming = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return NoScreenshotWrapper(
      child: Scaffold(
        appBar: isLandscape ? null : AppBar(title: Text(widget.fileName)),
        body: SafeArea(
          child: Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTap: _toggleControlsVisibility,
                child: Center(
                  // Center the video
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : AspectRatio(
                            aspectRatio: _controller.value.aspectRatio,
                            child: VideoPlayer(_controller),
                          ),
                      AnimatedOpacity(
                        opacity: _isDimming ? 0.2 : 0.0,
                        duration: Duration(milliseconds: 200),
                        child: ColoredBox(color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ),
              if (isLandscape && _isBackButtonVisible)
                Positioned(
                  top: 16,
                  left: 16,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              if (_controlsVisible && !_isLoading)
                Positioned(
                  child: IconButton(
                    iconSize: 72.0,
                    icon: Icon(
                      _controller.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _controller.value.isPlaying
                            ? _controller.pause()
                            : _controller.play();
                        _startControlVisibilityTimer();
                      });
                    },
                  ),
                ),
              if (_controlsVisible && !_isLoading)
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Colors.red,
                          inactiveTrackColor: Colors.red.shade100,
                          thumbColor: Colors.red,
                          overlayColor: Colors.red.withValues(alpha: 0.3),
                          thumbShape: RoundSliderThumbShape(
                            enabledThumbRadius: 10.0,
                          ),
                          overlayShape: RoundSliderOverlayShape(
                            overlayRadius: 14.0,
                          ),
                        ),
                        child: Slider(
                          value:
                              _controller.value.position.inSeconds.toDouble(),
                          min: 0.0,
                          max: _controller.value.duration.inSeconds.toDouble(),
                          onChanged: (value) {
                            setState(() {
                              _controller.seekTo(
                                Duration(seconds: value.toInt()),
                              );
                              _startControlVisibilityTimer();
                            });
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(_controller.value.position),
                              style: TextStyle(color: Colors.white),
                            ),
                            Text(
                              _formatDuration(_controller.value.duration),
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
