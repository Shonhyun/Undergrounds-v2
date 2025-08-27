import 'package:flutter/material.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavigationBarItem> items;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: const BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.15),
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
        ),
        ClipRRect(
          child: Container(
            color: Colors.white,
            child: Stack(
              children: [
                BottomNavigationBar(
                  currentIndex: currentIndex,
                  onTap: onTap,
                  type: BottomNavigationBarType.fixed,
                  selectedItemColor:
                      theme.bottomNavigationBarTheme.selectedItemColor,
                  unselectedItemColor:
                      theme.bottomNavigationBarTheme.unselectedItemColor,
                  backgroundColor:
                      theme.bottomNavigationBarTheme.backgroundColor,
                  items: items,
                ),
                Positioned(
                  bottom: 0,
                  left:
                      MediaQuery.of(context).size.width /
                      items.length *
                      currentIndex,
                  width: MediaQuery.of(context).size.width / items.length,
                  height: 4,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
