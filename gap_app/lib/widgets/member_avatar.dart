import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/group_member.dart';
import '../providers/auth_provider.dart';
import '../services/contact_photo_service.dart';
import '../services/local_avatar_storage.dart';

/// A'zo rasmi: o'z profili → qurilmadagi avatar; boshqalar → kontakt rasmi.
class MemberAvatar extends StatefulWidget {
  const MemberAvatar({
    super.key,
    required this.displayName,
    this.member,
    this.phone,
    this.linkedUserId,
    this.radius = 22,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String displayName;
  final GroupMember? member;
  final String? phone;
  final String? linkedUserId;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  State<MemberAvatar> createState() => _MemberAvatarState();
}

class _MemberAvatarState extends State<MemberAvatar> {
  File? _photoFile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(MemberAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phone != widget.phone ||
        oldWidget.linkedUserId != widget.linkedUserId) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    File? file;

    final auth = context.read<AuthProvider>().user;
    final memberPhone = widget.phone ?? widget.member?.phone;
    final linkedId = widget.linkedUserId ?? widget.member?.linkedUserId;

    if (auth != null && linkedId == auth.id) {
      file = await LocalAvatarStorage.instance.fileForUser(
        auth.id,
        auth.localAvatarFileName,
      );
    } else if (memberPhone != null) {
      file = await ContactPhotoService.instance.photoFileForPhone(memberPhone);
    }

    if (mounted) {
      setState(() {
        _photoFile = file;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = widget.backgroundColor ?? cs.primary;
    final fg = widget.foregroundColor ?? Colors.white;
    final letter = widget.displayName.isNotEmpty
        ? widget.displayName[0].toUpperCase()
        : '?';

    if (_loading) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: bg.withValues(alpha: 0.3),
        child: SizedBox(
          width: widget.radius,
          height: widget.radius,
          child: CircularProgressIndicator(strokeWidth: 2, color: fg),
        ),
      );
    }

    if (_photoFile != null) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundImage: FileImage(_photoFile!),
      );
    }

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: bg,
      child: Text(
        letter,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: widget.radius * 0.85,
        ),
      ),
    );
  }
}

/// Profil ekrani uchun katta avatar.
class ProfileAvatarPicker extends StatelessWidget {
  const ProfileAvatarPicker({
    super.key,
    required this.name,
    required this.photoFile,
    required this.onPickCamera,
    required this.onPickGallery,
    required this.onRemove,
    this.radius = 52,
  });

  final String name;
  final File? photoFile;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;
  final VoidCallback onRemove;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: radius,
              backgroundColor: cs.primaryContainer,
              backgroundImage:
                  photoFile != null ? FileImage(photoFile!) : null,
              child: photoFile == null
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: radius * 0.7,
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                      ),
                    )
                  : null,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Material(
                color: cs.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onPickGallery,
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: onPickCamera,
              icon: const Icon(Icons.photo_camera_outlined, size: 20),
              label: const Text('Kamera'),
            ),
            TextButton.icon(
              onPressed: onPickGallery,
              icon: const Icon(Icons.photo_library_outlined, size: 20),
              label: const Text('Galereya'),
            ),
            if (photoFile != null)
              TextButton(
                onPressed: onRemove,
                child: Text('O\'chirish',
                    style: TextStyle(color: cs.error)),
              ),
          ],
        ),
        Text(
          'Rasm faqat shu telefonda saqlanadi',
          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}
