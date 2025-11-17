import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nexa_app/app/routes.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/constants.dart';
import '../../../wallet/wallet_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _walletAddress;
  String? _coverImage;
  String? _avatarImage;
  bool _isUploadingCover = false;
  bool _isUploadingAvatar = false;
  bool _hasChanges = false;

  static const String _storageBucket = 'profiles';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWalletData();
    });
  }

  Future<void> _loadWalletData() async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final walletAddress = walletProvider.walletAddress;
    setState(() {
      _walletAddress = walletAddress;
    });
    if (walletAddress != null && walletAddress.isNotEmpty) {
      await _loadExistingAssets(walletAddress);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, provider, child) {
        final walletAddress = provider.walletAddress ?? _walletAddress ?? '';

        return Scaffold(
          backgroundColor: AppColors.gray50,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(0, 8, 0, 28),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFFDFDFE), Color(0xFFF4F6F8)],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSimpleAppBar(),
                          const SizedBox(height: 16),
                          _buildCoverSection(walletAddress),
                          const SizedBox(height: 64),
                          _buildIdentityCard(walletAddress),
                          const SizedBox(height: 32),
                          _buildActionButtons(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoverSection(String walletAddress) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _coverImage != null
                      ? [AppColors.gray700, AppColors.gray900]
                      : [AppColors.primary, AppColors.primaryDark],
                ),
              ),
              child: Stack(
                children: [
                  if (_coverImage != null)
                    Positioned.fill(
                      child: Image.network(_coverImage!, fit: BoxFit.cover),
                    ),
                  if (_isUploadingCover)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.4),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: ElevatedButton.icon(
                      onPressed: _changeCoverImage,
                      icon: const Icon(Icons.image_outlined, size: 18),
                      label: const Text('Change Cover'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: AppColors.white,
                        backgroundColor: Colors.white.withOpacity(0.12),
                        shadowColor: Colors.transparent,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile',
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Manage how the community sees you',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -48,
            left: 32,
            child: GestureDetector(
              onTap: _changeAvatarImage,
              behavior: HitTestBehavior.translucent,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 44,
                      backgroundImage: _avatarImage != null
                          ? NetworkImage(_avatarImage!)
                          : null,
                      backgroundColor: AppColors.primary,
                      child: _avatarImage == null
                          ? Text(
                              walletAddress.isNotEmpty
                                  ? walletAddress.substring(2, 3).toUpperCase()
                                  : 'N',
                              style: GoogleFonts.inter(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                  ),
                  if (_isUploadingAvatar)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityCard(String walletAddress) {
    final isConnected = walletAddress.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.wallet_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wallet Address',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray900,
                        ),
                      ),
                      Text(
                        isConnected
                            ? 'Tap copy button to share your wallet'
                            : 'No wallet connected',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isConnected
                          ? walletAddress
                          : 'Connect your wallet to view full address',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.gray800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: isConnected
                        ? () => _copyToClipboard(walletAddress)
                        : null,
                    icon: Icon(
                      Icons.copy_outlined,
                      color: isConnected
                          ? AppColors.gray500
                          : AppColors.gray300,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _hasChanges ? _saveChanges : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Save Changes'),
        ),
      ),
    );
  }

  Widget _buildSimpleAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
              Text(
                'Customize your public identity',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.gray500,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.settings_outlined,
                color: AppColors.gray700,
              ),
              onPressed: _openSettings,
            ),
          ),
        ],
      ),
    );
  }

  void _changeCoverImage() {
    _pickAndUploadImage(isCover: true);
  }

  void _changeAvatarImage() {
    _pickAndUploadImage(isCover: false);
  }

  Future<void> _saveChanges() async {
    await _syncProfileRecord();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile changes saved')));
    setState(() {
      _hasChanges = false;
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Address copied to clipboard!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _pickAndUploadImage({required bool isCover}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (pickedFile == null) {
      return;
    }

    final wallet = _walletAddress;
    if (wallet == null || wallet.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connect wallet before uploading.')),
      );
      return;
    }

    setState(() {
      if (isCover) {
        _isUploadingCover = true;
      } else {
        _isUploadingAvatar = true;
      }
    });

    try {
      final fileBytes = await File(pickedFile.path).readAsBytes();
      final fileExt = pickedFile.path.split('.').last;
      final fileName =
          '${isCover ? 'cover' : 'avatar'}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final storagePath = '$wallet/$fileName';

      final supabase = Supabase.instance.client;
      await supabase.storage
          .from(_storageBucket)
          .uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: pickedFile.mimeType ?? 'image/$fileExt',
            ),
          );

      final publicUrl = supabase.storage
          .from(_storageBucket)
          .getPublicUrl(storagePath);

      setState(() {
        if (isCover) {
          _coverImage = publicUrl;
        } else {
          _avatarImage = publicUrl;
        }
        _hasChanges = true;
      });
      await _syncProfileRecord();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCover
                ? 'Cover updated successfully!'
                : 'Avatar updated successfully!',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          if (isCover) {
            _isUploadingCover = false;
          } else {
            _isUploadingAvatar = false;
          }
        });
      }
    }
  }

  Future<void> _loadExistingAssets(String walletAddress) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('profiles')
          .select('cover_url, avatar_url')
          .eq('wallet_address', walletAddress)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _coverImage = response['cover_url'] as String?;
          _avatarImage = response['avatar_url'] as String?;
        });
      }
    } catch (e) {
      debugPrint('Failed to load profile assets: $e');
    }
  }

  Future<void> _syncProfileRecord() async {
    final wallet = _walletAddress;
    if (wallet == null || wallet.isEmpty) return;

    try {
      await Supabase.instance.client.from('profiles').upsert({
        'wallet_address': wallet,
        'cover_url': _coverImage,
        'avatar_url': _avatarImage,
      }, onConflict: 'wallet_address');
    } catch (e) {
      debugPrint('Failed to save profile asset: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sync failed: $e')));
      }
    }
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool notificationsEnabled = true;
        bool biometricEnabled = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 30,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 48,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.gray200,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.tune,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Profile Settings',
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.black,
                                    ),
                                  ),
                                  Text(
                                    'Manage your preferences & privacy',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.gray500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.gray100),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Column(
                          children: [
                            _buildSettingsSwitchTile(
                              title: 'Marketplace Notifications',
                              subtitle: 'Stay updated with bids & sales',
                              value: notificationsEnabled,
                              onChanged: (value) {
                                setModalState(() {
                                  notificationsEnabled = value;
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildSettingsSwitchTile(
                              title: 'Biometric Confirmation',
                              subtitle: 'Use Face ID / Touch ID for actions',
                              value: biometricEnabled,
                              onChanged: (value) {
                                setModalState(() {
                                  biometricEnabled = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.gray100),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Column(
                          children: [
                            _buildSettingsActionTile(
                              icon: Icons.security,
                              iconColor: AppColors.secondary,
                              title: 'Security & Protection',
                              subtitle: 'Recovery phrase, device access',
                              onTap: () => _showComingSoon('Security settings'),
                            ),
                            const SizedBox(height: 12),
                            _buildSettingsActionTile(
                              icon: Icons.palette_outlined,
                              iconColor: AppColors.primary,
                              title: 'Theme & Appearance',
                              subtitle: 'Dark mode, accent colors',
                              onTap: () => _showComingSoon('Theme settings'),
                            ),
                            const SizedBox(height: 12),
                            _buildSettingsActionTile(
                              icon: Icons.logout,
                              iconColor: AppColors.error,
                              title: 'Disconnect Wallet',
                              subtitle: 'Log out from current session',
                              onTap: () {
                                Navigator.of(context).pop();
                                _logout();
                              },
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _showComingSoon('Wallet settings'),
                            icon: const Icon(Icons.wallet_outlined, size: 18),
                            label: const Text('Manage Wallet'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSettingsSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.gray100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: AppColors.gray800,
      ),
    );
  }

  Future<void> _logout() async {
    final provider = context.read<WalletProvider>();
    await provider.disconnect();
    if (!mounted) return;
    context.go(AppRoutes.getStarted);
  }
}
