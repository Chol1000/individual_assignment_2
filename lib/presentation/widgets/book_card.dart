import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/book_model.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/user_profile_modal.dart';

class BookCard extends StatelessWidget {
  final BookModel book;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onSwap;
  final bool showActions;

  const BookCard({
    super.key,
    required this.book,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onSwap,
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context) {
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
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Book Cover
                Hero(
                  tag: 'book_card_${book.id}_${DateTime.now().millisecondsSinceEpoch}',
                  child: Container(
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
                    child: _buildBookCover(context),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Book Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Title
                      Text(
                        book.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      
                      // Author
                      Text(
                        'by ${book.author}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF718096),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      
                      // Owner
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => _showUserProfile(context, book.ownerId, book.ownerName),
                            child: _buildOwnerAvatar(book.ownerId, book.ownerName),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showUserProfile(context, book.ownerId, book.ownerName),
                              child: Text(
                                book.ownerName,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF718096),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Bottom Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getConditionColor(book.condition).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              book.condition,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: _getConditionColor(book.condition),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: book.isAvailable 
                                  ? const Color(0xFF48BB78).withOpacity(0.1)
                                  : const Color(0xFFED8936).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              book.isAvailable ? 'Available' : 'Pending',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: book.isAvailable 
                                    ? const Color(0xFF48BB78)
                                    : const Color(0xFFED8936),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Action Button
                if (showActions) ...[
                  const SizedBox(width: 12),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onEdit != null)
                        _buildActionButton(
                          icon: Icons.edit_outlined,
                          color: const Color(0xFF4299E1),
                          onTap: onEdit!,
                        ),
                      if (onEdit != null && onDelete != null) const SizedBox(height: 8),
                      if (onDelete != null)
                        _buildActionButton(
                          icon: Icons.delete_outline,
                          color: const Color(0xFFE53E3E),
                          onTap: onDelete!,
                        ),
                    ],
                  ),
                ] else if (onSwap != null) ...[
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: book.isAvailable
                          ? AppTheme.primaryColor
                          : const Color(0xFFA0AEC0),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: (book.isAvailable ? AppTheme.primaryColor : const Color(0xFFA0AEC0)).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: book.isAvailable ? onSwap : null,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                book.isAvailable ? Icons.swap_horiz : Icons.schedule,
                                color: book.isAvailable ? Colors.black : Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                book.isAvailable ? 'Swap' : 'Pending',
                                style: TextStyle(
                                  color: book.isAvailable ? Colors.black : Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Icon(
            icon,
            size: 18,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildBookCover(BuildContext context) {
    // Asset image (sample book covers)
    if (book.imageUrl != null && book.imageUrl!.startsWith('assets/')) {
      return Image.asset(
        book.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    
    // Real image
    if (book.imageUrl != null && book.imageUrl!.isNotEmpty && !book.imageUrl!.startsWith('sample_')) {
      return CachedNetworkImage(
        imageUrl: book.imageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) => _buildPlaceholder(),
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

  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'new':
        return const Color(0xFF48BB78);
      case 'like new':
        return const Color(0xFF4299E1);
      case 'good':
        return const Color(0xFFED8936);
      case 'used':
        return const Color(0xFFA0AEC0);
      default:
        return const Color(0xFFA0AEC0);
    }
  }



  Widget _buildOwnerAvatar(String ownerId, String ownerName) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUserProfile(ownerId),
      builder: (context, snapshot) {
        final userProfile = snapshot.data;
        final profileImageUrl = userProfile?['profileImageUrl'] as String?;
        
        if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
          if (profileImageUrl.startsWith('assets/')) {
            return CircleAvatar(
              radius: 8,
              backgroundImage: AssetImage(profileImageUrl),
            );
          } else {
            return CircleAvatar(
              radius: 8,
              backgroundImage: NetworkImage(profileImageUrl),
            );
          }
        }
        
        // Fallback to colored circle with initial
        return CircleAvatar(
          radius: 8,
          backgroundColor: const Color(0xFF667EEA),
          child: Text(
            ownerName.isNotEmpty ? ownerName[0].toUpperCase() : 'U',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _getUserProfile(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  void _showUserProfile(BuildContext context, String userId, String userName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UserProfileModal(
        userId: userId,
        userName: userName,
      ),
    );
  }
}