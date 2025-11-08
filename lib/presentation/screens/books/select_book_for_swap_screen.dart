import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/book_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/book_card.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/book_model.dart';

/// Screen for selecting which book to offer in exchange during swap requests.
/// Shows user's available books and allows selection of one to propose as trade.
/// Implements true book-for-book exchange functionality.
class SelectBookForSwapScreen extends StatefulWidget {
  /// The book that user wants to request from another user
  final BookModel targetBook;

  const SelectBookForSwapScreen({
    super.key,
    required this.targetBook,
  });

  @override
  State<SelectBookForSwapScreen> createState() => _SelectBookForSwapScreenState();
}

class _SelectBookForSwapScreenState extends State<SelectBookForSwapScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser != null) {
        final bookProvider = Provider.of<BookProvider>(context, listen: false);
        bookProvider.listenToUserBooks(authProvider.currentUser!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        title: const Text(
          'Select Your Book to Swap',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildTargetBookInfo(),
          const Divider(),
          Expanded(child: _buildMyBooksList()),
        ],
      ),
    );
  }

  Widget _buildTargetBookInfo() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'You want to get:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          BookCard(
            book: widget.targetBook,
          ),
        ],
      ),
    );
  }

  Widget _buildMyBooksList() {
    return Consumer2<BookProvider, AuthProvider>(
      builder: (context, bookProvider, authProvider, child) {
        // Show books that are available OR not currently in pending swaps
        final myBooks = bookProvider.userBooks.toList();

        if (myBooks.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.book_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No books available to swap',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                Text(
                  'Add some books first to start swapping',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Select one of your books to offer:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: myBooks.length,
                itemBuilder: (context, index) {
                  final book = myBooks[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: BookCard(
                      book: book,
                      onTap: () => _selectBookForSwap(context, book),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _selectBookForSwap(BuildContext context, BookModel myBook) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Confirm Swap'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('You want to swap:'),
            const SizedBox(height: 8),
            Text(
              '• Your: "${myBook.title}"',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              '• For: "${widget.targetBook.title}"',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text(
              'Send this swap proposal?',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, myBook);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text(
              'Send Swap Proposal',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}