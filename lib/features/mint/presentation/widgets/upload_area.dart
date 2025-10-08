import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/constants.dart';

class UploadArea extends StatelessWidget {
  final String? imagePath;
  final Function(String) onImageSelected;

  const UploadArea({
    super.key,
    required this.imagePath,
    required this.onImageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload NFT Image',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'File types supported: JPG, PNG, GIF, SVG. Max size: 100MB',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.gray500,
          ),
        ),
        const SizedBox(height: 12),
        
        GestureDetector(
          onTap: _selectImage,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: imagePath != null ? Colors.transparent : AppColors.gray100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.gray300,
                style: BorderStyle.solid,
              ),
              image: imagePath != null
                  ? DecorationImage(
                      image: AssetImage('assets/images/nft_image_1.png'), // Mock image
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imagePath == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.cloud_upload_outlined,
                          size: 40,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Drag & drop or click to upload',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.gray700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose file',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Stack(
                    children: [
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: GestureDetector(
                            onTap: () => onImageSelected(''),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  void _selectImage() {
    // Mock image selection
    onImageSelected('nft_image_1.png');
  }
}
