# Nexa App - Modern Flutter Architecture

## 📋 Tổng quan

Nexa App là một ứng dụng Flutter được xây dựng theo kiến trúc hiện đại, scalable và maintainable. Ứng dụng tập trung vào việc kết nối ví MetaMask và quản lý NFTs.

## 🏗️ Kiến trúc

Project sử dụng **Feature-based Architecture** kết hợp với **Clean Architecture principles**:

- ✅ **Tách biệt rõ ràng**: Mỗi feature có data, domain, presentation layer riêng
- ✅ **Scalable**: Dễ dàng thêm features mới mà không ảnh hưởng code cũ  
- ✅ **Testable**: Mỗi layer có thể test độc lập
- ✅ **Maintainable**: Code được tổ chức logic, dễ bảo trì

## 📁 Cấu trúc thư mục

```
lib/
│
├── main.dart                    # 🚀 Entry point của ứng dụng
│
├── app/                         # 🔧 App-level configuration
│   ├── app.dart                 # Khởi tạo MaterialApp, providers
│   ├── routes.dart              # Định nghĩa routes và navigation
│   ├── theme.dart               # Theme configuration (light/dark)
│   └── constants.dart           # App constants, colors, strings
│
├── core/                        # 🏛️ Core layer - Shared components
│   ├── config/
│   │   └── app_config.dart      # Environment & build configurations
│   ├── services/
│   │   └── storage_service.dart # SharedPreferences wrapper
│   ├── utils/                   # Utility functions
│   └── widgets/                 # Reusable UI components
│
├── features/                    # 🎯 Feature-based modules
│   ├── app/                     # App-level state management
│   │   ├── app_provider.dart    # Onboarding & app state
│   │   ├── data/                # App data layer
│   │   ├── domain/              # App business logic
│   │   └── presentation/        # App UI components
│   │       └── screens/
│   │           └── get_started_screen.dart
│   │
│   ├── onboarding/              # Onboarding flow
│   │   ├── data/                # Onboarding data layer
│   │   ├── domain/              # Onboarding business logic  
│   │   └── presentation/        # Onboarding UI
│   │       └── screens/
│   │           └── onboarding_screen.dart
│   │
│   └── wallet/                  # Wallet & MetaMask integration
│       ├── wallet_provider.dart # Wallet state management
│       ├── data/                # Wallet data layer
│       ├── domain/              # Wallet business logic
│       └── presentation/        # Wallet UI
│           ├── screens/
│           │   └── home_screen.dart
│           └── widgets/
│               └── wallet_card.dart
│
├── l10n/                        # 🌍 Internationalization
│
└── injection.dart               # 💉 Dependency injection setup
```

## 🔧 Chi tiết từng thành phần

### 📱 App Layer (`lib/app/`)

**Mục đích**: Cấu hình toàn bộ ứng dụng

| File | Mô tả |
|------|-------|
| `app.dart` | Khởi tạo MaterialApp, setup providers, routing |
| `routes.dart` | Định nghĩa tất cả routes, navigation logic |
| `theme.dart` | Light/dark theme configuration |
| `constants.dart` | Colors, strings, app constants |

### 🏛️ Core Layer (`lib/core/`)

**Mục đích**: Shared components không phụ thuộc vào business logic

| Thành phần | Mô tả |
|------------|-------|
| `config/` | Environment configurations |
| `services/` | Core services (storage, network, etc.) |
| `utils/` | Helper functions, extensions |
| `widgets/` | Reusable UI components |

#### 📄 `storage_service.dart`
```dart
abstract class IStorageService {
  Future<void> setBool(String key, bool value);
  Future<bool> getBool(String key, {bool defaultValue = false});
  // ... other methods
}
```

### 🎯 Features Layer (`lib/features/`)

**Mục đích**: Feature-based modules theo Clean Architecture

#### 🔐 App Feature (`lib/features/app/`)
- **Responsibility**: Quản lý app-level state (onboarding, first launch)
- **Provider**: `AppProvider` - handle onboarding completion
- **Key Methods**: 
  - `completeOnboarding()`
  - `resetAppState()`

#### 🎨 Onboarding Feature (`lib/features/onboarding/`)
- **Responsibility**: Giới thiệu ứng dụng cho người dùng mới
- **Screens**: `OnboardingScreen` với 3 slides giới thiệu
- **Integration**: Sử dụng `AppProvider` để mark onboarding complete

#### 💰 Wallet Feature (`lib/features/wallet/`)
- **Responsibility**: Kết nối & quản lý ví MetaMask
- **Provider**: `WalletProvider` - handle wallet connection state
- **Key Features**:
  - MetaMask connection simulation
  - Wallet address display
  - Balance management
  - Transaction history UI

## 🔄 Data Flow

```
UI (Screens/Widgets) 
    ↕ 
Provider (State Management)
    ↕
Service (Core Services)
    ↕
Storage/External APIs
```

## 📦 Dependencies

### Core Dependencies
```yaml
dependencies:
  flutter: sdk
  provider: ^6.1.5          # State management
  go_router: ^16.1.0        # Navigation
  get_it: ^8.0.2           # Dependency injection
  shared_preferences: ^2.5.3 # Local storage
  google_fonts: ^6.3.0     # Typography
```

### UI Dependencies
```yaml
  flutter_svg: ^2.2.0      # SVG support
  cupertino_icons: ^1.0.8  # iOS icons
```

### Web3 Dependencies
```yaml
  web3dart: ^2.6.0         # Ethereum integration
  http: ^1.5.0             # HTTP client
```

## 🚀 Cách sử dụng

### 1. Khởi chạy ứng dụng
```bash
flutter pub get
flutter run
```

### 2. Thêm feature mới

1. Tạo thư mục trong `lib/features/new_feature/`
2. Tạo structure:
   ```
   new_feature/
   ├── new_feature_provider.dart
   ├── data/
   ├── domain/
   └── presentation/
       ├── screens/
       └── widgets/
   ```
3. Register provider trong `injection.dart`
4. Thêm routes trong `app/routes.dart`

### 3. Thêm service mới

1. Tạo interface trong `core/services/`
2. Implement concrete class
3. Register trong `injection.dart`
4. Inject vào providers cần thiết

## 🧪 Testing

### Unit Tests
```bash
flutter test
```

### Widget Tests
```bash
flutter test test/widget_test.dart
```

## 🔧 Development

### Thêm màu mới
```dart
// lib/app/constants.dart
class AppColors {
  static const Color newColor = Color(0xFF123456);
}
```

### Thêm string mới
```dart
// lib/app/constants.dart
class AppStrings {
  static const String newString = "New string content";
}
```

## 📊 State Management

### Provider Pattern
- **AppProvider**: App-level state (onboarding, settings)
- **WalletProvider**: Wallet connection, balance, transactions
- **Future providers**: Authentication, NFT management, etc.

### Dependency Injection
```dart
// lib/injection.dart
getIt.registerLazySingleton<AppProvider>(() => 
  AppProvider(getIt<IStorageService>())
);
```

## 🔮 Roadmap

### Phase 1 ✅ (Completed)
- [x] Modern architecture setup
- [x] Feature-based structure
- [x] Onboarding flow
- [x] Basic wallet connection UI

### Phase 2 🚧 (In Progress)
- [ ] Real MetaMask integration
- [ ] Authentication system
- [ ] User profiles

### Phase 3 📋 (Planned)
- [ ] NFT marketplace
- [ ] Transaction history
- [ ] Multi-wallet support

## 🤝 Contributing

1. Fork project
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Follow existing architecture patterns
4. Add tests for new features
5. Commit changes (`git commit -m 'Add amazing feature'`)
6. Push to branch (`git push origin feature/amazing-feature`)
7. Open Pull Request

## 📝 Best Practices

### 1. Naming Conventions
- **Files**: snake_case (`user_profile_screen.dart`)
- **Classes**: PascalCase (`UserProfileScreen`)
- **Variables**: camelCase (`userProfile`)
- **Constants**: UPPER_CASE (`API_BASE_URL`)

### 2. Architecture Rules
- ✅ **DO**: Keep business logic in providers
- ✅ **DO**: Use dependency injection for services
- ✅ **DO**: Follow single responsibility principle
- ❌ **DON'T**: Put business logic in widgets
- ❌ **DON'T**: Access services directly from UI

### 3. Import Organization
```dart
// 1. Flutter imports
import 'package:flutter/material.dart';

// 2. Package imports  
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

// 3. Relative imports
import '../../app/constants.dart';
import '../providers/wallet_provider.dart';
```

---

**📞 Contact**: [Your contact information]  
**📄 License**: [Your license]  
**🌟 Give it a star if you found this helpful!**