import 'package:flutter/material.dart';

class CustomExpansionTile extends StatefulWidget {
  const CustomExpansionTile({super.key});

  @override
  _CustomExpansionTileState createState() => _CustomExpansionTileState();
}

class _CustomExpansionTileState extends State<CustomExpansionTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: const Text('Tap to Expand'),
          trailing: Icon(
            _isExpanded ? Icons.expand_less : Icons.expand_more,
          ),
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          child: _isExpanded
              ? const Column(
                  children: [
                    ListTile(title: Text('Expanded Content 1')),
                    ListTile(title: Text('Expanded Content 2')),
                  ],
                )
              : Container(),
        ),
      ],
    );
  }
}
