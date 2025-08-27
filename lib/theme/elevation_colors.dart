import 'package:flutter/material.dart';

class ElevationColors {
  /// Base Background
  static const Color darkBase = Color(0xFF121212);
  static const Color lightBase = Color(0xFFFFFFFF);

  /// Dark Mode Elevation
  static const Color dark01dp = Color(0xFF1A1A1A);
  static const Color dark02dp = Color(0xFF1C1C1C);
  static const Color dark03dp = Color(0xFF1E1E1E);
  static const Color dark04dp = Color(0xFF1F1F1F);
  static const Color dark06dp = Color(0xFF212121);
  static const Color dark08dp = Color(0xFF222222);
  static const Color dark12dp = Color(0xFF242424);
  static const Color dark16dp = Color(0xFF252525);
  static const Color dark24dp = Color(0xFF262626);

  /// Light Mode Elevation (Slight Shadow Effect)
  static const Color light01dp = Color(0xFFE0E0E0);
  static const Color light02dp = Color(0xFFDDDDDD);
  static const Color light03dp = Color(0xFFCCCCCC);
  static const Color light04dp = Color(0xFFBBBBBB);
  static const Color light06dp = Color(0xFFAAAAAA);
  static const Color light08dp = Color(0xFF999999);
  static const Color light12dp = Color(0xFF888888);
  static const Color light16dp = Color(0xFF777777);
  static const Color light24dp = Color(0xFF666666);
}

/// Elevation Overlay for Dark Theme (`#121212` Background)
///
/// Elevation | Opacity | Calculated HEX  
/// ----------|---------|---------------  
/// 00dp      | 0%      | #121212  
/// 01dp      | 5%      | #1A1A1A  
/// 02dp      | 7%      | #1C1C1C  
/// 03dp      | 8%      | #1E1E1E  
/// 04dp      | 9%      | #1F1F1F  
/// 06dp      | 11%     | #212121  
/// 08dp      | 12%     | #222222  
/// 12dp      | 14%     | #242424  
/// 16dp      | 15%     | #252525  
/// 24dp      | 16%     | #262626  