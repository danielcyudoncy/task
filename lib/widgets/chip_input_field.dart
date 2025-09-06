// widgets/chip_input_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChipInputField<T> extends StatefulWidget {
  final List<T> initialItems;
  final List<T> availableSuggestions;
  final Widget Function(BuildContext, T) itemBuilder;
  final Widget Function(BuildContext, T) suggestionBuilder;
  final void Function(List<T>) onChanged;
  final InputDecoration decoration;
  final double chipSpacing;
  final double runSpacing;
  final bool showSuggestionsOnFocus;
  final bool allowDuplicates;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final TextEditingController? controller;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const ChipInputField({
    super.key,
    this.initialItems = const [],
    this.availableSuggestions = const [],
    required this.itemBuilder,
    required this.suggestionBuilder,
    required this.onChanged,
    this.decoration = const InputDecoration(),
    this.chipSpacing = 8.0,
    this.runSpacing = 8.0,
    this.showSuggestionsOnFocus = true,
    this.allowDuplicates = false,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.focusNode,
    this.controller,
    this.textInputAction,
    this.onSubmitted,
  });

@override
  State<ChipInputField<T>> createState() => _ChipInputFieldState<T>();
}

class _ChipInputFieldState<T> extends State<ChipInputField<T>> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final Set<T> _items = {};
  final List<T> _filteredSuggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _items.addAll(widget.initialItems);
    
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && widget.showSuggestionsOnFocus) {
        _showSuggestionOverlay();
      } else {
        _hideSuggestionOverlay();
      }
    });
  }

  @override
  void didUpdateWidget(ChipInputField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.controller == null && oldWidget.controller != null) {
      _controller = TextEditingController();
    } else if (widget.controller != null && oldWidget.controller == null) {
      _controller = widget.controller!;
    }
    
    if (widget.focusNode == null && oldWidget.focusNode != null) {
      _focusNode = FocusNode();
      _setupFocusNode();
    } else if (widget.focusNode != null && oldWidget.focusNode == null) {
      _focusNode = widget.focusNode!;
      _setupFocusNode();
    }
    
    if (widget.initialItems != oldWidget.initialItems) {
      _items.clear();
      _items.addAll(widget.initialItems);
    }
  }

  void _setupFocusNode() {
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && widget.showSuggestionsOnFocus) {
        _showSuggestionOverlay();
      } else {
        _hideSuggestionOverlay();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _hideSuggestionOverlay();
    super.dispose();
  }

  void _showSuggestionOverlay() {
    if (_overlayEntry != null) return;
    
    _filterSuggestions(_controller.text);
    
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 4.0,
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 4.0),
          child: Material(
            elevation: 4.0,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200.0),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(4.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8.0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _filteredSuggestions.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'No suggestions available',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).hintColor,
                            ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _filteredSuggestions.length,
                      itemBuilder: (context, index) => widget.suggestionBuilder(
                        context,
                        _filteredSuggestions[index],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _showSuggestions = true;
  }

  void _hideSuggestionOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _showSuggestions = false;
  }

  void _filterSuggestions(String query) {
    if (query.isEmpty) {
      _filteredSuggestions.clear();
      _filteredSuggestions.addAll(
        widget.availableSuggestions.where(
          (suggestion) => !_items.contains(suggestion),
        ),
      );
    } else {
      _filteredSuggestions.clear();
      _filteredSuggestions.addAll(
        widget.availableSuggestions.where((suggestion) {
          if (_items.contains(suggestion) && !widget.allowDuplicates) {
            return false;
          }
          return suggestion.toString().toLowerCase().contains(
                query.toLowerCase(),
              );
        }),
      );
    }
    
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _addItem(T item) {
    if (_items.contains(item) && !widget.allowDuplicates) {
      return;
    }
    
    setState(() {
      _items.add(item);
      _controller.clear();
      _filterSuggestions('');
      widget.onChanged(_items.toList());
    });
    
    _focusNode.requestFocus();
  }


  void _onSubmitted(String value) {
    if (value.trim().isNotEmpty) {
      // Try to find a matching suggestion
      final matchingSuggestion = _filteredSuggestions.firstWhere(
        (suggestion) =>
            suggestion.toString().toLowerCase() == value.trim().toLowerCase(),
        orElse: () => value as T,
      );
      
      _addItem(matchingSuggestion);
      
      if (widget.onSubmitted != null) {
        widget.onSubmitted!(value);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Chips
          if (_items.isNotEmpty)
            Wrap(
              spacing: widget.chipSpacing,
              runSpacing: widget.runSpacing,
              children: _items
                  .map(
                    (item) => widget.itemBuilder(context, item),
                  )
                  .toList(),
            ),
          
          // Text field
          TextFormField(
            controller: _controller,
            focusNode: _focusNode,
            keyboardType: widget.keyboardType,
            inputFormatters: widget.inputFormatters,
            textInputAction: widget.textInputAction,
            onFieldSubmitted: _onSubmitted,
            onChanged: (value) {
              _filterSuggestions(value);
              if (value.isNotEmpty && !_showSuggestions) {
                _showSuggestionOverlay();
              }
            },
            decoration: widget.decoration.copyWith(
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _controller.clear();
                        _filterSuggestions('');
                        if (!_focusNode.hasFocus) {
                          _hideSuggestionOverlay();
                        }
                      },
                    )
                  : null,
            ),
            validator: widget.validator,
          ),
        ],
      ),
    );
  }
}
