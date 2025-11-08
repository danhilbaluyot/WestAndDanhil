import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  // 1. A key to validate our Form
  final _formKey = GlobalKey<FormState>();

  // 2. Controllers for each text field
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController(); // For the image link

  // 3. A variable to show a loading spinner
  bool _isLoading = false;

  // 4. An instance of Firestore to save data
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 5. Clean up the controllers
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  // The upload logic
  Future<void> _uploadProduct() async {
    // 1. Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String imageUrl = _imageUrlController.text.trim();

      final docRef = await _firestore.collection('products').add({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Log the created document ID so it's easy to verify in logs
      debugPrint('Product uploaded successfully. docId=${docRef.id}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product uploaded successfully!')),
        );
      }

      // Clear fields
      _formKey.currentState!.reset();
      _nameController.clear();
      _descriptionController.clear();
      _priceController.clear();
      _imageUrlController.clear();
    } catch (e, st) {
      // Print detailed error + stacktrace to help debugging
      debugPrint('Failed to upload product: $e');
      debugPrint('$st');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to upload product: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin - Add Product')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(labelText: 'Image URL'),
                  keyboardType: TextInputType.url,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an image URL';
                    }
                    if (!value.startsWith('http')) {
                      return 'Please enter a valid URL (e.g., http://...)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Product Name'),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a name' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a description' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a price';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isLoading ? null : _uploadProduct,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Upload Product'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
