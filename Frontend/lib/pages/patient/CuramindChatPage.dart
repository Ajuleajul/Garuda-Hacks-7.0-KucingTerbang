import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/chat_service.dart';
import '../../theme/curamind_theme.dart';

class CuramindChatPage extends StatefulWidget {
  const CuramindChatPage({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const CuramindChatPage(),
      ),
    );
  }

  @override
  State<CuramindChatPage> createState() => _CuramindChatPageState();
}

class _CuramindChatPageState extends State<CuramindChatPage> {
  static const _prefsKey = 'curamind_chat_history_v1';
  static const _welcome =
      'Hi — I’m Curamind Assist. Ask me how to use the app: diary, '
      'medications, reminders, distress kit, clinician link, and more.\n\n'
      'I’m not a clinician and I don’t place emergency calls. '
      'If you’re in crisis, use SOS on Home or dial 112 / 119.';

  static const _quickPrompts = [
    'How do I log a diary entry?',
    'How do medication reminders work?',
    'What’s in the distress kit?',
    'How do I link my clinician?',
  ];

  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();

  final List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (!mounted) return;
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = (jsonDecode(raw) as List)
            .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        if (list.isNotEmpty) {
          setState(() {
            _messages
              ..clear()
              ..addAll(list);
            _loading = false;
          });
          _scrollToEnd();
          return;
        }
      } catch (_) {}
    }
    setState(() {
      _messages.add(
        ChatMessage(
          role: 'assistant',
          content: _welcome,
          at: DateTime.now(),
        ),
      );
      _loading = false;
    });
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = _messages.length > 80
        ? _messages.sublist(_messages.length - 80)
        : _messages;
    await prefs.setString(
      _prefsKey,
      jsonEncode(trimmed.map((m) => m.toJson()).toList()),
    );
  }

  Future<void> _clearChat() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    if (!mounted) return;
    setState(() {
      _messages
        ..clear()
        ..add(
          ChatMessage(
            role: 'assistant',
            content: _welcome,
            at: DateTime.now(),
          ),
        );
      _sending = false;
    });
    await _persist();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || _sending) return;

    final history = List<ChatMessage>.from(_messages);
    final userMsg = ChatMessage(
      role: 'user',
      content: text,
      at: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _sending = true;
      _controller.clear();
    });
    await _persist();
    _scrollToEnd();

    try {
      final reply = await ChatService.instance.send(
        history: history,
        userMessage: text,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(
            role: 'assistant',
            content: reply,
            at: DateTime.now(),
          ),
        );
        _sending = false;
      });
      await _persist();
      _scrollToEnd();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(
            role: 'assistant',
            content:
                'I couldn’t reach the assistant just now. '
                'Check that the Curamind API is running, then try again.\n\n'
                '($e)',
            at: DateTime.now(),
          ),
        );
        _sending = false;
      });
      await _persist();
      _scrollToEnd();
    }
  }

  String _timeLabel(DateTime at) {
    final h = at.hour.toString().padLeft(2, '0');
    final m = at.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFD6E2E0),
      appBar: AppBar(
        backgroundColor: CuramindColors.sageDeep,
        foregroundColor: CuramindColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: CuramindColors.sageSoft,
              child: Icon(
                Icons.smart_toy_outlined,
                color: CuramindColors.sageDeep,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Curamind Assist',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: CuramindColors.white,
                    ),
                  ),
                  Text(
                    _sending ? 'typing…' : 'usually replies instantly',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: CuramindColors.white.withValues(alpha: 0.78),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Clear chat',
            onPressed: _sending ? null : _clearChat,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                const Positioned.fill(child: _ChatWallpaper()),
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else
                  ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
                    itemCount: _messages.length + (_sending ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (_sending && i == _messages.length) {
                        return const _TypingBubble();
                      }
                      final msg = _messages[i];
                      final showChips = i == 0 &&
                          msg.isAssistant &&
                          _messages.length <= 1 &&
                          !_sending;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Bubble(
                            message: msg,
                            timeLabel: _timeLabel(msg.at),
                          ),
                          if (showChips) ...[
                            const SizedBox(height: 8),
                            _QuickChips(
                              prompts: _quickPrompts,
                              onPick: _send,
                            ),
                          ],
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
          AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.only(bottom: bottomInset),
            child: _Composer(
              controller: _controller,
              focusNode: _focus,
              enabled: !_sending && !_loading,
              onSend: () => _send(_controller.text),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatWallpaper extends StatelessWidget {
  const _ChatWallpaper();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFD6E2E0),
            CuramindColors.mist,
            const Color(0xFFCBD9D6),
          ],
        ),
      ),
      child: CustomPaint(
        painter: _DotPatternPainter(
          color: CuramindColors.sageDeep.withValues(alpha: 0.05),
        ),
      ),
    );
  }
}

class _DotPatternPainter extends CustomPainter {
  _DotPatternPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const step = 22.0;
    for (var y = 0.0; y < size.height; y += step) {
      for (var x = 0.0; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 1.1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotPatternPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.timeLabel,
  });

  final ChatMessage message;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    final mine = message.isUser;
    final maxW = MediaQuery.sizeOf(context).width * 0.78;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          decoration: BoxDecoration(
            color: mine ? CuramindColors.sageSoft : CuramindColors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(mine ? 14 : 4),
              bottomRight: Radius.circular(mine ? 4 : 14),
            ),
            boxShadow: [
              BoxShadow(
                color: CuramindColors.ink.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  message.content,
                  style: GoogleFonts.outfit(
                    fontSize: 14.5,
                    height: 1.4,
                    color: CuramindColors.ink.withValues(alpha: 0.92),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timeLabel,
                style: GoogleFonts.outfit(
                  fontSize: 10.5,
                  color: CuramindColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: CuramindColors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(14),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return Padding(
              padding: EdgeInsets.only(right: i < 2 ? 5 : 0),
              child: _BounceDot(delayMs: i * 140),
            );
          }),
        ),
      ),
    );
  }
}

class _BounceDot extends StatefulWidget {
  const _BounceDot({required this.delayMs});

  final int delayMs;

  @override
  State<_BounceDot> createState() => _BounceDotState();
}

class _BounceDotState extends State<_BounceDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    Future<void>.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -3 * _c.value),
          child: child,
        );
      },
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: CuramindColors.inkMuted.withValues(alpha: 0.55),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _QuickChips extends StatelessWidget {
  const _QuickChips({
    required this.prompts,
    required this.onPick,
  });

  final List<String> prompts;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final p in prompts)
          ActionChip(
            label: Text(
              p,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: CuramindColors.sageDeep,
              ),
            ),
            backgroundColor: CuramindColors.white.withValues(alpha: 0.9),
            side: BorderSide(
              color: CuramindColors.sage.withValues(alpha: 0.35),
            ),
            onPressed: () => onPick(p),
          ),
      ],
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          decoration: BoxDecoration(
            color: CuramindColors.mist.withValues(alpha: 0.92),
            border: Border(
              top: BorderSide(
                color: CuramindColors.mistBlue.withValues(alpha: 0.8),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: CuramindColors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: CuramindColors.mistBlue),
                    ),
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      enabled: enabled,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.send,
                      onSubmitted: enabled ? (_) => onSend() : null,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        color: CuramindColors.ink,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Message Curamind Assist',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        filled: false,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: enabled
                      ? CuramindColors.sageDeep
                      : CuramindColors.slate.withValues(alpha: 0.45),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: enabled ? onSend : null,
                    child: const SizedBox(
                      width: 46,
                      height: 46,
                      child: Icon(
                        Icons.send_rounded,
                        color: CuramindColors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
