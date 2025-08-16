import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppProvider extends ChangeNotifier {
  bool _isFirstLaunch = true;
  bool _isWalletConnected = false;
  String _walletAddress = '';
  bool _isLoading = false;

  // Getters
  bool get isFirstLaunch => _isFirstLaunch;
  bool get isWalletConnected => _isWalletConnected;
  String get walletAddress => _walletAddress;
  bool get isLoading => _isLoading;

  // Initialize app state
  Future<void> initializeApp() async {
    _setLoading(true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _isFirstLaunch = prefs.getBool('first_launch') ?? true;
      _isWalletConnected = prefs.getBool('wallet_connected') ?? false;
      _walletAddress = prefs.getString('wallet_address') ?? '';
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing app: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Complete onboarding
  Future<void> completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('first_launch', false);
      _isFirstLaunch = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error completing onboarding: $e');
    }
  }

  // Connect wallet (placeholder for MetaMask integration)
  Future<bool> connectWallet() async {
    _setLoading(true);
    
    try {
      // TODO: Implement actual MetaMask connection
      // For now, simulate connection
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulate successful connection
      const simulatedAddress = '0x742d35Cc6633C0532925a3b8D87C8d0e77b7c8';
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('wallet_connected', true);
      await prefs.setString('wallet_address', simulatedAddress);
      
      _isWalletConnected = true;
      _walletAddress = simulatedAddress;
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error connecting wallet: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Disconnect wallet
  Future<void> disconnectWallet() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('wallet_connected', false);
      await prefs.setString('wallet_address', '');
      
      _isWalletConnected = false;
      _walletAddress = '';
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error disconnecting wallet: $e');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
