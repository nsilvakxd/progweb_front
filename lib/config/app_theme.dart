import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class AppTheme {
  // 1. Defina suas cores principais aqui
  static const Color primaryColor = Color(0xFF673AB7); // Roxo (Deep Purple)
  static const Color secondaryColor = Color(0xFF9575CD);
  static const Color backgroundColor = Color(0xFFF5F5F5); // Cinza claro de fundo
  static const Color errorColor = Color(0xFFD32F2F);

  // 2. Método para gerar o Tema
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      
      // Esquema de Cores
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        background: backgroundColor,
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
      ),

      // Tipografia (Google Fonts)
      textTheme: GoogleFonts.poppinsTextTheme(), // Ou Roboto, Lato, etc.

      // Estilo Global dos AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),

      // Estilo Global dos Botões (ElevatedButton)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white, // Cor do texto
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Borda arredondada
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Estilo Global dos Campos de Texto (InputDecoration)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none, // Sem borda quando inativo (estilo moderno)
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        labelStyle: TextStyle(color: Colors.grey.shade700),
      ),
      
      // Estilo dos Cards
      cardTheme: CardThemeData( // <--- Note o "Data" no final
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    );
  }
}