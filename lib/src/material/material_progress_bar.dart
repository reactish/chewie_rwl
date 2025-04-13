import 'package:chewie/src/chewie_progress_colors.dart';
import 'package:chewie/src/omni_video_controller.dart';
import 'package:chewie/src/progress_bar.dart';
import 'package:flutter/material.dart';

class MaterialVideoProgressBar extends StatelessWidget {
  MaterialVideoProgressBar(
    this.controller, {
    this.height = kToolbarHeight,
    this.barHeight = 10,
    this.handleHeight = 6,
    ChewieProgressColors? colors,
    this.onDragEnd,
    this.onDragStart,
    this.onDragUpdate,
    super.key,
    this.draggableProgressBar = true,
  }) : colors = colors ?? ChewieProgressColors();

  final double height;
  final double barHeight;
  final double handleHeight;
  final OmniVideoController controller;
  final ChewieProgressColors colors;
  final Function()? onDragStart;
  final Function()? onDragEnd;
  final Function()? onDragUpdate;
  final bool draggableProgressBar;

  @override
  Widget build(BuildContext context) {
    return VideoProgressBar(
      controller,
      barHeight: barHeight,
      handleHeight: handleHeight,
      drawShadow: true,
      colors: colors,
      onDragEnd: onDragEnd,
      onDragStart: onDragStart,
      onDragUpdate: onDragUpdate,
      draggableProgressBar: draggableProgressBar,
    );
  }
}
