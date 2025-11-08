import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/book_provider.dart';
import '../../providers/swap_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/book_card.dart';
import '../../widgets/book_details_modal.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/book_model.dart';
import 'add_book_screen.dart';
import '../notifications/notifications_screen.dart';

/// Screen for managing user's books and swap offers.
/// Features three tabs: My Books (user's listings), My Offers (sent requests), 
/// and Received (incoming swap requests from other users).
class MyBooksScreen extends StatefulWidget {
  const MyBooksScreen({super.key});

  @override
  State<MyBooksScreen> createState() => _MyBooksScreenState();
}

class _MyBooksScreenState extends State<MyBooksScreen> with TickerProviderStateMixin {
  /// Controller for managing the three tabs (My Books, My Offers, Received)
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser != null) {
        final bookProvider = Provider.of<BookProvider>(context, listen: false);
        bookProvider.listenToUserBooks(authProvider.currentUser!.id);
        
        final swapProvider = Provider.of<SwapProvider>(context, listen: false);
        swapProvider.listenToUserSwaps(authProvider.currentUser!.id);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text('My Books'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              final unreadCount = notificationProvider.notifications
                  .where((n) => n['read'] != true)
                  .length;
              
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.white,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'My Books'),
            Tab(text: 'My Offers'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyListings(),
          _buildMyOffers(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddBookScreen()),
          );
        },
        heroTag: "myBooksAddFAB",
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }





  /// Builds the "My Books" tab showing user's own book listings.
  /// Allows editing and deleting of user's books.
  Widget _buildMyListings() {
    return Consumer<BookProvider>(
      builder: (context, bookProvider, child) {
        // Don't show loading spinner, just show empty state or books
        // if (bookProvider.userBooks.isEmpty && bookProvider.error == null) {
        //   return const Center(
        //     child: CircularProgressIndicator(
        //       valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        //     ),
        //   );
        // }

        if (bookProvider.userBooks.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.book_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No books yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                Text('Add your first book to get started', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookProvider.userBooks.length,
          itemBuilder: (context, index) {
            final book = bookProvider.userBooks[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: BookCard(
                book: book,
                onTap: () => _showBookDetails(book),
                showActions: true,
                onEdit: () => _editBook(book),
                onDelete: () => _deleteBook(book.id),
              ),
            );
          },
        );
      },
    );
  }

  /// Builds the "My Offers" tab showing all swap requests (sent and received).
  /// Displays books that user has requested or that others have requested from user.
  Widget _buildMyOffers() {
    return Consumer3<SwapProvider, BookProvider, AuthProvider>(
      builder: (context, swapProvider, bookProvider, authProvider, child) {
        final currentUserId = authProvider.currentUser?.id;
        
        // Show ALL swaps (both sent and received) in My Offers - including accepted/rejected
        final sentSwaps = swapProvider.sentSwaps;
        final receivedSwaps = swapProvider.receivedSwaps;
        
        final myOffers = [...sentSwaps, ...receivedSwaps];
        myOffers.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (myOffers.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.swap_horiz, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No swap offers', style: TextStyle(fontSize: 18, color: Colors.grey)),
                Text('Sent and received offers will appear here', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: myOffers.length,
          itemBuilder: (context, index) {
            final swap = myOffers[index];
            final isMyRequest = swap.requesterId == currentUserId;
            
            // Show the target book (what you want to get)
            final targetBook = BookModel(
              id: swap.targetBookId,
              title: swap.targetBookTitle,
              author: swap.targetBookAuthor,
              condition: swap.targetBookCondition,
              imageUrl: swap.targetBookImageUrl,
              ownerId: swap.ownerId,
              ownerName: swap.ownerName,
              createdAt: swap.createdAt,
              isAvailable: false,
            );
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildSwapCard(targetBook, swap, isMyRequest),
            );
          },
        );
      },
    );
  }





  void _editBook(book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddBookScreen(book: book),
      ),
    );
  }

  Future<void> _deleteBook(String bookId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Book', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this book? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final bookProvider = Provider.of<BookProvider>(context, listen: false);
      final success = await bookProvider.deleteBook(bookId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Book deleted successfully' : 'Failed to delete book'),
            backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _acceptSwap(String swapId) async {
    final swapProvider = Provider.of<SwapProvider>(context, listen: false);
    final success = await swapProvider.updateSwapStatus(swapId, 'accepted');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Swap accepted!' : 'Failed to accept swap'),
          backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _rejectSwap(String swapId) async {
    final swapProvider = Provider.of<SwapProvider>(context, listen: false);
    final success = await swapProvider.updateSwapStatus(swapId, 'rejected');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Swap rejected' : 'Failed to reject swap'),
          backgroundColor: success ? AppTheme.warningColor : AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _showBookDetails(book) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookDetailsModal(
        book: book,
        showActions: true,
        onEdit: () {
          Navigator.pop(context);
          _editBook(book);
        },
        onDelete: () {
          Navigator.pop(context);
          _deleteBook(book.id);
        },
      ),
    );
  }

  void _showOfferDetails(swap) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Swap Offer Details',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Want: ${swap.targetBookTitle}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Offer: ${swap.offeredBookTitle}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                'Owner: ${swap.ownerName}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    _getStatusIcon(swap.status),
                    size: 16,
                    color: _getStatusColor(swap.status),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Status: ${_getStatusText(swap.status)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(swap.status),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFED8936);
      case 'accepted':
        return const Color(0xFF48BB78);
      case 'rejected':
        return const Color(0xFFE53E3E);
      default:
        return const Color(0xFFA0AEC0);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'accepted':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  Widget _buildSwapCard(BookModel targetBook, swap, bool isMyRequest) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showOfferDetails(swap),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Book Cover
                Container(
                  width: 70,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: _buildBookCover(targetBook),
                ),
                const SizedBox(width: 16),
                
                // Book Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Target Book Title
                      Text(
                        'Want: ${targetBook.title}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      
                      // Offered Book
                      Text(
                        'Offer: ${swap.offeredBookTitle}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF718096),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      
                      // Requester Info
                      Text(
                        isMyRequest ? 'Requested by: Me' : 'Requested by: ${swap.requesterName}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isMyRequest ? const Color(0xFF4299E1) : const Color(0xFF718096),
                          fontWeight: isMyRequest ? FontWeight.w600 : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      
                      // Status
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(swap.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getStatusText(swap.status),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(swap.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Action Buttons based on status and request type
                if (swap.status == 'pending' && isMyRequest) ...[
                  // Cancel button for my requests
                  const SizedBox(width: 12),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53E3E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFE53E3E).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _cancelSwap(swap.id),
                        borderRadius: BorderRadius.circular(10),
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: Color(0xFFE53E3E),
                        ),
                      ),
                    ),
                  ),
                ] else if (swap.status == 'pending' && !isMyRequest) ...[
                  // Accept and Reject buttons for received requests
                  const SizedBox(width: 8),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF48BB78).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF48BB78).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _acceptSwap(swap.id),
                        borderRadius: BorderRadius.circular(10),
                        child: const Icon(
                          Icons.check,
                          size: 18,
                          color: Color(0xFF48BB78),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53E3E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFE53E3E).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _rejectSwap(swap.id),
                        borderRadius: BorderRadius.circular(10),
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: Color(0xFFE53E3E),
                        ),
                      ),
                    ),
                  ),
                ] else if (swap.status == 'accepted') ...[
                  const SizedBox(width: 12),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF48BB78).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF48BB78).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 18,
                      color: Color(0xFF48BB78),
                    ),
                  ),
                ] else if (swap.status == 'rejected') ...[
                  const SizedBox(width: 12),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53E3E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFE53E3E).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.cancel,
                      size: 18,
                      color: Color(0xFFE53E3E),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildBookCover(BookModel book) {
    // Asset image (sample book covers)
    if (book.imageUrl != null && book.imageUrl!.startsWith('assets/')) {
      return Image.asset(
        book.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    
    // Network image
    if (book.imageUrl != null && book.imageUrl!.isNotEmpty) {
      return Image.network(
        book.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    
    // Default placeholder
    return _buildPlaceholder();
  }
  
  Widget _buildPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
      ),
      child: const Icon(
        Icons.book,
        size: 28,
        color: Colors.white,
      ),
    );
  }



  Future<void> _cancelSwap(String swapId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Cancel Swap Request'),
        content: const Text('Are you sure you want to cancel this swap request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Request'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final swapProvider = Provider.of<SwapProvider>(context, listen: false);
      final success = await swapProvider.cancelSwap(swapId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Swap request cancelled' : 'Failed to cancel request'),
            backgroundColor: success ? AppTheme.warningColor : AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }


}