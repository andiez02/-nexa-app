import 'package:flutter/material.dart';

/// App-wide constants
class AppConstants {
  // App Info
  static const String appName = 'Nexa';
  static const String appVersion = '1.0.0';
  
  // API
  static const String baseUrl = 'https://api.nexa.io';
  static const Duration apiTimeout = Duration(seconds: 30);
  
  // Storage Keys
  static const String firstLaunchKey = 'first_launch';
  static const String walletConnectedKey = 'wallet_connected';
  static const String walletAddressKey = 'wallet_address';
  static const String themeKey = 'theme_mode';
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // UI
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double defaultElevation = 2.0;
  
  // Breakpoints
  static const double mobileBreakpoint = 768;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;
  
  // Private constructor to prevent instantiation
  AppConstants._();
}

/// App colors
class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryDark = Color(0xFF5A4FCF);
  static const Color primaryLight = Color(0xFF8B7ED8);
  
  // Secondary colors
  static const Color secondary = Color(0xFF00CEC9);
  static const Color secondaryDark = Color(0xFF00B894);
  static const Color secondaryLight = Color(0xFF55EAE7);
  
  // Neutral colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF2D3436);
  static const Color gray50 = Color(0xFFFDFDFD);
  static const Color gray100 = Color(0xFFF8F9FA);
  static const Color gray200 = Color(0xFFE9ECEF);
  static const Color gray300 = Color(0xFFDEE2E6);
  static const Color gray400 = Color(0xFFCED4DA);
  static const Color gray500 = Color(0xFFADB5BD);
  static const Color gray600 = Color(0xFF6C757D);
  static const Color gray700 = Color(0xFF495057);
  static const Color gray800 = Color(0xFF343A40);
  static const Color gray900 = Color(0xFF212529);
  
  // Status colors
  static const Color success = Color(0xFF00B894);
  static const Color error = Color(0xFFE17055);
  static const Color warning = Color(0xFFFDCB6E);
  static const Color info = Color(0xFF74B9FF);
  
  // Background colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF1A1A1A);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF2D3436);
  
  // Private constructor to prevent instantiation
  AppColors._();
}

/// App strings (can be moved to l10n later)
class AppStrings {
  // Onboarding
  static const String onboardingTitle1 = "Create Collects, Timeless Artworks";
  static const String onboardingSubtitle1 = "The world's largest digital marketplace for crypto collectibles and non-fungible tokens. Buy, sell, and discover exclusive digital items.";
  
  static const String onboardingTitle2 = "Secure Your Assests with the good one";
  static const String onboardingSubtitle2 = "OKNFT has partnered with some notable companies and recently partnered with Web3 Foundation to help secure non-fungible tokens artists' and creators' work.";
  
  static const String onboardingTitle3 = "Variety of cryptocurrency wallet";
  static const String onboardingSubtitle3 = "Supports more than 150 cryptocurrency wallet. For an introduction to the non-fungible tokens world, OKNFT is a great place to start.";
  
  // Get Started
  static const String getStartedTitle = "Get Started";
  static const String getStartedSubtitle = "Connect your wallet to hold your NFTs";
  static const String connectMetaMask = "Connect MetaMask Wallet";
  static const String skip = "Skip";
  
  // Home
  static const String homeWelcome = "Welcome back!";
  static const String totalBalance = "Total Balance";
  static const String myWallet = "My Wallet";
  static const String transactions = "Transactions";
  static const String settings = "Settings";
  
  // Common
  static const String next = "Next";
  static const String getStarted = "Get Started";
  static const String loading = "Loading...";
  static const String error = "Error";
  static const String retry = "Retry";
  static const String cancel = "Cancel";
  static const String confirm = "Confirm";
  
  // Private constructor to prevent instantiation
  AppStrings._();
}
