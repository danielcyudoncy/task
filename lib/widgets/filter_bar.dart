import 'package:flutter/material.dart';

class FilterBarWidget extends StatelessWidget {
  final double basePadding;
  final double textScale;
  final String filterStatus;
  final String sortBy;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onFilter;
  final ValueChanged<String?> onSort;

  const FilterBarWidget({
    required this.basePadding,
    required this.textScale,
    required this.filterStatus,
    required this.sortBy,
    required this.onSearch,
    required this.onFilter,
    required this.onSort,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: basePadding, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              label: "Search by creator username",
              textField: true,
              child: TextField(
                style: TextStyle(fontSize: 15 * textScale),
                decoration: InputDecoration(
                  hintText: 'Search by creator username...',
                  prefixIcon: const Icon(Icons.search, semanticLabel: "Search Icon"),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFF171FA0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFF171FA0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFF171FA0), width: 2),
                  ),
                ),
                onChanged: onSearch,
              ),
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: filterStatus,
            underline: const SizedBox(),
            items: <String>['All', 'Completed', 'Pending', 'Overdue']
                .map((String value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: TextStyle(fontSize: 12 * textScale)),
                    ))
                .toList(),
            onChanged: onFilter,
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: sortBy,
            underline: const SizedBox(),
            items: <String>['Newest', 'Oldest']
                .map((String value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: TextStyle(fontSize: 12 * textScale)),
                    ))
                .toList(),
            onChanged: onSort,
          ),
        ],
      ),
    );
  }
}