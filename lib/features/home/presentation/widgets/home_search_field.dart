import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../search/presentation/cubits/search_suggestion_cubit.dart';
import '../../../search/presentation/cubits/search_suggestion_state.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../../../common/domain/entities/category_entity.dart';

class HomeSearchField extends StatefulWidget {
  final Function(String) onSearch;
  final Function(ProductEntity)? onProductSelect;
  final Function(CategoryEntity)? onCategorySelect;
  final VoidCallback? onTap;
  final bool readOnly;

  const HomeSearchField({
    super.key,
    required this.onSearch,
    this.onProductSelect,
    this.onCategorySelect,
    this.onTap,
    this.readOnly = false,
  });

  @override
  State<HomeSearchField> createState() => _HomeSearchFieldState();
}

class _HomeSearchFieldState extends State<HomeSearchField> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        // Small delay to allow tap events on the overlay to process
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && !_focusNode.hasFocus) {
            _hideOverlay();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;
    final cubit = context.read<SearchSuggestionCubit>();

    return OverlayEntry(
      builder: (_) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 8.h),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12.r),
            color: Theme.of(context).colorScheme.surface,
            child: Container(
              constraints: BoxConstraints(maxHeight: 300.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.1),
                ),
              ),
              child: BlocProvider.value(
                value: cubit,
                child:
                    BlocBuilder<SearchSuggestionCubit, SearchSuggestionState>(
                  builder: (context, state) {
                    if (state is SearchSuggestionLoading) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (state is SearchSuggestionLoaded) {
                      if (state.products.isEmpty && state.categories.isEmpty) {
                        return Padding(
                          padding: EdgeInsets.all(16.w),
                          child: Text(
                            'No results found',
                            style: GoogleFonts.poppins(fontSize: 14.sp),
                          ),
                        );
                      }

                      return ListView(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        children: [
                          if (state.categories.isNotEmpty) ...[
                            _buildSectionHeader('Categories'),
                            ...state.categories
                                .map((category) => _buildSuggestionItem(
                                      icon: Icons.category_outlined,
                                      title: category.name,
                                      onTap: () {
                                        _focusNode.unfocus();
                                        _hideOverlay();
                                        _controller.clear();
                                        widget.onCategorySelect?.call(category);
                                      },
                                    )),
                          ],
                          if (state.products.isNotEmpty) ...[
                            _buildSectionHeader('Products'),
                            ...state.products
                                .map((product) => _buildSuggestionItem(
                                      icon: Icons.shopping_basket_outlined,
                                      title: product.name,
                                      subtitle: 'Fresh Veggie',
                                      onTap: () {
                                        _focusNode.unfocus();
                                        _hideOverlay();
                                        _controller.clear();
                                        widget.onProductSelect?.call(product);
                                      },
                                    )),
                          ],
                        ],
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSuggestionItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, size: 20.sp),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 14.sp),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.poppins(fontSize: 12.sp),
            )
          : null,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          onChanged: (value) {
            if (!widget.readOnly) {
              _showOverlay();
              context.read<SearchSuggestionCubit>().getSuggestions(value);
            }
          },
          onSubmitted: (value) {
            _hideOverlay();
            widget.onSearch(value);
          },
          decoration: InputDecoration(
            hintText: 'Search fresh vegetables...',
            hintStyle: GoogleFonts.poppins(
              fontSize: 14.sp,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: colorScheme.primary,
              size: 22.sp,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: colorScheme.surface,
            contentPadding: EdgeInsets.symmetric(vertical: 12.h),
          ),
        ),
      ),
    );
  }
}
