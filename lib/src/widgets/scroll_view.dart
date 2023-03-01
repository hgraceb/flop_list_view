// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'viewport.dart';

/// A version of [CustomScrollView] that allows does not constrict the extents
/// to be within 0 and 1. See [CustomScrollView] for more information.
class UnboundedCustomScrollView extends CustomScrollView {
  const UnboundedCustomScrollView({
    super.key,
    super.scrollDirection,
    super.reverse,
    super.controller,
    super.primary,
    super.physics,
    super.scrollBehavior,
    super.center,
    super.anchor,
    super.cacheExtent,
    super.slivers,
    super.semanticChildCount,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.restorationId,
    super.clipBehavior,
    this.onPerformLayout,
    this.cacheExtentStyle = CacheExtentStyle.pixel,
  });

  /// [RenderObject.performLayout] 执行完成后的回调
  final VoidCallback? onPerformLayout;

  /// 预渲染区域计算方式
  final CacheExtentStyle cacheExtentStyle;

  @override
  @protected
  Widget buildViewport(
    BuildContext context,
    ViewportOffset offset,
    AxisDirection axisDirection,
    List<Widget> slivers,
  ) {
    return UnboundedViewport(
      axisDirection: axisDirection,
      offset: offset,
      slivers: slivers,
      cacheExtent: cacheExtent,
      cacheExtentStyle: cacheExtentStyle,
      center: center,
      anchor: anchor,
      onPerformLayout: onPerformLayout,
    );
  }
}
