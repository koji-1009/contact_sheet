import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

import 'package:tabs_app/pages/home_shell.dart';
import 'package:tabs_app/previews/fake_services.dart';

@Preview(group: 'タブ', name: 'フィード', size: Size(390, 844), wrapper: guest)
Widget feedTab() => const HomeShell();

@Preview(group: 'タブ', name: '検索', size: Size(390, 844), wrapper: guest)
Widget searchTab() => const HomeShell(initialTab: 1);

@Preview(group: 'タブ', name: 'プロフィール（未ログイン）', size: Size(390, 844), wrapper: guest)
@Preview(group: 'タブ', name: 'プロフィール（ログイン済み）', size: Size(390, 844), wrapper: signedIn)
Widget profileTab() => const HomeShell(initialTab: 2);
