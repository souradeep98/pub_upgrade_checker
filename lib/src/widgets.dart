library widgets;

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:animations/animations.dart';
import 'package:async/async.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_essentials/flutter_essentials.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:gesture_x_detector/gesture_x_detector.dart';
import 'package:get/get.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:pub_upgrade_checker/src/constants.dart';
import 'package:pub_upgrade_checker/src/globals.dart';
import 'package:pub_upgrade_checker/src/structures.dart';
import 'package:pub_upgrade_checker/src/utils.dart';
import 'package:window_manager/window_manager.dart';

part 'widgets/desktop_window_control_buttons.dart';
part 'widgets/app_bar.dart';
part 'widgets/settings.dart';
part 'widgets/buttons.dart';
part 'widgets/home.dart';
part 'widgets/desktop_frame.dart';
part 'widgets/utils/blinking.dart';
part 'widgets/utils/staggered_column.dart';
part 'widgets/item_view.dart';
