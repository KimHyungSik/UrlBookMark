import 'dart:async';

import 'package:flutter/material.dart';

class PressableButton extends StatefulWidget {
  final Widget child;
  final double width;
  final double height;
  final VoidCallback onPressed;

  const PressableButton({
    Key? key,
    required this.child,
    this.width = 160,
    this.height = 55,
    required this.onPressed,
  }) : super(key: key);

  @override
  _PressableButtonState createState() => _PressableButtonState();
}

class _PressableButtonState extends State<PressableButton> {
  bool _isPressed = false;
  bool _isClicked = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if(_isClicked) return;
        setState(
          () {
            _isPressed = true;
            _isClicked = true;
          },
        );

        Future.delayed(const Duration(milliseconds: 200), () {
          widget.onPressed();
          setState(() {
            _isClicked = false;
            _isPressed = false;
          });
        });
      },
      child: Stack(
        children: [
          // 배경 (버튼이 떠 있는 효과를 주는 부분)
          AnimatedContainer(
            duration: Duration(milliseconds: 100),
            margin: EdgeInsets.only(top: _isPressed ? 2 : 8),
            // 눌렀을 때 변화
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8), // 어두운 배경
              borderRadius: BorderRadius.circular(30),
            ),
            width: widget.width,
            height: widget.height,
          ),

          // 실제 버튼
          AnimatedContainer(
            duration: Duration(milliseconds: 100),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.black, width: 2), // 테두리 추가
            ),
            width: widget.width,
            height: widget.height,
            alignment: Alignment.center,
            child: widget.child, // 전달된 위젯을 표시
          ),
        ],
      ),
    );
  }
}
