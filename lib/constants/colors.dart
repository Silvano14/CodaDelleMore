import 'package:flutter/material.dart';

/// Palette colori ispirata all'etichetta "Coda delle More"
/// Chardonnay Traminer - Trevenezie
class AppColors {
  // Colori primari dall'etichetta

  /// Viola/Purple - colore dominante dell'etichetta
  static const Color primary = Color(0xFF7B68AE);

  /// Viola più scuro per contrasto
  static const Color primaryDark = Color(0xFF5D4E8C);

  /// Viola chiaro per sfondi
  static const Color primaryLight = Color(0xFFB8A9D6);

  /// Arancione - accento del sole nel logo
  static const Color accent = Color(0xFFE87722);

  /// Arancione chiaro/dorato - colore del vino
  static const Color accentLight = Color(0xFFF5A623);

  /// Arancione scuro per hover/press states
  static const Color accentDark = Color(0xFFD4651A);

  // Colori neutrali

  /// Testo scuro (viola molto scuro)
  static const Color textDark = Color(0xFF2D2344);

  /// Testo secondario
  static const Color textSecondary = Color(0xFF6B6180);

  /// Sfondo chiaro (argento/bianco dell'etichetta)
  static const Color background = Color(0xFFF8F7FA);

  /// Sfondo card
  static const Color surface = Color(0xFFFFFFFF);

  /// Bordi e divisori
  static const Color border = Color(0xFFE8E4EF);

  // Colori gradienti per le card eventi
  static const List<List<Color>> cardGradients = [
    [Color(0xFF7B68AE), Color(0xFF9B8BC8)], // Viola etichetta
    [Color(0xFFE87722), Color(0xFFF5A623)], // Arancione sole
    [Color(0xFF8B79B3), Color(0xFFB8A9D6)], // Viola chiaro
    [Color(0xFFD4651A), Color(0xFFE87722)], // Arancione intenso
    [Color(0xFF5D4E8C), Color(0xFF7B68AE)], // Viola scuro
  ];

  // Colori di stato
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFF5A623);
  static const Color info = Color(0xFF7B68AE);
}
