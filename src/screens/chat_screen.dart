import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String currentUserId;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.currentUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 155, 165, 178),
              Color.fromARGB(255, 34, 45, 63),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [

              // 🔹 Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 20),
                child: Row(
                  children: const [
                    Text(
                      "Chat",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 4, 38, 39),
                      ),
                    ),
                  ],
                ),
              ),

              // 🔹 Messages Area
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15),
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 221, 225, 225).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('chats')
                        .doc(widget.chatId)
                        .collection('messages')
                        .orderBy('timestamp')
                        .snapshots(),
                    builder: (context, snapshot) {

                      if (!snapshot.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      final messages = snapshot.data!.docs;

                      scrollToBottom();

                      return ListView.builder(
                        controller: scrollController,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {

                          final data = messages[index].data()
                              as Map<String, dynamic>;

                          final isMe =
                              data['senderId'] == widget.currentUserId;

                          return buildMessageBubble(
                            message: data['message'],
                            isMe: isMe,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 🔹 Input Bar
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 15, vertical: 10),
                margin: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 221, 225, 225),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Row(
                  children: [

                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          hintText: "Type your message...",
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    Container(
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(25, 87, 104, 1),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.send,
                          color: Color.fromARGB(255, 192, 198, 199),
                        ),
                        onPressed: () async {

                          if (controller.text.trim().isEmpty) return;

                          await FirebaseFirestore.instance
                              .collection('chats')
                              .doc(widget.chatId)
                              .collection('messages')
                              .add({
                            'message': controller.text.trim(),
                            'senderId': widget.currentUserId,
                            'timestamp': FieldValue.serverTimestamp(),
                          });

                          controller.clear();
                          scrollToBottom();
                        },
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

  Widget buildMessageBubble({
    required String message,
    required bool isMe,
  }) {
    return Align(
      alignment:
          isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(
            vertical: 6, horizontal: 8),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 260),
        decoration: BoxDecoration(
          color: isMe
              ? const Color.fromARGB(255, 101, 178, 189)
              : const Color.fromARGB(255, 65, 108, 128),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft:
                isMe ? const Radius.circular(18) : Radius.zero,
            bottomRight:
                isMe ? Radius.zero : const Radius.circular(18),
          ),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}