import 'package:flutter/material.dart';
import 'package:reown_appkit/reown_appkit.dart';

class WalletProvider extends ChangeNotifier {
  late final ReownAppKitModal _appKitModal;
  SessionData? _session;
  bool _isInitialized = false;

  SessionData? get session => _session;
  bool get isConnected => _session != null;

  static const String projectId = 'be2f3ed58f943aa53db990ddff2a31b5';

  Future<void> initAppKit(BuildContext context) async {
    if (_isInitialized) {
      debugPrint("⚠️ AppKit already initialized");
      return;
    }

    debugPrint("🚀 Initializing AppKit...");

    final appKit = await ReownAppKit.createInstance(
      logLevel: LogLevel.debug,
      projectId: projectId,
      metadata: const PairingMetadata(
        name: 'Nexa App',
        description: 'Nexa App for NFT',
        url: 'https://github.com/andiez02/-nexa-app',
        icons: [
          'https://github.com/andiez02/-nexa-app/blob/main/assets/images/icon.jpg',
        ],
        redirect: Redirect(
          native: 'nexanft://home',
          universal: 'https://github.com/andiez02/-nexa-app/home',
          linkMode: false,
        ),
      ),
    );

    debugPrint("✅ AppKit instance created");

    if (!context.mounted) {
      debugPrint("⛔ Context is not mounted, stopping init");
      return;
    }
    _appKitModal = ReownAppKitModal(
      context: context,
      appKit: appKit,
      featuredWalletIds: {
        // MetaMask id
        'c57ca95b47569778a828d19178114f4db188b89b763c899ba0be274e97267d96',
        // Rainbow Wallet ID
        '1ae92b26df02f0abca6304df07debccd18262fdf5fe82daa81593582dac9a369',
      },
      includedWalletIds: {
        'c57ca95b47569778a828d19178114f4db188b89b763c899ba0be274e97267d96',
        '1ae92b26df02f0abca6304df07debccd18262fdf5fe82daa81593582dac9a369',
      },
    );

    await _appKitModal.init();
    debugPrint("✅ AppKitModal initialized");
    appKit.onSessionConnect.subscribe((event) {
      _session = event.session;
      debugPrint("🔗 Session connected: ${event.session.topic}");
      notifyListeners();
    });

    appKit.onSessionDelete.subscribe((event) {
      debugPrint("❌ Session deleted: ${event.topic}");
      _session = null;
      notifyListeners();
    });

    _isInitialized = true;

    debugPrint("🎉 AppKit fully initialized");
  }

  Future<void> connectToWallet(BuildContext context) async {
    await initAppKit(context);
    debugPrint("🟢 Opening wallet modal...");

    try {
      // Check if already connected
      if (_session != null) {
        debugPrint("🔗 Already connected to: ${_session!.topic}");
        return;
      }

      // Open modal and wait a bit
      _appKitModal.openModalView();
      debugPrint("📱 Modal opened, waiting for user interaction...");
    } catch (e) {
      debugPrint("❌ Error opening modal: $e");
    }
  }

  Future<void> disconnect() async {
    if (_session != null) {
      debugPrint("👋 Disconnecting session: ${_session?.topic}");
      await _appKitModal.appKit?.disconnectSession(
        topic: _session!.topic,
        reason: Errors.getSdkError(Errors.USER_DISCONNECTED).toSignError(),
      );
      _session = null;
      debugPrint("✅ Disconnected");
      notifyListeners();
    }
  }

  // Future<void> getWalletInfo() async {
  //   if (_appKitModal.appKit != null) {
  //     final session = _appKitModal.session!;

  //     final accounts = session.namespaces!['eip155']?.accounts ?? [];

  //     if (accounts.isNotEmpty) {
  //       // account format: "eip155:chainId:0xWalletAddress"
  //       final parts = accounts.first.split(":");

  //       final chainId = parts[1];
  //       final address = parts[2];

  //       debugPrint("✅ Address: $address");
  //       debugPrint("🌐 Chain ID: $chainId");
  //     }
  //   } else {
  //     debugPrint("⚠️ Chưa có session ví nào.");
  //   }
  // }

  String? get walletAddress {
    if (_session == null) return null;
    return _session!.namespaces["eip155"]?.accounts.first.split(":").last;
  }
}
