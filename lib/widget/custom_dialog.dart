import 'package:flutter/material.dart';

class CustomDialog extends StatelessWidget {
  final String title;
  final String message;
  final String cancelText;
  final String confirmText;
  final Color confirmColor;
  final Color cancelColor;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;
  final IconData? icon;
  final Color? iconColor;
  final bool isDestructive;

  const CustomDialog({
    Key? key,
    required this.title,
    required this.message,
    this.cancelText = '취소',
    this.confirmText = '확인',
    this.confirmColor = Colors.blue,
    this.cancelColor = Colors.grey,
    this.onCancel,
    this.onConfirm,
    this.icon,
    this.iconColor,
    this.isDestructive = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _buildDialogContent(context),
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // Main dialog container
        Container(
          margin: const EdgeInsets.only(top: 30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Add extra space at top for the icon overlap
              const SizedBox(height: 30),

              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 8),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Message
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Cancel button
                    Expanded(
                      child: _dialogButton(
                        context: context,
                        text: cancelText,
                        textColor: Colors.grey[700]!,
                        backgroundColor: Colors.grey[200]!,
                        onPressed: () {
                          if (onCancel != null) {
                            onCancel!();
                          } else {
                            Navigator.of(context).pop(false);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Confirm button
                    Expanded(
                      child: _dialogButton(
                        context: context,
                        text: confirmText,
                        textColor: Colors.white,
                        backgroundColor: isDestructive ? Colors.red : confirmColor,
                        onPressed: () {
                          if (onConfirm != null) {
                            onConfirm!();
                          } else {
                            Navigator.of(context).pop(true);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Floating icon at the top
        if (icon != null)
          Container(
            decoration: BoxDecoration(
              color: iconColor ?? (isDestructive ? Colors.red : confirmColor),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
      ],
    );
  }

  Widget _dialogButton({
    required BuildContext context,
    required String text,
    required Color textColor,
    required Color backgroundColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(15),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Helper for showing confirmation dialog
Future<bool?> showCustomConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String cancelText = '취소',
  String confirmText = '확인',
  IconData? icon,
  Color? iconColor,
  bool isDestructive = false,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return CustomDialog(
        title: title,
        message: message,
        cancelText: cancelText,
        confirmText: confirmText,
        icon: icon,
        iconColor: iconColor,
        isDestructive: isDestructive,
      );
    },
  );
}

// Helper for showing alert dialog (one button)
Future<void> showCustomAlertDialog({
  required BuildContext context,
  required String title,
  required String message,
  String buttonText = '확인',
  IconData? icon,
  Color? iconColor,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Main dialog container
            Container(
              margin: const EdgeInsets.only(top: 30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 8),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Text(
                      message,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          buttonText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Floating icon at the top
            if (icon != null)
              Container(
                decoration: BoxDecoration(
                  color: iconColor ?? Colors.blue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
          ],
        ),
      );
    },
  );
}