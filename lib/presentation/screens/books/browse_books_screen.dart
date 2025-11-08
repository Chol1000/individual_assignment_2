import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import '../../providers/book_provider.dart';
import '../../providers/swap_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/book_card.dart';
import '../../widgets/book_details_modal.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/book_model.dart';
import 'select_book_for_swap_screen.dart';
import '../notifications/notifications_screen.dart';

/// Screen for browsing all available books from other users.
/// Features filtering by condition, search functionality, and swap requests.
/// Implements scroll-to-hide filters for better user experience.
class BrowseBooksScreen extends StatefulWidget {
  const BrowseBooksScreen({super.key});

  @override
  State<BrowseBooksScreen> createState() => _BrowseBooksScreenState();
}

class _BrowseBooksScreenState extends State<BrowseBooksScreen> {
  /// Current search query for filtering books by title or author
  String _searchQuery = '';
  
  /// Currently selected condition filter
  String _selectedCondition = 'All';
  
  /// Available condition filter options
  final List<String> _conditions = ['All', 'New', 'Like New', 'Good', 'Used'];
  
  /// Controller for managing scroll behavior and filter visibility
  final ScrollController _scrollController = ScrollController();
  
  /// Controls visibility of filter section (hidden on scroll down)
  bool _showFilters = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bookProvider = Provider.of<BookProvider>(context, listen: false);
      bookProvider.loadBooks();
      bookProvider.listenToAllBooks();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Handles scroll events to show/hide filters based on scroll direction.
  /// Hides filters when scrolling down, shows them when scrolling up.
  void _onScroll() {
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      // Hide filters when scrolling down
      if (_showFilters) {
        setState(() {
          _showFilters = false;
        });
      }
    } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      // Show filters when scrolling up
      if (!_showFilters) {
        setState(() {
          _showFilters = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text('Browse Books'),
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
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showFilters ? null : 0,
            child: _showFilters ? _buildFilters() : const SizedBox.shrink(),
          ),
          Expanded(child: _buildBooksList()),
        ],
      ),
    );
  }

  /// Builds the search bar widget for filtering books by title or author.
  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search books...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primaryColor),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }

  /// Builds the condition filter dropdown that can be hidden on scroll.
  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text(
            'Filter:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                color: AppTheme.primaryColor.withOpacity(0.05),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCondition,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.primaryColor),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  items: _conditions.map((condition) {
                    return DropdownMenuItem<String>(
                      value: condition,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(condition),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCondition = value;
                      });
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the main books list with filtering and error handling.
  /// Only shows available books from other users that haven't been requested.
  Widget _buildBooksList() {
    return Consumer<BookProvider>(
      builder: (context, bookProvider, child) {
        // Don't show loading spinner, just show empty state or books
        // if (bookProvider.books.isEmpty && bookProvider.error == null) {
        //   return const Center(
        //     child: CircularProgressIndicator(
        //       valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        //     ),
        //   );
        // }

        if (bookProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppTheme.errorColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  bookProvider.error!,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => bookProvider.loadBooks(),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          );
        }

        final currentUserId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
        
        final filteredBooks = bookProvider.books.where((book) {
          // Only show books from other users that are available
          final isFromOtherUser = book.ownerId != currentUserId;
          final isAvailable = book.isAvailable;
          
          // Check if current user has pending request for this book
          final hasPendingRequest = book.pendingRequests?.contains(currentUserId) ?? false;
          
          final matchesSearch = _searchQuery.isEmpty ||
              book.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              book.author.toLowerCase().contains(_searchQuery.toLowerCase());
          
          final matchesCondition = _selectedCondition == 'All' ||
              book.condition == _selectedCondition;
          
          // Only show available books from other users that current user hasn't requested
          return isFromOtherUser && isAvailable && !hasPendingRequest && matchesSearch && matchesCondition;
        }).toList();

        if (filteredBooks.isEmpty && bookProvider.books.isNotEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No books found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                Text('Try adjusting your search or filters', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        
        if (bookProvider.books.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.book_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No books available', style: TextStyle(fontSize: 18, color: Colors.grey)),
                Text('Be the first to add a book!', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            bookProvider.loadBooks();
            bookProvider.listenToAllBooks();
          },
          child: _buildListView(filteredBooks),
        );
      },
    );
  }

  /// Builds the scrollable list view of filtered books.
  Widget _buildListView(List books) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        final currentUserId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
        final isOwner = book.ownerId == currentUserId;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: BookCard(
            book: book,
            onTap: () => _showBookDetails(book, isOwner),
            onSwap: (!isOwner && book.isAvailable) ? () => _requestSwap(book) : null,
          ),
        );
      },
    );
  }



  /// Initiates a swap request by allowing user to select which book to offer.
  /// Navigates to book selection screen and creates swap request if book is selected.
  Future<void> _requestSwap(book) async {
    // Navigate to book selection screen where user chooses which book to offer
    final selectedBook = await Navigator.push<BookModel>(
      context,
      MaterialPageRoute(
        builder: (context) => SelectBookForSwapScreen(targetBook: book),
      ),
    );

    if (selectedBook != null) {
      final swapProvider = Provider.of<SwapProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final success = await swapProvider.createSwapRequest(
        book, // target book
        selectedBook, // offered book
        authProvider.currentUser!.id,
        authProvider.currentUser!.name,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Swap proposal sent!' : 'Failed to send swap proposal'),
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

  /// Shows detailed book information in a modal bottom sheet.
  /// Provides swap option for books owned by other users.
  void _showBookDetails(book, bool isOwner) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookDetailsModal(
        book: book,
        onSwap: isOwner ? null : () {
          Navigator.pop(context);
          _requestSwap(book);
        },
      ),
    );
  }
}