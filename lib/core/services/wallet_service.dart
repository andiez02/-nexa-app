
// import 'package:walletconnect_dart/walletconnect_dart.dart';

// class WalletService {
//   WalletConnect? connector;
//   SessionStatus? session;

//   WalletService() {
//     connector = WalletConnect(
//       bridge: 'https://bridge.walletconnect.org',
//       clientMeta: PeerMeta(
//         name: 'Nexa',
//         description: 'Nexa',
//         url: 'https://nexa.io',
//       ),
//     );
//   }

// bool get isConnected => connector?.connected ?? false;
// String? get currentAccoutnt => session?.accounts[0];

//   Future<void> connect() async {
//     if (connector!.connected) return;

//     session = await connector!.createSession(
//       onDisplayUri: (uri) async {
//         await launchUrl(Uri.parse(uri), mode: LaunchMode.externalApplication);
//       },
//     );
//   }

//   void disconnect() {
//     connector?.killSession();
//     session = null;
//   }
// }
// }

