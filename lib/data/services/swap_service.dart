import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/swap_model.dart';
import '../models/book_model.dart';
import '../../core/constants/app_constants.dart';
import 'notification_service.dart';

class SwapService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<SwapModel>> getUserSwaps(String userId) {
    return _firestore
        .collection(AppConstants.swapsCollection)
        .where('requesterId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final swaps = snapshot.docs
              .map((doc) => SwapModel.fromMap(doc.data(), doc.id))
              .toList();
          // Return ALL swaps regardless of status (pending, accepted, rejected)
          swaps.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return swaps;
        });
  }
  
  Stream<List<SwapModel>> getAllUserSwaps(String userId) {
    return _firestore
        .collection(AppConstants.swapsCollection)
        .where('requesterId', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
          final sentSwaps = snapshot.docs
              .map((doc) => SwapModel.fromMap(doc.data(), doc.id))
              .toList();
          
          final receivedSnapshot = await _firestore
              .collection(AppConstants.swapsCollection)
              .where('ownerId', isEqualTo: userId)
              .get();
          
          final receivedSwaps = receivedSnapshot.docs
              .map((doc) => SwapModel.fromMap(doc.data(), doc.id))
              .toList();
          
          final allSwaps = [...sentSwaps, ...receivedSwaps];
          allSwaps.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return allSwaps;
        });
  }

  Stream<List<SwapModel>> getReceivedSwaps(String userId) {
    return _firestore
        .collection(AppConstants.swapsCollection)
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final swaps = snapshot.docs
              .map((doc) => SwapModel.fromMap(doc.data(), doc.id))
              .toList();
          // Return ALL received swaps regardless of status (pending, accepted, rejected)
          swaps.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return swaps;
        });
  }

  Future<String> createSwapRequest({
    required BookModel targetBook,
    required BookModel offeredBook,
    required String requesterId,
    required String requesterName,
  }) async {
    try {
      // Prevent users from swapping with themselves
      if (targetBook.ownerId == requesterId) {
        throw Exception('Cannot request swap for your own book');
      }
      
      final swap = SwapModel(
        id: '',
        targetBookId: targetBook.id,
        targetBookTitle: targetBook.title,
        targetBookAuthor: targetBook.author,
        targetBookCondition: targetBook.condition,
        targetBookImageUrl: targetBook.imageUrl ?? '',
        offeredBookId: offeredBook.id,
        offeredBookTitle: offeredBook.title,
        offeredBookAuthor: offeredBook.author,
        offeredBookCondition: offeredBook.condition,
        offeredBookImageUrl: offeredBook.imageUrl ?? '',
        requesterId: requesterId,
        requesterName: requesterName,
        ownerId: targetBook.ownerId,
        ownerName: targetBook.ownerName,
        status: AppConstants.swapPending,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection(AppConstants.swapsCollection)
          .add(swap.toMap());

      // Add requester to book's pending requests
      try {
        await _firestore
            .collection(AppConstants.booksCollection)
            .doc(targetBook.id)
            .update({
          'pendingRequests': FieldValue.arrayUnion([requesterId])
        });
      } catch (e) {
        print('Warning: Could not update pending requests: $e');
      }

      // Send notification to book owner
      await NotificationService.addLocalNotification(
        userId: targetBook.ownerId,
        title: 'New Swap Request',
        body: '$requesterName wants to swap for "${targetBook.title}"',
        type: 'swap_request',
        data: {
          'swapId': docRef.id,
          'bookTitle': targetBook.title,
          'requesterName': requesterName,
        },
      );

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create swap request: $e');
    }
  }

  Future<void> updateSwapStatus({
    required String swapId,
    required String status,
  }) async {
    try {
      // Get swap details for notification
      final swapDoc = await _firestore
          .collection(AppConstants.swapsCollection)
          .doc(swapId)
          .get();
      
      SwapModel? swap;
      if (swapDoc.exists) {
        swap = SwapModel.fromMap(swapDoc.data()!, swapDoc.id);
      }

      // Update swap status and ownership if accepted
      Map<String, dynamic> updateData = {
        'status': status,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };
      
      // If accepted, swap the ownership in the swap document for immediate visibility
      if (status == AppConstants.swapAccepted && swap != null) {
        updateData.addAll({
          'ownerId': swap.requesterId,
          'ownerName': swap.requesterName,
          'requesterId': swap.ownerId,
          'requesterName': swap.ownerName,
        });
      }
      
      await _firestore
          .collection(AppConstants.swapsCollection)
          .doc(swapId)
          .update(updateData);

      // Send notification to requester about status update
      if (swap != null) {
        final statusText = status == AppConstants.swapAccepted ? 'accepted' : 'rejected';
        await NotificationService.addLocalNotification(
          userId: swap.requesterId,
          title: 'Swap $statusText',
          body: 'Your swap request for "${swap.targetBookTitle}" was $statusText',
          type: 'swap_status',
          data: {
            'swapId': swapId,
            'status': status,
            'bookTitle': swap.targetBookTitle,
          },
        );
      }

      // Update book availability based on status
      if (swap != null) {
        try {
          if (status == AppConstants.swapAccepted) {
            // Transfer book ownership when swap is accepted
            print('Transferring ownership for swap: ${swap.id}');
            print('Target book: ${swap.targetBookTitle} (${swap.targetBookId}) -> ${swap.requesterName}');
            print('Offered book: ${swap.offeredBookTitle} (${swap.offeredBookId}) -> ${swap.ownerName}');
            
            // Target book goes to requester
            print('Transferring target book ${swap.targetBookTitle} (${swap.targetBookId}) from ${swap.ownerName} to ${swap.requesterName}');
            await _firestore
                .collection(AppConstants.booksCollection)
                .doc(swap.targetBookId)
                .update({
                  'ownerId': swap.requesterId,
                  'ownerName': swap.requesterName,
                  'isAvailable': true,
                });
            print('✅ Target book ownership updated successfully');
            
            // Offered book goes to original target book owner
            print('Transferring offered book ${swap.offeredBookTitle} (${swap.offeredBookId}) from ${swap.requesterName} to ${swap.ownerName}');
            await _firestore
                .collection(AppConstants.booksCollection)
                .doc(swap.offeredBookId)
                .update({
                  'ownerId': swap.ownerId,
                  'ownerName': swap.ownerName,
                  'isAvailable': true,
                });
            print('✅ Offered book ownership updated successfully');
            
            // Remove pending requests for both books
            await _firestore
                .collection(AppConstants.booksCollection)
                .doc(swap.targetBookId)
                .update({
              'pendingRequests': FieldValue.arrayRemove([swap.requesterId])
            });
            await _firestore
                .collection(AppConstants.booksCollection)
                .doc(swap.offeredBookId)
                .update({
              'pendingRequests': FieldValue.arrayRemove([swap.ownerId])
            });
          } else if (status == AppConstants.swapRejected) {
            // Remove pending request when rejected
            await _firestore
                .collection(AppConstants.booksCollection)
                .doc(swap.targetBookId)
                .update({
              'pendingRequests': FieldValue.arrayRemove([swap.requesterId])
            });
          }
        } catch (e) {
          print('Warning: Could not update book availability: $e');
        }
      }
    } catch (e) {
      throw Exception('Failed to update swap status: $e');
    }
  }

  Future<SwapModel?> getSwap(String swapId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.swapsCollection)
          .doc(swapId)
          .get();

      if (doc.exists) {
        return SwapModel.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      throw Exception('Failed to get swap: $e');
    }
    return null;
  }

  Future<void> cancelSwap(String swapId) async {
    try {
      // Get swap details first
      final swapDoc = await _firestore
          .collection(AppConstants.swapsCollection)
          .doc(swapId)
          .get();
      
      if (swapDoc.exists) {
        final swap = SwapModel.fromMap(swapDoc.data()!, swapDoc.id);
        
        // Remove pending request when cancelled
        await _firestore
            .collection(AppConstants.booksCollection)
            .doc(swap.targetBookId)
            .update({
          'pendingRequests': FieldValue.arrayRemove([swap.requesterId])
        });
        
        // Delete the swap request
        await _firestore
            .collection(AppConstants.swapsCollection)
            .doc(swapId)
            .delete();
      }
    } catch (e) {
      throw Exception('Failed to cancel swap: $e');
    }
  }
}