import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MyCustomListTile extends StatelessWidget {
  final Widget title;
  final Widget subtitle;
  final VoidCallback onTap;
  final VoidCallback? onTitleTap;

  const MyCustomListTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.onTitleTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: CupertinoTheme.of(context).scaffoldBackgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onTitleTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: DefaultTextStyle(
                  style: CupertinoTheme.of(context).textTheme.textStyle,
                  child: title,
                ),
              ),
            ),
            DefaultTextStyle(
              style: CupertinoTheme.of(context).textTheme.tabLabelTextStyle,
              child: subtitle,
            ),
            const Divider(height: 1, indent: 0),
          ],
        ),
      ),
    );
  }
}