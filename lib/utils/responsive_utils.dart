import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Screen size breakpoints
class Breakpoints {
  static const double mobile = 480;
  static const double tablet = 768;
  static const double desktop = 1024;
  static const double largeDesktop = 1440;

  // Common mobile breakpoints
  static const double smallMobile = 320;
  static const double largeMobile = 414;

  // Tablet breakpoints
  static const double smallTablet = 600;
  static const double largeTablet = 900;
}

// Device type enumeration
enum DeviceType {
  mobile,
  tablet,
  desktop,
  largeDesktop,
}

// Screen orientation
enum ScreenOrientation {
  portrait,
  landscape,
}

// Responsive controller for managing screen information
class ResponsiveController extends GetxController {
  static ResponsiveController get to => Get.find();

  final Rx<DeviceType> _deviceType = DeviceType.mobile.obs;
  final Rx<ScreenOrientation> _orientation = ScreenOrientation.portrait.obs;
  final RxDouble _screenWidth = 0.0.obs;
  final RxDouble _screenHeight = 0.0.obs;
  final RxDouble _safeAreaTop = 0.0.obs;
  final RxDouble _safeAreaBottom = 0.0.obs;
  final RxBool _isKeyboardVisible = false.obs;

  // Getters
  DeviceType get deviceType => _deviceType.value;
  ScreenOrientation get orientation => _orientation.value;
  double get screenWidth => _screenWidth.value;
  double get screenHeight => _screenHeight.value;
  double get safeAreaTop => _safeAreaTop.value;
  double get safeAreaBottom => _safeAreaBottom.value;
  bool get isKeyboardVisible => _isKeyboardVisible.value;

  // Observables
  Rx<DeviceType> get deviceTypeObs => _deviceType;
  Rx<ScreenOrientation> get orientationObs => _orientation;
  RxDouble get screenWidthObs => _screenWidth;
  RxDouble get screenHeightObs => _screenHeight;
  RxBool get isKeyboardVisibleObs => _isKeyboardVisible;

  // Device type checks
  bool get isMobile => deviceType == DeviceType.mobile;
  bool get isTablet => deviceType == DeviceType.tablet;
  bool get isDesktop =>
      deviceType == DeviceType.desktop || deviceType == DeviceType.largeDesktop;
  bool get isLargeDevice =>
      deviceType == DeviceType.desktop || deviceType == DeviceType.largeDesktop;

  // Orientation checks
  bool get isPortrait => orientation == ScreenOrientation.portrait;
  bool get isLandscape => orientation == ScreenOrientation.landscape;

  // Screen size checks
  bool get isSmallScreen => screenWidth < Breakpoints.mobile;
  bool get isMediumScreen =>
      screenWidth >= Breakpoints.mobile && screenWidth < Breakpoints.desktop;
  bool get isLargeScreen => screenWidth >= Breakpoints.desktop;

  @override
  void onInit() {
    super.onInit();
    _updateScreenInfo();
  }

  void updateScreenInfo(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final padding = mediaQuery.padding;

    _screenWidth.value = size.width;
    _screenHeight.value = size.height;
    _safeAreaTop.value = padding.top;
    _safeAreaBottom.value = padding.bottom;

    // Determine device type
    _deviceType.value = _getDeviceType(size.width);

    // Determine orientation
    _orientation.value = size.width > size.height
        ? ScreenOrientation.landscape
        : ScreenOrientation.portrait;

    // Check keyboard visibility
    _isKeyboardVisible.value = mediaQuery.viewInsets.bottom > 0;
  }

  void _updateScreenInfo() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.context != null) {
        updateScreenInfo(Get.context!);
      }
    });
  }

  DeviceType _getDeviceType(double width) {
    if (width >= Breakpoints.largeDesktop) {
      return DeviceType.largeDesktop;
    } else if (width >= Breakpoints.desktop) {
      return DeviceType.desktop;
    } else if (width >= Breakpoints.tablet) {
      return DeviceType.tablet;
    } else {
      return DeviceType.mobile;
    }
  }

  // Get responsive value based on screen size
  T getResponsiveValue<T>({
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    switch (deviceType) {
      case DeviceType.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.mobile:
        return mobile;
    }
  }

  // Get responsive padding
  EdgeInsets getResponsivePadding({
    double? mobile,
    double? tablet,
    double? desktop,
  }) {
    final padding = getResponsiveValue(
      mobile: mobile ?? 16.0,
      tablet: tablet ?? 24.0,
      desktop: desktop ?? 32.0,
    );
    return EdgeInsets.all(padding);
  }

  // Get responsive margin
  EdgeInsets getResponsiveMargin({
    double? mobile,
    double? tablet,
    double? desktop,
  }) {
    final margin = getResponsiveValue(
      mobile: mobile ?? 8.0,
      tablet: tablet ?? 12.0,
      desktop: desktop ?? 16.0,
    );
    return EdgeInsets.all(margin);
  }

  // Get responsive font size
  double getResponsiveFontSize({
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return getResponsiveValue(
      mobile: mobile,
      tablet: tablet ?? mobile * 1.1,
      desktop: desktop ?? mobile * 1.2,
    );
  }

  // Get responsive icon size
  double getResponsiveIconSize({
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return getResponsiveValue(
      mobile: mobile,
      tablet: tablet ?? mobile * 1.2,
      desktop: desktop ?? mobile * 1.4,
    );
  }

  // Get grid columns based on screen size
  int getGridColumns({
    int mobile = 1,
    int tablet = 2,
    int desktop = 3,
    int largeDesktop = 4,
  }) {
    return getResponsiveValue(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
  }
}

// Responsive builder widget
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext, DeviceType) builder;
  final Widget Function(BuildContext)? mobile;
  final Widget Function(BuildContext)? tablet;
  final Widget Function(BuildContext)? desktop;
  final Widget Function(BuildContext)? largeDesktop;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  })  : mobile = null,
        tablet = null,
        desktop = null,
        largeDesktop = null;

  const ResponsiveBuilder.specific({
    super.key,
    this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  }) : builder = _defaultBuilder;

  static Widget _defaultBuilder(BuildContext context, DeviceType deviceType) {
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Update responsive controller
        ResponsiveController.to.updateScreenInfo(context);

        final deviceType = ResponsiveController.to.deviceType;

        // Use specific builders if provided
        if (mobile != null ||
            tablet != null ||
            desktop != null ||
            largeDesktop != null) {
          switch (deviceType) {
            case DeviceType.largeDesktop:
              return largeDesktop?.call(context) ??
                  desktop?.call(context) ??
                  tablet?.call(context) ??
                  mobile?.call(context) ??
                  const SizedBox.shrink();
            case DeviceType.desktop:
              return desktop?.call(context) ??
                  tablet?.call(context) ??
                  mobile?.call(context) ??
                  const SizedBox.shrink();
            case DeviceType.tablet:
              return tablet?.call(context) ??
                  mobile?.call(context) ??
                  const SizedBox.shrink();
            case DeviceType.mobile:
              return mobile?.call(context) ?? const SizedBox.shrink();
          }
        }

        // Use general builder
        return builder(context, deviceType);
      },
    );
  }
}

// Responsive layout widget
class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? maxWidth;
  final bool centerContent;

  const ResponsiveLayout({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.maxWidth,
    this.centerContent = false,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType) {
        final controller = ResponsiveController.to;

        // Get responsive padding and margin
        final responsivePadding = padding ?? controller.getResponsivePadding();
        final responsiveMargin = margin ?? controller.getResponsiveMargin();

        // Get max width
        final containerMaxWidth = maxWidth ??
            controller.getResponsiveValue<double>(
              mobile: double.infinity,
              tablet: 800.0,
              desktop: 1200.0,
              largeDesktop: 1400.0,
            );

        Widget content = Container(
          constraints: BoxConstraints(maxWidth: containerMaxWidth),
          padding: responsivePadding,
          margin: responsiveMargin,
          child: child,
        );

        if (centerContent && controller.isDesktop) {
          content = Center(child: content);
        }

        return content;
      },
    );
  }
}

// Responsive grid view
class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final int? largeDesktopColumns;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const ResponsiveGridView({
    super.key,
    required this.children,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.largeDesktopColumns,
    this.mainAxisSpacing = 8.0,
    this.crossAxisSpacing = 8.0,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType) {
        final controller = ResponsiveController.to;

        final columns = controller.getGridColumns(
          mobile: mobileColumns ?? 1,
          tablet: tabletColumns ?? 2,
          desktop: desktopColumns ?? 3,
          largeDesktop: largeDesktopColumns ?? 4,
        );

        return GridView.count(
          crossAxisCount: columns,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          padding: padding,
          shrinkWrap: shrinkWrap,
          physics: physics,
          children: children,
        );
      },
    );
  }
}

// Responsive text widget
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final double? mobileFontSize;
  final double? tabletFontSize;
  final double? desktopFontSize;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.mobileFontSize,
    this.tabletFontSize,
    this.desktopFontSize,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType) {
        final controller = ResponsiveController.to;

        final fontSize = controller.getResponsiveFontSize(
          mobile: mobileFontSize ?? 14.0,
          tablet: tabletFontSize ?? (mobileFontSize ?? 14.0) * 1.1,
          desktop: desktopFontSize ?? (mobileFontSize ?? 14.0) * 1.2,
        );

        final responsiveStyle = (style ?? const TextStyle()).copyWith(
          fontSize: fontSize,
        );

        return Text(
          text,
          style: responsiveStyle,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );
      },
    );
  }
}

// Responsive spacing widget
class ResponsiveSpacing extends StatelessWidget {
  final double? mobile;
  final double? tablet;
  final double? desktop;
  final bool isHorizontal;

  const ResponsiveSpacing({
    super.key,
    this.mobile,
    this.tablet,
    this.desktop,
    this.isHorizontal = false,
  });

  const ResponsiveSpacing.horizontal({
    super.key,
    this.mobile,
    this.tablet,
    this.desktop,
  }) : isHorizontal = true;

  const ResponsiveSpacing.vertical({
    super.key,
    this.mobile,
    this.tablet,
    this.desktop,
  }) : isHorizontal = false;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType) {
        final controller = ResponsiveController.to;

        final spacing = controller.getResponsiveValue(
          mobile: mobile ?? 8.0,
          tablet: tablet ?? 12.0,
          desktop: desktop ?? 16.0,
        );

        return SizedBox(
          width: isHorizontal ? spacing : null,
          height: isHorizontal ? null : spacing,
        );
      },
    );
  }
}

// Responsive card widget
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? elevation;
  final BorderRadius? borderRadius;
  final Color? color;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.elevation,
    this.borderRadius,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType) {
        final controller = ResponsiveController.to;

        final responsivePadding = padding ??
            controller.getResponsivePadding(
              mobile: 12.0,
              tablet: 16.0,
              desktop: 20.0,
            );

        final responsiveMargin = margin ??
            controller.getResponsiveMargin(
              mobile: 4.0,
              tablet: 6.0,
              desktop: 8.0,
            );

        final responsiveElevation = elevation ??
            controller.getResponsiveValue(
              mobile: 2.0,
              tablet: 4.0,
              desktop: 6.0,
            );

        return Card(
          elevation: responsiveElevation,
          color: color,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(8),
          ),
          margin: responsiveMargin,
          child: Padding(
            padding: responsivePadding,
            child: child,
          ),
        );
      },
    );
  }
}

// Utility functions
class ResponsiveUtils {
  static ResponsiveController get controller => ResponsiveController.to;

  // Check if screen is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < Breakpoints.tablet;
  }

  // Check if screen is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= Breakpoints.tablet && width < Breakpoints.desktop;
  }

  // Check if screen is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= Breakpoints.desktop;
  }

  // Get screen width
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  // Get screen height
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  // Get safe area padding
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  // Get responsive columns for grid
  static int getGridColumns(
    BuildContext context, {
    int mobile = 1,
    int tablet = 2,
    int desktop = 3,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }

  // Get responsive aspect ratio
  static double getAspectRatio(
    BuildContext context, {
    double mobile = 16 / 9,
    double tablet = 4 / 3,
    double desktop = 16 / 10,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }
}
