import 'package:flutter/material.dart';
import 'tts_service.dart';

class SpeakerButton extends StatefulWidget {
  final String urduText;

  const SpeakerButton({super.key, required this.urduText});

  @override
  State<SpeakerButton> createState() => _SpeakerButtonState();
}

class _SpeakerButtonState extends State<SpeakerButton> {
  bool _speaking = false;

  Future<void> _toggle() async {
    if (_speaking) {
      await TtsService.stop();
      setState(() => _speaking = false);
    } else {
      setState(() => _speaking = true);
      await TtsService.speak(widget.urduText);
      if (mounted) setState(() => _speaking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: _speaking
              ? const Color(0xFF1A6B4A)
              : const Color(0xFF1A6B4A).withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          _speaking ? Icons.volume_up_rounded : Icons.volume_up_outlined,
          size: 16,
          color: _speaking ? Colors.white : const Color(0xFF1A6B4A),
        ),
      ),
    );
  }
}