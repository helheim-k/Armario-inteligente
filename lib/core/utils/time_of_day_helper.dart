import 'package:flutter/material.dart';

enum DayPeriod { morning, afternoon, night }

class TimeOfDayHelper {
  static DayPeriod current() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) return DayPeriod.morning;
    if (hour >= 12 && hour < 19) return DayPeriod.afternoon;
    return DayPeriod.night;
  }

  static String greetingPrefix() {
    switch (current()) {
      case DayPeriod.morning:
        return 'Buenos días';
      case DayPeriod.afternoon:
        return 'Buenas tardes';
      case DayPeriod.night:
        return 'Buenas noches';
    }
  }

  static IconData icon() {
    switch (current()) {
      case DayPeriod.morning:
        return Icons.wb_sunny_outlined;
      case DayPeriod.afternoon:
        return Icons.wb_cloudy_outlined;
      case DayPeriod.night:
        return Icons.nightlight_outlined;
    }
  }
}