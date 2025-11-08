import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/book_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/form_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/book_model.dart';

class AddBookScreen extends StatelessWidget {
  final BookModel? book;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final List<String> _conditions = ['New', 'Like New', 'Good', 'Used'];

  AddBookScreen({super.key, this.book});

  bool get isEditing => book != null;

  @override
  Widget build(BuildContext context) {
    return Consumer<FormProvider>(
      builder: (context, formProvider, child) {
        if (isEditing && _titleController.text.isEmpty) {
          _titleController.text = book!.title;
          _authorController.text = book!.author;
          formProvider.initializeForEdit(book!.title, book!.author, book!.condition);
        }
        
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            backgroundColor: AppTheme.primaryDark,
            elevation: 0,
            title: Text(
              isEditing ? 'Edit Book' : 'Add Book',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            child: _buildForm(context, formProvider),
          ),
        );
      },
    );
  }

  Widget _buildForm(BuildContext context, FormProvider formProvider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImagePicker(context, formProvider),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Book Title',
                hintText: 'Enter book title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.book),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the book title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _authorController,
              decoration: const InputDecoration(
                labelText: 'Author',
                hintText: 'Enter author name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the author name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            _buildConditionSelector(formProvider),
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: formProvider.isLoading ? null : () => _handleSubmit(context, formProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: formProvider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        isEditing ? 'Update Post' : 'Post',
                        style: const TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryDark,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker(BuildContext context, FormProvider formProvider) {
    return GestureDetector(
      onTap: () => _pickImage(context),
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: formProvider.selectedImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  formProvider.selectedImage!,
                  fit: BoxFit.cover,
                ),
              )
            : formProvider.selectedBookCover != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      formProvider.selectedBookCover!['image'] as String,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[300],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.book,
                              color: Colors.grey,
                              size: 60,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              formProvider.selectedBookCover!['name'] as String,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : isEditing && book!.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          book!.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                        ),
                      )
                    : _buildImagePlaceholder(),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate,
          size: 48,
          color: Colors.grey,
        ),
        SizedBox(height: 8),
        Text(
          'Add Book Cover',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        Text(
          'Tap to select image',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildConditionSelector(FormProvider formProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Condition',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _conditions.map((condition) {
            final isSelected = formProvider.condition == condition;
            return FilterChip(
              label: Text(condition),
              selected: isSelected,
              onSelected: (selected) => formProvider.setCondition(condition),
              selectedColor: AppTheme.primaryDark.withOpacity(0.2),
              checkmarkColor: AppTheme.primaryDark,
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.collections_bookmark),
              title: const Text('Sample Book Covers'),
              onTap: () {
                Navigator.pop(context);
                _showSampleBooks(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _getImage(context, ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _getImage(context, ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSampleBooks(BuildContext context) {
    final sampleBooks = _getAvailableBookCovers();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Choose Sample Book Cover',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.7,
              ),
              itemCount: sampleBooks.length,
              itemBuilder: (context, index) {
                final book = sampleBooks[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    context.read<FormProvider>().setSelectedBookCover({'name': book['name'] as String, 'image': book['image'] as String});
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        book['image'] as String,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[300],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.book, size: 40, color: Colors.grey),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  book['name'] as String,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<Map<String, String>> _getAvailableBookCovers() {
    return [
      {'name': 'Programming Textbook', 'image': 'assets/images/bookcover1.jpg'},
      {'name': 'Mathematics Textbook', 'image': 'assets/images/bookcover2.jpeg'},
      {'name': 'Physics Textbook', 'image': 'assets/images/bookcover3.jpg'},
      {'name': 'Chemistry Textbook', 'image': 'assets/images/bookcover4.jpg'},
      {'name': 'History Textbook', 'image': 'assets/images/bookcover5.jpg'},
      {'name': 'Science Textbook', 'image': 'assets/images/bookcover7.avif'},
      {'name': 'Literature Textbook', 'image': 'assets/images/bookcover8.webp'},
      {'name': 'Biology Textbook', 'image': 'assets/images/bookcover9.jpeg'},
      {'name': 'Profile Book 1', 'image': 'assets/images/profile1.jpg'},
      {'name': 'Profile Book 2', 'image': 'assets/images/profile2.jpg'},
      {'name': 'Profile Book 3', 'image': 'assets/images/profile3.jpg'},
      {'name': 'Profile Book 4', 'image': 'assets/images/profile4.webp'},
      {'name': 'Profile Book 5', 'image': 'assets/images/profile5.avif'},
    ];
  }

  Future<void> _getImage(BuildContext context, ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null && context.mounted) {
        context.read<FormProvider>().setSelectedImage(File(image.path));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleSubmit(BuildContext context, FormProvider formProvider) async {
    if (_formKey.currentState!.validate()) {
      formProvider.setLoading(true);
      
      final bookProvider = Provider.of<BookProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      bool success;
      
      if (isEditing) {
        success = await bookProvider.updateBook(
          bookId: book!.id,
          title: _titleController.text.trim(),
          author: _authorController.text.trim(),
          condition: formProvider.condition,
          imageFile: formProvider.selectedImage,
          existingImageUrl: book!.imageUrl,
          sampleBookCover: formProvider.selectedBookCover,
        );
      } else {
        success = await bookProvider.createBook(
          title: _titleController.text.trim(),
          author: _authorController.text.trim(),
          condition: formProvider.condition,
          ownerId: authProvider.currentUser!.id,
          ownerName: authProvider.currentUser!.name,
          imageFile: formProvider.selectedImage,
          sampleBookCover: formProvider.selectedBookCover,
        );
      }

      formProvider.setLoading(false);

      if (context.mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEditing ? 'Book updated!' : 'Book added!'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(bookProvider.error ?? 'Failed to save book'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}