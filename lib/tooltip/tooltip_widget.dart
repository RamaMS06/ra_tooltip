import 'package:flutter/material.dart';
import 'dart:async' show Timer;
import 'package:ra_tooltip/tooltip/model/model.dart';
part '../tooltip/internal/tooltip_arrow.dart';

class RATooltip extends StatefulWidget {
  const RATooltip({
    this.message,
    this.customMessage,
    required this.child,
    this.messageAlign = TextAlign.center,
    super.key,
    this.color,
    this.trigger = RATooltipTrigger.tap,
    this.enabled = true,
    this.position = RATooltipPosition.top,
    this.onTapOutside,
    this.messageStyle,
    this.padding,
    this.boxShadow,
  }) : assert(child != null || key != null);

  /// Displays text message to tooltip.
  final String? message;

  /// Displays custom message to tooltip.
  final Widget? customMessage;

  /// Displays child to trigger tooltip.
  final Widget? child;

  /// Displays different of tooltip color.
  final Color? color;

  /// Displays different box shadow of tooltip.
  final List<BoxShadow>? boxShadow;

  /// Displays different text alignment of tooltip.
  final TextAlign? messageAlign;

  /// The trigger mode for showing the tooltip
  final RATooltipTrigger trigger;

  /// Completely disables the tooltip behaviour when set to false.
  final bool enabled;

  /// Tooltip position relative to the target widget.
  final RATooltipPosition position;

  /// The style of the message text.
  final TextStyle? messageStyle;

  /// The padding of the tooltip.
  final EdgeInsets? padding;

  /// If true, the tooltip will not close when tapping outside or pressing other widgets.
  /// Default is false.
  final void Function(PointerDownEvent)? onTapOutside;

  @override
  State<RATooltip> createState() => _RATooltipState();
}

class _RATooltipState extends State<RATooltip>
    with SingleTickerProviderStateMixin {
  double? _tooltipTop;
  double? _tooltipBottom;
  double? _tooltipLeft;
  double? _tooltipRight;
  Alignment _tooltipAlignment = Alignment.center;
  Alignment _transitionAlignment = Alignment.center;
  Alignment _arrowAlignment = Alignment.center;
  late BuildContext _targetContext;
  late GlobalKey _targetGlobalKey;
  bool _isInverted = false;
  bool _isHorizontal = false; // true if left/right
  bool _isActive = false;
  final _arrowSize = const Size(16, 8);
  final _tooltipMinimumHeight = 140;
  final _overlayController = OverlayPortalController();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  Timer? _holdTimer;
  Timer? _autoHideTimer;
  final _tooltipManager = _RATooltipManager();

  late final GlobalKey _key;

  final Color _defaultTooltipColor = const Color(0xFF333F47);

  final Color _defaultTextColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _key = GlobalKey();
    _targetGlobalKey =
        widget.key != null ? (widget.key as GlobalKey) : GlobalKey();
    _targetContext = context;
    _tooltipManager.registerTooltip(_key, this);
    _setupAnimation();
  }

  @override
  void didUpdateWidget(covariant RATooltip oldWidget) {
    super.didUpdateWidget(oldWidget);
    // No external trigger logic needed anymore
  }

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    _holdTimer?.cancel();
    _tooltipManager.unregisterTooltip(_key);
    _animationController.dispose();
    super.dispose();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150), // Smooth animation
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic, // Smooth curve for better UX
    );
  }

  void _toggle() {
    _autoHideTimer?.cancel();
    _holdTimer?.cancel();
    _animationController.stop();
    if (_overlayController.isShowing) {
      hideTooltipImmediate();
    } else {
      _updatePosition();
      _showTooltip();
    }
  }

  void _showTooltip() {
    if (!mounted || _overlayController.isShowing) return;
    // No longer closes other tooltips
    _isActive = true;
    _overlayController.show();
    _animationController.forward();
  }

  void _hideTooltip() {
    if (!mounted || !_isActive) return;

    _autoHideTimer?.cancel();
    hideTooltipImmediate();
  }

  void hideTooltipImmediate() {
    if (!mounted || !_overlayController.isShowing) return;

    _isActive = false;
    _autoHideTimer?.cancel();
    _animationController.reverse().then((_) {
      if (!mounted) return;
      if (_overlayController.isShowing) {
        _overlayController.hide();
      }
    });
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.trigger == RATooltipTrigger.tap) {
      _toggle();
    } else if (widget.trigger == RATooltipTrigger.hold) {
      // Start the hold timer
      _holdTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          _updatePosition();
          _showTooltip();
        }
      });
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.trigger == RATooltipTrigger.hold) {
      _holdTimer?.cancel();
      // If tooltip is already showing, keep it visible (don't hide immediately)
      // The tooltip will behave like tap mode once shown
    }
  }

  void _handleTapCancel() {
    if (widget.trigger == RATooltipTrigger.hold) {
      _holdTimer?.cancel();
      // Only hide if the tooltip was shown due to successful hold
      if (_isActive) {
        _hideTooltip();
      }
    }
  }

  void _handleLongPress() {
    if (widget.trigger == RATooltipTrigger.hold) {
      // This ensures the tooltip shows on long press as well
      _holdTimer?.cancel();
      if (!_isActive) {
        _updatePosition();
        _showTooltip();
      }
    }
  }

  void _updatePosition() {
    if (!mounted) return;

    try {
      final contextSize = MediaQuery.of(context).size;
      _targetGlobalKey =
          (widget.key != null ? (widget.key as GlobalKey) : GlobalKey());
      _targetContext = _targetGlobalKey.currentContext ?? context;

      final targetRenderBox = _targetContext.findRenderObject() as RenderBox?;
      if (targetRenderBox == null ||
          !targetRenderBox.attached ||
          !targetRenderBox.hasSize) {
        // Reset positions if we can't calculate them
        setState(() {
          _tooltipTop = null;
          _tooltipBottom = null;
          _tooltipLeft = null;
          _tooltipRight = null;
          _tooltipAlignment = Alignment.center;
          _transitionAlignment = Alignment.center;
          _arrowAlignment = Alignment.center;
          _isInverted = false;
          _isHorizontal = false;
        });
        return;
      }

      final targetOffset = targetRenderBox.localToGlobal(Offset.zero);
      final targetSize = targetRenderBox.size;

      // Default values
      double? tooltipTop, tooltipBottom, tooltipLeft, tooltipRight;
      Alignment tooltipAlignment = Alignment.center;
      Alignment transitionAlignment = Alignment.center;
      Alignment arrowAlignment = Alignment.center;
      bool isInverted = false;
      bool isHorizontal = false;

      // Helper for horizontal alignment
      double horizontalAlign(double dx, double width) =>
          (dx + width / 2) / contextSize.width * 2 - 1.0;
      double verticalAlign(double dy, double height) =>
          (dy + height / 2) / contextSize.height * 2 - 1.0;

      // Determine position based on widget.position
      switch (widget.position) {
        case RATooltipPosition.top:
          // Place tooltip above the target
          tooltipBottom = contextSize.height - targetOffset.dy + 5;
          tooltipTop = null;
          tooltipLeft = null;
          tooltipRight = null;
          tooltipAlignment = Alignment(
            horizontalAlign(targetOffset.dx, targetSize.width),
            -1.0,
          );
          transitionAlignment = Alignment(
            horizontalAlign(targetOffset.dx, targetSize.width),
            1.0,
          );
          arrowAlignment = Alignment(
            horizontalAlign(targetOffset.dx, targetSize.width),
            1.0,
          );
          isInverted = false;
          isHorizontal = false;
          break;
        case RATooltipPosition.bottom:
          // Place tooltip below the target
          tooltipTop = targetOffset.dy + targetSize.height + 5;
          tooltipBottom = null;
          tooltipLeft = null;
          tooltipRight = null;
          tooltipAlignment = Alignment(
            horizontalAlign(targetOffset.dx, targetSize.width),
            1.0,
          );
          transitionAlignment = Alignment(
            horizontalAlign(targetOffset.dx, targetSize.width),
            -1.0,
          );
          arrowAlignment = Alignment(
            horizontalAlign(targetOffset.dx, targetSize.width),
            -1.0,
          );
          isInverted = true;
          isHorizontal = false;
          break;
        case RATooltipPosition.left:
          // Place tooltip to the left of the target
          tooltipTop = null;
          tooltipBottom = null;
          // Position tooltip with fixed gap from target
          tooltipLeft = null;
          tooltipRight = contextSize.width - targetOffset.dx + 12;
          tooltipAlignment = Alignment(
            -1.0,
            verticalAlign(targetOffset.dy, targetSize.height),
          );
          // Custom transition alignment: always show from the right (1.0, y)
          transitionAlignment = Alignment(
            1.0,
            verticalAlign(targetOffset.dy, targetSize.height),
          );
          arrowAlignment = Alignment(
            -1.0,
            verticalAlign(targetOffset.dy, targetSize.height),
          );
          isInverted = false;
          isHorizontal = true;
          break;
        case RATooltipPosition.right:
          // Place tooltip to the right of the target
          tooltipTop = null;
          tooltipBottom = null;
          tooltipLeft = targetOffset.dx + targetSize.width + 12;
          tooltipRight = null;
          tooltipAlignment = Alignment(
            1.0,
            verticalAlign(targetOffset.dy, targetSize.height),
          );
          transitionAlignment = Alignment(
            -1.0,
            verticalAlign(targetOffset.dy, targetSize.height),
          );
          arrowAlignment = Alignment(
            -1.0,
            verticalAlign(targetOffset.dy, targetSize.height),
          );
          isInverted = true;
          isHorizontal = true;
          break;
        default:
          // Try to position the tooltip above the target,
          // otherwise try to position it below or in the center of the target.
          final tooltipFitsAboveTarget =
              targetOffset.dy - _tooltipMinimumHeight >= 0;
          final tooltipFitsBelowTarget =
              targetOffset.dy + targetSize.height + _tooltipMinimumHeight <=
                  contextSize.height;

          tooltipTop = tooltipFitsAboveTarget
              ? null
              : tooltipFitsBelowTarget
                  ? targetOffset.dy + targetSize.height + 5
                  : null;
          tooltipBottom = tooltipFitsAboveTarget
              ? contextSize.height - targetOffset.dy + 5
              : tooltipFitsBelowTarget
                  ? null
                  : targetOffset.dy + targetSize.height / 2;
          tooltipLeft = null;
          tooltipRight = null;

          isInverted = tooltipTop != null;
          isHorizontal = false;

          tooltipAlignment = Alignment(
            (targetOffset.dx) / (contextSize.width - targetSize.width) * 2 -
                1.0,
            isInverted ? 1.0 : -1.0,
          );

          transitionAlignment = Alignment(
            (targetOffset.dx + targetSize.width / 2) / contextSize.width * 2 -
                1.0,
            isInverted ? -1.0 : 1.0,
          );

          arrowAlignment = Alignment(
            (targetOffset.dx + targetSize.width / 2) /
                    (contextSize.width - _arrowSize.width) *
                    2 -
                1.0,
            isInverted ? 1.0 : -1.0,
          );
          break;
      }

      setState(() {
        _tooltipTop = tooltipTop;
        _tooltipBottom = tooltipBottom;
        _tooltipLeft = tooltipLeft;
        _tooltipRight = tooltipRight;
        _tooltipAlignment = tooltipAlignment;
        _transitionAlignment = transitionAlignment;
        _arrowAlignment = arrowAlignment;
        _isInverted = isInverted;
        _isHorizontal = isHorizontal;
      });
    } catch (e) {
      // Reset positions if calculation fails
      setState(() {
        _tooltipTop = null;
        _tooltipBottom = null;
        _tooltipLeft = null;
        _tooltipRight = null;
        _tooltipAlignment = Alignment.center;
        _transitionAlignment = Alignment.center;
        _arrowAlignment = Alignment.center;
        _isInverted = false;
        _isHorizontal = false;
      });
    }
  }

  void _handleContentTap() {
    if (widget.trigger == RATooltipTrigger.tap ||
        widget.trigger == RATooltipTrigger.hold) {
      hideTooltipImmediate();
    }
  }

  @override
  Widget build(BuildContext context) {
    // If disabled just render the child and skip all tooltip logic
    if (!widget.enabled) {
      return widget.child ?? const SizedBox.shrink();
    }
    final theme = ThemeData(
      brightness: Brightness.dark,
    );

    Widget tooltipTarget = KeyedSubtree(
      key: _key,
      child: widget.child ?? const SizedBox.shrink(),
    );

    // Ensure the tooltip target preserves child size but has minimum constraints
    tooltipTarget = ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 1,
        minHeight: 1,
      ),
      child: tooltipTarget,
    );

    // Add gesture detection based on trigger type
    switch (widget.trigger) {
      case RATooltipTrigger.tap:
        tooltipTarget = GestureDetector(
          onTap: _toggle,
          behavior: HitTestBehavior.opaque,
          child: tooltipTarget,
        );
        break;
      case RATooltipTrigger.hold:
        tooltipTarget = GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          onLongPress: _handleLongPress,
          onTap: () {
            // If tooltip is already active, toggle it off
            if (_isActive) {
              _toggle();
            }
          },
          behavior: HitTestBehavior.opaque,
          child: tooltipTarget,
        );
        break;
    }

    Widget tooltipContent(BuildContext context) => RepaintBoundary(
          child: Material(
            type: MaterialType.transparency,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  top: _tooltipTop,
                  bottom: _tooltipBottom,
                  left: _tooltipLeft,
                  right: _tooltipRight,
                  child: ScaleTransition(
                    alignment: widget.position == RATooltipPosition.left
                        // Always show from the right for left tooltips
                        ? Alignment(1.0, _transitionAlignment.y)
                        : _transitionAlignment,
                    scale: _scaleAnimation,
                    child: TapRegion(
                      onTapOutside: (PointerDownEvent event) {
                        // Don't close if persistent is true
                        if (widget.onTapOutside != null) {
                          widget.onTapOutside!(event);
                        }

                        if (widget.trigger == RATooltipTrigger.tap ||
                            widget.trigger == RATooltipTrigger.hold) {
                          hideTooltipImmediate();
                        }
                      },
                      child: Theme(
                        data: theme,
                        child: GestureDetector(
                          onTap: _handleContentTap,
                          behavior: HitTestBehavior.opaque,
                          child: SizedBox(
                            width: _isHorizontal
                                ? null
                                : MediaQuery.of(context).size.width,
                            height: _isHorizontal
                                ? MediaQuery.of(context).size.height
                                : null,
                            child: _isHorizontal
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      if (_isInverted)
                                        Align(
                                          alignment: _arrowAlignment,
                                          child: Transform.rotate(
                                            angle: 3.14159, // 180 deg
                                            child: RATooltipArrow(
                                              size: Size(_arrowSize.height,
                                                  _arrowSize.width),
                                              isInverted: false,
                                              color: widget.color ??
                                                  _defaultTooltipColor,
                                              direction: widget.position ==
                                                      RATooltipPosition.left
                                                  ? ArrowDirection.left
                                                  : ArrowDirection.right,
                                            ),
                                          ),
                                        ),
                                      Align(
                                        alignment: _tooltipAlignment,
                                        child: IntrinsicWidth(
                                          child: IntrinsicHeight(
                                            child: ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                maxWidth: 150,
                                              ),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: widget.color ??
                                                      _defaultTooltipColor,
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                  boxShadow: widget.boxShadow ??
                                                      [
                                                        BoxShadow(
                                                          color:
                                                              _defaultTooltipColor
                                                                  .withOpacity(
                                                                      0.12),
                                                          spreadRadius: -2,
                                                          blurRadius: 16,
                                                          offset: const Offset(
                                                              0, 4),
                                                        ),
                                                      ],
                                                ),
                                                child: Padding(
                                                  padding: widget.padding ??
                                                      const EdgeInsets.all(8),
                                                  child: DefaultTextStyle(
                                                    style: DefaultTextStyle.of(
                                                            context)
                                                        .style
                                                        .copyWith(
                                                          color: widget.color ??
                                                              _defaultTooltipColor,
                                                        ),
                                                    child: widget
                                                            .customMessage ??
                                                        (widget.message != null
                                                            ? Text(
                                                                widget.message!,
                                                                style: widget
                                                                        .messageStyle ??
                                                                    TextStyle(
                                                                      color:
                                                                          _defaultTextColor,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                    ),
                                                                textAlign: widget
                                                                    .messageAlign,
                                                              )
                                                            : const SizedBox
                                                                .shrink()),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (!_isInverted)
                                        Align(
                                          alignment: _arrowAlignment,
                                          child: RATooltipArrow(
                                            size: Size(_arrowSize.height,
                                                _arrowSize.width),
                                            isInverted: false,
                                            color: widget.color ??
                                                _defaultTooltipColor,
                                            direction: widget.position ==
                                                    RATooltipPosition.left
                                                ? ArrowDirection.left
                                                : ArrowDirection.right,
                                          ),
                                        ),
                                    ],
                                  )
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_isInverted)
                                        Align(
                                          alignment: _arrowAlignment,
                                          child: RATooltipArrow(
                                            size: _arrowSize,
                                            isInverted: _isInverted,
                                            color: widget.color ??
                                                _defaultTooltipColor,
                                            direction: widget.position ==
                                                    RATooltipPosition.top
                                                ? ArrowDirection.up
                                                : widget.position ==
                                                        RATooltipPosition.bottom
                                                    ? ArrowDirection.down
                                                    : ArrowDirection.up,
                                          ),
                                        ),
                                      Align(
                                        alignment: _tooltipAlignment,
                                        child: IntrinsicWidth(
                                          child: ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              maxWidth: 150,
                                            ),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: widget.color ??
                                                    _defaultTooltipColor,
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                                boxShadow: widget.boxShadow ??
                                                    [
                                                      BoxShadow(
                                                        color:
                                                            _defaultTooltipColor
                                                                .withOpacity(
                                                                    0.12),
                                                        spreadRadius: -2,
                                                        blurRadius: 16,
                                                        offset:
                                                            const Offset(0, 4),
                                                      ),
                                                    ],
                                              ),
                                              child: Padding(
                                                padding: widget.padding ??
                                                    const EdgeInsets.all(8),
                                                child: DefaultTextStyle(
                                                  style: DefaultTextStyle.of(
                                                          context)
                                                      .style
                                                      .copyWith(
                                                        color: widget.color ??
                                                            _defaultTooltipColor,
                                                      ),
                                                  child: widget.customMessage ??
                                                      (widget.message != null
                                                          ? Text(
                                                              widget.message!,
                                                              style: widget
                                                                      .messageStyle ??
                                                                  TextStyle(
                                                                    color:
                                                                        _defaultTextColor,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                  ),
                                                              textAlign: widget
                                                                  .messageAlign,
                                                            )
                                                          : const SizedBox
                                                              .shrink()),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (!_isInverted)
                                        Align(
                                          alignment: _arrowAlignment,
                                          child: RATooltipArrow(
                                            size: _arrowSize,
                                            color: widget.color ??
                                                _defaultTooltipColor,
                                            direction: widget.position ==
                                                    RATooltipPosition.top
                                                ? ArrowDirection.up
                                                : widget.position ==
                                                        RATooltipPosition.bottom
                                                    ? ArrowDirection.down
                                                    : ArrowDirection.down,
                                          ),
                                        ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

    return OverlayPortal.targetsRootOverlay(
      controller: _overlayController,
      overlayChildBuilder: tooltipContent,
      child: tooltipTarget,
    );
  }
}

// Simple tooltip manager for basic tracking
class _RATooltipManager {
  static final _RATooltipManager _instance = _RATooltipManager._internal();
  factory _RATooltipManager() => _instance;
  _RATooltipManager._internal();

  final Map<GlobalKey, _RATooltipState> _tooltipRegistry = {};

  void registerTooltip(GlobalKey key, _RATooltipState tooltip) {
    _tooltipRegistry[key] = tooltip;
  }

  void unregisterTooltip(GlobalKey key) {
    _tooltipRegistry.remove(key);
  }
}
