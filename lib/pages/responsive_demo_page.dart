// pages/responsive_demo_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/responsive_utils.dart';
import '../widgets/responsive_widgets.dart';

class ResponsiveDemoPage extends StatelessWidget {
  const ResponsiveDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      appBar: AdaptiveAppBar(
        title: Text('responsive_layout'.tr),
        centerTitle: true,
      ),
      body: const ResponsiveDemoContent(),
    );
  }
}

class ResponsiveDemoContent extends StatelessWidget {
  const ResponsiveDemoContent({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Screen info section
            const _ScreenInfoSection(),
            const ResponsiveSpacing.vertical(mobile: 24, tablet: 32, desktop: 40),
            
            // Responsive grid section
            const _ResponsiveGridSection(),
            const ResponsiveSpacing.vertical(mobile: 24, tablet: 32, desktop: 40),
            
            // Responsive text section
            const _ResponsiveTextSection(),
            const ResponsiveSpacing.vertical(mobile: 24, tablet: 32, desktop: 40),
            
            // Responsive cards section
            const _ResponsiveCardsSection(),
            const ResponsiveSpacing.vertical(mobile: 24, tablet: 32, desktop: 40),
            
            // Responsive form section
            const _ResponsiveFormSection(),
            const ResponsiveSpacing.vertical(mobile: 24, tablet: 32, desktop: 40),
            
            // Responsive buttons section
            const _ResponsiveButtonsSection(),
          ],
        ),
      ),
    );
  }
}

class _ScreenInfoSection extends StatelessWidget {
  const _ScreenInfoSection();

  @override
  Widget build(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'screen_size'.tr,
            style: Theme.of(context).textTheme.headlineSmall,
            mobileFontSize: 20,
            tabletFontSize: 22,
            desktopFontSize: 24,
          ),
          const ResponsiveSpacing.vertical(mobile: 16, tablet: 20, desktop: 24),
          Obx(() {
            final controller = ResponsiveController.to;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                  'Device Type',
                  controller.deviceType.toString().split('.').last.toUpperCase(),
                ),
                _InfoRow(
                  'Screen Width',
                  '${controller.screenWidth.toStringAsFixed(0)}px',
                ),
                _InfoRow(
                  'Screen Height',
                  '${controller.screenHeight.toStringAsFixed(0)}px',
                ),
                _InfoRow(
                  'Orientation',
                  controller.isPortrait
                      ? 'orientation_portrait'.tr
                       : 'orientation_landscape'.tr,
                ),
                _InfoRow(
                  'Is Mobile',
                  controller.isMobile.toString(),
                ),
                _InfoRow(
                  'Is Tablet',
                  controller.isTablet.toString(),
                ),
                _InfoRow(
                  'Is Desktop',
                  controller.isDesktop.toString(),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ResponsiveText(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
            mobileFontSize: 14,
            tabletFontSize: 15,
            desktopFontSize: 16,
          ),
          ResponsiveText(
            value,
            mobileFontSize: 14,
            tabletFontSize: 15,
            desktopFontSize: 16,
          ),
        ],
      ),
    );
  }
}

class _ResponsiveGridSection extends StatelessWidget {
  const _ResponsiveGridSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          'Responsive Grid',
          style: Theme.of(context).textTheme.headlineSmall,
          mobileFontSize: 20,
          tabletFontSize: 22,
          desktopFontSize: 24,
        ),
        const ResponsiveSpacing.vertical(mobile: 16, tablet: 20, desktop: 24),
        ResponsiveGridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mobileColumns: 1,
          tabletColumns: 2,
          desktopColumns: 3,
          largeDesktopColumns: 4,
          children: List.generate(8, (index) => ResponsiveCard(
            child: SizedBox(
              height: 100,
              child: Center(
                child: ResponsiveText(
                  'Item ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  mobileFontSize: 16,
                  tabletFontSize: 18,
                  desktopFontSize: 20,
                ),
              ),
            ),
          )),
        ),
      ],
    );
  }
}

class _ResponsiveTextSection extends StatelessWidget {
  const _ResponsiveTextSection();

  @override
  Widget build(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Responsive Typography',
            style: Theme.of(context).textTheme.headlineSmall,
            mobileFontSize: 20,
            tabletFontSize: 22,
            desktopFontSize: 24,
          ),
          const ResponsiveSpacing.vertical(mobile: 16, tablet: 20, desktop: 24),
          ResponsiveText(
            'This is a heading that adapts to screen size',
            style: Theme.of(context).textTheme.headlineMedium,
            mobileFontSize: 24,
            tabletFontSize: 28,
            desktopFontSize: 32,
          ),
          const ResponsiveSpacing.vertical(mobile: 12, tablet: 16, desktop: 20),
          ResponsiveText(
            'This is body text that scales appropriately across different devices. On mobile devices, it uses a smaller font size for better readability, while on tablets and desktops, it uses larger sizes to take advantage of the available screen space.',
            mobileFontSize: 14,
            tabletFontSize: 16,
            desktopFontSize: 18,
          ),
          const ResponsiveSpacing.vertical(mobile: 12, tablet: 16, desktop: 20),
          ResponsiveText(
            'Small text for captions and labels',
            style: Theme.of(context).textTheme.bodySmall,
            mobileFontSize: 12,
            tabletFontSize: 13,
            desktopFontSize: 14,
          ),
        ],
      ),
    );
  }
}

class _ResponsiveCardsSection extends StatelessWidget {
  const _ResponsiveCardsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          'Responsive Cards',
          style: Theme.of(context).textTheme.headlineSmall,
          mobileFontSize: 20,
          tabletFontSize: 22,
          desktopFontSize: 24,
        ),
        const ResponsiveSpacing.vertical(mobile: 16, tablet: 20, desktop: 24),
        Row(
          children: [
            Expanded(
              child: ResponsiveCard(
                child: Column(
                  children: [
                    Icon(
                      Icons.phone_android,
                      size: ResponsiveController.to.getResponsiveIconSize(
                        mobile: 32,
                        tablet: 40,
                        desktop: 48,
                      ),
                      color: Theme.of(context).primaryColor,
                    ),
                    const ResponsiveSpacing.vertical(mobile: 8, tablet: 12, desktop: 16),
                    ResponsiveText(
                      'mobile_view'.tr,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      mobileFontSize: 14,
                      tabletFontSize: 16,
                      desktopFontSize: 18,
                    ),
                  ],
                ),
              ),
            ),
            const ResponsiveSpacing.horizontal(mobile: 8, tablet: 12, desktop: 16),
            Expanded(
              child: ResponsiveCard(
                child: Column(
                  children: [
                    Icon(
                      Icons.tablet_android,
                      size: ResponsiveController.to.getResponsiveIconSize(
                        mobile: 32,
                        tablet: 40,
                        desktop: 48,
                      ),
                      color: Theme.of(context).primaryColor,
                    ),
                    const ResponsiveSpacing.vertical(mobile: 8, tablet: 12, desktop: 16),
                    ResponsiveText(
                      'tablet_view'.tr,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      mobileFontSize: 14,
                      tabletFontSize: 16,
                      desktopFontSize: 18,
                    ),
                  ],
                ),
              ),
            ),
            const ResponsiveSpacing.horizontal(mobile: 8, tablet: 12, desktop: 16),
            Expanded(
              child: ResponsiveCard(
                child: Column(
                  children: [
                    Icon(
                      Icons.desktop_windows,
                      size: ResponsiveController.to.getResponsiveIconSize(
                        mobile: 32,
                        tablet: 40,
                        desktop: 48,
                      ),
                      color: Theme.of(context).primaryColor,
                    ),
                    const ResponsiveSpacing.vertical(mobile: 8, tablet: 12, desktop: 16),
                    ResponsiveText(
                      'desktop_view'.tr,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      mobileFontSize: 14,
                      tabletFontSize: 16,
                      desktopFontSize: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ResponsiveFormSection extends StatelessWidget {
  const _ResponsiveFormSection();

  @override
  Widget build(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Responsive Form',
            style: Theme.of(context).textTheme.headlineSmall,
            mobileFontSize: 20,
            tabletFontSize: 22,
            desktopFontSize: 24,
          ),
          const ResponsiveSpacing.vertical(mobile: 16, tablet: 20, desktop: 24),
          AdaptiveFormField(
            label: 'Name',
            isRequired: true,
            child: TextFormField(
              decoration: const InputDecoration(
                hintText: 'Enter your name',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          AdaptiveFormField(
            label: 'Email',
            isRequired: true,
            child: TextFormField(
              decoration: const InputDecoration(
                hintText: 'Enter your email',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          AdaptiveFormField(
            label: 'Message',
            child: TextFormField(
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Enter your message',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponsiveButtonsSection extends StatelessWidget {
  const _ResponsiveButtonsSection();

  @override
  Widget build(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Responsive Buttons',
            style: Theme.of(context).textTheme.headlineSmall,
            mobileFontSize: 20,
            tabletFontSize: 22,
            desktopFontSize: 24,
          ),
          const ResponsiveSpacing.vertical(mobile: 16, tablet: 20, desktop: 24),
          ResponsiveBuilder(
            builder: (context, deviceType) {
              if (deviceType == DeviceType.mobile) {
                // Stack buttons vertically on mobile
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AdaptiveButton(
                      text: 'Primary Action',
                      onPressed: () {},
                      isFullWidth: true,
                    ),
                    const ResponsiveSpacing.vertical(mobile: 12),
                    AdaptiveButton(
                      text: 'Secondary Action',
                      onPressed: () {},
                      isFullWidth: true,
                    ),
                    const ResponsiveSpacing.vertical(mobile: 12),
                    AdaptiveButton(
                      text: 'With Icon',
                      icon: const Icon(Icons.star),
                      onPressed: () {},
                      isFullWidth: true,
                    ),
                  ],
                );
              } else {
                // Arrange buttons horizontally on larger screens
                return Row(
                  children: [
                    AdaptiveButton(
                      text: 'Primary Action',
                      onPressed: () {},
                    ),
                    const ResponsiveSpacing.horizontal(tablet: 12, desktop: 16),
                    AdaptiveButton(
                      text: 'Secondary Action',
                      onPressed: () {},
                    ),
                    const ResponsiveSpacing.horizontal(tablet: 12, desktop: 16),
                    AdaptiveButton(
                      text: 'With Icon',
                      icon: const Icon(Icons.star),
                      onPressed: () {},
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }
}