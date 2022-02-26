import 'package:flutter/material.dart';

///Mainly intended to hold a key.
class EmptyWidget extends StatelessWidget {
  final Widget child;

  const EmptyWidget({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
