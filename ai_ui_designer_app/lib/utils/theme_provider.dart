import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  // 🔥 Set default to Light mode instead of System
  ThemeMode _currentTheme = ThemeMode.light;

  // Getter to let main.dart know what theme to show
  ThemeMode get currentTheme => _currentTheme;

  // Toggle between Light and Dark mode only (no system mode)
  void toggleTheme() {
    // If it's currently light, switch to dark
    if (_currentTheme == ThemeMode.light) {
      _currentTheme = ThemeMode.dark;
    } 
    // Otherwise, switch back to light
    else {
      _currentTheme = ThemeMode.light;
    }
    
    // 🔥 This tells the whole app to rebuild instantly
    notifyListeners(); 
  }
  
  // Optional: Method to explicitly set light mode
  void setLightMode() {
    if (_currentTheme != ThemeMode.light) {
      _currentTheme = ThemeMode.light;
      notifyListeners();
    }
  }
  
  // Optional: Method to explicitly set dark mode
  void setDarkMode() {
    if (_currentTheme != ThemeMode.dark) {
      _currentTheme = ThemeMode.dark;
      notifyListeners();
    }
  }
}