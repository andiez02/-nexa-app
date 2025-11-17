import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/constants.dart';

class MintForm extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController descriptionController;

  const MintForm({
    super.key,
    required this.nameController,
    required this.descriptionController,
  });

  @override
  State<MintForm> createState() => _MintFormState();
}

class _MintFormState extends State<MintForm> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // NFT Name
        _buildTextField(
          label: 'NFT Name *',
          hint: 'Enter NFT name',
          controller: widget.nameController,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Please enter NFT name';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 20),
        
        // Description
        _buildTextField(
          label: 'Description',
          hint: 'Provide a detailed description of your NFT',
          controller: widget.descriptionController,
          maxLines: 4,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
        ),
        
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputAction textInputAction = TextInputAction.done,
    void Function(String)? onFieldSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: AppColors.gray500,
              fontSize: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.gray300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.gray300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
          ),
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.black,
          ),
        ),
      ],
    );
  }

  // Collection and Properties removed for Sepolia-only MVP
}
