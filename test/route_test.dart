import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:contact_sheet/contact_sheet.dart';
import 'package:contact_sheet/src/map.dart';
import 'package:contact_sheet/src/route.dart';
import 'package:contact_sheet/src/route_js.g.dart';
import 'package:test/test.dart';

import '../tool/route_sources.dart';

final _m = Messages.of('en');

/// A shop: home, a product, the cart, checkout, log in.
final _shop = Sheet.parse('''
pages:
  - id: home
    label: Home
    states: [{name: Guest, preview: a.dart#a}, {name: Member, preview: a.dart#a@1}]
  - id: product
    label: Product
    states: [{name: Guest, preview: b.dart#b}, {name: Member, preview: b.dart#b@1}]
  - id: cart
    label: Cart
    states: [{name: Full, preview: c.dart#c}, {name: Empty, preview: c.dart#c@1, data: true}]
  - id: checkout
    label: Checkout
    states: [{name: Full, preview: d.dart#d}]
  - id: login
    label: Log in
    states: [{name: To checkout, preview: e.dart#e}]
  - id: done
    label: Done
    states: [{name: s, preview: f.dart#f}]
edges:
  - {from: home, to: product, trigger: other:Tap a product}
  - {from: home, to: cart, trigger: label:Cart}
  - {from: cart, to: checkout, trigger: text:Buy, when: Full}
  - {from: product, to: checkout, trigger: text:Buy, when: Member, then: Full}
  - {from: product, to: login, trigger: text:Buy, when: Guest, kind: redirect}
  - {from: login, to: checkout, trigger: text:Log in, then: Full, kind: go}
  - {from: checkout, to: done, trigger: text:Pay, kind: go}
  - {from: done, to: home, trigger: text:Home, then: Member, kind: replace}
''', _m);

/// [sheet]'s router, the conditions' values [held].
Router _holding(Sheet sheet, Map<String, String> held) => Router(
  sheet.router.pages,
  sheet.router.edges,
  conditions: sheet.router.conditions,
  tabBars: sheet.router.tabBars,
  held: held,
);

/// [sheet]'s deep links, as the router reads them.
List<RouteEntry> _entries(Sheet sheet) => [
  for (final e in sheet.entries)
    (to: e.to, then: e.then, guard: e.guard, tab: e.tab),
];

/// What [shown] shows as `page:state`.
Set<String> _framesOf(RouteShown shown) => {
  for (final MapEntry(key: page, value: states) in shown.states.entries)
    for (final s in states) '$page:$s',
};

/// [route] as `page:state` and, for each step, `edge key|back => page:state`.
List<String> _said(Sheet sheet, Route route) => [
  route.start.map((f) => '${f.page}:${f.state}').join(' '),
  for (final s in route.steps ?? const <RouteStep>[])
    '${s.edge == null ? s.move : sheet.edges[s.edge!].key} => ${s.to.page}:${s.to.state}',
];

void main() {
  test('the back of a page pushed goes to the page under it', () {
    // From the product as the app's start reaches it: over home.
    expect(_said(_shop, _shop.router.route('product', null, 'cart')), [
      'home:Guest product:Guest',
      'back => home:Guest',
      'home>cart label:Cart push => cart:Full',
    ]);
  });

  test('a state is kept by its name, and a go starts the history again', () {
    // As a member, the product is the member's, and buying needs no login.
    expect(_said(_shop, _shop.router.route('home', 'Member', 'checkout')), [
      'home:Member',
      'home>product other:Tap a product push => product:Member',
      'product>checkout text:Buy [Member] push => checkout:Full',
    ]);
    // After a go there is nothing under the page: no back.
    final fromDone = _shop.router.route('done', null, 'product');
    expect(fromDone.start.length, 1);
    expect(_said(_shop, fromDone).skip(1), [
      'done>home text:Home replace => home:Member',
      'home>product other:Tap a product push => product:Member',
    ]);
  });

  test('a redirect is a push: its back goes to the page tapped on', () {
    expect(_said(_shop, _shop.router.route('login', null, 'product')), [
      'home:Guest product:Guest login:To checkout',
      'back => product:Guest',
    ]);
  });

  test('with nothing under it, a page\'s back goes to its parent: in its '
      'tab, as a go to a nested route builds the path\'s pages', () {
    final sheet = Sheet.parse('''
tabs:
  - pages:
      - {page: explore, trigger: text:Explore}
      - {page: trips, trigger: text:Trips}
pages:
  - {id: explore, label: Explore, states: [{name: s, preview: a.dart#a}]}
  - {id: trips, label: Trips, states: [{name: s, preview: b.dart#b}]}
  - {id: hotel, label: Hotel, tab: explore, parent: explore, states: [{name: s, preview: c.dart#c}]}
  - {id: reviews, label: Reviews, tab: explore, parent: hotel, states: [{name: s, preview: d.dart#d}]}
  - {id: help, label: Help, parent: trips, states: [{name: s, preview: e.dart#e}]}
edges:
  - {from: trips, to: reviews, trigger: text:Reviews, kind: go}
  - {from: explore, to: help, trigger: text:Help, kind: go}
  - {from: hotel, to: reviews, trigger: text:Reviews}
''', _m);
    // Gone to from the Trips tab: alone in Explore's history, its back goes
    // to the hotel, then to Explore.
    final route = sheet.router.route('reviews', null, 'explore');
    expect(route.start.map((f) => f.page), ['reviews']);
    expect(_said(sheet, route).skip(1), [
      'back => hotel:s',
      'back => explore:s',
    ]);
    // Gone to out of the bar, alone: its parent is opened in its tab.
    final help = sheet.router.route('help', null, 'trips');
    expect(_said(sheet, help), ['help:s', 'back => trips:s']);
    expect(help.steps!.single.tab, 'trips');
    // Pushed, its back goes to the page under it.
    expect(_said(sheet, sheet.router.route('hotel', null, 'explore')).skip(1), [
      'back => explore:s',
    ]);
  });

  test('tapping the tab shown again goes to its first page from any other '
      'page, alone in its history too', () {
    final sheet = Sheet.parse('''
tabs:
  - retap: first
    pages:
      - {page: explore, trigger: text:Explore}
      - {page: trips, trigger: text:Trips}
pages:
  - {id: explore, label: Explore, states: [{name: s, preview: a.dart#a}]}
  - {id: trips, label: Trips, states: [{name: s, preview: b.dart#b}]}
  - {id: hotel, label: Hotel, tab: explore, states: [{name: s, preview: c.dart#c}]}
edges:
  - {from: trips, to: hotel, trigger: text:Hotel, kind: go}
''', _m);
    final route = sheet.router.route('hotel', null, 'explore');
    expect(route.start.map((f) => f.page), ['hotel']);
    expect(_said(sheet, route).skip(1), ['retap => explore:s']);
  });

  test('a written back that goes elsewhere replaces the back', () {
    final sheet = Sheet.parse('''
pages:
  - {id: a, label: A, states: [{name: s, preview: a.dart#a}]}
  - {id: b, label: B, states: [{name: s, preview: b.dart#b}]}
  - {id: c, label: C, states: [{name: s, preview: c.dart#c}]}
edges:
  - {from: a, to: b, trigger: text:B}
  - {from: b, to: c, trigger: text:C}
  - {from: c, to: a, trigger: back, kind: pop}
''', _m);
    // c's back goes to a, not to b under it.
    expect(_said(sheet, sheet.router.route('c', null, 'b')), [
      'a:s b:s c:s',
      'c>a back pop => a:s',
      'a>b text:B push => b:s',
    ]);
  });

  test('a written pop lands in the state its then says', () {
    final sheet = Sheet.parse('''
pages:
  - id: list
    label: List
    states: [{name: Full, preview: a.dart#a}, {name: Saved, preview: a.dart#a@1}]
  - {id: edit, label: Edit, states: [{name: s, preview: b.dart#b}]}
  - {id: other, label: Other, states: [{name: s, preview: c.dart#c}]}
edges:
  - {from: list, to: edit, trigger: text:Edit}
  - {from: edit, to: list, trigger: text:Save, then: Saved, kind: pop}
  - {from: list, to: other, trigger: text:Other, when: Saved}
''', _m);
    // Only a saved list leads to other: saving, not the back, gets there.
    expect(_said(sheet, sheet.router.route('edit', null, 'other')), [
      'list:Full edit:s',
      'edit>list text:Save pop => list:Saved',
      'list>other text:Other [Saved] push => other:s',
    ]);
  });

  test('a condition is carried through a page that does not show it', () {
    final sheet = Sheet.parse('''
conditions:
  - {name: Login, values: [Guest, Member]}
pages:
  - id: home
    label: Home
    states:
      - {name: Guest, preview: a.dart#a, if: {Login: Guest}}
      - {name: Member, preview: a.dart#a@1, if: {Login: Member}}
  - {id: cart, label: Cart, states: [{name: Full, preview: c.dart#c}]}
  - {id: checkout, label: Checkout, states: [{name: s, preview: d.dart#d}]}
  - {id: login, label: Log in, states: [{name: s, preview: e.dart#e}]}
edges:
  - {from: home, to: cart, trigger: label:Cart}
  - {from: cart, to: checkout, trigger: text:Buy, if: {Login: Member}}
  - {from: cart, to: login, trigger: text:Buy, if: {Login: Guest}, kind: redirect}
  - {from: login, to: checkout, trigger: text:Log in, set: {Login: Member}, kind: go}
''', _m);
    // A guest is sent to log in: the cart does not show it, the app knows.
    final guest = sheet.router.route('home', 'Guest', 'checkout');
    expect(_said(sheet, guest), [
      'home:Guest',
      'home>cart label:Cart push => cart:Full',
      'cart>login text:Buy {Login=Guest} redirect => login:s',
      'login>checkout text:Log in go => checkout:s',
    ]);
    expect(guest.valuation, {'Login': 'Guest'});
    expect(guest.steps!.last.sets, {'Login': 'Member'});
    // Logged in, as chosen, from the cart: straight on.
    final member = sheet.router.route('cart', null, 'checkout', {
      'Login': 'Member',
    });
    expect(member.valuation, {'Login': 'Member'});
    expect(_said(sheet, member).skip(1), [
      'cart>checkout text:Buy {Login=Member} push => checkout:s',
    ]);
  });

  test('a state chosen keeps its own values over those chosen', () {
    final sheet = Sheet.parse('''
conditions:
  - {name: Welcome, values: [Not seen, Seen]}
  - {name: Language, values: [English, Japanese]}
pages:
  - {id: welcome, label: Welcome, states: [{name: s, preview: w.dart#w}]}
  - {id: home, label: Home, states: [{name: s, preview: h.dart#h}]}
  - id: language
    label: Language
    states:
      - {name: English, preview: l.dart#l, if: {Language: English}}
      - {name: Japanese, preview: l.dart#l@1, if: {Language: Japanese}}
edges:
  - {from: welcome, to: home, trigger: text:Start, set: {Welcome: Seen}, kind: go}
  - {from: home, to: language, trigger: label:Language}
''', _m);
    // Japanese is not the English state's: the start is where the app's
    // launch reaches the English state, the welcome seen.
    final route = sheet.router.route('language', 'English', 'home', {
      'Language': 'Japanese',
    });
    expect(route.valuation, {'Welcome': 'Seen', 'Language': 'English'});
    expect(route.start.map((f) => f.page), ['home', 'language']);
  });

  test('a pop brings no older value back: the page under shows as now', () {
    final sheet = Sheet.parse('''
conditions:
  - {name: Login, values: [Guest, Member]}
pages:
  - {id: feed, label: Feed, states: [{name: s, preview: f.dart#f}]}
  - id: profile
    label: Profile
    states:
      - {name: Guest, preview: p.dart#p, if: {Login: Guest}}
      - {name: Member, preview: p.dart#p@1, if: {Login: Member}}
  - {id: sign_in, label: Sign in, states: [{name: s, preview: s.dart#s}]}
  - {id: settings, label: Settings, states: [{name: s, preview: t.dart#t}]}
edges:
  - {from: feed, to: profile, trigger: text:Profile, kind: replace}
  - {from: profile, to: feed, trigger: text:Feed, kind: replace}
  - {from: profile, to: sign_in, trigger: text:Sign in, when: Guest}
  - {from: sign_in, to: profile, trigger: text:Done, set: {Login: Member}, kind: pop}
  - {from: profile, to: profile, trigger: text:Sign out, when: Member, set: {Login: Guest}, kind: replace}
  - {from: profile, to: settings, trigger: text:Settings, when: Member}
''', _m);
    // The profile under the sign-in, shown as a guest, shows signed in.
    expect(_said(sheet, sheet.router.route('sign_in', null, 'settings')), [
      'profile:Guest sign_in:s',
      'sign_in>profile text:Done pop => profile:Member',
      'profile>settings text:Settings [Member] push => settings:s',
    ]);
    // Signed in, the profile stays signed in after the tabs change.
    final back = sheet.router.route('feed', null, 'profile', {
      'Login': 'Member',
    });
    expect(_said(sheet, back), [
      'feed:s',
      'feed>profile text:Profile replace => profile:Member',
    ]);
    // Signing out in place: the same page in the other state.
    expect(_said(sheet, sheet.router.route('profile', 'Member', 'sign_in')), [
      'profile:Member',
      'profile>profile text:Sign out [Member] replace => profile:Guest',
      'profile>sign_in text:Sign in [Guest] push => sign_in:s',
    ]);
  });

  test('a pop back to the page under it goes to whichever is', () {
    final sheet = Sheet.parse('''
pages:
  - {id: list, label: List, states: [{name: s, preview: a.dart#a}]}
  - {id: detail, label: Detail, states: [{name: s, preview: b.dart#b}]}
  - id: edit
    label: Edit
    states: [{name: s, preview: c.dart#c}, {name: Asking, preview: c.dart#c@1}]
  - {id: other, label: Other, states: [{name: s, preview: d.dart#d}]}
edges:
  - {from: list, to: detail, trigger: text:Open}
  - {from: list, to: edit, trigger: text:New}
  - {from: detail, to: edit, trigger: text:Edit}
  - {from: edit, trigger: text:Save, kind: pop}
  - {from: list, to: other, trigger: text:Other}
  # Back asks first: the back of the page is this, not a pop.
  - {from: edit, to: edit, trigger: back, when: s, then: Asking, kind: replace}
  - {from: edit, trigger: text:Discard, when: Asking, kind: pop}
''', _m);
    // One edge to each page it can be over.
    expect(
      [
        for (final e in sheet.edges)
          if (e.under) e.key,
      ],
      [
        'edit>list text:Save pop',
        'edit>detail text:Save pop',
        'edit>list text:Discard [Asking] pop',
        'edit>detail text:Discard [Asking] pop',
      ],
    );
    // Opened from the list, saving goes back to the list, not to detail.
    expect(_said(sheet, sheet.router.route('edit', null, 'other')), [
      'list:s edit:s',
      'edit>list text:Save pop => list:s',
      'list>other text:Other push => other:s',
    ]);
    // From detail, back to detail; the back asks first.
    final fromDetail = sheet.router.route('detail', null, 'list');
    expect(_said(sheet, fromDetail), ['list:s detail:s', 'back => list:s']);
    // Something written done by the back takes the back's place.
    final asking = Sheet.parse('''
pages:
  - {id: list, label: List, states: [{name: s, preview: a.dart#a}]}
  - id: edit
    label: Edit
    states: [{name: s, preview: c.dart#c}, {name: Asking, preview: c.dart#c@1}]
edges:
  - {from: list, to: edit, trigger: text:New}
  - {from: edit, to: edit, trigger: back, when: s, then: Asking, kind: replace}
  - {from: edit, trigger: text:Discard, when: Asking, kind: pop}
''', _m);
    expect(_said(asking, asking.router.route('edit', 's', 'list')), [
      'list:s edit:s',
      'edit>edit back [s] replace => edit:Asking',
      'back => list:s',
    ]);
  });

  test('a transition from every page is one from each', () {
    final sheet = Sheet.parse('''
conditions:
  - {name: Session, values: [Live, Expired]}
pages:
  - {id: home, label: Home, states: [{name: s, preview: a.dart#a}]}
  - {id: deep, label: Deep, states: [{name: s, preview: b.dart#b}]}
  - {id: login, label: Log in, states: [{name: s, preview: c.dart#c}]}
edges:
  - {from: home, to: deep, trigger: text:Deep}
  - {from: '*', to: login, trigger: other:Session expired, set: {Session: Expired}, kind: go}
''', _m);
    expect(
      [for (final e in sheet.edges) (e.from, e.to, e.anywhere)],
      [
        ('home', 'deep', false),
        ('home', 'login', true),
        ('deep', 'login', true),
      ],
    );
    expect(_said(sheet, sheet.router.route('deep', null, 'login')).skip(1), [
      'deep>login other:Session expired go => login:s',
    ]);
  });

  test('tabs keep their histories: a switch finds a tab as it was left', () {
    final sheet = Sheet.parse('''
conditions:
  - {name: Login, values: [Guest, Member]}
tabs:
  - retap: first
    pages:
      - {page: feed, trigger: text:Feed}
      - {page: search, trigger: text:Search}
      - {page: profile, trigger: text:Profile}
pages:
  - {id: feed, label: Feed, states: [{name: Loaded, preview: p.dart#feed}]}
  - {id: search, label: Search, states: [{name: Empty, preview: p.dart#search}, {name: Results, preview: p.dart#search@1, data: true}]}
  - id: profile
    label: Profile
    states:
      - {name: Guest, preview: p.dart#profile, if: {Login: Guest}}
      - {name: Member, preview: p.dart#profile@1, if: {Login: Member}}
  - {id: post, label: Post, tab: [feed, search], states: [{name: Loaded, preview: p.dart#post}]}
  - {id: comments, label: Comments, tab: [feed, search], states: [{name: Loaded, preview: p.dart#comments}]}
  - {id: quote, label: Quoted post, tab: [feed, search], states: [{name: Loaded, preview: p.dart#quote}]}
  - {id: sign_in, label: Sign in, states: [{name: Default, preview: s.dart#signIn}]}
  - {id: settings, label: Settings, states: [{name: Default, preview: p.dart#settings}]}
edges:
  - {from: feed, to: post, trigger: other:Tap a post}
  - {from: search, to: post, trigger: other:Tap a result, when: Results}
  - {from: post, to: comments, trigger: text:Comments, if: {Login: Member}}
  - {from: comments, to: quote, trigger: other:Tap the quoted post}
  - {from: profile, to: sign_in, trigger: text:Sign in, when: Guest}
  - {from: sign_in, to: profile, trigger: text:Done, set: {Login: Member}, kind: pop}
  - {from: profile, to: settings, trigger: text:Settings, when: Member}
  - {from: settings, to: feed, trigger: text:Done, kind: go}
''', _m);
    final router = sheet.router;
    // Signed in on another tab, the post is found again where it was left.
    final a = router.route('post', null, 'comments');
    expect(_said(sheet, a), [
      'feed:Loaded post:Loaded',
      'switch => profile:Guest',
      'profile>sign_in text:Sign in [Guest] push => sign_in:Default',
      'sign_in>profile text:Done pop => profile:Member',
      'switch => post:Loaded',
      'post>comments text:Comments {Login=Member} push => comments:Loaded',
    ]);
    expect(a.active, 'feed');
    expect(a.steps!.map((s) => s.tab), [
      'profile',
      null,
      'profile',
      'feed',
      'feed',
    ]);
    // Over the bar, the tabs as left; a go into a tab keeps the others.
    final b = router.route('settings', null, 'comments');
    expect(b.tabs.map((t) => t.page), ['feed']);
    expect(_said(sheet, b), [
      'profile:Member settings:Default',
      'settings>feed text:Done go => feed:Loaded',
      'feed>post other:Tap a post push => post:Loaded',
      'post>comments text:Comments {Login=Member} push => comments:Loaded',
    ]);
    // The tab shown, tapped again: its first page.
    expect(_said(sheet, router.route('comments', null, 'feed')).skip(1), [
      'retap => feed:Loaded',
    ]);
    expect(_said(sheet, router.route('comments', null, 'search')).skip(1), [
      'switch => search:Empty',
    ]);
    // Four pages deep in a tab, past the bound (3): one tap to the search
    // tab still, whichever tab the start's history went by.
    final d = router.route('quote', null, 'search');
    expect(d.inTab + d.start.skip(d.inTab).length, 4);
    expect(d.steps, hasLength(1));
    expect((d.bounded, d.searched), (false, true));
    expect(lintSheet(sheet, _m), isEmpty);
  });

  test('the bound below a route counts what a pop to another page leaves', () {
    // c's back goes to x in b's place: under x is a, where the back goes.
    final sheet = Sheet.parse('''
pages:
  - {id: a, label: A, states: [{name: s, preview: a.dart#a}]}
  - {id: b, label: B, states: [{name: s, preview: b.dart#b}]}
  - {id: c, label: C, states: [{name: s, preview: c.dart#c}]}
  - {id: x, label: X, states: [{name: s, preview: x.dart#x}]}
  - {id: t, label: T, states: [{name: s, preview: t.dart#t}]}
edges:
  - {from: a, to: b, trigger: text:B}
  - {from: b, to: c, trigger: text:C}
  - {from: c, to: x, trigger: back, kind: pop}
  - {from: a, to: t, trigger: text:T}
''', _m);
    expect(_said(sheet, sheet.router.route('c', null, 't')), [
      'a:s b:s c:s',
      'c>x back pop => x:s',
      'back => a:s',
      'a>t text:T push => t:s',
    ]);
  });

  test('out of a tab bar, its tabs\' histories are gone', () {
    final sheet = Sheet.parse('''
conditions:
  - {name: Login, values: [Guest, Member]}
tabs:
  - pages:
      - {page: feed, trigger: text:Feed}
      - {page: search, trigger: text:Search}
pages:
  - {id: feed, label: Feed, states: [{name: s, preview: f.dart#f}]}
  - {id: search, label: Search, states: [{name: s, preview: s.dart#s}]}
  - {id: post, label: Post, tab: search, states: [{name: s, preview: p.dart#p}]}
  - {id: detail, label: Detail, tab: search, states: [{name: s, preview: d.dart#d}]}
  - {id: login, label: Log in, states: [{name: s, preview: l.dart#l}]}
edges:
  - {from: search, to: post, trigger: text:Post}
  - {from: post, to: detail, trigger: text:Detail, if: {Login: Member}}
  - {from: post, to: login, trigger: text:Out, kind: go}
  - {from: login, to: feed, trigger: text:In, set: {Login: Member}, kind: go}
''', _m);
    // Back in the bar, the search tab opens anew: the post is not kept.
    expect(_said(sheet, sheet.router.route('post', null, 'detail')), [
      'search:s post:s',
      'post>login text:Out go => login:s',
      'login>feed text:In go => feed:s',
      'switch => search:s',
      'search>post text:Post push => post:s',
      'post>detail text:Detail {Login=Member} push => detail:s',
    ]);
  });

  test('a start deeper than the bound is searched again from as deep', () {
    final sheet = Sheet.parse('''
tabs:
  - retap: first
    pages:
      - {page: feed, trigger: text:Feed}
      - {page: search, trigger: text:Search}
pages:
  - {id: feed, label: Feed, states: [{name: s, preview: f.dart#f}]}
  - {id: search, label: Search, states: [{name: s, preview: s.dart#s}]}
  - {id: p1, label: P1, tab: feed, states: [{name: s, preview: a.dart#a}]}
  - {id: p2, label: P2, tab: feed, states: [{name: s, preview: b.dart#b}]}
  - {id: p3, label: P3, tab: feed, states: [{name: s, preview: c.dart#c}]}
  - {id: p4, label: P4, tab: feed, states: [{name: s, preview: d.dart#d}]}
  - {id: p5, label: P5, tab: feed, states: [{name: s, preview: e.dart#e}]}
edges:
  - {from: feed, to: p1, trigger: text:1}
  - {from: p1, to: p2, trigger: text:2}
  - {from: p2, to: p3, trigger: text:3}
  - {from: p3, to: p4, trigger: text:4}
  - {from: p4, to: p5, trigger: text:5}
''', _m);
    // Six pages deep in the feed tab, the search tab is one tap away.
    final route = sheet.router.route('p5', null, 'search');
    expect(_said(sheet, route).skip(1), ['switch => search:s']);
    expect(route.bounded, isFalse);
  });

  group('past a tab\'s bound, the navigator goes as within it', () {
    RoutePage page(String id, {List<String> tabs = const []}) =>
        RoutePage(id, [const RouteState('s')], tabs: tabs);
    final bars = [
      const RouteTabBar([RouteTab('feed'), RouteTab('search')]),
    ];
    // Three pages deep in the feed tab.
    final pages = [
      page('feed'),
      page('search'),
      page('a', tabs: ['feed']),
      page('b', tabs: ['feed']),
      page('c', tabs: ['feed']),
      page('sheet'),
      page('x'),
    ];
    const deep = [
      RouteEdge(from: 'feed', to: 'a', move: RouteMove.push),
      RouteEdge(from: 'a', to: 'b', move: RouteMove.push),
      RouteEdge(from: 'b', to: 'c', move: RouteMove.push),
    ];
    List<String> said(Route route) => [
      route.start.map((f) => f.page).join(' '),
      for (final s in route.steps ?? const <RouteStep>[])
        '${s.edge ?? s.move} => ${s.to.page}',
    ];

    test('a go to another tab, from a page over the tab\'s history, keeps '
        'it: past the bound, it is not taken', () {
      const edges = [
        ...deep,
        RouteEdge(from: 'c', to: 'sheet', move: RouteMove.push),
        RouteEdge(from: 'sheet', to: 'search', move: RouteMove.reset),
        // The sheet's back asks first: it does not go back.
        RouteEdge(
          from: 'sheet',
          to: 'sheet',
          move: RouteMove.replace,
          back: true,
        ),
      ];
      final within = Router(pages, edges, tabBars: bars, tabDepth: 4);
      expect(said(within.route('sheet', null, 'b')), [
        'feed a b c sheet',
        '4 => search',
        'switch => c',
        'back => b',
      ]);
      // The switch back shows c, not b: past the bound, none is found, and
      // the route says one might be.
      final past = Router(pages, edges, tabBars: bars);
      final route = past.route('sheet', null, 'b');
      expect(route.steps, isNull);
      expect(route.bounded, isTrue);
    });

    test('a replace by a page not in the tab puts it over the bar, the '
        'tab\'s top kept', () {
      const edges = [
        ...deep,
        RouteEdge(from: 'c', to: 'sheet', move: RouteMove.replace),
      ];
      for (final depth in [2, 3, 4, 5]) {
        final router = Router(pages, edges, tabBars: bars, tabDepth: depth);
        expect(said(router.route('sheet', null, 'b')), [
          'feed a b c sheet',
          'back => c',
          'back => b',
        ], reason: 'depth $depth');
      }
    });

    test('a pop to another page than the one under it lands in the tab\'s '
        'history, whichever page', () {
      const edges = [
        ...deep,
        RouteEdge(from: 'c', to: 'sheet', move: RouteMove.push),
        RouteEdge(from: 'sheet', to: 'x', move: RouteMove.pop),
      ];
      for (final depth in [2, 3, 4, 5]) {
        final router = Router(pages, edges, tabBars: bars, tabDepth: depth);
        expect(said(router.route('x', null, 'search')), [
          'feed a b x',
          'switch => search',
        ], reason: 'depth $depth');
        expect(said(router.route('x', null, 'b')), [
          'feed a b x',
          'back => b',
        ], reason: 'depth $depth');
      }
    });

    test('a start the app\'s launch reaches only past the bound says so', () {
      final router = Router(
        [
          ...pages.take(5),
          page('t', tabs: ['search']),
        ],
        const [
          ...deep,
          RouteEdge(
            from: 'c',
            to: 'c',
            move: RouteMove.replace,
            sets: {'Login': 'Member'},
          ),
          // c's back asks first, and nothing on c goes back.
          RouteEdge(from: 'c', to: 'c', move: RouteMove.replace, back: true),
          RouteEdge(
            from: 'search',
            to: 't',
            move: RouteMove.push,
            guard: {
              'Login': ['Member'],
            },
          ),
        ],
        tabBars: bars,
        conditions: const [
          RouteCondition('Login', ['Guest', 'Member']),
        ],
      );
      // Signing in is past the bound: within it, t starts alone.
      expect(router.route('t', null, 'feed').bounded, isTrue);
      expect(router.route('t', null, 'search').bounded, isTrue);
    });
  });

  test('a pop back to the page under it arrives in the state that page is '
      'in there', () {
    final router = Router(
      const [
        RoutePage('list', [RouteState('A'), RouteState('B')]),
        RoutePage('edit', [RouteState('s')]),
      ],
      const [
        RouteEdge(from: 'list', to: 'list', move: RouteMove.replace, then: 'B'),
        // Only in B does the list open the editor.
        RouteEdge(from: 'list', to: 'edit', move: RouteMove.push, when: ['B']),
        RouteEdge(from: 'edit', to: 'list', move: RouteMove.pop, under: true),
      ],
    );
    expect(router.arrivals(2), {
      's': ['B'],
    });
  });

  test('a page the app\'s start does not reach starts alone', () {
    final sheet = Sheet.parse('''
pages:
  - {id: a, label: A, states: [{name: s, preview: a.dart#a}]}
  - {id: b, label: B, states: [{name: s, preview: b.dart#b}, {name: t, preview: b.dart#b@1}]}
edges:
  - {from: b, to: a, trigger: text:A}
''', _m);
    expect(_said(sheet, sheet.router.route('b', null, 'a')), [
      'b:s',
      'b>a text:A push => a:s',
    ]);
    // In the state chosen, alone too.
    expect(_said(sheet, sheet.router.route('b', 't', 'a')), [
      'b:t',
      'b>a text:A push => a:s',
    ]);
    expect(sheet.router.route('a', null, 'b').steps, isNull);
  });

  group('with values held, what the app shows', () {
    final sheet = Sheet.parse('''
conditions: [{name: Login, values: [Guest, Member]}]
pages:
  - id: home
    label: Home
    states:
      - {name: Guest, if: {Login: Guest}, preview: a.dart#a}
      - {name: Member, if: {Login: Member}, preview: a.dart#a@1}
  - {id: login, label: Log in, states: [{name: s, preview: b.dart#b}]}
  - {id: perks, label: Perks, states: [{name: s, preview: c.dart#c}]}
  - {id: help, label: Help, states: [{name: s, preview: d.dart#d}]}
edges:
  - {from: home, to: login, trigger: text:Log in, if: {Login: Guest}}
  - {from: login, to: home, trigger: text:Log in, set: {Login: Member}, kind: go}
  - {from: home, to: perks, trigger: text:Perks, if: {Login: Member}}
  - {from: perks, to: home, trigger: text:Log out, set: {Login: Guest}, kind: go}
  - {from: home, to: help, trigger: text:Help}
entries:
  - {to: perks, via: /perks, if: {Login: Member}}
''', _m);

    test('nothing held: every page the app reaches, every edge', () {
      final shown = sheet.router.shown(_entries(sheet));
      expect(_framesOf(shown), {
        'home:Guest',
        'home:Member',
        'login:s',
        'perks:s',
        'help:s',
      });
      expect(shown.edges, [0, 1, 2, 3, 4]);
      expect(shown.entries, [0]);
    });

    test('a guest: never signed in, so neither the member\'s look nor the '
        'perks, and logging in does not happen', () {
      final shown = _holding(sheet, {'Login': 'Guest'}).shown(_entries(sheet));
      expect(shown.states, {
        'home': ['Guest'],
        'login': ['s'],
        'help': ['s'],
      });
      expect(shown.edges, [0, 4]);
      expect(shown.entries, isEmpty);
    });

    test('a member: launched signed in, never signed out; the deep link '
        'opens', () {
      final shown = _holding(sheet, {'Login': 'Member'}).shown(_entries(sheet));
      expect(shown.states, {
        'home': ['Member'],
        'perks': ['s'],
        'help': ['s'],
      });
      expect(shown.edges, [2, 4]);
      expect(shown.entries, [0]);
    });
  });

  test('with values held, the pages shown are those every history keeps '
      'them on, searched in full', () {
    // Random sheets, against a search over every stack up to [limit] steps
    // that never changes the values held: what it reaches is shown, and a
    // page shown that it does not reach is one the route takes more steps
    // to, or, in a tab bar, one the route cannot tell of.
    for (final tabs in [false, true]) {
      final limit = tabs ? 6 : 7;
      for (var seed = 1; seed <= 25; seed++) {
        final sheet = _random(Random(seed), tabs: tabs);
        for (final value in ['u', 'v']) {
          final router = _holding(sheet, {'C': value});
          final shown = router.shown(const []);
          final first = sheet.pages.first.id;
          final start = router.route(first, null, first);
          final reason = 'seed $seed${tabs ? ', tabs' : ''}, C: $value';
          // Its first page has no look with the value: nothing is shown.
          if (start.valuation['C'] != value) {
            expect(shown.states, isEmpty, reason: reason);
            continue;
          }
          final frames = <String>{};
          final reached = _searched(
            router,
            start,
            limit,
            held: {'C': value},
            frames: frames,
          );
          expect(_framesOf(shown), containsAll(frames), reason: reason);
          for (final page in shown.states.keys) {
            if (reached.containsKey(page)) continue;
            final route = router.route(first, null, page);
            if (!route.searched || route.bounded) continue;
            expect(
              route.steps?.length,
              greaterThan(limit),
              reason: '$reason, $page',
            );
          }
        }
      }
    }
  });

  test('it reads sheet.json as it reads the sheet: tab bars, parents, '
      'states and the values chosen too', () {
    for (final sheet in [
      _shop,
      _random(Random(1)),
      _random(Random(2)),
      _random(Random(3), tabs: true),
      _random(Random(4), tabs: true),
    ]) {
      final json = jsonDecode(
        jsonEncode(SheetMap(sheet, shots: const {}, m: _m).json(app: 'shop')),
      ) as Map<String, Object?>;
      final router = Router.fromJson(json);
      // What it shows with values held, its deep links too.
      for (final held in [
        const <String, String>{},
        for (final c in sheet.conditions) {c.name: c.values.last},
      ]) {
        expect(
          jsonEncode(
            Router.fromJson(
              json,
              held: held,
            ).shown(Router.entriesFromJson(json)).toJson(),
          ),
          jsonEncode(_holding(sheet, held).shown(_entries(sheet)).toJson()),
          reason: 'held $held',
        );
      }
      for (final from in sheet.pages) {
        for (final state in [null, from.states.last.name]) {
          for (final chosen in [
            const <String, String>{},
            for (final c in sheet.conditions) {c.name: c.values.last},
          ]) {
            for (final to in sheet.pages) {
              expect(
                jsonEncode(
                  router.route(from.id, state, to.id, chosen).toJson(),
                ),
                jsonEncode(
                  sheet.router.route(from.id, state, to.id, chosen).toJson(),
                ),
                reason: '${from.id} ($state) to ${to.id} under $chosen',
              );
            }
          }
        }
      }
    }
  });

  test('its fewest steps are those of every history, searched in full', () {
    // Random sheets, against a search over every stack up to [limit] steps
    // that knows nothing of summaries; from where the app's start reaches
    // a page, and from where it reaches it logged in (C: v).
    const limit = 7;
    for (var seed = 1; seed <= 25; seed++) {
      final sheet = _random(Random(seed));
      final router = sheet.router;
      for (final from in sheet.pages) {
        for (final chosen in [
          const <String, String>{},
          const {'C': 'v'},
        ]) {
          // From the same start, whichever page it goes to.
          final searched = _searched(
            router,
            router.route(from.id, null, from.id, chosen),
            limit,
          );
          for (final to in sheet.pages) {
            if (from == to) continue;
            final route = router.route(from.id, null, to.id, chosen);
            expect(route.valuation, containsPair('C', chosen['C'] ?? anything));
            final found = route.steps?.length;
            if (found != null && found > limit && searched[to.id] == null) {
              continue;
            }
            expect(
              found,
              searched[to.id],
              reason: 'seed $seed, ${from.id} to ${to.id} under $chosen',
            );
          }
        }
      }
    }
  });

  test(
    'in tabs that keep their histories, every history, searched in full',
    () {
      // Random sheets with a tab bar: for each bound, a route found is the
      // fewest of every history, unbounded (and no more than of those in which
      // a tab is left only within the bound); none found is none, unless the
      // route says one past the bound might be.
      const limit = 6;
      for (var seed = 1; seed <= 30; seed++) {
        final sheet = _random(Random(seed), tabs: true);
        for (final depth in [1, 2, 3]) {
          final router = Router(
            sheet.router.pages,
            sheet.router.edges,
            conditions: sheet.router.conditions,
            tabBars: sheet.router.tabBars,
            tabDepth: depth,
            searchLimit: 3000,
          );
          for (final from in sheet.pages) {
            final start = router.route(from.id, null, from.id);
            final bounded = _searched(router, start, limit, switchDepth: depth);
            final unbounded = _searched(router, start, limit);
            for (final to in sheet.pages) {
              if (from == to) continue;
              final route = router.route(from.id, null, to.id);
              // A search that stopped short says nothing.
              if (!route.searched) continue;
              final found = route.steps?.length;
              final reason = 'seed $seed, depth $depth, ${from.id} to ${to.id}';
              // No more than within the bound: searched again past it.
              if (found != null && bounded[to.id] != null) {
                expect(
                  found,
                  lessThanOrEqualTo(bounded[to.id]!),
                  reason: reason,
                );
              }
              // None found, but one past the bound might be.
              if (found == null && route.bounded) continue;
              if (found != null && found > limit && unbounded[to.id] == null) {
                continue;
              }
              expect(found, unbounded[to.id], reason: '$reason, unbounded');
            }
          }
        }
      }
    },
  );

  test('the JavaScript is compiled from the route as it is', () {
    final generated = File('lib/src/route_js.g.dart').readAsStringSync();
    expect(
      RegExp(r'^// sources: (\w+)$', multiLine: true).firstMatch(generated)?[1],
      routeSourcesHash(),
      reason: 'run dart run tool/gen_route_js.dart',
    );
    // Inlined in a <script>: nothing in it may end it.
    expect(routeJs.toLowerCase(), isNot(contains('</script')));
    expect(routeJs, isNot(contains('<!--')));
  });
}

/// A sheet of one condition (C: u, at launch, or v), 10 pages of 2 states
/// (the same 2 names on each: on some pages its states of C, x of u and y
/// of v; on others, y some decided by data), and 26 edges of every kind,
/// some only in a state, some while a value of C, some with `then`, some
/// setting C, some pops by the back. With [tabs], a tab bar of the first 2
/// or 3 pages (one switched to only while C: v), and the next 4 shown in 1
/// or 2 of its tabs.
Sheet _random(Random r, {bool tabs = false}) {
  const n = 10;
  const kinds = ['push', 'push', 'push', 'redirect', 'replace', 'go', 'pop'];
  final of = [for (var i = 0; i < n; i++) r.nextInt(3) == 0];
  final roots = tabs ? 2 + r.nextInt(2) : 0;
  final inTabs = [
    for (var i = 0; i < n; i++)
      i < roots || i >= roots + 4 || !tabs
          ? const <int>[]
          : ({r.nextInt(roots), r.nextInt(roots)}.toList()..sort()),
  ];
  String page(int i) {
    final data = !of[i] && r.nextInt(4) == 0 ? ', data: true' : '';
    final x = of[i] ? ', if: {C: u}' : '';
    final y = of[i] ? ', if: {C: v}' : '';
    final tab = inTabs[i].isEmpty
        ? ''
        : ', tab: [${inTabs[i].map((t) => 'p$t').join(', ')}]';
    // Nested under a page before it, sometimes.
    final parent = i > 0 && r.nextInt(3) == 0
        ? ', parent: p${r.nextInt(i)}'
        : '';
    return '  - {id: p$i, label: P$i$tab$parent, states: [{name: x, preview: a$i.dart#a$x}, '
        '{name: y, preview: a$i.dart#a@1$data$y}]}';
  }

  final bar = !tabs
      ? ''
      : 'tabs:\n  - retap: ${r.nextBool() ? 'first' : 'stay'}\n    pages:\n'
            '${[for (var t = 0; t < roots; t++) '      - {page: p$t, trigger: text:T$t${t == roots - 1 && r.nextBool() ? ', if: {C: v}' : ''}}'].join('\n')}\n';

  String? pick(int odds) =>
      r.nextInt(odds) == 0 ? (r.nextBool() ? 'x' : 'y') : null;
  String valueOf(String state) => state == 'x' ? 'u' : 'v';
  final pages = [for (var i = 0; i < n; i++) page(i)];
  // The pages put over another so far: a pop back to the page under it is
  // from one of them.
  final pushed = <int>[];
  final edges = [
    for (var k = 0; k < 26; k++)
      () {
        final kind = kinds[r.nextInt(kinds.length)];
        final under = kind == 'pop' && pushed.isNotEmpty && r.nextBool();
        final from = under ? pushed[r.nextInt(pushed.length)] : r.nextInt(n);
        final to = (from + 1 + r.nextInt(n - 1)) % n;
        if (kind == 'push' || kind == 'redirect') pushed.add(to);
        // The back, written: a pop, or anything else done by it.
        final trigger = r.nextInt(kind == 'pop' ? 2 : 8) == 0
            ? 'back'
            : 'text:t$k';
        final when = pick(4);
        final then = pick(5);
        var guard = r.nextInt(4) == 0 ? (r.nextBool() ? 'u' : 'v') : null;
        var set = r.nextInt(5) == 0 ? (r.nextBool() ? 'u' : 'v') : null;
        // As the sheet allows: an if its when's state is of, a set its
        // then's state is of.
        if (guard != null && when != null && of[from]) guard = valueOf(when);
        if (set != null && then != null && (under || of[to])) {
          set = under ? null : valueOf(then);
        }
        // A go to a page in tabs, sometimes saying which.
        final tab = kind == 'go' && inTabs[to].isNotEmpty && r.nextBool()
            ? ', tab: p${inTabs[to][r.nextInt(inTabs[to].length)]}'
            : '';
        return '  - {from: p$from${under ? '' : ', to: p$to'}, '
            'trigger: $trigger, kind: $kind$tab'
            '${when != null ? ', when: $when' : ''}'
            '${then != null ? ', then: $then' : ''}'
            '${guard != null ? ', if: {C: $guard}' : ''}'
            '${set != null ? ', set: {C: $set}' : ''}}';
      }(),
  ];
  return Sheet.parse(
    'conditions: [{name: C, values: [u, v]}]\n$bar'
    'pages:\n${pages.join('\n')}\nedges:\n${edges.join('\n')}\n',
    _m,
  );
}

/// The fewest steps from [route]'s start (its stack, under its values) to
/// each page, searched over every stack, up to [limit] steps; a page none
/// gets to in them is not in it. The history's rules, written again apart from
/// [Router]: a transition happens in its `when`'s states while its `if`'s
/// values, gives its `set`'s and its `then` state's; it arrives in its
/// `then`, else the state of the name left if the values allow it, else
/// the page's first, data and conditions' states the values allow. A push
/// puts on, a replace takes the top's place, a go starts again, a pop or
/// the back takes off, the page under landing as a written pop says, else
/// in the state of the name left, else in its own, else as unsaid, each if
/// the values allow it. The values are the app's: a pop keeps them.
///
/// In a tab bar: a push from a tab's page to a page shown in it adds to the
/// tab's history (past [switchDepth] pages, over it, where the bar does not
/// switch); a switch, while the bar shows, opens another tab at its first
/// page, or as it was left; a go to a page in a tab opens it alone in that
/// tab's history, the others kept; tapping the tab shown again, where the
/// bar says so, goes back to its first page. Without [switchDepth], a tab's
/// history has no bound.
///
/// No step changes the values [held] names. Each page shown, in its state,
/// is put in [frames] as `page:state`.
Map<String, int> _searched(
  Router router,
  Route route,
  int limit, {
  int? switchDepth,
  Map<String, String> held = const {},
  Set<String>? frames,
}) {
  final reached = <String, int>{};
  final pages = {for (final p in router.pages) p.id: p};
  RouteState? state(String page, String name) =>
      pages[page]!.states.where((s) => s.name == name).firstOrNull;
  bool fits(RouteState s, Map<String, String> g) =>
      s.conditions.entries.every((e) => g[e.key] == e.value);
  List<RouteFrame> unsaid(String page, Map<String, String> g) => [
    for (final (i, s) in pages[page]!.states.indexed)
      if ((i == 0 || s.data || s.conditions.isNotEmpty) && fits(s, g))
        (page: page, state: s.name),
  ];
  (Map<String, String>, List<RouteFrame>) arrive(
    RouteEdge e,
    String left,
    Map<String, String> g,
  ) {
    final after = {...g, ...e.sets};
    final then = e.thenBy[left] ?? e.then;
    if (then != null) {
      return (
        {...after, ...state(e.to, then)!.conditions},
        [(page: e.to, state: then)],
      );
    }
    final kept = state(e.to, left);
    if (kept != null && fits(kept, after)) {
      return (after, [(page: e.to, state: left)]);
    }
    return (after, unsaid(e.to, after));
  }

  List<RouteFrame> under(RouteFrame below, String left, Map<String, String> g) {
    final kept = state(below.page, left);
    if (kept != null && fits(kept, g)) return [(page: below.page, state: left)];
    if (fits(state(below.page, below.state)!, g)) return [below];
    return unsaid(below.page, g);
  }

  // With nothing under [top], its back: to its page's parent, in the state
  // of the name it left, else as unsaid.
  List<RouteFrame> toParent(RouteFrame top, Map<String, String> g) {
    final parent = pages[top.page]!.parent;
    if (parent == null) return const [];
    final kept = state(parent, top.state);
    if (kept != null && fits(kept, g)) {
      return [(page: parent, state: top.state)];
    }
    return unsaid(parent, g);
  }

  // The tab bars: each tab's bar, the tabs of a bar, the values a tab is
  // switched to while, whether a bar's tab tapped again goes to its first.
  final barOf = <String, int>{};
  final barTabs = <List<String>>[];
  final tabGuard = <String, Map<String, List<String>>>{};
  for (final (b, bar) in router.tabBars.indexed) {
    barTabs.add([for (final t in bar.tabs) t.page]);
    for (final t in bar.tabs) {
      barOf[t.page] = b;
      tabGuard[t.page] = t.guard;
    }
  }
  bool inTab(String page, String tab) =>
      page == tab || pages[page]!.tabs.contains(tab);
  String? tabFor(String page, String? active, String? named) {
    if (named != null) return named;
    if (barOf.containsKey(page)) return page;
    final tabs = pages[page]!.tabs;
    if (tabs.isEmpty) return null;
    return active != null && tabs.contains(active) ? active : tabs.first;
  }

  String key(_Config c) => [
    if (c.shell case final s?)
      '${s.active}|${[for (final t in barTabs[barOf[s.active]!]) s.stacks[t]!.map((f) => '${f.page}\u0000${f.state}').join(',')].join(';')}',
    ...c.above.map(
      (a) => '${a.frame.page}\u0000${a.frame.state}\u0000${a.tab}',
    ),
    ...[for (final c2 in router.conditions) c.g[c2.name]],
  ].join('\u0001');

  // The start, as the route gives it: a shell holding the tab shown's first
  // [Route.inTab] frames (and, unbounded, those past the bound in it, its
  // [Route.pastBound]), and the frames over it.
  _Config start;
  if (route.active case final active?) {
    final above = <({RouteFrame frame, String? tab})>[
      for (final (i, f) in route.start.skip(route.inTab).indexed)
        (frame: f, tab: i < route.pastBound ? active : null),
    ];
    final deep = [
      for (final a in above.takeWhile((a) => a.tab != null)) a.frame,
    ];
    final stacks = {
      for (final t in barTabs[barOf[active]!]) t: <RouteFrame>[],
      for (final t in route.tabs) t.page: t.frames,
      active: [
        ...route.start.take(route.inTab),
        if (switchDepth == null) ...deep,
      ],
    };
    start = (
      shell: (active: active, stacks: stacks),
      above: switchDepth == null ? above.skip(deep.length).toList() : above,
      g: route.valuation,
    );
  } else {
    start = (
      shell: null,
      above: [for (final f in route.start) (frame: f, tab: null)],
      g: route.valuation,
    );
  }

  var layer = [start];
  final seen = {key(start)};
  for (var d = 0; d <= limit && layer.isNotEmpty; d++) {
    final next = <_Config>[];
    void add(_Config c) {
      if (held.entries.any((h) => c.g[h.key] != h.value)) return;
      if (seen.add(key(c))) next.add(c);
    }

    for (final c in layer) {
      final (:shell, :above, :g) = c;
      final onShell = above.isEmpty;
      final stack = shell?.stacks[shell.active];
      final top = onShell ? stack!.last : above.last.frame;
      reached.putIfAbsent(top.page, () => d);
      frames?.add('${top.page}:${top.state}');
      _Config withStack(
        List<RouteFrame> s,
        Map<String, String> g2, {
        String? active,
      }) {
        final t = active ?? shell!.active;
        return (
          shell: (active: t, stacks: {...shell!.stacks, t: s}),
          above: const [],
          g: g2,
        );
      }

      final out = [
        for (final e in router.edges)
          if (e.from == top.page &&
              e.can(top.state) &&
              e.guard.entries.every((c) => c.value.contains(g[c.key])))
            e,
      ];
      for (final e in out) {
        final (after, frames) = arrive(e, top.state, g);
        for (final f in frames) {
          switch (e.move) {
            case RouteMove.push when onShell:
              if (!inTab(f.page, shell!.active)) {
                add((shell: shell, above: [(frame: f, tab: null)], g: after));
              } else if (switchDepth == null || stack!.length < switchDepth) {
                add(withStack([...stack!, f], after));
              } else {
                add((
                  shell: shell,
                  above: [(frame: f, tab: shell.active)],
                  g: after,
                ));
              }
            case RouteMove.push:
              final t = above.last.tab;
              add((
                shell: shell,
                above: [
                  ...above,
                  (frame: f, tab: t != null && inTab(f.page, t) ? t : null),
                ],
                g: after,
              ));
            // A page not in the tab, in its top's place: over the bar.
            case RouteMove.replace when onShell:
              if (inTab(f.page, shell!.active)) {
                add(withStack([...stack!.take(stack.length - 1), f], after));
              } else {
                add((shell: shell, above: [(frame: f, tab: null)], g: after));
              }
            // Past the bound as within it: a page not in the tab, over it.
            case RouteMove.replace
                when above.last.tab != null && !inTab(f.page, above.last.tab!):
              add((
                shell: shell,
                above: [...above, (frame: f, tab: null)],
                g: after,
              ));
            case RouteMove.replace:
              final t = above.last.tab;
              add((
                shell: shell,
                above: [...above.take(above.length - 1), (frame: f, tab: t)],
                g: after,
              ));
            case RouteMove.reset:
              final t = tabFor(f.page, shell?.active, e.tab);
              if (t == null) {
                add((shell: null, above: [(frame: f, tab: null)], g: after));
              } else if (shell != null && barOf[t] == barOf[shell.active]) {
                // Past the bound, the tab shown is not left for another,
                // from its history or over it.
                if (above.any((a) => a.tab != null) && t != shell.active) {
                  continue;
                }
                add(withStack([f], after, active: t));
              } else {
                add((
                  shell: (
                    active: t,
                    stacks: {
                      for (final u in barTabs[barOf[t]!]) u: <RouteFrame>[],
                      t: [f],
                    },
                  ),
                  above: const [],
                  g: after,
                ));
              }
            case RouteMove.pop when onShell:
              if (stack!.length == 1 && !e.under) {
                if (inTab(f.page, shell!.active)) {
                  add(withStack([f], after));
                } else {
                  add((shell: null, above: [(frame: f, tab: null)], g: after));
                }
              }
            case RouteMove.pop:
              if (shell == null && above.length == 1 && !e.under) {
                add((shell: null, above: [(frame: f, tab: null)], g: after));
              }
          }
        }
      }
      // Taken off, the page under it: in the tab's history, over the bar,
      // or the tab shown's top under what is over the bar.
      final RouteFrame? below;
      final _Config Function(RouteFrame, Map<String, String>) landed;
      if (onShell) {
        below = stack!.length >= 2 ? stack[stack.length - 2] : null;
        landed = (f, g2) => withStack([...stack.take(stack.length - 2), f], g2);
      } else if (above.length >= 2) {
        final b = above[above.length - 2];
        below = b.frame;
        // In the tab's history past the bound, whichever page.
        landed = (f, g2) => (
          shell: shell,
          above: [...above.take(above.length - 2), (frame: f, tab: b.tab)],
          g: g2,
        );
      } else if (shell != null) {
        below = stack!.last;
        landed = (f, g2) => withStack([...stack.take(stack.length - 1), f], g2);
      } else {
        below = null;
        landed = (f, g2) => throw StateError('nothing under');
      }
      if (below != null) {
        final pops = out.where((e) => e.move == RouteMove.pop);
        // The back, unless something written is done by it here.
        if (!out.any((e) => e.back)) {
          for (final f in under(below, top.state, g)) {
            add(landed(f, g));
          }
        }
        for (final e in pops) {
          // Back to the page under it: only the one written for that page.
          if (e.under && e.to != below.page) continue;
          if (e.to != below.page) {
            final (after, frames) = arrive(e, top.state, g);
            for (final f in frames) {
              add(landed(f, after));
            }
            continue;
          }
          final after = {...g, ...e.sets};
          final then = e.thenBy[top.state] ?? e.then;
          if (then != null) {
            add(
              landed(
                (page: below.page, state: then),
                {...after, ...state(below.page, then)!.conditions},
              ),
            );
            continue;
          }
          for (final f in under(below, top.state, after)) {
            add(landed(f, after));
          }
        }
      } else if (!out.any((e) => e.back)) {
        // Nothing under it: its back to its parent, in the tab where the
        // parent is in it, else as a go from nowhere puts it.
        for (final f in toParent(top, g)) {
          if (onShell && inTab(f.page, shell!.active)) {
            add(withStack([f], g));
            continue;
          }
          final t = tabFor(f.page, null, null);
          add(
            t == null
                ? (shell: null, above: [(frame: f, tab: null)], g: g)
                : (
                    shell: (
                      active: t,
                      stacks: {
                        for (final u in barTabs[barOf[t]!]) u: <RouteFrame>[],
                        t: [f],
                      },
                    ),
                    above: const [],
                    g: g,
                  ),
          );
        }
      }
      if (shell == null) continue;
      // Tapping the tab shown again, while it can be switched to.
      final retap =
          router.tabBars[barOf[shell.active]!].retapFirst &&
          tabGuard[shell.active]!.entries.every(
            (c) => c.value.contains(g[c.key]),
          );
      if (onShell) {
        // A switch: a tab not opened at its first page, else as left.
        for (final t in barTabs[barOf[shell.active]!]) {
          if (t == shell.active ||
              !tabGuard[t]!.entries.every((c) => c.value.contains(g[c.key]))) {
            continue;
          }
          final other = shell.stacks[t]!;
          if (other.isEmpty) {
            for (final f in unsaid(t, g)) {
              add(withStack([f], g, active: t));
            }
          } else if (fits(state(other.last.page, other.last.state)!, g)) {
            add(withStack(other, g, active: t));
          } else {
            for (final f in unsaid(other.last.page, g)) {
              add(
                withStack([...other.take(other.length - 1), f], g, active: t),
              );
            }
          }
        }
        // Not on the tab's first page alone.
        if (retap &&
            (stack!.length >= 2 || stack.single.page != shell.active)) {
          for (final f in unsaid(shell.active, g)) {
            add(withStack([f], g));
          }
        }
      } else if (retap && above.last.tab == shell.active) {
        for (final f in unsaid(shell.active, g)) {
          add(withStack([f], g));
        }
      }
    }
    layer = next;
  }
  return reached;
}

/// A history as [_searched] keeps it: the shell of a tab bar at its bottom
/// (the tab shown, and each tab's history by its first page), if any; the
/// frames over it (each in a tab's history past the bound, or none); and
/// the conditions' values.
typedef _Config = ({
  ({String active, Map<String, List<RouteFrame>> stacks})? shell,
  List<({RouteFrame frame, String? tab})> above,
  Map<String, String> g,
});
