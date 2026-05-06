import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/services/location_suggestion_service.dart';

class LocationAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Function(String) onChanged;
  final Function(LocationSuggestion)? onSuggestionSelected;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool enabled;
  final String? Function(String?)? validator;

  const LocationAutocompleteField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.onChanged,
    this.onSuggestionSelected,
    this.keyboardType,
    this.maxLines = 1,
    this.enabled = true,
    this.validator,
  });

  @override
  State<LocationAutocompleteField> createState() =>
      _LocationAutocompleteFieldState();
}

class _LocationAutocompleteFieldState extends State<LocationAutocompleteField> {
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();
  List<LocationSuggestion> _suggestions = [];
  bool _isLoading = false;
  OverlayEntry? _overlayEntry;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _removeOverlay();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => _buildSuggestionsOverlay(),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      _debounce?.cancel();
      _suggestions.clear();
      _isLoading = false;
      _removeOverlay();
      setState(() {});
      widget.onChanged(query);
      return;
    }

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchLocations(query.trim());
    });
  }

  Future<void> _searchLocations(String query) async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    _overlayEntry?.markNeedsBuild();

    try {
      final suggestions =
          await LocationSuggestionService.getStreetAreaSuggestions(query);

      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _isLoading = false;
        });

        if (_suggestions.isNotEmpty && _focusNode.hasFocus) {
          _showOverlay();
        } else if (_suggestions.isEmpty &&
            query.isNotEmpty &&
            _focusNode.hasFocus) {
          // Show "No results" if we have a query but no suggestions
          _showOverlay();
        } else {
          _removeOverlay();
        }
        _overlayEntry?.markNeedsBuild();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _suggestions = [];
        });
        _removeOverlay();
      }
    }
  }

  void _onSuggestionTap(LocationSuggestion suggestion) {
    widget.controller.text = suggestion.title;
    widget.onChanged(suggestion.title);
    widget.onSuggestionSelected?.call(suggestion);
    _removeOverlay();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        maxLines: widget.maxLines,
        keyboardType: widget.keyboardType,
        enabled: widget.enabled,
        validator: widget.validator,
        onChanged: _onSearchChanged,
        onFieldSubmitted: (_) => _removeOverlay(),
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: 'Search for a location...',
          prefixIcon: Icon(widget.icon, color: colorScheme.primary),
          suffixIcon: _isLoading
              ? Container(
                  width: 20.w,
                  height: 20.w,
                  padding: EdgeInsets.all(12.w),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  ),
                )
              : (widget.controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear_rounded, size: 20.sp),
                      onPressed: () {
                        widget.controller.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          filled: true,
          fillColor: colorScheme.surface,
        ),
      ),
    );
  }

  Widget _buildSuggestionsOverlay() {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    return CompositedTransformFollower(
      link: _layerLink,
      showWhenUnlinked: false,
      offset: Offset(0, 60.h),
      child: Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12.r),
          clipBehavior: Clip.antiAlias,
          color: colorScheme.surface,
          child: Container(
            width: size.width - 32.w,
            constraints: BoxConstraints(maxHeight: 400.h),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: _isLoading && _suggestions.isEmpty
                ? _buildLoadingState()
                : _suggestions.isEmpty
                    ? _buildNoResultsState()
                    : _buildSuggestionsList(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24.w,
              height: 24.w,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(height: 12.h),
            Text(
              'Searching locations...',
              style: TextStyle(
                fontSize: 13.sp,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
      child: Row(
        children: [
          Icon(Icons.location_off_outlined, color: Colors.orange, size: 20.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'No matching locations found in India. Try being more specific.',
              style: TextStyle(
                fontSize: 13.sp,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList() {
    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: _suggestions.length,
      separatorBuilder: (_, __) => Divider(height: 1, indent: 48.w),
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        return InkWell(
          onTap: () => _onSuggestionTap(suggestion),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    size: 18.sp,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion.title,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (suggestion.subtitle != null) ...[
                        SizedBox(height: 2.h),
                        Text(
                          suggestion.subtitle!,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
