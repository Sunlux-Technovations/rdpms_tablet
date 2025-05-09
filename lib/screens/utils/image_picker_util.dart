import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerUtil {
static Future<File?> pickImage(BuildContext context) async {
  final picker = ImagePicker();

  return showModalBottomSheet<File?>(
    context: context,
    backgroundColor: Colors.white,
    builder: (context) => SizedBox(
      height: 160.h, 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          buildPickerOption(context, 'Camera', Icons.camera, () async {
            final picked = await picker.pickImage(source: ImageSource.camera);
            Navigator.pop(context, picked != null ? File(picked.path) : null);
          }),
          buildPickerOption(context, 'Gallery', Icons.photo, () async {
            final picked = await picker.pickImage(source: ImageSource.gallery);
            Navigator.pop(context, picked != null ? File(picked.path) : null);
          }),
        ],
      ),
    ),
  );
}


  static Widget buildPickerOption(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          child: CircleAvatar(
            radius: 30.r,
            child: Icon(icon, size: 24.r),
          ),
        ),
        SizedBox(height: 8.h),
        Text(label),
      ],
    );
  }
}
