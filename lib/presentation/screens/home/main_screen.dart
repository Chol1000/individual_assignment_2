import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

import '../books/browse_books_screen.dart';
import '../books/my_books_screen.dart';
import '../chats/chats_screen.dart';
import '../settings/settings_screen.dart';

import '../../../core/theme/app_theme.dart';

/// Main screen that serves as the root navigation container for the BookSwap app.
/// Manages bottom navigation between Browse, My Books, Chats, and Settings screens.
/// Also handles email verification flow by showing verification screen when needed.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  /// Current selected tab index for bottom navigation
  int _currentIndex = 0;

  /// List of screens corresponding to each bottom navigation tab
  final List<Widget> _screens = [
    const BrowseBooksScreen(),
    const MyBooksScreen(),
    const ChatsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: null, // No main app bar - individual screens have their own
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          // Show email verification screen if user hasn't verified email
          if (!authProvider.isEmailVerified) {
            return _buildEmailVerificationScreen();
          }
          
          // Use IndexedStack to preserve state when switching tabs
          return IndexedStack(
            index: _currentIndex,
            children: _screens,
          );
        },
      ),
      bottomNavigationBar: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          // Hide bottom navigation during email verification
          if (!authProvider.isEmailVerified) {
            return const SizedBox.shrink();
          }
          
          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              // Update selected tab index
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppTheme.primaryDark,
            selectedItemColor: AppTheme.primaryColor,
            unselectedItemColor: Colors.grey[400],
            elevation: 8,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.book_outlined),
                activeIcon: Icon(Icons.book),
                label: 'My Listings',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_outlined),
                activeIcon: Icon(Icons.chat),
                label: 'Chats',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          );
        },
      ),
    );
  }



  /// Builds the email verification screen shown to unverified users.
  /// Provides options to check verification status, resend email, or sign out.
  Widget _buildEmailVerificationScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.email_outlined,
                size: 80,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 24),
              const Text(
                'Verify Your Email',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Check your inbox and click the verification link to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  await authProvider.checkEmailVerification();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('I\'ve Verified'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  await authProvider.resendVerificationEmail();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Verification email sent!')),
                    );
                  }
                },
                child: const Text('Resend Email'),
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () async {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  await authProvider.signOut();
                },
                child: Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}