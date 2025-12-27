import 'package:flutter/material.dart';

class CustomWosoolAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;

  const CustomWosoolAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF4A80F0), // اللون الأزرق الاحترافي
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(35), // انحناء دائري كما في الصورة
          bottomRight: Radius.circular(35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // الأيقونات الجانبية (leading)
            Align(alignment: Alignment.centerRight, child: leading),
            // العنوان في المنتصف تماماً
            Center(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // الأيقونات في الجهة الأخرى (actions)
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: actions ?? [],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(90); // ارتفاع مريح للعين
}
