import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

class CursorHoverRegion extends StatelessWidget {
  final Widget child;
  const CursorHoverRegion({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.none,
      onEnter: (_) => AnimatedCustomCursor.isHoveringClickable.value = true,
      onExit: (_) => AnimatedCustomCursor.isHoveringClickable.value = false,
      child: child,
    );
  }
}

class AnimatedCustomCursor extends StatefulWidget {
  final Widget child;

  static final ValueNotifier<bool> isHoveringClickable = ValueNotifier(false);

  const AnimatedCustomCursor({super.key, required this.child});

  @override
  State<AnimatedCustomCursor> createState() => _AnimatedCustomCursorState();
}

class _AnimatedCustomCursorState extends State<AnimatedCustomCursor> {
  Offset _position = Offset.zero;
  Offset _lastPosition = Offset.zero;
  
  bool _isMoving = false;
  bool _isMovingRight = false;
  bool _isClicked = false;
  bool _isHoveringScreen = false;
  
  Timer? _movementTimer;

  @override
  void initState() {
    super.initState();
    AnimatedCustomCursor.isHoveringClickable.addListener(_onHoverClickableChanged);
  }

  @override
  void dispose() {
    AnimatedCustomCursor.isHoveringClickable.removeListener(_onHoverClickableChanged);
    _movementTimer?.cancel();
    super.dispose();
  }

  void _onHoverClickableChanged() {
    if (mounted) setState(() {});
  }

  void _onPointerEvent(PointerEvent event) {
    if (!mounted) return;

    if (event.position.dx > _lastPosition.dx + 1) {
      _isMovingRight = true;
    } else if (event.position.dx < _lastPosition.dx - 1) {
      _isMovingRight = false;
    }

    setState(() {
      _lastPosition = _position;
      _position = event.position;
      _isMoving = true;
      _isHoveringScreen = true;
    });

    _movementTimer?.cancel();
    _movementTimer = Timer(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _isMoving = false;
        });
      }
    });
  }

  void _onExit(PointerEvent event) {
    setState(() {
      _isHoveringScreen = false;
      _isMoving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    String imagePath = 'assets/images/Select-Cursor--Streamline-Freehand.png';
    bool shouldMirror = false;

    if (_isClicked) {
      imagePath = 'assets/images/Cursor-Highlight-Click-2--Streamline-Freehand.png';
    } else if (AnimatedCustomCursor.isHoveringClickable.value) {
      imagePath = 'assets/images/Cursor-Highlight-Click-1--Streamline-Freehand.png';
    } else if (_isMoving) {
      imagePath = 'assets/images/Cursor-Speed-1--Streamline-Freehand.png';
      shouldMirror = _isMovingRight;
    }

    Widget cursorImage = Image.asset(
      imagePath,
      width: 32,
      height: 32,
    );

    if (shouldMirror) {
      cursorImage = Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationY(math.pi),
        child: cursorImage,
      );
    }

    double leftOffset = _position.dx - (shouldMirror ? 28 : 4);
    double topOffset = _position.dy - 2;

    return MouseRegion(
      cursor: SystemMouseCursors.none,
      onHover: _onPointerEvent,
      onExit: _onExit,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) {
          setState(() {
            _isClicked = true;
            _position = event.position;
          });
        },
        onPointerUp: (event) {
          setState(() {
            _isClicked = false;
            _position = event.position;
          });
        },
        onPointerHover: _onPointerEvent,
        onPointerMove: _onPointerEvent,
        child: Stack(
          children: [
            widget.child,
            if (_isHoveringScreen)
              Positioned(
                left: leftOffset,
                top: topOffset,
                child: IgnorePointer(
                  child: cursorImage,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
