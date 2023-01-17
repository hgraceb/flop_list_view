// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of 'package:flop_list_view/src/widgets/viewport.dart';

class UnboundedViewport extends Viewport {
  UnboundedViewport({
    super.key,
    super.axisDirection,
    super.crossAxisDirection,
    super.anchor,
    required super.offset,
    super.center,
    super.cacheExtent,
    super.cacheExtentStyle,
    super.clipBehavior,
    super.slivers,
  });

  @override
  RenderViewport createRenderObject(BuildContext context) {
    return UnboundedRenderViewport(
      axisDirection: axisDirection,
      crossAxisDirection: crossAxisDirection ?? Viewport.getDefaultCrossAxisDirection(context, axisDirection),
      anchor: anchor,
      offset: offset,
      cacheExtent: cacheExtent,
      cacheExtentStyle: cacheExtentStyle,
      clipBehavior: clipBehavior,
    );
  }
}

class UnboundedRenderViewport extends RenderViewport {
  UnboundedRenderViewport({
    super.axisDirection,
    required super.crossAxisDirection,
    required super.offset,
    super.anchor,
    super.children,
    super.center,
    super.cacheExtent,
    super.cacheExtentStyle,
    super.clipBehavior,
  });

  static const int _maxLayoutCycles = 10;

  @override
  void performLayout() {
    // Ignore the return value of applyViewportDimension because we are
    // doing a layout regardless.
    switch (axis) {
      case Axis.vertical:
        offset.applyViewportDimension(size.height);
        break;
      case Axis.horizontal:
        offset.applyViewportDimension(size.width);
        break;
    }

    if (center == null) {
      assert(firstChild == null);
      _minScrollExtent = 0.0;
      _maxScrollExtent = 0.0;
      _hasVisualOverflow = false;
      offset.applyContentDimensions(0.0, 0.0);
      return;
    }
    assert(center!.parent == this);

    final double mainAxisExtent;
    final double crossAxisExtent;
    switch (axis) {
      case Axis.vertical:
        mainAxisExtent = size.height;
        crossAxisExtent = size.width;
        break;
      case Axis.horizontal:
        mainAxisExtent = size.width;
        crossAxisExtent = size.height;
        break;
    }

    final double centerOffsetAdjustment = center!.centerOffsetAdjustment;

    double correction;
    int count = 0;
    do {
      assert(offset.pixels != null);
      correction = _attemptLayout(mainAxisExtent, crossAxisExtent, offset.pixels + centerOffsetAdjustment);
      if (correction != 0.0) {
        offset.correctBy(correction);
      } else {
        /// region Difference from [RenderViewport].
        final top = _minScrollExtent + mainAxisExtent * anchor;
        final bottom = _maxScrollExtent - mainAxisExtent * (1.0 - anchor);
        final maxScrollOffset = math.max(math.min(0.0, top), bottom);
        final minScrollOffset = math.min(top, maxScrollOffset);
        if (offset.applyContentDimensions(minScrollOffset, maxScrollOffset)) {
          break;
        }
        /// endregion Difference from [RenderViewport].
      }
      count += 1;
    } while (count < _maxLayoutCycles);
    assert(() {
      if (count >= _maxLayoutCycles) {
        assert(count != 1);
        throw FlutterError(
          'A RenderViewport exceeded its maximum number of layout cycles.\n'
              'RenderViewport render objects, during layout, can retry if either their '
              'slivers or their ViewportOffset decide that the offset should be corrected '
              'to take into account information collected during that layout.\n'
              'In the case of this RenderViewport object, however, this happened $count '
              'times and still there was no consensus on the scroll offset. This usually '
              'indicates a bug. Specifically, it means that one of the following three '
              'problems is being experienced by the RenderViewport object:\n'
              ' * One of the RenderSliver children or the ViewportOffset have a bug such'
              ' that they always think that they need to correct the offset regardless.\n'
              ' * Some combination of the RenderSliver children and the ViewportOffset'
              ' have a bad interaction such that one applies a correction then another'
              ' applies a reverse correction, leading to an infinite loop of corrections.\n'
              ' * There is a pathological case that would eventually resolve, but it is'
              ' so complicated that it cannot be resolved in any reasonable number of'
              ' layout passes.',
        );
      }
      return true;
    }());
  }
}
