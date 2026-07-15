import 'package:flutter/material.dart';

class WorkerBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabChange;
  final int unreadCount;

  const WorkerBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabChange,
    this.unreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTabChange,
      selectedItemColor: const Color(0xFF1A6B4A),
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      elevation: 10,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.work_outline),
          activeIcon: Icon(Icons.work),
          label: 'Jobs',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.attach_money_outlined),
          activeIcon: Icon(Icons.attach_money),
          label: 'Wages',
        ),
        BottomNavigationBarItem(
          icon: _ChatIcon(unreadCount: unreadCount, active: false),
          activeIcon: _ChatIcon(unreadCount: unreadCount, active: true),
          label: 'Chats',
        ),
      ],
    );
  }
}

class _ChatIcon extends StatelessWidget {
  final int unreadCount;
  final bool active;

  const _ChatIcon({required this.unreadCount, required this.active});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          active ? Icons.chat_bubble : Icons.chat_bubble_outline,
        ),
        if (unreadCount > 0)
          Positioned(
            top: -4,
            right: -6,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  unreadCount > 9 ? '9+' : '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}