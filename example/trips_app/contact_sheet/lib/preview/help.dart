import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:trips_app_sheet/fakes/fakes.dart';
import 'package:trips_app_sheet/fakes/states.dart';
import 'package:trips_app_sheet/preview/start.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// The help page asks url_launcher, a plugin, whether the device can send
/// an email: the fake answers instead.
Widget _help({required bool canEmail}) {
  UrlLauncherPlatform.instance = FakeUrlLauncher(canEmail: canEmail);
  return startAt('/account/help');
}

/// A device that cannot send an email: the help center alone.
@Preview(name: 'Help', size: phone, wrapper: guest)
Widget help() => _help(canEmail: false);

/// A device that can: Email support too.
@Preview(name: 'With email', size: phone, wrapper: guest)
Widget helpWithEmail() => _help(canEmail: true);
