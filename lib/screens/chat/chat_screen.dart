import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:after_hours/theme/app_theme.dart';
import 'package:after_hours/services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String otherUid;
  final String otherDisplayName;

  const ChatScreen({
    super.key,
    required this.otherUid,
    required this.otherDisplayName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller     = TextEditingController();
  final _scrollController = ScrollController();
  final _chatService    = ChatService();

  String? _chatId;
  String get _currentUid => FirebaseAuth.instance.currentUser?.uid ?? '';
  int _lastMessageCount = 0; // track count so we only scroll when a new message arrives

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initChat() async {
    if (_currentUid.isEmpty) return; // no session, bail out safely
    final id = await _chatService.getOrCreateChat(_currentUid, widget.otherUid);
    if (mounted) setState(() => _chatId = id);
  }

  Future<void> _send() async {
    if (_chatId == null || _controller.text.trim().isEmpty) return;
    final text = _controller.text;
    try {
      _controller.clear();
      await _chatService.sendMessage(_chatId!, _currentUid, text);
      _scrollToBottom();
    } catch (_) {
      // restore text so the user can retry if the write failed
      _controller.text = text;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _timeLabel(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    final h  = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m  = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: kBgDecoration,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 4),
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: kAccent.withValues(alpha: 0.3),
                      child: Text(
                        (widget.otherDisplayName.isEmpty ? '?' : widget.otherDisplayName[0]).toUpperCase(),  //ternary operator to prevent crash if name is empty
                         style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.otherDisplayName,
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: kBorder),
              Expanded(
                child: _chatId == null
                    ? const Center(child: CircularProgressIndicator(color: kAccent, strokeWidth: 2))
                    : StreamBuilder<QuerySnapshot>(
                        stream: _chatService.messagesStream(_chatId!),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(color: kAccent, strokeWidth: 2),
                            );
                          }

                          final messages = snapshot.data?.docs ?? [];

                          // only scroll when a genuinely new message arrives,
                          // not on every rebuild (keyboard open, theme change, etc.)
                          if (messages.length != _lastMessageCount) {
                            _lastMessageCount = messages.length;
                            WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                          }

                          if (messages.isEmpty) {
                            return const Center(
                              child: Text('Say something 👋', style: TextStyle(color: kDim, fontSize: 14)),
                            );
                          }

                          return ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final msg  = messages[index].data() as Map<String, dynamic>;
                              final isMe = msg['sender_uid'] == _currentUid;
                              final text = msg['text'] as String? ?? '';
                              final ts   = msg['created_at'] as Timestamp?;

                              return Align(
                                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isMe ? kAccent : kSurface,
                                    borderRadius: BorderRadius.only(
                                      topLeft:     const Radius.circular(16),
                                      topRight:    const Radius.circular(16),
                                      bottomLeft:  Radius.circular(isMe ? 16 : 4),
                                      bottomRight: Radius.circular(isMe ? 4 : 16),
                                    ),
                                    border: isMe ? null : Border.all(color: kBorder),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        text,
                                        style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _timeLabel(ts),
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.5),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
              const Divider(height: 1, color: kBorder),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: kSurface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: kBorder),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: TextField(
                          controller: _controller,
                          style: const TextStyle(color: Colors.white),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          decoration: const InputDecoration(
                            hintText: 'Message...',
                            hintStyle: TextStyle(color: kDim),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _send,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [kAccent, kPink]),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}