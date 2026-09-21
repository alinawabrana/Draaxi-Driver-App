import 'package:draaxi_driver/src/router/router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final header = const Color(0xFFF4BE05);
    final incomingBubble = isDark
        ? const Color(0xFF2E3137)
        : const Color(0xFFEDEDF1);
    final outgoingBubble = const Color(0xFFF4BE05);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1F1F1F);
    final muted = isDark ? const Color(0xFF9EA2AA) : const Color(0xFF989898);
    final chatBg = isDark ? const Color(0xFF202228) : const Color(0xFFEDEDEF);
    final inputBg = isDark ? const Color(0xFF2A2D33) : const Color(0xFFF6F6F7);

    return Scaffold(
      backgroundColor: chatBg,
      body: Column(
        children: [
          Container(
            color: header,
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: MediaQuery.of(context).padding.top + 12,
              bottom: 20,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        if (Navigator.of(context).canPop()) {
                          context.pop();
                        } else {
                          context.goNamed(ARouter.home);
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Asif Raj',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white.withValues(alpha: 0.35),
                      child: CircleAvatar(
                        radius: 34,
                        backgroundColor: isDark
                            ? const Color(0xFF3E4148)
                            : const Color(0xFFE9E9EA),
                        child: Icon(
                          Icons.person,
                          size: 34,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF8C8C90),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: chatBg,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
                children: [
                  Center(
                    child: Text(
                      'Today at 5:03 PM',
                      style: TextStyle(color: muted, fontSize: 20),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _ChatBubble(
                    text: 'Hello, are you nearby?',
                    isOutgoing: true,
                    color: outgoingBubble,
                    textColor: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  _ChatBubble(
                    text: "I'll be there in a few mins",
                    isOutgoing: false,
                    color: incomingBubble,
                    textColor: textPrimary,
                  ),
                  const SizedBox(height: 16),
                  _ChatBubble(
                    text: 'OK, I am waiting at\nMaxmart Store',
                    isOutgoing: true,
                    color: outgoingBubble,
                    textColor: Colors.white,
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Text(
                      '5:33 PM',
                      style: TextStyle(color: muted, fontSize: 20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ChatBubble(
                    text:
                        "Sorry , I'm stuck in traffic.\nPlease give me a moment.",
                    isOutgoing: false,
                    color: incomingBubble,
                    textColor: textPrimary,
                  ),
                ],
              ),
            ),
          ),
          Container(
            color: isDark ? const Color(0xFF2A2C31) : const Color(0xFFF0F0F1),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF3B3F48)
                            : const Color(0xFFE4E4E6),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 3,
                          height: 30,
                          color: const Color(0xFFF4BE05),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Type a message...',
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFF9398A2)
                                : const Color(0xFFB0B0B3),
                            fontSize: 38 / 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 54,
                  height: 42,
                  decoration: const BoxDecoration(color: Colors.black),
                  child: const Icon(
                    Icons.send,
                    color: Color(0xFFF4BE05),
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.text,
    required this.isOutgoing,
    required this.color,
    required this.textColor,
  });

  final String text;
  final bool isOutgoing;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: CustomPaint(
        painter: _BubbleTailPainter(color: color, isOutgoing: isOutgoing),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 300),
          margin: EdgeInsets.only(
            left: isOutgoing ? 44 : 0,
            right: isOutgoing ? 0 : 44,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 24 / 1.45,
              height: 1.25,
            ),
          ),
        ),
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  const _BubbleTailPainter({required this.color, required this.isOutgoing});

  final Color color;
  final bool isOutgoing;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();

    if (isOutgoing) {
      path.moveTo(size.width - 16, size.height - 1);
      path.lineTo(size.width - 2, size.height + 10);
      path.lineTo(size.width - 2, size.height - 1);
    } else {
      path.moveTo(16, size.height - 1);
      path.lineTo(2, size.height + 10);
      path.lineTo(2, size.height - 1);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isOutgoing != isOutgoing;
  }
}
