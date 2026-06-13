import 'dart:io';

import 'package:flutter/material.dart';

Future<void> showImagePreview(BuildContext context, String imagePath, {String? title}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.9),
    builder: (context) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          title: Text(title ?? 'Photo preview'),
        ),
        body: SafeArea(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Hero(
                  tag: imagePath,
                  child: Image.file(File(imagePath), fit: BoxFit.contain),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
