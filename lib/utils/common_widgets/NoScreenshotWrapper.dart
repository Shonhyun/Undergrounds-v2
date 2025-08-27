import 'package:flutter/material.dart';
import 'package:no_screenshot/no_screenshot.dart';

final _noScreenshot = NoScreenshot.instance;

class NoScreenshotWrapper extends StatefulWidget {
  final Widget child;

  const NoScreenshotWrapper({required this.child, super.key});

  @override
  State<NoScreenshotWrapper> createState() => _NoScreenshotWrapperState();
}

class _NoScreenshotWrapperState extends State<NoScreenshotWrapper> {
  @override
  void initState() {
    super.initState();
    _noScreenshot.screenshotOff();
  }

  @override
  void dispose() {
    _noScreenshot.screenshotOn();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
