import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/book_model.dart';
import '../../domain/repositories/book_repository.dart';
import '../../data/repositories/book_repository_impl.dart';

class BookProvider extends ChangeNotifier {
  final BookRepository _bookRepository = BookRepositoryImpl();
  
  List<BookModel> _allBooks = [];
  List<BookModel> _userBooks = [];
  bool _isLoading = false;
  String? _error;

  List<BookModel> get books => _allBooks;
  List<BookModel> get allBooks => _allBooks;
  List<BookModel> get userBooks => _userBooks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadBooks() async {
    try {
      _clearError();
      listenToAllBooks();
    } catch (e) {
      _setError(e.toString());
    }
  }

  void listenToAllBooks() {
    _clearError();
    _bookRepository.getAllBooks().listen((books) {
      _allBooks = books;
      notifyListeners();
    });
  }

  void listenToUserBooks(String userId) {
    _bookRepository.getUserBooks(userId).listen((books) {
      _userBooks = books;
      notifyListeners();
    });
  }

  Future<bool> createBook({
    required String title,
    required String author,
    required String condition,
    required String ownerId,
    required String ownerName,
    File? imageFile,
    Map<String, dynamic>? sampleBookCover,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      final bookId = await _bookRepository.createBook(
        title: title,
        author: author,
        condition: condition,
        ownerId: ownerId,
        ownerName: ownerName,
        imageFile: imageFile,
        sampleBookCover: sampleBookCover,
      );
      
      print('Book created with ID: $bookId'); // Debug log
      
      _setLoading(false);
      return true;
    } catch (e) {
      print('Error creating book: $e'); // Debug log
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateBook({
    required String bookId,
    required String title,
    required String author,
    required String condition,
    File? imageFile,
    String? existingImageUrl,
    Map<String, dynamic>? sampleBookCover,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _bookRepository.updateBook(
        bookId: bookId,
        title: title,
        author: author,
        condition: condition,
        imageFile: imageFile,
        existingImageUrl: existingImageUrl,
        sampleBookCover: sampleBookCover,
      );
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteBook(String bookId) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _bookRepository.deleteBook(bookId);
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() => _clearError();


}