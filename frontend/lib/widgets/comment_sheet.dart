import 'package:flutter/material.dart';
import '../models/comment_model.dart';

/// CommentSheet - Yorum bottom sheet
///
/// Features:
/// - Yorum listesi
/// - Yeni yorum ekleme
/// - Yanıt verme (reply)
/// - Beğeni
class CommentSheet extends StatefulWidget {
  final String postId;
  final List<CommentModel> comments;
  final bool isLoading;
  final Function(String content, {String? parentId})? onAddComment;
  final Function(CommentModel comment)? onLikeComment;
  final VoidCallback? onLoadMore;

  const CommentSheet({
    super.key,
    required this.postId,
    required this.comments,
    this.isLoading = false,
    this.onAddComment,
    this.onLikeComment,
    this.onLoadMore,
  });

  @override
  State<CommentSheet> createState() => _CommentSheetState();

  /// Comment sheet'i göster
  static Future<void> show({
    required BuildContext context,
    required String postId,
    required List<CommentModel> comments,
    bool isLoading = false,
    Function(String content, {String? parentId})? onAddComment,
    Function(CommentModel comment)? onLikeComment,
    VoidCallback? onLoadMore,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => CommentSheet(
          postId: postId,
          comments: comments,
          isLoading: isLoading,
          onAddComment: onAddComment,
          onLikeComment: onLikeComment,
          onLoadMore: onLoadMore,
        ),
      ),
    );
  }
}

class _CommentSheetState extends State<CommentSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _replyingTo;
  String? _replyingToUsername;

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitComment() {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    widget.onAddComment?.call(content, parentId: _replyingTo);
    _commentController.clear();
    _cancelReply();
    FocusScope.of(context).unfocus();
  }

  void _startReply(CommentModel comment) {
    setState(() {
      _replyingTo = comment.id;
      _replyingToUsername = comment.authorUsername;
    });
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
      _replyingToUsername = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Title
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Yorumlar',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        const Divider(height: 1),
        // Comments List
        Expanded(
          child: widget.isLoading
              ? const Center(child: CircularProgressIndicator())
              : widget.comments.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: widget.comments.length,
                  itemBuilder: (context, index) {
                    return _CommentTile(
                      comment: widget.comments[index],
                      onReply: () => _startReply(widget.comments[index]),
                      onLike: () =>
                          widget.onLikeComment?.call(widget.comments[index]),
                    );
                  },
                ),
        ),
        // Reply indicator
        if (_replyingTo != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Text(
                  '@$_replyingToUsername kullanıcısına yanıt veriliyor',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _cancelReply,
                  child: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
          ),
        // Input Field
        Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 8,
            top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'Yorum ekle...',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submitComment(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.deepPurple),
                  onPressed: _submitComment,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 60,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz yorum yok',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            'İlk yorumu sen yap!',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

/// Single Comment Tile
class _CommentTile extends StatelessWidget {
  final CommentModel comment;
  final VoidCallback? onReply;
  final VoidCallback? onLike;

  const _CommentTile({required this.comment, this.onReply, this.onLike});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: comment.isReply ? 56 : 16,
        right: 16,
        top: 8,
        bottom: 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: comment.isReply ? 14 : 18,
            backgroundImage: comment.authorAvatarUrl != null
                ? NetworkImage(comment.authorAvatarUrl!)
                : null,
            backgroundColor: Colors.grey.shade200,
            child: comment.authorAvatarUrl == null
                ? Text(
                    (comment.authorUsername ?? 'U')[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: comment.isReply ? 12 : 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black, fontSize: 13),
                    children: [
                      TextSpan(
                        text: '${comment.authorUsername ?? "kullanıcı"} ',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: comment.content),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      comment.timeAgo,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    if (comment.likeCount > 0) ...[
                      const SizedBox(width: 12),
                      Text(
                        '${comment.likeCount} beğenme',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: onReply,
                      child: Text(
                        'Yanıtla',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Like Button
          IconButton(
            icon: Icon(
              comment.isLiked ? Icons.favorite : Icons.favorite_border,
              size: 16,
              color: comment.isLiked ? Colors.red : Colors.grey.shade400,
            ),
            onPressed: onLike,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
