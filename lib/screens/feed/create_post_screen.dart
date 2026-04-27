import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../services/feed_service.dart';
import '../../services/auth_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});
  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _feedService = FeedService();
  final _authService = AuthService();
  final _captionCtrl = TextEditingController();
  final _picker = ImagePicker();
  File? _imageFile;
  bool _posting = false;

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, maxWidth: 1080, imageQuality: 85);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<void> _post() async {
    if (_imageFile == null) return;
    setState(() => _posting = true);
    try {
      await _feedService.createPost(
        imageFile: _imageFile!,
        caption: _captionCtrl.text.trim().isEmpty ? null : _captionCtrl.text.trim(),
        userId: _authService.currentUserId!,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally { if (mounted) setState(() => _posting = false); }
  }

  @override
  void dispose() { _captionCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Post'),
        actions: [
          TextButton(
            onPressed: (_imageFile == null || _posting) ? null : _post,
            child: _posting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: HaaahTheme.neonGreen))
                : const Text('Post', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Image preview / picker
          if (_imageFile != null)
            Stack(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(_imageFile!, width: double.infinity, height: 300, fit: BoxFit.cover),
              ),
              Positioned(top: 8, right: 8, child: GestureDetector(
                onTap: () => setState(() => _imageFile = null),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              )),
            ])
          else
            GestureDetector(
              onTap: () => _showPickerSheet(),
              child: Container(
                width: double.infinity, height: 200,
                decoration: BoxDecoration(
                  color: HaaahTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 2, strokeAlign: BorderSide.strokeAlignCenter),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.add_a_photo, size: 48, color: HaaahTheme.neonGreen.withValues(alpha: 0.6)),
                  const SizedBox(height: 12),
                  const Text('Tap to add a photo', style: TextStyle(color: HaaahTheme.textSecondary)),
                ]),
              ),
            ),
          const SizedBox(height: 20),

          // Caption
          TextField(
            controller: _captionCtrl,
            maxLength: 300,
            maxLines: 3,
            style: const TextStyle(color: HaaahTheme.textPrimary),
            decoration: const InputDecoration(hintText: 'Add a caption...', counterStyle: TextStyle(color: HaaahTheme.textSecondary)),
          ),
        ]),
      ),
    );
  }

  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: HaaahTheme.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.camera_alt, color: HaaahTheme.neonGreen),
            title: const Text('Take Photo'),
            onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: HaaahTheme.deepPurple),
            title: const Text('Choose from Gallery'),
            onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
          ),
        ]),
      )),
    );
  }
}
