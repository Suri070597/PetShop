import 'package:flutter/widgets.dart';

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  static const double mobileBreakpoint = 600;
  static const double desktopBreakpoint = 1000;

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  static bool isMobileWidth(double width) => width < mobileBreakpoint;
  static bool isTabletWidth(double width) =>
      width >= mobileBreakpoint && width <= desktopBreakpoint;
  static bool isDesktopWidth(double width) => width > desktopBreakpoint;

  static EdgeInsets pagePaddingForWidth(double width) {
    if (isDesktopWidth(width)) {
      return const EdgeInsets.fromLTRB(32, 20, 32, 24);
    }
    if (isTabletWidth(width)) {
      return const EdgeInsets.fromLTRB(28, 18, 28, 24);
    }
    return const EdgeInsets.fromLTRB(22, 16, 22, 24);
  }

  static int productGridColumnsForWidth(double width) {
    if (isDesktopWidth(width)) {
      return 4;
    }
    if (isTabletWidth(width)) {
      return 3;
    }
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (isDesktopWidth(width)) {
          return desktop ?? tablet ?? mobile;
        }
        if (isTabletWidth(width)) {
          return tablet ?? mobile;
        }
        return mobile;
      },
    );
  }
}
