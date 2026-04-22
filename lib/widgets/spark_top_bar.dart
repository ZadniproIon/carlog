import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SparkTopBar extends StatelessWidget implements PreferredSizeWidget {
  const SparkTopBar({
    super.key,
    required this.title,
    this.actions,
    this.bottom,
    this.leading,
    this.automaticallyImplyLeading = true,
  });

  final Widget title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize =>
      Size.fromHeight(72 + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final showLeading =
        leading != null || (automaticallyImplyLeading && canPop);
    final dividerColor = Theme.of(context).dividerColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final surface = Theme.of(context).colorScheme.surface;

    return Theme(
      data: Theme.of(context).copyWith(
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            shape: CircleBorder(side: BorderSide(color: dividerColor)),
            backgroundColor: surface,
            foregroundColor: onSurface,
            padding: const EdgeInsets.all(12),
            minimumSize: const Size(48, 48),
          ),
        ),
      ),
      child: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        toolbarHeight: 72,
        titleSpacing: 20,
        leadingWidth: 64,
        title: title,
        leading: showLeading
            ? Padding(
                padding: const EdgeInsets.only(left: 16),
                child:
                    leading ??
                    IconButton(
                      tooltip: 'Back',
                      onPressed: () {
                        Navigator.of(context).maybePop();
                      },
                      icon: const Icon(LucideIcons.arrowLeft),
                    ),
              )
            : null,
        actionsPadding: const EdgeInsets.only(right: 16),
        actions: actions,
        bottom: bottom,
      ),
    );
  }
}
