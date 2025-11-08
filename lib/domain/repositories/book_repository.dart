import 'dart:io';
import '../../data/models/book_model.dart';

abstract class BookRepository {
  Stream<List<BookModel>> getAllBooks();
  Stream<List<BookModel>> getUserBooks(String userId);
  Future<String> createBook({
    required String title,
    required String author,
    required String condition,
    required String ownerId,
    required String ownerName,
    File? imageFile,
    Map<String, dynamic>? sampleBookCover,
  });
  Future<void> updateBook({
    required String bookId,
    required String title,
    required String author,
    required String condition,
    File? imageFile,
    String? existingImageUrl,
    Map<String, dynamic>? sampleBookCover,
  });
  Future<void> deleteBook(String bookId);
}