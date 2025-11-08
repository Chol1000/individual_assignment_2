import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/book_model.dart';
import '../../core/constants/app_constants.dart';

class BookService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  Stream<List<BookModel>> getAllBooks() {
    return _firestore
        .collection(AppConstants.booksCollection)
        .snapshots()
        .map((snapshot) {
          final books = snapshot.docs
              .map((doc) => BookModel.fromMap(doc.data(), doc.id))
              .toList();
          books.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return books;
        });
  }

  Stream<List<BookModel>> getUserBooks(String userId) {
    return _firestore
        .collection(AppConstants.booksCollection)
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final books = snapshot.docs
              .map((doc) => BookModel.fromMap(doc.data(), doc.id))
              .toList();
          books.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return books;
        });
  }

  Future<String> createBook({
    required String title,
    required String author,
    required String condition,
    required String ownerId,
    required String ownerName,
    File? imageFile,
    Map<String, dynamic>? sampleBookCover,
  }) async {
    try {
      String? imageUrl;
      
      if (imageFile != null) {
        imageUrl = await _uploadImage(imageFile);
      } else if (sampleBookCover != null) {
        // For sample book covers, use the actual asset path
        imageUrl = sampleBookCover['image'] as String?;
      }

      final book = BookModel(
        id: '',
        title: title,
        author: author,
        condition: condition,
        imageUrl: imageUrl,
        ownerId: ownerId,
        ownerName: ownerName,
        createdAt: DateTime.now(),
      );

      final bookData = book.toMap();
      print('Creating book with data: $bookData'); // Debug log
      
      final docRef = await _firestore
          .collection(AppConstants.booksCollection)
          .add(bookData);

      print('Book created with Firestore ID: ${docRef.id}'); // Debug log
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create book: $e');
    }
  }

  Future<void> updateBook({
    required String bookId,
    required String title,
    required String author,
    required String condition,
    File? imageFile,
    String? existingImageUrl,
    Map<String, dynamic>? sampleBookCover,
  }) async {
    try {
      String? imageUrl = existingImageUrl;
      
      if (imageFile != null) {
        imageUrl = await _uploadImage(imageFile);
      } else if (sampleBookCover != null) {
        imageUrl = sampleBookCover['image'] as String?;
      }

      final updateData = {
        'title': title,
        'author': author,
        'condition': condition,
        'imageUrl': imageUrl,
      };
      
      print('Updating book $bookId with data: $updateData'); // Debug
      
      await _firestore
          .collection(AppConstants.booksCollection)
          .doc(bookId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update book: $e');
    }
  }

  Future<void> deleteBook(String bookId) async {
    try {
      await _firestore
          .collection(AppConstants.booksCollection)
          .doc(bookId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete book: $e');
    }
  }

  Future<BookModel?> getBook(String bookId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.booksCollection)
          .doc(bookId)
          .get();

      if (doc.exists) {
        return BookModel.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      throw Exception('Failed to get book: $e');
    }
    return null;
  }

  Future<String> _uploadImage(File imageFile) async {
    final fileName = '${_uuid.v4()}.jpg';
    final ref = _storage
        .ref()
        .child(AppConstants.bookImagesPath)
        .child(fileName);

    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }
}