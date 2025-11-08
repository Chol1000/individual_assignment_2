import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/swap_model.dart';

import 'package:intl/intl.dart';

class SwapCard extends StatelessWidget {
  final SwapModel swap;
  final bool isOwner;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onChat;
  final VoidCallback? onTap;

  const SwapCard({
    super.key,
    required this.swap,
    required this.isOwner,
    this.onAccept,
    this.onReject,
    this.onChat,
    this.onTap,
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
            Container(
              width: 60,
              height: 80,
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
              child: _buildBookCover(),
            ),
            const SizedBox(width: 16),
            
            // Swap Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Book Title
                  Text(
                    swap.targetBookTitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // User Info
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            isOwner 
                                ? swap.requesterName.isNotEmpty ? swap.requesterName[0].toUpperCase() : 'U'
                                : swap.ownerName.isNotEmpty ? swap.ownerName[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          isOwner ? swap.requesterName : swap.ownerName,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF718096),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Time and Status Row
                  Row(
                    children: [
                      Text(
                        DateFormat('MMM dd, yyyy').format(swap.createdAt),
                        style: const TextStyle(
                          fontSize: 9,
                          color: Color(0xFF718096),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(swap.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _getStatusColor(swap.status).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _getStatusText(swap.status),
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(swap.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Action Buttons
            const SizedBox(width: 12),
            if (swap.status == 'pending' && isOwner) ...
              _buildOwnerActions()
            else if (swap.status == 'pending' && !isOwner) ...
              _buildRequesterStatus()
            else if (swap.status == 'accepted') ...
              _buildChatButton()
            else ...
              _buildStatusIcon(),
          ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookCover() {
    if (swap.targetBookImageUrl.isNotEmpty && swap.targetBookImageUrl.startsWith('assets/')) {
      return Image.asset(
        swap.targetBookImageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    
    if (swap.targetBookImageUrl.isNotEmpty && !swap.targetBookImageUrl.startsWith('sample_')) {
      return CachedNetworkImage(
        imageUrl: swap.targetBookImageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      );
    }
    
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
        size: 24,
        color: Colors.white,
      ),
    );
  }

  List<Widget> _buildOwnerActions() {
    return [
      Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFE53E3E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFE53E3E).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onReject,
                borderRadius: BorderRadius.circular(8),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Color(0xFFE53E3E),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onAccept,
                borderRadius: BorderRadius.circular(8),
                child: const Icon(
                  Icons.check,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildRequesterStatus() {
    return [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFED8936).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.schedule,
          size: 16,
          color: Color(0xFFED8936),
        ),
      ),
    ];
  }

  List<Widget> _buildChatButton() {
    return [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4FD1C7), Color(0xFF38B2AC)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onChat,
            borderRadius: BorderRadius.circular(8),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 16,
              color: Colors.white,
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildStatusIcon() {
    IconData icon;
    Color color;
    
    switch (swap.status.toLowerCase()) {
      case 'accepted':
        icon = Icons.check_circle;
        color = const Color(0xFF48BB78);
        break;
      case 'rejected':
        icon = Icons.cancel;
        color = const Color(0xFFE53E3E);
        break;
      default:
        icon = Icons.help_outline;
        color = const Color(0xFFA0AEC0);
    }
    
    return [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: color,
        ),
      ),
    ];
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


}