import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

import 'package:tabs_app/pages/post_page.dart';
import 'package:tabs_app/previews/fake_services.dart';

@Preview(group: '投稿', name: '標準', size: Size(390, 844), wrapper: guestOverTabs)
Widget postPage() => PostPage(post: previewPosts.first);
