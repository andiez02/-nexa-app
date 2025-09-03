import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nexa_app/app/constants.dart';
import 'package:nexa_app/core/services/pinata_service.dart';

class MintNFTPage extends StatefulWidget {
  const MintNFTPage({super.key});

  @override
  State<MintNFTPage> createState() => _MintNFTPageState();
}

class _MintNFTPageState extends State<MintNFTPage> {
  final ImagePicker _picker = ImagePicker();
  late final PinataService _pinataService;
  File? _imageFile;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _nameFieldKey = GlobalKey();
  final GlobalKey _descriptionFieldKey = GlobalKey();
  String _status = 'No image selected.';
  String? _imageCid;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _pinataService = PinataService();

    // Add focus listeners for onBlur functionality
    _nameFocus.addListener(_onNameFocusChange);
    _descriptionFocus.addListener(_onDescriptionFocusChange);
  }

  void _onNameFocusChange() {
    if (_nameFocus.hasFocus) {
      _scrollToField(_nameFieldKey);
    } else {
      // onBlur for name field - you can add validation here
      setState(() {}); // Refresh UI if needed
    }
  }

  void _onDescriptionFocusChange() {
    if (_descriptionFocus.hasFocus) {
      _scrollToField(_descriptionFieldKey);
    } else {
      // onBlur for description field - you can add validation here
      setState(() {}); // Refresh UI if needed
    }
  }

  void _scrollToField(GlobalKey fieldKey) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? renderBox =
          fieldKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final position = renderBox.localToGlobal(Offset.zero);
        final screenHeight = MediaQuery.of(context).size.height;
        final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
        final bottomBarHeight = 86.0;

        // Calculate available screen height after keyboard and bottom bar
        final availableHeight = screenHeight - keyboardHeight - bottomBarHeight;

        // Target position: higher up (1/3 from top of available screen)
        final targetY = availableHeight / 3;

        // Current field position relative to scroll
        final fieldHeight = renderBox.size.height;
        final scrollOffset = position.dy - targetY + (fieldHeight / 2);

        // Animate to center the field
        _scrollController.animateTo(
          (_scrollController.offset + scrollOffset).clamp(
            0.0,
            _scrollController.position.maxScrollExtent,
          ),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    // Remove focus listeners to prevent memory leaks
    _nameFocus.removeListener(_onNameFocusChange);
    _descriptionFocus.removeListener(_onDescriptionFocusChange);

    _nameController.dispose();
    _descriptionController.dispose();
    _nameFocus.dispose();
    _descriptionFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _status = 'Image selected successfully.';
      });
    }
  }

  Future<void> _uploadToPinata() async {
    if (_imageFile == null) {
      setState(() {
        _status = 'Please select an image first.';
      });
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _status = 'Please enter NFT name.';
      });
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      setState(() {
        _status = 'Please enter NFT description.';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _status = 'Uploading to IPFS...';
    });

    try {
      final String imageCid = await _pinataService.uploadImage(_imageFile!);
      setState(() {
        _imageCid = imageCid;
        _status = 'Image uploaded successfully!';
      });
    } catch (e) {
      setState(() {
        _status = 'Error occurred: $e';
        _isUploading = false;
      });
    }
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final bottomNavHeight = 86.0;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: GestureDetector(
        onTap: _dismissKeyboard,
        child: SafeArea(
          bottom:
              false, // Don't apply SafeArea to bottom since we have fixed bottom bar
          child: SingleChildScrollView(
            controller: _scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom:
                  bottomNavHeight +
                  (keyboardHeight > 0 ? keyboardHeight + 10 : 20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Create New NFT",
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Upload Image Button
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _pickImage,
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              color: AppColors.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Select Image from Gallery",
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Image Preview
                if (_imageFile != null)
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        _imageFile!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // NFT Name Field
                Container(
                  key: _nameFieldKey,
                  child: _buildTextField(
                    controller: _nameController,
                    focusNode: _nameFocus,
                    label: "NFT Name",
                    hint: "Enter your NFT name",
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.text,
                    onFieldSubmitted: () =>
                        FocusScope.of(context).requestFocus(_descriptionFocus),
                  ),
                ),

                const SizedBox(height: 16),

                // Description Field
                Container(
                  key: _descriptionFieldKey,
                  child: _buildTextField(
                    controller: _descriptionController,
                    focusNode: _descriptionFocus,
                    label: "Description",
                    hint: "Describe your artwork",
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                    keyboardType: TextInputType.multiline,
                    onFieldSubmitted: () => _dismissKeyboard(),
                  ),
                ),

                const SizedBox(height: 30),

                // Upload Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _uploadToPinata,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: AppColors.primary.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isUploading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Uploading to IPFS...",
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.cloud_upload, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                "Upload to Pinata",
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // Status Display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusColor().withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _status,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Image CID Display
                if (_imageCid != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.success.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Image CID:",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          _imageCid!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.success,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (_status.contains('Error') || _status.contains('Please')) {
      return AppColors.error;
    } else if (_status.contains('successfully') ||
        _status.contains('NFT created')) {
      return AppColors.success;
    } else if (_status.contains('Uploading')) {
      return AppColors.warning;
    }
    return AppColors.info;
  }
}

// Text Field with Controller
Widget _buildTextField({
  required TextEditingController controller,
  required String label,
  required String hint,
  FocusNode? focusNode,
  int maxLines = 1,
  TextInputAction textInputAction = TextInputAction.done,
  TextInputType keyboardType = TextInputType.text,
  VoidCallback? onFieldSubmitted,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
      ),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          maxLines: maxLines,
          textInputAction: textInputAction,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.black,
          ),
          onSubmitted: (_) => onFieldSubmitted?.call(),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 15,
              color: AppColors.gray400,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.gray200, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: maxLines > 1 ? 16 : 18,
            ),
          ),
        ),
      ),
    ],
  );
}

// Legacy function wrapper for compatibility
Widget buildMintNFTTab() {
  return const MintNFTPage();
}
