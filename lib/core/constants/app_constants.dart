class AppConstants {
  static const String appName = 'BookSwap';
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String booksCollection = 'books';
  static const String swapsCollection = 'swaps';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';
  
  // Book Conditions
  static const List<String> bookConditions = ['New', 'Like New', 'Good', 'Used'];
  
  // Swap States
  static const String swapPending = 'pending';
  static const String swapAccepted = 'accepted';
  static const String swapRejected = 'rejected';
  
  // Storage paths
  static const String bookImagesPath = 'book_images';
  static const String profileImagesPath = 'profile_images';
}