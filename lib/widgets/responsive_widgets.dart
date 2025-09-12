// widgets/responsive_widgets.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/responsive_utils.dart';

// Adaptive navigation widget that switches between different navigation patterns
class AdaptiveNavigation extends StatelessWidget {
  final List<NavigationItem> items;
  final int currentIndex;
  final Function(int) onTap;
  final Widget? leading;
  final Widget? title;
  final List<Widget>? actions;
  
  const AdaptiveNavigation({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.leading,
    this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType) {
        switch (deviceType) {
          case DeviceType.mobile:
            return _buildBottomNavigation();
          case DeviceType.tablet:
            return _buildNavigationRail();
          case DeviceType.desktop:
          case DeviceType.largeDesktop:
            return _buildNavigationDrawer();
        }
      },
    );
  }
  
  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      items: items.map((item) => BottomNavigationBarItem(
        icon: Icon(item.icon),
        label: item.label,
        activeIcon: Icon(item.activeIcon ?? item.icon),
      )).toList(),
    );
  }
  
  Widget _buildNavigationRail() {
    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      labelType: NavigationRailLabelType.selected,
      destinations: items.map((item) => NavigationRailDestination(
        icon: Icon(item.icon),
        selectedIcon: Icon(item.activeIcon ?? item.icon),
        label: Text(item.label),
      )).toList(),
    );
  }
  
  Widget _buildNavigationDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (title != null)
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(Get.context!).primaryColor,
              ),
              child: title!,
            ),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return ListTile(
              leading: Icon(
                index == currentIndex ? (item.activeIcon ?? item.icon) : item.icon,
              ),
              title: Text(item.label),
              selected: index == currentIndex,
              onTap: () => onTap(index),
            );
          }),
        ],
      ),
    );
  }
}

// Navigation item model
class NavigationItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final String? tooltip;
  
  const NavigationItem({
    required this.icon,
    required this.label,
    this.activeIcon,
    this.tooltip,
  });
}

// Adaptive scaffold that adjusts layout based on screen size
class AdaptiveScaffold extends StatelessWidget {
  final Widget? appBar;
  final Widget body;
  final Widget? drawer;
  final Widget? endDrawer;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  
  const AdaptiveScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.drawer,
    this.endDrawer,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType) {
        final controller = ResponsiveController.to;
        
        // Adjust scaffold based on device type
        Widget scaffoldBody = body;
        
        // Add responsive padding for larger screens
        if (controller.isDesktop) {
          scaffoldBody = ResponsiveLayout(
            maxWidth: 1200,
            centerContent: true,
            child: body,
          );
        }
        
        return Scaffold(
          appBar: appBar as PreferredSizeWidget?,
          body: scaffoldBody,
          drawer: drawer,
          endDrawer: endDrawer,
          bottomNavigationBar: bottomNavigationBar,
          floatingActionButton: floatingActionButton,
          floatingActionButtonLocation: floatingActionButtonLocation,
          extendBody: extendBody,
          extendBodyBehindAppBar: extendBodyBehindAppBar,
          backgroundColor: backgroundColor,
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        );
      },
    );
  }
}

// Adaptive app bar that adjusts height and content based on screen size
class AdaptiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;
  final double? elevation;
  final bool centerTitle;
  final Widget? flexibleSpace;
  final PreferredSizeWidget? bottom;
  
  const AdaptiveAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.elevation,
    this.centerTitle = false,
    this.flexibleSpace,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType) {
        final controller = ResponsiveController.to;
        
        // Adjust app bar height based on device type
        final appBarHeight = controller.getResponsiveValue(
          mobile: kToolbarHeight,
          tablet: kToolbarHeight + 8,
          desktop: kToolbarHeight + 16,
        );
        
        // Adjust title style based on device type
        Widget? responsiveTitle = title;
        if (title is Text) {
          final textWidget = title as Text;
          final fontSize = controller.getResponsiveFontSize(
            mobile: 20.0,
            tablet: 22.0,
            desktop: 24.0,
          );
          
          responsiveTitle = Text(
            textWidget.data ?? '',
            style: (textWidget.style ?? const TextStyle()).copyWith(
              fontSize: fontSize,
            ),
          );
        }
        
        return AppBar(
          title: responsiveTitle,
          leading: leading,
          actions: actions,
          automaticallyImplyLeading: automaticallyImplyLeading,
          backgroundColor: backgroundColor,
          elevation: elevation,
          centerTitle: centerTitle || controller.isMobile,
          flexibleSpace: flexibleSpace,
          bottom: bottom,
          toolbarHeight: appBarHeight,
        );
      },
    );
  }

  @override
  Size get preferredSize {
    final controller = ResponsiveController.to;
    final height = controller.getResponsiveValue(
      mobile: kToolbarHeight,
      tablet: kToolbarHeight + 8,
      desktop: kToolbarHeight + 16,
    );
    
    return Size.fromHeight(height + (bottom?.preferredSize.height ?? 0));
  }
}

// Adaptive dialog that adjusts size and position based on screen size
class AdaptiveDialog extends StatelessWidget {
  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final EdgeInsets? contentPadding;
  final bool scrollable;
  final double? maxWidth;
  final double? maxHeight;
  
  const AdaptiveDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.contentPadding,
    this.scrollable = false,
    this.maxWidth,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType) {
        final controller = ResponsiveController.to;
        
        // Adjust dialog constraints based on device type
        final dialogMaxWidth = maxWidth ?? controller.getResponsiveValue<double>(
          mobile: MediaQuery.of(context).size.width * 0.9,
          tablet: 500.0,
          desktop: 600.0,
        );
        
        final dialogMaxHeight = maxHeight ?? controller.getResponsiveValue<double>(
          mobile: MediaQuery.of(context).size.height * 0.8,
          tablet: MediaQuery.of(context).size.height * 0.7,
          desktop: MediaQuery.of(context).size.height * 0.6,
        );
        
        // Use different dialog types based on device
        if (controller.isMobile) {
          return AlertDialog(
            title: title,
            content: content != null
                ? ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: dialogMaxWidth,
                      maxHeight: dialogMaxHeight,
                    ),
                    child: content!,
                  )
                : null,
            actions: actions,
            contentPadding: contentPadding,
            scrollable: scrollable,
          );
        } else {
          return Dialog(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: dialogMaxWidth,
                maxHeight: dialogMaxHeight,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null)
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: DefaultTextStyle(
                        style: Theme.of(context).textTheme.headlineSmall!,
                        child: title!,
                      ),
                    ),
                  if (content != null)
                    Flexible(
                      child: Padding(
                        padding: contentPadding ?? const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 24.0),
                        child: scrollable
                            ? SingleChildScrollView(child: content!)
                            : content!,
                      ),
                    ),
                  if (actions != null && actions!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: actions!,
                      ),
                    ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}

// Adaptive list view that adjusts item layout based on screen size
class AdaptiveListView extends StatelessWidget {
  final List<Widget> children;
  final ScrollController? controller;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsets? padding;
  final bool useCards;
  final double? itemSpacing;
  
  const AdaptiveListView({
    super.key,
    required this.children,
    this.controller,
    this.shrinkWrap = false,
    this.physics,
    this.padding,
    this.useCards = false,
    this.itemSpacing,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType) {
        final responsiveController = ResponsiveController.to;
        
        // Adjust spacing based on device type
        final spacing = itemSpacing ?? responsiveController.getResponsiveValue(
          mobile: 8.0,
          tablet: 12.0,
          desktop: 16.0,
        );
        
        // Adjust padding based on device type
        final listPadding = padding ?? responsiveController.getResponsivePadding();
        
        List<Widget> listChildren = children;
        
        // Wrap items in cards for larger screens if requested
        if (useCards && responsiveController.isDesktop) {
          listChildren = children.map((child) => ResponsiveCard(
            child: child,
          )).toList();
        }
        
        // Add spacing between items
        if (spacing != null && spacing > 0) {
          final spacedChildren = <Widget>[];
          for (int i = 0; i < listChildren.length; i++) {
            spacedChildren.add(listChildren[i]);
            if (i < listChildren.length - 1) {
              spacedChildren.add(SizedBox(height: spacing));
            }
          }
          listChildren = spacedChildren;
        }
        
        return ListView(
          controller: controller,
          shrinkWrap: shrinkWrap,
          physics: physics,
          padding: listPadding,
          children: listChildren,
        );
      },
    );
  }
}

// Adaptive form field that adjusts size and layout based on screen size
class AdaptiveFormField extends StatelessWidget {
  final String? label;
  final String? hint;
  final Widget child;
  final bool isRequired;
  final String? errorText;
  final Widget? prefix;
  final Widget? suffix;
  
  const AdaptiveFormField({
    super.key,
    this.label,
    this.hint,
    required this.child,
    this.isRequired = false,
    this.errorText,
    this.prefix,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType) {
        final controller = ResponsiveController.to;
        
        // Adjust field spacing based on device type
        final fieldSpacing = controller.getResponsiveValue(
          mobile: 8.0,
          tablet: 12.0,
          desktop: 16.0,
        );
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label != null)
              Padding(
                padding: EdgeInsets.only(bottom: fieldSpacing / 2),
                child: Row(
                  children: [
                    ResponsiveText(
                      label!,
                      style: Theme.of(context).textTheme.labelLarge,
                      mobileFontSize: 14.0,
                      tabletFontSize: 15.0,
                      desktopFontSize: 16.0,
                    ),
                    if (isRequired)
                      Text(
                        ' *',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ),
            Row(
              children: [
                if (prefix != null) ...[prefix!, const SizedBox(width: 8)],
                Expanded(child: child),
                if (suffix != null) ...[const SizedBox(width: 8), suffix!],
              ],
            ),
            if (errorText != null)
              Padding(
                padding: EdgeInsets.only(top: fieldSpacing / 2),
                child: ResponsiveText(
                  errorText!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                  mobileFontSize: 12.0,
                  tabletFontSize: 13.0,
                  desktopFontSize: 14.0,
                ),
              ),
            SizedBox(height: fieldSpacing),
          ],
        );
      },
    );
  }
}

// Adaptive button that adjusts size based on screen size
class AdaptiveButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final Widget? icon;
  final bool isLoading;
  final bool isFullWidth;
  
  const AdaptiveButton({
    super.key,
    required this.text,
    this.onPressed,
    this.style,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType) {
        final controller = ResponsiveController.to;
        
        // Adjust button padding based on device type
        final buttonPadding = controller.getResponsiveValue(
          mobile: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          tablet: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          desktop: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        );
        
        // Adjust font size based on device type
        final fontSize = controller.getResponsiveFontSize(
          mobile: 14.0,
          tablet: 15.0,
          desktop: 16.0,
        );
        
        final buttonStyle = (style ?? ElevatedButton.styleFrom()).copyWith(
          padding: WidgetStateProperty.all(buttonPadding),
          textStyle: WidgetStateProperty.all(
            TextStyle(fontSize: fontSize),
          ),
        );
        
        Widget button;
        
        if (icon != null) {
          button = ElevatedButton.icon(
            onPressed: isLoading ? null : onPressed,
            icon: isLoading ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ) : icon!,
            label: Text(text),
            style: buttonStyle,
          );
        } else {
          button = ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: buttonStyle,
            child: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(text),
          );
        }
        
        if (isFullWidth) {
          return SizedBox(
            width: double.infinity,
            child: button,
          );
        }
        
        return button;
      },
    );
  }
}