import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/constants.dart';

class MintForm extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController collectionController;
  final List<Map<String, String>> attributes;
  final Function(List<Map<String, String>>) onAttributesChanged;

  const MintForm({
    super.key,
    required this.nameController,
    required this.descriptionController,
    required this.collectionController,
    required this.attributes,
    required this.onAttributesChanged,
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
        ),
        
        const SizedBox(height: 20),
        
        // Collection
        _buildCollectionField(),
        
        const SizedBox(height: 24),
        
        // Attributes
        _buildAttributesSection(),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    String? Function(String?)? validator,
    int maxLines = 1,
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

  Widget _buildCollectionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Collection',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.gray300),
          ),
          child: DropdownButtonFormField<String>(
            value: widget.collectionController.text.isEmpty 
                ? null 
                : widget.collectionController.text,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
            hint: Text(
              'Select or create collection',
              style: GoogleFonts.inter(
                color: AppColors.gray500,
                fontSize: 14,
              ),
            ),
            items: [
              'My Collection',
              'Abstract Art',
              'Digital Photography',
              'Create New Collection',
            ].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: GoogleFonts.inter(fontSize: 14),
                ),
              );
            }).toList(),
            onChanged: (String? value) {
              if (value != null) {
                widget.collectionController.text = value;
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAttributesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Properties',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
            TextButton.icon(
              onPressed: _addAttribute,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Add properties that describe your NFT',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.gray500,
          ),
        ),
        const SizedBox(height: 12),
        
        if (widget.attributes.isNotEmpty) ...[
          ...widget.attributes.asMap().entries.map((entry) {
            final index = entry.key;
            final attribute = entry.value;
            return _buildAttributeItem(index, attribute);
          }),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.gray200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.category_outlined,
                  size: 32,
                  color: AppColors.gray400,
                ),
                const SizedBox(height: 8),
                Text(
                  'No properties added yet',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.gray600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAttributeItem(int index, Map<String, String> attribute) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              initialValue: attribute['trait_type'],
              decoration: InputDecoration(
                hintText: 'Property name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: AppColors.gray300),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.all(8),
              ),
              style: GoogleFonts.inter(fontSize: 12),
              onChanged: (value) {
                final updatedAttributes = [...widget.attributes];
                updatedAttributes[index]['trait_type'] = value;
                widget.onAttributesChanged(updatedAttributes);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              initialValue: attribute['value'],
              decoration: InputDecoration(
                hintText: 'Value',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: AppColors.gray300),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.all(8),
              ),
              style: GoogleFonts.inter(fontSize: 12),
              onChanged: (value) {
                final updatedAttributes = [...widget.attributes];
                updatedAttributes[index]['value'] = value;
                widget.onAttributesChanged(updatedAttributes);
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _removeAttribute(index),
            icon: Icon(Icons.delete_outline, size: 16, color: AppColors.error),
          ),
        ],
      ),
    );
  }

  void _addAttribute() {
    final updatedAttributes = [
      ...widget.attributes,
      {'trait_type': '', 'value': ''},
    ];
    widget.onAttributesChanged(updatedAttributes);
  }

  void _removeAttribute(int index) {
    final updatedAttributes = [...widget.attributes];
    updatedAttributes.removeAt(index);
    widget.onAttributesChanged(updatedAttributes);
  }
}
