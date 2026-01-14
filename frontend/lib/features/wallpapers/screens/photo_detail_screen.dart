import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/unsplash_photo.dart';

/// Photo Detail Screen - Fotoğraf Detay Görüntüleme
///
/// Tam ekran fotoğraf görüntüleme, zoom, ve fotoğrafçı bilgileri.
class PhotoDetailScreen extends StatefulWidget {
  final UnsplashPhoto photo;

  const PhotoDetailScreen({super.key, required this.photo});

  @override
  State<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen>
    with SingleTickerProviderStateMixin {
  late TransformationController _transformationController;
  late AnimationController _animationController;
  bool _showInfo = true;
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    final endMatrix = Matrix4.identity();
    final animation =
        Matrix4Tween(
          begin: _transformationController.value,
          end: endMatrix,
        ).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    animation.addListener(() {
      _transformationController.value = animation.value;
    });

    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          setState(() {
            _dragOffset += details.delta.dy;
          });
        },
        onVerticalDragEnd: (details) {
          if (_dragOffset.abs() > 100) {
            Navigator.pop(context);
          } else {
            setState(() {
              _dragOffset = 0;
            });
          }
        },
        onTap: () {
          setState(() {
            _showInfo = !_showInfo;
          });
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Blurred Background
            _buildBlurredBackground(),

            // Main Image with Hero animation
            Transform.translate(
              offset: Offset(0, _dragOffset),
              child: Center(
                child: Hero(
                  tag: 'photo_${widget.photo.id}',
                  child: InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: 1.0,
                    maxScale: 4.0,
                    onInteractionEnd: (_) {
                      if (_transformationController.value.getMaxScaleOnAxis() <
                          1.1) {
                        _resetZoom();
                      }
                    },
                    child: CachedNetworkImage(
                      imageUrl: widget.photo.urls.full,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => CachedNetworkImage(
                        imageUrl: widget.photo.urls.regular,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Info Panel
            if (_showInfo) _buildInfoPanel(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _showInfo ? Colors.black54 : Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 18,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: _showInfo
          ? [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.share, color: Colors.white, size: 18),
                ),
                onPressed: () => _sharePhoto(),
              ),
              const SizedBox(width: 8),
            ]
          : null,
    );
  }

  Widget _buildBlurredBackground() {
    return CachedNetworkImage(
      imageUrl: widget.photo.urls.small,
      fit: BoxFit.cover,
      imageBuilder: (context, imageProvider) => Container(
        decoration: BoxDecoration(
          image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(color: Colors.black.withOpacity(0.6)),
        ),
      ),
    );
  }

  Widget _buildInfoPanel() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          40,
          20,
          MediaQuery.of(context).padding.bottom + 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Photographer Info
            Row(
              children: [
                // Avatar
                if (widget.photo.user.profileImage != null)
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: CachedNetworkImageProvider(
                      widget.photo.user.profileImage!,
                    ),
                  ),
                const SizedBox(width: 12),
                // Name & Username
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.photo.user.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '@${widget.photo.user.username}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Unsplash Link
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.open_in_new,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  onPressed: () => _openUnsplash(),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Description
            if (widget.photo.description != null ||
                widget.photo.altDescription != null)
              Text(
                widget.photo.description ?? widget.photo.altDescription ?? '',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

            const SizedBox(height: 16),

            // Stats Row
            Row(
              children: [
                _buildStatChip(
                  Icons.favorite,
                  '${widget.photo.likes}',
                  Colors.red,
                ),
                const SizedBox(width: 12),
                _buildStatChip(
                  Icons.aspect_ratio,
                  '${widget.photo.width} x ${widget.photo.height}',
                  Colors.blue,
                ),
                const Spacer(),
                // Download Button
                ElevatedButton.icon(
                  onPressed: () => _downloadPhoto(),
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('İndir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _sharePhoto() async {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Paylaşım özelliği yakında!'),
        backgroundColor: const Color(0xFFE91E63),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _openUnsplash() async {
    final url = 'https://unsplash.com/photos/${widget.photo.id}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _downloadPhoto() async {
    // Open download URL in browser (Unsplash attribution required)
    final url = '${widget.photo.urls.full}&dl=${widget.photo.id}.jpg';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }
}
