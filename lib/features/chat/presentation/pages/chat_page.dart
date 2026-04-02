// lib/features/chat/presentation/pages/chat_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:trainapp/features/chat/domain/entities/message.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../viewmodels/chat_viewmodel.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/utils/keyboard_utils.dart';
import '../../../../config/di/providers.dart';
import '../../../../core/theme/premium_theme.dart';

class ChatPage extends ConsumerStatefulWidget {
  final Profile otherUser;
  
  const ChatPage({super.key, required this.otherUser});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();
  
  String? _currentUserId;
  bool _isUploading = false;
  bool _isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    _initChat();
    
    // Слушаем фокус поля ввода для скролла
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _scrollToBottom();
        });
      }
    });
    
    // Слушаем изменение высоты клавиатуры
    KeyboardUtils.addKeyboardListener(
      context: context,
      onKeyboardShow: () {
        setState(() => _isKeyboardVisible = true);
        _scrollToBottom();
      },
      onKeyboardHide: () {
        setState(() => _isKeyboardVisible = false);
      },
    );
  }

  Future<void> _initChat() async {
    final userId = await _getCurrentUserId();
    if (userId == null) return;

    setState(() {
      _currentUserId = userId;
    });

    await _ensureConnection();
    
    ref.read(chatViewModelProvider.notifier).setOtherUser(widget.otherUser);
    
    await ref.read(chatViewModelProvider.notifier)
        .loadChatHistory(userId, widget.otherUser.id);
    
    ref.read(chatViewModelProvider.notifier)
        .subscribeToMessages(userId, widget.otherUser.id);
    
    await _markMessagesAsRead();
    
    _scrollToBottom();
  }

  Future<void> _markMessagesAsRead() async {
    if (_currentUserId == null) return;
    
    final unreadMessages = ref.read(chatViewModelProvider).messages
        .where((m) => m.receiverId == _currentUserId && !m.isRead)
        .toList();
    
    if (unreadMessages.isNotEmpty) {
      for (var message in unreadMessages) {
        await Supabase.instance.client
            .from('messages')
            .update({
              'is_read': true,
              'read_at': DateTime.now().toIso8601String(),
            })
            .eq('id', message.id);
      }
      
      final updatedMessages = ref.read(chatViewModelProvider).messages.map((m) {
        if (unreadMessages.any((um) => um.id == m.id)) {
          return m.copyWith(isRead: true, readAt: DateTime.now());
        }
        return m;
      }).toList();
      
      ref.read(chatViewModelProvider.notifier).updateMessages(updatedMessages);
    }
  }

  Future<void> _ensureConnection() async {
    final currentUserId = await _getCurrentUserId();
    if (currentUserId == null) return;
    
    final currentUserRole = await _getUserRole(currentUserId);
    final otherUserRole = widget.otherUser.role;
    
    String trainerId, clientId;
    
    if (currentUserRole == 'trainer' && otherUserRole == 'client') {
      trainerId = currentUserId;
      clientId = widget.otherUser.id;
    } else if (currentUserRole == 'client' && otherUserRole == 'trainer') {
      trainerId = widget.otherUser.id;
      clientId = currentUserId;
    } else {
      return;
    }
    
    final existing = await Supabase.instance.client
        .from('trainer_clients')
        .select()
        .eq('trainer_id', trainerId)
        .eq('client_id', clientId)
        .maybeSingle();
    
    if (existing == null) {
      await Supabase.instance.client
          .from('trainer_clients')
          .insert({
            'trainer_id': trainerId,
            'client_id': clientId,
            'status': 'active',
            'start_date': DateTime.now().toIso8601String(),
          });
    }
  }
  
  Future<String> _getUserRole(String userId) async {
    final response = await Supabase.instance.client
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .single();
    return response['role'];
  }

  Future<String?> _getCurrentUserId() async {
    final session = Supabase.instance.client.auth.currentSession;
    return session?.user.id;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _scrollController.position.maxScrollExtent > 0) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _currentUserId == null) return;

    final message = Message(
      id: _uuid.v4(),
      senderId: _currentUserId!,
      receiverId: widget.otherUser.id,
      content: _messageController.text.trim(),
      type: MessageType.text,
      createdAt: DateTime.now(),
    );

    _messageController.clear();
    
    try {
      await ref.read(chatViewModelProvider.notifier).sendMessage(message);
      _scrollToBottom();
    } catch (e) {
      Helpers.showSnackBar(context, 'Не удалось отправить сообщение', isError: true);
    }
  }

  Future<void> _pickAndSendImage() async {
    await _pickAndSendMedia(ImageSource.gallery);
  }

  Future<void> _takeAndSendPhoto() async {
    await _pickAndSendMedia(ImageSource.camera);
  }

  Future<void> _pickAndSendMedia(ImageSource source) async {
    if (_currentUserId == null) return;

    XFile? image;
    
    try {
      image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );
      
      if (image == null) return;

      setState(() => _isUploading = true);

      final file = File(image.path);
      final fileName = '${_uuid.v4()}${path.extension(image.path)}';
      final filePath = 'chat_media/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      
      await Supabase.instance.client.storage
          .from('chat_media')
          .upload(filePath, file);
      
      final publicUrl = Supabase.instance.client.storage
          .from('chat_media')
          .getPublicUrl(filePath);
      
      final message = Message(
        id: _uuid.v4(),
        senderId: _currentUserId!,
        receiverId: widget.otherUser.id,
        content: '📷 Фото',
        type: MessageType.image,
        imageUrl: publicUrl,
        createdAt: DateTime.now(),
      );
      
      await ref.read(chatViewModelProvider.notifier).sendMessage(message);
      _scrollToBottom();
      
      if (mounted) {
        Helpers.showSnackBar(context, 'Фото отправлено');
      }
    } catch (e) {
      print('Error uploading image: $e');
      if (mounted) {
        Helpers.showSnackBar(context, 'Ошибка: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _downloadAndOpen(String url) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1D24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.green),
              const SizedBox(height: 16),
              const Text('Загрузка...', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/image_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        
        Navigator.pop(context);
        
        _showImageDialog(file);
      } else {
        throw Exception('Ошибка загрузки');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        Helpers.showSnackBar(context, 'Ошибка загрузки: $e', isError: true);
      }
    }
  }

  void _showImageDialog(File file) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(
                file,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1D24),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const Text(
                  'Выбрать фото',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.green),
                title: const Text(
                  'Сделать фото',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _takeAndSendPhoto();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatViewModelProvider);

    return KeyboardUtils.wrapWithDismissGesture(
      child: Scaffold(
        backgroundColor: const Color(0xFF0F1115),
        appBar: AppBar(
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.green.withOpacity(0.15),
                backgroundImage: widget.otherUser.avatarUrl != null
                    ? NetworkImage(widget.otherUser.avatarUrl!)
                    : null,
                child: widget.otherUser.avatarUrl == null
                    ? Text(
                        widget.otherUser.fullName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.otherUser.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'онлайн',
                      style: TextStyle(fontSize: 11, color: Colors.green),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
        ),
        body: Column(
          children: [
            Expanded(
              child: state.isLoading && state.messages.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.green),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) {
                        final message = state.messages[index];
                        final isMe = message.senderId == _currentUserId;
                        return _buildMessageBubble(message, isMe);
                      },
                    ),
            ),
            
            // Поле ввода
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1A1D24),
                    Color(0xFF22262F),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _showMediaOptions,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.green,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F1115),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.05),
                            width: 0.5,
                          ),
                        ),
                        child: TextField(
                          controller: _messageController,
                          focusNode: _focusNode,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Сообщение...',
                            hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: _isUploading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.green,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.send,
                                color: Colors.green,
                                size: 22,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    final isImage = message.type == MessageType.image;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) const SizedBox(width: 8),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                gradient: isMe
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.green, Color(0xFF00AA55)],
                      )
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1A1D24), Color(0xFF22262F)],
                      ),
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isImage && message.imageUrl != null)
                    GestureDetector(
                      onTap: () => _downloadAndOpen(message.imageUrl!),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          message.imageUrl!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 200,
                              width: double.infinity,
                              color: Colors.grey.withOpacity(0.2),
                              child: const Center(
                                child: CircularProgressIndicator(color: Colors.green),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              width: double.infinity,
                              color: Colors.grey.withOpacity(0.2),
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text(
                                      'Фото недоступно\n(истек срок хранения)',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  if (message.content.isNotEmpty && !isImage)
                    Text(
                      message.content,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        Helpers.formatTime(message.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe ? Colors.white70 : Colors.grey,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        if (message.isRead)
                          const Icon(
                            Icons.done_all,
                            size: 12,
                            color: Colors.green,
                          )
                        else
                          const Icon(
                            Icons.done,
                            size: 12,
                            color: Colors.white70,
                          ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }
}