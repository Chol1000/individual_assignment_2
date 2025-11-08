import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Clean up demo books that don't belong to real users
  Future<void> cleanupDemoBooks() async {
    try {
      // Get all books
      final booksSnapshot = await _firestore
          .collection(AppConstants.booksCollection)
          .get();

      // Get all real users
      final usersSnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .get();

      final realUserIds = usersSnapshot.docs.map((doc) => doc.id).toSet();

      // Find books with fake owners
      final booksToDelete = <String>[];
      
      for (final bookDoc in booksSnapshot.docs) {
        final bookData = bookDoc.data();
        final ownerId = bookData['ownerId'] as String?;
        
        // If book owner doesn't exist in users collection, mark for deletion
        if (ownerId == null || !realUserIds.contains(ownerId)) {
          booksToDelete.add(bookDoc.id);
          print('Found demo book to delete: ${bookData['title']} by ${bookData['ownerName']}');
        }
      }

      // Delete demo books
      for (final bookId in booksToDelete) {
        await _firestore
            .collection(AppConstants.booksCollection)
            .doc(bookId)
            .delete();
        print('Deleted demo book: $bookId');
      }

      print('Cleanup complete. Deleted ${booksToDelete.length} demo books.');
    } catch (e) {
      print('Error during cleanup: $e');
      throw Exception('Failed to cleanup demo books: $e');
    }
  }

  /// Clean up demo swaps that reference non-existent users or books
  Future<void> cleanupDemoSwaps() async {
    try {
      // Get all swaps
      final swapsSnapshot = await _firestore
          .collection(AppConstants.swapsCollection)
          .get();

      // Get all real users and books
      final usersSnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .get();
      final booksSnapshot = await _firestore
          .collection(AppConstants.booksCollection)
          .get();

      final realUserIds = usersSnapshot.docs.map((doc) => doc.id).toSet();
      final realBookIds = booksSnapshot.docs.map((doc) => doc.id).toSet();

      // Find swaps with fake users or books
      final swapsToDelete = <String>[];
      
      for (final swapDoc in swapsSnapshot.docs) {
        final swapData = swapDoc.data();
        final requesterId = swapData['requesterId'] as String?;
        final ownerId = swapData['ownerId'] as String?;
        final bookId = swapData['bookId'] as String?;
        
        // If swap references non-existent users or books, mark for deletion
        if (requesterId == null || !realUserIds.contains(requesterId) ||
            ownerId == null || !realUserIds.contains(ownerId) ||
            bookId == null || !realBookIds.contains(bookId)) {
          swapsToDelete.add(swapDoc.id);
          print('Found demo swap to delete: ${swapData['bookTitle']}');
        }
      }

      // Delete demo swaps
      for (final swapId in swapsToDelete) {
        await _firestore
            .collection(AppConstants.swapsCollection)
            .doc(swapId)
            .delete();
        print('Deleted demo swap: $swapId');
      }

      print('Swap cleanup complete. Deleted ${swapsToDelete.length} demo swaps.');
    } catch (e) {
      print('Error during swap cleanup: $e');
      throw Exception('Failed to cleanup demo swaps: $e');
    }
  }

  /// Reset all books to available status
  Future<void> resetAllBooksToAvailable() async {
    try {
      final booksSnapshot = await _firestore
          .collection(AppConstants.booksCollection)
          .get();

      final batch = _firestore.batch();
      int count = 0;

      for (final bookDoc in booksSnapshot.docs) {
        final bookData = bookDoc.data();
        final isAvailable = bookData['isAvailable'] as bool? ?? true;
        
        if (!isAvailable) {
          batch.update(bookDoc.reference, {'isAvailable': true});
          count++;
          print('Resetting book to available: ${bookData['title']}');
        }
      }

      if (count > 0) {
        await batch.commit();
        print('Reset $count books to available status.');
      } else {
        print('All books are already available.');
      }
    } catch (e) {
      print('Error resetting books: $e');
      throw Exception('Failed to reset books: $e');
    }
  }
}