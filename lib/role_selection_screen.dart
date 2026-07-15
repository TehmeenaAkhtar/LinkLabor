import 'package:flutter/material.dart';
import 'worker_registration_screen.dart';
import 'customer_registration_screen.dart';
import 'chat_screen.dart';
import 'language_state.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE8F5EE),
              Color(0xFFE3F2FD),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Logo / Icon ──
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A6B4A),
                  borderRadius: BorderRadius.circular(36),
                ),
                child: const Icon(
                  Icons.handshake_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
              const SizedBox(height: 20),

              // ── Title ──
              const Text(
                "LinkLabour",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A6B4A),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isUrdu ? "آپ کون ہیں؟" : "Who are you?",
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 48),

              // ── Worker Card ──
              _RoleCard(
                label: isUrdu ? "میں ایک کارکن ہوں" : "I am a Worker",
                subtitle: isUrdu
                    ? "کام تلاش کریں اور آمدنی حاصل کریں"
                    : "Find jobs & earn money",
                icon: "👷",
                iconBg: const Color(0xFFD4EDE1),
                borderColor: const Color(0xFF1A6B4A),
                textColor: const Color(0xFF1A6B4A),
                onTap: () => _navigateToWorkerRegistration(context),
              ),

              const SizedBox(height: 16),

              // ── Customer Card ──
              _RoleCard(
                label: isUrdu ? "مجھے ایک کارکن چاہیے" : "I Need a Worker",
                subtitle: isUrdu
                    ? "تصدیق شدہ ماہرین کی خدمات حاصل کریں"
                    : "Hire verified professionals",
                icon: "🙋",
                iconBg: const Color(0xFFD0E8F8),
                borderColor: const Color(0xFF1565C0),
                textColor: const Color(0xFF1565C0),
                onTap: () => _navigateToCustomerRegistration(context),
              ),

              const SizedBox(height: 40),

              // ── Divider with "or" ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        isUrdu
                            ? "پہلے سے رجسٹرڈ ہیں؟"
                            : "already registered?",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300])),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Quick Chat Buttons (for already registered users) ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _QuickChatButton(
                    label: isUrdu ? "ورکر چیٹ" : "Worker Chat",
                    icon: Icons.construction_rounded,
                    color: const Color(0xFF1A6B4A),
                    onTap: () => _openChat(
                      context,
                      role: "worker",
                      name: isUrdu ? "ورکر" : "Worker",
                    ),
                  ),
                  const SizedBox(width: 12),
                  _QuickChatButton(
                    label: isUrdu ? "کسٹمر چیٹ" : "Customer Chat",
                    icon: Icons.person_rounded,
                    color: const Color(0xFF1565C0),
                    onTap: () => _openChat(
                      context,
                      role: "customer",
                      name: isUrdu ? "صارف" : "Customer",
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Goes to worker registration form ──
  void _navigateToWorkerRegistration(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WorkerRegistrationScreen(),
      ),
    );
  }

  // ── Goes to customer registration form ──
  void _navigateToCustomerRegistration(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CustomerRegistrationScreen(),
      ),
    );
  }

  // ── Opens chat directly (for already-registered users) ──
  void _openChat(
      BuildContext context, {
        required String role,
        required String name,
      }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(role: role, name: name),
      ),
    );
  }
}

// ════════════════════════════════════════
//  Role Card Widget
// ════════════════════════════════════════
class _RoleCard extends StatefulWidget {
  final String label;
  final String subtitle;
  final String icon;
  final Color iconBg;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.borderColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 300,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          color: _pressed
              ? widget.borderColor.withOpacity(0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _pressed
                ? widget.borderColor
                : widget.borderColor.withOpacity(0.25),
            width: _pressed ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.borderColor.withOpacity(_pressed ? 0.12 : 0.06),
              blurRadius: _pressed ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon circle
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: widget.iconBg,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Center(
                child: Text(
                  widget.icon,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Labels
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: widget.textColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: widget.borderColor.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════
//  Quick Chat Button (already registered)
// ════════════════════════════════════════
class _QuickChatButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickChatButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}