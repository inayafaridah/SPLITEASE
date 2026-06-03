import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

class ThemeProvider extends ChangeNotifier {
  String _theme = 'purple';
  final PreferencesService _prefs = PreferencesService();

  String get theme => _theme;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    _theme = await _prefs.getColorTheme();
    notifyListeners();
  }

  Future<void> setTheme(String themeName) async {
    _theme = themeName;
    await _prefs.setColorTheme(themeName);
    notifyListeners();
  }

  Color get primaryColor {
    switch (_theme) {
      case 'blue':
        return Colors.blue.shade700;
      case 'green':
        return Colors.green.shade700;
      case 'purple':
      default:
        return const Color(0xFF4A00E0);
    }
  }

  Color get gradientEndColor {
    switch (_theme) {
      case 'blue':
        return Colors.blue.shade400;
      case 'green':
        return Colors.green.shade400;
      case 'purple':
      default:
        return const Color(0xFF8E2DE2);
    }
  }
}
