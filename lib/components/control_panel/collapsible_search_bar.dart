// components/control_panel/collapsible_search_bar.dart
import 'package:flutter/material.dart';

class CollapsibleSearchBar extends StatefulWidget {
  final ValueChanged<String>? onChanged;
  final ValueChanged<bool>? onExpandChanged;
  final String hintText;

  const CollapsibleSearchBar({
    super.key,
    this.onChanged,
    this.onExpandChanged,
    this.hintText = 'Search...',
  });

  @override
  State<CollapsibleSearchBar> createState() => _CollapsibleSearchBarState();
}

class _CollapsibleSearchBarState extends State<CollapsibleSearchBar>
    with SingleTickerProviderStateMixin {
  bool isExpanded = false;
  final TextEditingController _controller = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _widthAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  void _toggleExpand() {
    final next = !isExpanded;
    setState(() => isExpanded = next);
    widget.onExpandChanged?.call(next);

    if (next) {
      _animationController.forward();
    } else {
      _animationController.reverse();
      _controller.clear();
      widget.onChanged?.call('');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _widthAnimation,
      builder: (context, child) {
        return Container(
          height: 48,
          constraints: BoxConstraints(
            maxWidth: _widthAnimation.value * 300 + 48,
          ),
          decoration: BoxDecoration(
            color: isExpanded
                ? const Color(0xFF3C3C3E)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isExpanded)
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: _toggleExpand,
                )
              else ...[
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onChanged: (value) {
                      widget.onChanged?.call(value);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: _toggleExpand,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}