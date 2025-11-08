import 'dart:io';
import 'package:flutter/material.dart';

class FormProvider extends ChangeNotifier {
  String _title = '';
  String _author = '';
  String _condition = 'New';
  File? _selectedImage;
  Map<String, dynamic>? _selectedBookCover;
  bool _isLoading = false;

  String get title => _title;
  String get author => _author;
  String get condition => _condition;
  File? get selectedImage => _selectedImage;
  Map<String, dynamic>? get selectedBookCover => _selectedBookCover;
  bool get isLoading => _isLoading;

  void setTitle(String value) {
    _title = value;
    notifyListeners();
  }

  void setAuthor(String value) {
    _author = value;
    notifyListeners();
  }

  void setCondition(String value) {
    _condition = value;
    notifyListeners();
  }

  void setSelectedImage(File? image) {
    _selectedImage = image;
    _selectedBookCover = null;
    notifyListeners();
  }

  void setSelectedBookCover(Map<String, dynamic>? cover) {
    _selectedBookCover = cover;
    _selectedImage = null;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void initializeForEdit(String title, String author, String condition) {
    _title = title;
    _author = author;
    _condition = condition;
    notifyListeners();
  }

  void reset() {
    _title = '';
    _author = '';
    _condition = 'New';
    _selectedImage = null;
    _selectedBookCover = null;
    _isLoading = false;
    notifyListeners();
  }
}