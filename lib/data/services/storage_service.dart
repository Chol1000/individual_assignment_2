import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<String> uploadProfileImage(String filePath, String userId) async {
    final file = File(filePath);
    final ref = _storage.ref().child('profile_images').child('$userId.jpg');
    
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;
    
    return await snapshot.ref.getDownloadURL();
  }

  static Future<String> uploadBookImage(String filePath, String bookId) async {
    final file = File(filePath);
    final ref = _storage.ref().child('book_images').child('$bookId.jpg');
    
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;
    
    return await snapshot.ref.getDownloadURL();
  }

  static Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // Image might not exist or already deleted
      print('Error deleting image: $e');
    }
  }
}