import 'dart:io';
import '../../domain/repositories/book_repository.dart';
import '../models/book_model.dart';
import '../services/book_service.dart';

class BookRepositoryImpl implements BookRepository {
  final BookService _bookService = BookService();

  @override
  Stream<List<BookModel>> getAllBooks() => _bookService.getAllBooks();

  @override
  Stream<List<BookModel>> getUserBooks(String userId) => _bookService.getUserBooks(userId);

  @override
  Future<String> createBook({
    required String title,
    required String author,
    required String condition,
    required String ownerId,
    required String ownerName,
    File? imageFile,
    Map<String, dynamic>? sampleBookCover,
  }) => _bookService.createBook(
    title: title,
    author: author,
    condition: condition,
    ownerId: ownerId,
    ownerName: ownerName,
    imageFile: imageFile,
    sampleBookCover: sampleBookCover,
  );

  @override
  Future<void> updateBook({
    required String bookId,
    required String title,
    required String author,
    required String condition,
    File? imageFile,
    String? existingImageUrl,
    Map<String, dynamic>? sampleBookCover,
  }) => _bookService.updateBook(
    bookId: bookId,
    title: title,
    author: author,
    condition: condition,
    imageFile: imageFile,
    existingImageUrl: existingImageUrl,
    sampleBookCover: sampleBookCover,
  );

  @override
  Future<void> deleteBook(String bookId) => _bookService.deleteBook(bookId);
}