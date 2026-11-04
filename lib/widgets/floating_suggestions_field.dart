import 'dart:async';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Ô nhập văn bản hỗ trợ gợi ý dạng floating overlay dropdown.
///
/// Các tính năng:
/// 1. Chạm vào bất kỳ vị trí nào trên ô nhập là hiển thị danh sách gợi ý ngay.
/// 2. Danh sách nổi đè lên trên giao diện bên dưới (OverlayPortal + LayerLink)
///    không làm đẩy layout hoặc xê dịch các trường khác.
/// 3. Lọc gợi ý theo thời gian thực khi người dùng gõ ký tự.
/// 4. Tự động đóng overlay khi chạm ra ngoài hoặc khi chuyển sang trường khác (TapRegion + FocusNode).
class FloatingSuggestionsField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final List<String> suggestions;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSelected;
  final FutureOr<void> Function()? onTap;
  final IconData? itemIcon;
  final double maxHeight;
  final TextInputAction? textInputAction;

  const FloatingSuggestionsField({
    super.key,
    required this.controller,
    required this.suggestions,
    this.focusNode,
    this.hintText = '',
    this.onChanged,
    this.onSelected,
    this.onTap,
    this.itemIcon,
    this.maxHeight = 190.0,
    this.textInputAction,
  });

  @override
  State<FloatingSuggestionsField> createState() =>
      _FloatingSuggestionsFieldState();
}

class _FloatingSuggestionsFieldState extends State<FloatingSuggestionsField> {
  final OverlayPortalController _portalController = OverlayPortalController();
  final LayerLink _layerLink = LayerLink();
  late final Object _tapRegionGroupId = Object();

  FocusNode? _internalFocusNode;
  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  bool _isOpen = false;
  double? _targetWidth;
  ScrollPosition? _scrollPosition;
  Timer? _scrollTimer;

  @override
  void initState() {
    super.initState();
    _effectiveFocusNode.addListener(_handleFocusChange);
    widget.controller.addListener(_handleControllerChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newPosition = Scrollable.maybeOf(context)?.position;
    if (_scrollPosition != newPosition) {
      _scrollPosition?.removeListener(_handleScroll);
      _scrollPosition = newPosition;
      _scrollPosition?.addListener(_handleScroll);
    }
  }

  void _handleScroll() {
    if (_isOpen && mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(FloatingSuggestionsField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChange);
      widget.controller.addListener(_handleControllerChange);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      if (oldWidget.focusNode == null) {
        _internalFocusNode?.removeListener(_handleFocusChange);
      } else {
        oldWidget.focusNode?.removeListener(_handleFocusChange);
      }
      _effectiveFocusNode.addListener(_handleFocusChange);
    }
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollPosition?.removeListener(_handleScroll);
    _effectiveFocusNode.removeListener(_handleFocusChange);
    widget.controller.removeListener(_handleControllerChange);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void _scrollToVisible() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer(const Duration(milliseconds: 120), () {
      if (mounted && context.mounted) {
        Scrollable.ensureVisible(
          context,
          alignment: 0.18, // Đẩy ô nhập lên vị trí 18% từ đỉnh màn hình xuống
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _handleFocusChange() {
    if (_effectiveFocusNode.hasFocus) {
      _showOverlay();
      _scrollToVisible();
    }
    // Khi mất focus, việc đóng overlay được xử lý bởi TapRegion.onTapOutside
    // hoặc khi chọn 1 item trong danh sách, tránh đóng sớm làm huỷ sự kiện onTap.
  }

  void _handleControllerChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _showOverlay() {
    if (!_isOpen) {
      setState(() {
        _isOpen = true;
      });
      _portalController.show();
    }
  }

  void _hideOverlay() {
    if (_isOpen) {
      setState(() {
        _isOpen = false;
      });
      _portalController.hide();
    }
  }

  List<String> get _filteredSuggestions {
    final query = widget.controller.text.trim().toLowerCase();
    final uniqueList = widget.suggestions.toSet().toList();
    if (query.isEmpty) {
      return uniqueList;
    }
    return uniqueList
        .where((item) => item.toLowerCase().contains(query))
        .toList();
  }

  void _selectItem(String item) {
    widget.controller.text = item;
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: item.length),
    );
    widget.onChanged?.call(item);
    widget.onSelected?.call(item);
    _hideOverlay();
    _effectiveFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredSuggestions;

    return OverlayPortal(
      controller: _portalController,
      overlayChildBuilder: (BuildContext context) {
        if (filtered.isEmpty) {
          return const SizedBox.shrink();
        }

        final fieldWidth = _layerLink.leaderSize?.width ?? _targetWidth;

        return CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, 6),
          child: Align(
            alignment: Alignment.topLeft,
            child: TapRegion(
              groupId: _tapRegionGroupId,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: fieldWidth,
                  constraints: BoxConstraints(
                    maxHeight: widget.maxHeight <= 190.0 ? widget.maxHeight : 190.0,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F000000), // opacity 0.12 black
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return InkWell(
                          onTap: () => _selectItem(item),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  widget.itemIcon ?? Icons.history_rounded,
                                  size: 18,
                                  color: AppColors.secondaryBlue,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: const TextStyle(
                                      color: AppColors.textDark,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          _targetWidth = constraints.maxWidth;
          return CompositedTransformTarget(
            link: _layerLink,
            child: TapRegion(
              groupId: _tapRegionGroupId,
              onTapOutside: (_) {
                _hideOverlay();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.borderGray,
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: widget.controller,
                  focusNode: _effectiveFocusNode,
                  textInputAction: widget.textInputAction,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  onTap: () async {
                    if (widget.onTap != null) {
                      await widget.onTap!();
                    }
                    _showOverlay();
                    _scrollToVisible();
                  },
                  onChanged: (val) {
                    if (!_isOpen && _filteredSuggestions.isNotEmpty) {
                      _showOverlay();
                    }
                    widget.onChanged?.call(val);
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.controller.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(
                              Icons.cancel_rounded,
                              color: AppColors.textMuted,
                              size: 18,
                            ),
                            onPressed: () {
                              widget.controller.clear();
                              widget.onChanged?.call('');
                              _effectiveFocusNode.requestFocus();
                              _showOverlay();
                              setState(() {});
                            },
                          ),
                        IconButton(
                          icon: Icon(
                            _isOpen && filtered.isNotEmpty
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: AppColors.primaryBlue,
                            size: 24,
                          ),
                          onPressed: () async {
                            if (_isOpen) {
                              _hideOverlay();
                            } else {
                              if (widget.onTap != null) {
                                await widget.onTap!();
                              }
                              _effectiveFocusNode.requestFocus();
                              _showOverlay();
                              _scrollToVisible();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

