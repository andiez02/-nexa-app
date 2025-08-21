import 'package:flutter/foundation.dart';
import '../../app/constants.dart';
import '../../core/services/storage_service.dart';

/// App provider handles onboarding and app-level state
class AppProvider extends ChangeNotifier {
  final IStorageService _storageService;
  
  bool _isFirstLaunch = true;
  bool _isLoading = false;

  AppProvider(this._storageService);

  // Getters
  bool get isFirstLaunch => _isFirstLaunch;
  bool get isLoading => _isLoading;

  /// Initialize auth state from storage
  Future<void> initialize() async {
    _setLoading(true);
    try {
      // Check if it's first launch - if key doesn't exist, it's first launch
      final hasLaunched = await _storageService.getBool(AppConstants.firstLaunchKey);
      _isFirstLaunch = !hasLaunched;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing auth: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Mark onboarding as completed
  Future<void> completeOnboarding() async {
    try {
      await _storageService.setBool(AppConstants.firstLaunchKey, true);
      _isFirstLaunch = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error completing onboarding: $e');
      rethrow;
    }
  }

  /// Reset app state (useful for testing/development)
  Future<void> resetAppState() async {
    try {
      await _storageService.clear();
      _isFirstLaunch = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error resetting app state: $e');
      rethrow;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
