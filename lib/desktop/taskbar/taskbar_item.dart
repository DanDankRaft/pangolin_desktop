/*
Copyright 2021 The dahliaOS Authors

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

import 'package:dahlia_backend/dahlia_backend.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pangolin/utils/app_list.dart';
import 'package:pangolin/utils/context_menus/context_menu.dart';
import 'package:pangolin/utils/context_menus/context_menu_item.dart';
import 'package:pangolin/utils/context_menus/core/context_menu_region.dart';
import 'package:pangolin/utils/wm_api.dart';
import 'package:provider/provider.dart';
import 'package:utopia_wm/wm.dart';
import 'package:pangolin/utils/preference_extension.dart';

class TaskbarItem extends StatefulWidget {
  final String packageName;
  TaskbarItem({required this.packageName, Key? key}) : super(key: key);

  @override
  _TaskbarItemState createState() => _TaskbarItemState();
}

class _TaskbarItemState extends State<TaskbarItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ac;
  late Animation<double> _anim;
  bool _hovering = false;
  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 150),
    );
    _anim = CurvedAnimation(
      parent: _ac,
      curve: Curves.ease,
      reverseCurve: Curves.ease,
    );
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //Running apps
    //// ITS FAILING HERE
    final hierarchy = context.watch<WindowHierarchyState>();
    final windows = hierarchy.entriesByFocus;
    //Selected App
    final _app = applications
        .firstWhere((element) => element.packageName == widget.packageName);
    //Check if App is running or just pinned
    bool appIsRunning =
        windows.any((element) => element.packageName == widget.packageName);
    //get the WindowEntry when the App is running
    late WindowEntry? entry = appIsRunning
        ? windows
            .firstWhere((element) => element.packageName == widget.packageName)
        : null;
    //check if the App is focused
    bool focused = windows.length > 1
        ? windows.last.packageName == widget.packageName &&
            !windows.last.minimized
        : true;

    bool showSelected = appIsRunning ? focused && !entry!.minimized : false;
    if (showSelected) {
      _ac.animateTo(1);
    } else {
      _ac.animateBack(0);
    }
    final _pref = Provider.of<PreferenceProvider>(context);
    //Build Widget
    return LayoutBuilder(
      builder: (context, constraints) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: SizedBox(
          height: 48,
          width: 50,
          child: ContextMenuRegion(
            useLongPress: false,
            contextMenu: ContextMenu(
              items: [
                ContextMenuItem(
                  icon: Icons.push_pin_outlined,
                  title: _pref.pinnedApps.contains(_app.packageName)
                      ? "Unpin from Taskbar"
                      : "Pin to Taskbar",
                  onTap: () {
                    _pref.togglePinnedApp(_app.packageName ?? "");
                  },
                  shortcut: "",
                ),
              ],
            ),
            child: GestureDetector(
              //key: _globalKey,
              child: Material(
                borderRadius: BorderRadius.circular(4),
                //set a background colour if the app is running or focused
                color: appIsRunning
                    ? (showSelected
                        ? Theme.of(context)
                            .textTheme
                            .bodyText1
                            ?.color
                            ?.withOpacity(0.2)
                        : Theme.of(context).backgroundColor.withOpacity(0.0))
                    : Colors.transparent,
                child: InkWell(
                  onHover: (value) {
                    _hovering = value;
                    setState(() {});
                  },
                  borderRadius: BorderRadius.circular(4),
                  onTap: () {
                    //open the app or toggle
                    if (appIsRunning) {
                      _onTap(context, entry);
                    } else {
                      WmAPI.of(context).openApp(widget.packageName);
                      //print(packageName);
                    }
                  },
                  child: AnimatedBuilder(
                    animation: _anim,
                    builder: (context, child) => Stack(
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Image(
                              image: appIsRunning
                                  ? entry?.icon ?? NetworkImage("")
                                  : AssetImage(
                                      "assets/icons/${_app.iconName}.png"),
                            ),
                          ),
                        ),
                        AnimatedPositioned(
                          duration: Duration(milliseconds: 150),
                          curve: Curves.ease,
                          bottom: 2,
                          left: appIsRunning
                              ? _hovering
                                  ? showSelected
                                      ? 4
                                      : 8
                                  : showSelected
                                      ? 4
                                      : constraints.maxHeight / 2 - 8
                              : 50 / 2,
                          right: appIsRunning
                              ? _hovering
                                  ? showSelected
                                      ? 4
                                      : 8
                                  : showSelected
                                      ? 4
                                      : constraints.maxHeight / 2 - 8
                              : 50 / 2,
                          height: 2,
                          child: Material(
                            borderRadius: BorderRadius.circular(2),
                            color: Theme.of(context).accentColor,
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
      ),
    );
  }

  void _onTap(BuildContext context, WindowEntry? entry) {
    //final entry = Provider.of<WindowEntry>(context, listen: false);
    final hierarchy = context.read<WindowHierarchyState>();
    final windows = hierarchy.entriesByFocus;

    bool focused = windows.last.id == entry!.id;
    setState(() {});
    if (focused && !entry.minimized) {
      entry.minimized = true;
      if (windows.length > 1) {
        hierarchy.requestWindowFocus(
          windows[windows.length - 2],
        );
      }
      setState(() {});
    } else {
      entry.minimized = false;
      hierarchy.requestWindowFocus(entry);
      setState(() {});
    }
  }
}
