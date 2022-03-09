import 'package:flutter/material.dart';

class StatsRow extends StatelessWidget {
  const StatsRow({Key? key, required this.left, required this.right}) : super(key: key);

  final String left;
  final String right;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(left),
          Text(right),
        ],
      ),
    );
  }
}
