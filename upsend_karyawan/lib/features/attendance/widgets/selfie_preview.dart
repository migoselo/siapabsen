import 'dart:io';
import 'package:flutter/material.dart';

class SelfiePreview extends StatelessWidget {
  final File? photoFile;

  const SelfiePreview({super.key, this.photoFile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.45,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.shade100,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: photoFile != null
            ? Image.file(photoFile!, fit: BoxFit.cover)
            : Image.network(
                'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=1000',
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}
