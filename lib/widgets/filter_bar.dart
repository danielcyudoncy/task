// widgets/filter_bar.dart
import 'package:flutter/material.dart';

class FilterBarWidget extends StatelessWidget {
  final double basePadding;
  final double textScale;
  final String filterStatus;
  final String sortBy;
  final Function(String) onSearch;
  final Function(String?) onFilter;
  final Function(String?) onSort;

  const FilterBarWidget({
    super.key,
    required this.basePadding,
    required this.textScale,
    required this.filterStatus,
    required this.sortBy,
    required this.onSearch,
    required this.onFilter,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    final isLightMode = Theme.of(context).brightness == Brightness.light;

    final backgroundColor =
        isLightMode ? Colors.white : const Color(0xFF1E1E1E);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: basePadding, vertical: 12),
      color: backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Field
          TextField(
            onChanged: onSearch,
            style: TextStyle(
              color: isLightMode ? Colors.black : Colors.white,
              fontSize: 14 * textScale,
            ),
            decoration: InputDecoration(
              hintText: "Search by creator name...",
              hintStyle: TextStyle(
                color: isLightMode ? Colors.grey[600] : Colors.grey[300],
              ),
              prefixIcon: Icon(Icons.search,
                  color: isLightMode ? Colors.grey[700] : Colors.white),
              filled: true,
              fillColor: isLightMode ? Colors.white : const Color(0xFF2C2C2E),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(
                  color: isLightMode ? Colors.blue.withOpacity(0.3) : Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Filter & Sort Row
          Row(
            children: [
              // Filter Status Dropdown
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: filterStatus,
                  onChanged: onFilter,
                  style: TextStyle(
                    color: isLightMode ? Colors.black : Colors.white,
                    fontSize: 14 * textScale,
                  ),
                  decoration: InputDecoration(
                    labelText: "Filter",
                    labelStyle: TextStyle(
                      color: isLightMode ? Colors.black : Colors.white,
                    ),
                    filled: true,
                    fillColor:
                        isLightMode ? Colors.white : const Color(0xFF2C2C2E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  dropdownColor:
                      isLightMode ? Colors.white : const Color(0xFF2C2C2E),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text("All")),
                    DropdownMenuItem(value: 'Pending', child: Text("Pending")),
                    DropdownMenuItem(
                        value: 'Completed', child: Text("Completed")),
                    DropdownMenuItem(value: 'Overdue', child: Text("Overdue")),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Sort Dropdown
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: sortBy,
                  onChanged: onSort,
                  style: TextStyle(
                    color: isLightMode ? Colors.black : Colors.white,
                    fontSize: 14 * textScale,
                  ),
                  decoration: InputDecoration(
                    labelText: "Sort",
                    labelStyle: TextStyle(
                      color: isLightMode ? Colors.black : Colors.white,
                    ),
                    filled: true,
                    fillColor:
                        isLightMode ? Colors.white : const Color(0xFF2C2C2E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  dropdownColor:
                      isLightMode ? Colors.white : const Color(0xFF2C2C2E),
                  items: const [
                    DropdownMenuItem(value: 'Newest', child: Text("Newest")),
                    DropdownMenuItem(value: 'Oldest', child: Text("Oldest")),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
