import 'package:flutter/material.dart';

class VaultProvider extends ChangeNotifier {
  final List<String> _savedImages = [];

  List<String> get savedImages => _savedImages;


  void addImageToVault(String imageUrl) {
    _savedImages.add(imageUrl);

    notifyListeners(); 
  }
}