import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';

/// CreatePostScreen - Post oluşturma ekranı
///
/// Workflow:
/// 1. Galeri/Kamera seçimi
/// 2. Önizleme
/// 3. Caption ve konum ekleme
/// 4. Paylaş
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final PostService _postService = PostService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  List<XFile> _selectedImages = [];
  int _currentStep = 0; // 0: select, 1: preview, 2: details
  bool _isUploading = false;

  @override
  void dispose() {
    _captionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final images = await _picker.pickMultiImage(
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages = images.take(10).toList(); // Max 10 images
          _currentStep = 1;
        });
      }
    } catch (e) {
      print('❌ Görsel seçme hatası: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Görsel seçilemedi')));
    }
  }

  Future<void> _takePhoto() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImages = [image];
          _currentStep = 1;
        });
      }
    } catch (e) {
      print('❌ Fotoğraf çekme hatası: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fotoğraf çekilemedi')));
    }
  }

  void _goToDetails() {
    setState(() => _currentStep = 2);
  }

  void _goBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _sharePost() async {
    if (_selectedImages.isEmpty) return;

    setState(() => _isUploading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Kullanıcı bulunamadı');

      // Upload images to Supabase Storage
      final List<String> mediaUrls = [];

      for (int i = 0; i < _selectedImages.length; i++) {
        final file = File(_selectedImages[i].path);
        final fileName =
            '${userId}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final path = 'posts/$userId/$fileName';

        await Supabase.instance.client.storage.from('media').upload(path, file);

        final publicUrl = Supabase.instance.client.storage
            .from('media')
            .getPublicUrl(path);

        mediaUrls.add(publicUrl);
      }

      // Create post
      final post = await _postService.createPost(
        userId: userId,
        mediaUrls: mediaUrls,
        caption: _captionController.text.trim().isNotEmpty
            ? _captionController.text.trim()
            : null,
        location: _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
        mediaType: mediaUrls.length > 1 ? MediaType.carousel : MediaType.image,
      );

      if (post != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gönderin paylaşıldı!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, post);
      }
    } catch (e) {
      print('❌ Paylaşım hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Paylaşılamadı: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _isUploading ? _buildUploadingState() : _buildStep(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    String title;
    List<Widget> actions = [];

    switch (_currentStep) {
      case 0:
        title = 'Yeni Gönderi';
        break;
      case 1:
        title = 'Önizleme';
        actions.add(
          TextButton(
            onPressed: _goToDetails,
            child: const Text(
              'İleri',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple,
              ),
            ),
          ),
        );
        break;
      case 2:
        title = 'Yeni Gönderi';
        actions.add(
          TextButton(
            onPressed: _isUploading ? null : _sharePost,
            child: const Text(
              'Paylaş',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple,
              ),
            ),
          ),
        );
        break;
      default:
        title = 'Yeni Gönderi';
    }

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.black),
        onPressed: _goBack,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: actions,
    );
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case 0:
        return _buildSelectStep();
      case 1:
        return _buildPreviewStep();
      case 2:
        return _buildDetailsStep();
      default:
        return _buildSelectStep();
    }
  }

  Widget _buildSelectStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 100,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            const Text(
              'Bir şeyler paylaş',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Galeriden seç veya fotoğraf çek',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 40),
            // Gallery Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.photo_library),
                label: const Text('Galeriden Seç'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Camera Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Fotoğraf Çek'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.deepPurple),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewStep() {
    return Column(
      children: [
        // Image Preview
        Expanded(
          child: _selectedImages.length == 1
              ? Image.file(
                  File(_selectedImages.first.path),
                  fit: BoxFit.contain,
                )
              : PageView.builder(
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          File(_selectedImages[index].path),
                          fit: BoxFit.contain,
                        ),
                        // Page indicator
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${index + 1}/${_selectedImages.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
        // Thumbnail strip
        if (_selectedImages.length > 1)
          Container(
            height: 80,
            color: Colors.black,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(8),
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 64,
                  height: 64,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: FileImage(File(_selectedImages[index].path)),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview thumbnail
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: FileImage(File(_selectedImages.first.path)),
                    fit: BoxFit.cover,
                  ),
                ),
                child: _selectedImages.length > 1
                    ? Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '+${_selectedImages.length - 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _captionController,
                  decoration: const InputDecoration(
                    hintText: 'Açıklama yaz...',
                    border: InputBorder.none,
                  ),
                  maxLines: 3,
                  maxLength: 2200,
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          // Location
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.location_on_outlined),
            title: TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                hintText: 'Konum ekle',
                border: InputBorder.none,
              ),
            ),
          ),
          const Divider(),
          // Options
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.alternate_email),
            title: const Text('Kişi etiketle'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Tag people
            },
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.settings),
            title: const Text('Gelişmiş ayarlar'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Advanced settings
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUploadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Paylaşılıyor...',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
