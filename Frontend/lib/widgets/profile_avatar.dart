import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/profile_photo_service.dart';
import '../theme/curamind_theme.dart';

class ProfileAvatar extends StatefulWidget {
  const ProfileAvatar({
    super.key,
    this.size = 40,
    this.onTap,
    this.showBorder = true,
  });

  final double size;
  final VoidCallback? onTap;
  final bool showBorder;

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _load();
    AuthService.instance.profileRevision.addListener(_load);
  }

  @override
  void dispose() {
    AuthService.instance.profileRevision.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final b64 = await ProfilePhotoService.instance.loadBase64();
    Uint8List? bytes;
    if (b64 != null && b64.isNotEmpty) {
      try {
        bytes = Uint8List.fromList(base64Decode(b64));
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => _bytes = bytes);
  }

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: CuramindColors.mistBlue,
        border: widget.showBorder
            ? Border.all(color: CuramindColors.slate, width: 1.2)
            : null,
        image: _bytes != null
            ? DecorationImage(
                image: MemoryImage(_bytes!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: _bytes == null
          ? Icon(
              Icons.person_outline_rounded,
              size: widget.size * 0.48,
              color: CuramindColors.ocean,
            )
          : null,
    );

    if (widget.onTap == null) return child;

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: widget.onTap,
        child: child,
      ),
    );
  }
}
