import 'package:contact_sheet/contact_sheet.dart';
import 'package:contact_sheet/src/map.dart';
import 'package:test/test.dart';

final _m = Messages.of('en');

Sheet _parse(String yaml) => Sheet.parse(yaml, _m);

/// [message]: the message, or a matcher of it.
Matcher _fails(Object message) =>
    throwsA(isA<SheetException>().having((e) => e.message, 'message', message));

void main() {
  test('reads pages, states, edges, deep links and dependencies', () {
    final sheet = _parse('''
dependencies:
  - {name: Auth, target: authProvider, source: lib/auth.dart}
tags:
  - {name: Spec}
pages:
  - id: home
    label: ホーム
    section: 購入
    widget: HomePage
    source: lib/home.dart
    path: /
    memo: Lists the products.
    tags: {Spec: {label: Spec, url: 'https://example.com/spec'}}
    dependencies: [Auth]
    states:
      - {name: Guest, preview: lib/preview/home.dart#home, uses: {Auth: guest}}
      - {name: Member, preview: lib/preview/home.dart#home@1}
  - id: detail
    label: 詳細
    states: [{name: Standard, preview: lib/preview/detail.dart#detail}]
edges:
  - {from: home, to: detail, trigger: key:p1, when: Guest, kind: go, source: lib/home.dart}
  - {from: detail, to: home, trigger: back, kind: pop}
entries:
  - {to: detail, via: /products/:id}
''');
    final [home, detail] = sheet.pages;
    expect(home.label, 'ホーム');
    expect(home.path, '/');
    expect(home.tags.single.url, 'https://example.com/spec');
    expect(sheet.dependenciesOf(home).single.target, 'authProvider');
    final [guest, member] = home.states;
    expect(
      (guest.file, guest.symbol, guest.index),
      ('lib/preview/home.dart', 'home', 0),
    );
    expect(guest.uses, {'Auth': 'guest'});
    expect(member.index, 1);
    expect(member.preview, 'lib/preview/home.dart#home@1');
    expect(detail.section, '');
    final [go, back] = sheet.edges;
    expect('${go.trigger}', 'key:p1');
    expect(go.kind, NavigationKind.go);
    expect(back.trigger!.isBack, isTrue);
    expect(sheet.entries.single.via, '/products/:id');
  });

  test('a tag is set alike for every page: a value goes in its url', () {
    final sheet = _parse('''
tags:
  - {name: Analytics, url: 'https://analytics.example.com/screens/{value}'}
  - {name: Spec}
  - {name: Owner}
  - {name: Web, url: 'https://app.example.com{value}'}
pages:
  - id: home
    label: Home
    tags:
      Analytics: [home view, home_scroll]
      Spec: {label: Home spec, url: 'https://example.com/spec'}
      Owner: Shop team
      Web: /products/p1?from=home
    states: [{name: s, preview: lib/home.dart#home}]
  - id: cart
    label: Cart
    tags: {Analytics: {label: Cart dashboard, url: 'https://example.com/cart'}}
    states: [{name: s, preview: lib/cart.dart#cart}]
''');
    expect(
      [for (final t in sheet.pages.first.tags) (t.tag, t.label, t.url)],
      [
        (
          'Analytics',
          'home view',
          'https://analytics.example.com/screens/home%20view',
        ),
        (
          'Analytics',
          'home_scroll',
          'https://analytics.example.com/screens/home_scroll',
        ),
        ('Spec', 'Home spec', 'https://example.com/spec'),
        ('Owner', 'Shop team', null),
        // A path, as the app on the web takes it.
        (
          'Web',
          '/products/p1?from=home',
          'https://app.example.com/products/p1?from=home',
        ),
      ],
    );
    // A link of its own, whatever the tag's url.
    expect(sheet.pages.last.tags.single.url, 'https://example.com/cart');
  });

  test('a tag made of the path is every page\'s with one, its parameters '
      'the params; a state has its own values', () {
    final sheet = _parse('''
tags:
  - {name: Web, url: 'https://app.example.com{path}'}
  - {name: Analytics, url: 'https://analytics.example.com/{value}'}
  - {name: Design}
pages:
  - id: home
    label: Home
    path: /
    tags: {Analytics: home}
    states:
      - {name: Guest, preview: lib/home.dart#home, tags: {Analytics: home_guest}}
      - {name: Member, preview: lib/home.dart#home@1, tags: {Analytics: []}}
  - id: product
    label: Product
    path: /products/:id/reviews/:review
    params: {id: p 1}
    tags: {Design: {label: Product, url: 'https://example.com/design'}}
    states:
      - {name: Saved, preview: lib/p.dart#p, params: {review: r/2}}
      - {name: Unsaved, preview: lib/p.dart#p@1}
  - {id: about, label: About, states: [{name: s, preview: lib/a.dart#a}]}
''');
    List<(String, String, String?)> said(List<SheetPageTag> tags) => [
      for (final t in tags) (t.tag, t.label, t.url),
    ];
    final [home, product, about] = sheet.pages;
    expect(said(home.tags), [
      ('Web', '/', 'https://app.example.com/'),
      ('Analytics', 'home', 'https://analytics.example.com/home'),
    ]);
    // A state's values in place of its page's; none, where it says so.
    expect(said(home.states.first.tags), [
      ('Web', '/', 'https://app.example.com/'),
      ('Analytics', 'home_guest', 'https://analytics.example.com/home_guest'),
    ]);
    expect(said(home.states.last.tags), [
      ('Web', '/', 'https://app.example.com/'),
    ]);
    // A parameter without a value: the path as declared, no link.
    expect(said(product.tags).first, (
      'Web',
      '/products/:id/reviews/:review',
      null,
    ));
    // A state's parameters over its page's, each escaped.
    expect(said(product.states.first.tags), [
      (
        'Web',
        '/products/p 1/reviews/r/2',
        'https://app.example.com/products/p%201/reviews/r%2F2',
      ),
      ('Design', 'Product', 'https://example.com/design'),
    ]);
    expect(product.states.first.params, {'review': 'r/2'});
    expect(about.tags, isEmpty);
    expect(
      lintHints(sheet, _m).map((h) => h.key),
      contains('path-params product'),
    );
    expect(
      lintSheet(sheet, _m),
      contains(
        'Product (product): its path\'s review has no value in params (the '
        'page\'s, or a state\'s), so a tag\'s url made with {path} has no link '
        'there',
      ),
    );
  });

  test('a tag a page names is one of tags, named once', () {
    const page = 'states: [{name: s, preview: lib/a.dart#a}]';
    expect(
      () => _parse('pages:\n  - {id: a, label: A, tags: {Spec: x}, $page}'),
      _fails(contains('pages[0].tags.Spec: Spec is not in tags')),
    );
    expect(
      () => _parse('tags: [{name: Spec}, {name: Spec}]\npages: []'),
      _fails(contains('tags[1]: another tag is named Spec')),
    );
    expect(
      () => _parse(
        'tags: [{name: Spec}]\n'
        'pages:\n  - {id: a, label: A, tags: {Spec: [[x]]}, $page}',
      ),
      _fails(contains('pages[0].tags.Spec[0]: write a value')),
    );
  });

  test('a preview is the app\'s, or the sheet package\'s, on any declaration '
      'shutter names', () {
    final sheet = _parse('''
pages:
  - id: a
    label: A
    states:
      - {name: app, preview: lib/features/home_preview.dart#HomePage.new@1}
      - {name: sheet, preview: contact_sheet/lib/preview/home.dart#Home.preview}
''');
    final [app, package] = sheet.pages.single.states;
    expect(app.inSheetPackage, isFalse);
    expect(app.projectFile, 'lib/features/home_preview.dart');
    expect((app.symbol, app.index), ('HomePage.new', 1));
    expect(package.inSheetPackage, isTrue);
    expect(package.projectFile, 'lib/preview/home.dart');
    expect(package.symbol, 'Home.preview');
  });

  test('an empty sheet has no pages', () {
    expect(_parse('').pages, isEmpty);
    expect(_parse('pages: []\nedges: []\n').pages, isEmpty);
  });

  test('says where it is wrong', () {
    expect(
      () => _parse('pages: [{id: a, label: A, states: []}]'),
      _fails(
        'contact_sheet/sheet.yaml, pages[0].states: '
        'a page needs at least one state',
      ),
    );
    expect(
      () =>
          _parse('pages: [{label: A, states: [{name: s, preview: a.dart#a}]}]'),
      _fails('contact_sheet/sheet.yaml, pages[0]: id is missing'),
    );
    const page = '{id: a, label: A, states: [{name: s, preview: a.dart#a}]}';
    expect(
      () => _parse('pages: [$page, $page]'),
      _fails(
        'contact_sheet/sheet.yaml, pages[1]: the id a is taken by another page',
      ),
    );
    expect(
      () => _parse('pages: [$page]\nedges: [{from: a, to: b}]'),
      _fails('contact_sheet/sheet.yaml, edges[0].to: there is no page b'),
    );
    expect(
      () => _parse('pages: [$page]\nedges: [{from: a, to: a, when: x}]'),
      _fails('contact_sheet/sheet.yaml, edges[0].when: a has no state x'),
    );
    expect(
      () => _parse('pages: [$page]\nedges: [{from: a, to: a, trigger: tap}]'),
      _fails(startsWith('contact_sheet/sheet.yaml, edges[0].trigger: tap is')),
    );
    expect(
      () => _parse('pages: [$page]\nedges: [{from: a, to: a, kind: jump}]'),
      _fails(startsWith('contact_sheet/sheet.yaml, edges[0].kind: jump is')),
    );
    expect(
      () =>
          _parse('pages: [{id: a, label: A, states: [{name: s, preview: a}]}]'),
      _fails(
        startsWith(
          'contact_sheet/sheet.yaml, pages[0].states[0].preview: a is not',
        ),
      ),
    );
    expect(
      () => _parse(
        'pages: [{id: a, label: A, dependencies: [X], '
        'states: [{name: s, preview: a.dart#a}]}]',
      ),
      _fails(
        'contact_sheet/sheet.yaml, pages[0].dependencies: '
        'X is not in dependencies',
      ),
    );
    expect(
      () => _parse('pages: [oops'),
      _fails(
        startsWith('contact_sheet/sheet.yaml, line 1, column 13: not YAML'),
      ),
    );
    // A file as shutter names it, which its shot's id is of.
    for (final file in ['./lib/a.dart', r'lib\a.dart', 'lib/../lib/a.dart']) {
      expect(
        () => _parse(
          'pages: [{id: a, label: A, states: [{name: s, '
          "preview: '$file#a'}]}]",
        ),
        _fails(
          startsWith(
            'contact_sheet/sheet.yaml, pages[0].states[0].preview: $file: '
            'write the file relative to the app',
          ),
        ),
      );
    }
    // A declaration is named, not a number.
    expect(
      () => _parse(
        'pages: [{id: a, label: A, states: [{name: s, preview: a.dart#fn.1}]}]',
      ),
      _fails(
        startsWith('contact_sheet/sheet.yaml, pages[0].states[0].preview'),
      ),
    );
    // A field misspelt, or where it does not go, is not left out unread.
    expect(
      () => _parse('pages: [$page]\nedges: [{from: a, to: a, wehn: s}]'),
      _fails(
        'contact_sheet/sheet.yaml, edges[0].wehn: wehn is not a field here: '
        'from, to, trigger, when, if, set, then, kind, tab, source',
      ),
    );
    expect(
      () => _parse('page: [$page]'),
      _fails(startsWith('contact_sheet/sheet.yaml, sheet.yaml.page: page is')),
    );
    expect(
      () => _parse(
        'pages: [{id: a, label: A, states: [{name: s, preview: a.dart#a, '
        'when: x}]}]',
      ),
      _fails(startsWith('contact_sheet/sheet.yaml, pages[0].states[0].when:')),
    );
    // Each field of the shape it takes, said where it is not.
    const login = 'conditions: [{name: Login, values: [Guest, Member]}]\n';
    for (final (yaml, where) in [
      ('pages: {a: 1}', 'sheet.yaml.pages'),
      ('checked: [[x]]', 'sheet.yaml.checked[0]'),
      ('pages: [{id: a, label: [A], states: [{name: s}]}]', 'pages[0].label'),
      (
        'pages: [{id: a, label: A, states: [{name: s, uses: [x]}]}]',
        'pages[0].states[0].uses',
      ),
      (
        'pages: [{id: a, label: A, params: [x], states: [{name: s}]}]',
        'pages[0].params',
      ),
      (
        'pages: [{id: a, label: A, states: [{name: s, params: {id: [x]}}]}]',
        'pages[0].states[0].params.id',
      ),
      ('pages: [$page]\nedges: [{from: a, to: a, if: x}]', 'edges[0].if'),
      (
        '${login}pages: [$page]\nedges: [{from: a, to: a, if: {Login: []}}]',
        'edges[0].if.Login',
      ),
      (
        '${login}pages: [$page]\nedges: [{from: a, to: a, if: {Login: {x: y}}}]',
        'edges[0].if.Login',
      ),
      (
        '${login}pages: [$page]\nedges: [{from: a, to: a, if: {Login: [[x]]}}]',
        'edges[0].if.Login[0]',
      ),
      (
        'pages: [$page]\nedges: [{from: a, to: a, then: {s: [x]}}]',
        'edges[0].then.s',
      ),
      (
        'pages: [$page]\nedges: [{from: a, to: a, then: {x: s}}]',
        'edges[0].then',
      ),
      (
        'pages: [$page]\ntabs: [{pages: [{page: a, trigger: tap}]}]',
        'tabs[0].pages[0].trigger',
      ),
    ]) {
      expect(
        () => _parse(yaml),
        _fails(startsWith('contact_sheet/sheet.yaml, $where: ')),
        reason: yaml,
      );
    }
    // A number or a truth where text goes is read as its text.
    expect(
      _parse(
        'pages: [{id: a, label: 404, states: [{name: true, preview: a.dart#a}]}]',
      ).pages.single,
      isA<SheetPage>()
          .having((p) => p.label, 'label', '404')
          .having((p) => p.states.single.name, 'state', 'true'),
    );
  });

  test('variants: a platform, and a Preview by its name; a preview may be '
      'the nth a MultiPreview gives', () {
    final sheet = _parse('''
variants:
  - {name: iPhone}
  - {name: Android, platform: android}
  - {name: Desktop, preview: Desktop}
pages:
  - id: a
    label: A
    states: [{name: s, preview: a.dart#a@1.2}]
''');
    final [iphone, android, desktop] = sheet.variants;
    expect((iphone.platform, iphone.preview), (VariantPlatform.ios, null));
    expect(android.platform, VariantPlatform.android);
    expect(desktop.preview, 'Desktop');
    final state = sheet.pages.single.states.single;
    expect((state.index, state.runtime), (1, 2));
    expect(state.preview, 'a.dart#a@1.2');
    // None named: one, unnamed, as iOS.
    final plain = _parse(
      'pages: [{id: a, label: A, states: [{name: s, preview: a.dart#a}]}]',
    );
    expect(plain.variants.single.name, '');
    expect(plain.variants.single.platform, VariantPlatform.ios);
    expect(
      () => _parse('variants: [{name: X, platform: web}]'),
      _fails(
        'contact_sheet/sheet.yaml, variants[0].platform: '
        'web is not a platform: ios or android',
      ),
    );
    expect(
      () => _parse('variants: [{name: X}, {name: X}]'),
      _fails(
        'contact_sheet/sheet.yaml, variants[1]: another variant is named X',
      ),
    );
  });

  test('an edge happens in one state or several, and arrives in one', () {
    final sheet = _parse('''
pages:
  - id: a
    label: A
    states:
      - {name: s, preview: a.dart#a}
      - {name: t, preview: a.dart#a@1}
      - {name: u, preview: a.dart#a@2}
  - id: b
    label: B
    states: [{name: x, preview: b.dart#b}, {name: y, preview: b.dart#b@1}]
edges:
  - {from: a, to: b, when: [s, t], then: y}
  - {from: a, to: b, when: u}
  - {from: b, to: a}
''');
    final [both, one, any] = sheet.edges;
    expect(both.when, ['s', 't']);
    expect(both.then, 'y');
    expect(one.when, ['u']);
    expect(one.then, isNull);
    expect(any.when, isEmpty);
    const page = '{id: a, label: A, states: [{name: s, preview: a.dart#a}]}';
    expect(
      () => _parse('pages: [$page]\nedges: [{from: a, to: a, when: [s, x]}]'),
      _fails('contact_sheet/sheet.yaml, edges[0].when: a has no state x'),
    );
    expect(
      () => _parse('pages: [$page]\nedges: [{from: a, to: a, then: x}]'),
      _fails('contact_sheet/sheet.yaml, edges[0].then: a has no state x'),
    );
    // A state is named by its name: two of one name are told.
    expect(
      () => _parse(
        'pages: [{id: a, label: A, states: '
        '[{name: s, preview: a.dart#a}, {name: s, preview: a.dart#a@1}]}]',
      ),
      _fails(
        'contact_sheet/sheet.yaml, pages[0].states[1]: '
        'the page has two states named s: when and then name a state by it',
      ),
    );
  });

  test('an edge from several pages, arriving by the state it leaves', () {
    final sheet = _parse('''
pages:
  - id: a
    label: A
    states: [{name: guest, preview: a.dart#a}, {name: member, preview: a.dart#a@1}]
  - id: b
    label: B
    states: [{name: guest, preview: b.dart#b}, {name: member, preview: b.dart#b@1}]
  - id: c
    label: C
    states:
      - {name: s, preview: c.dart#c}
      - {name: t, preview: c.dart#c@1}
      - {name: empty, preview: c.dart#c@2, data: true}
edges:
  - {from: [a, b], to: c, trigger: text:Go, then: {guest: s, member: t}}
  - {from: a, to: b, trigger: text:B}
  - {from: c, to: a, when: [s, t], then: member}
  - {from: a, to: c, trigger: text:C}
entries:
  - {to: c, via: /c, then: t}
  - {to: c, via: /any}
''');
    final [ac, bc, ab, ca, aOther] = sheet.edges;
    expect((ac.from, bc.from), ('a', 'b'));
    expect((ac.item, bc.item, ab.item, ca.item), (0, 0, 1, 2));
    expect(sheet.arrivals(ac)['guest'], ['s']);
    expect(sheet.arrivals(bc)['member'], ['t']);
    // Where the sheet says none: the state of the name it leaves; else the
    // page's first, or one its data decides.
    expect(sheet.arrivals(ab)['member'], ['member']);
    expect(sheet.arrivals(ca), {
      's': ['member'],
      't': ['member'],
    });
    expect(sheet.arrivals(aOther)['guest'], ['s', 'empty']);
    expect(sheet.pages.last.states.last.data, isTrue);
    final [said, unsaid] = sheet.entries;
    expect(sheet.opening(said), ['t']);
    expect(sheet.opening(unsaid), ['s', 'empty']);
    expect(ac.key, 'a>c text:Go push');
    expect(ca.key, 'c>a [s,t] push');
    expect(said.key, 'c</c');

    const page =
        '{id: a, label: A, states: '
        '[{name: s, preview: a.dart#a}, {name: t, preview: a.dart#a@1}]}';
    expect(
      () => _parse('pages: [$page]\nedges: [{from: [a, a], to: a}]'),
      _fails('contact_sheet/sheet.yaml, edges[0].from[1]: a is listed twice'),
    );
    expect(
      () => _parse(
        'pages: [$page]\nedges: [{from: a, to: a, when: s, then: {t: s}}]',
      ),
      _fails(
        'contact_sheet/sheet.yaml, edges[0].then: '
        't is not in when: the edge does not happen in it',
      ),
    );
    expect(
      () => _parse('pages: [$page]\nedges: [{from: a, to: a, then: {s: x}}]'),
      _fails('contact_sheet/sheet.yaml, edges[0].then: a has no state x'),
    );
    expect(
      () => _parse('pages: [$page]\nentries: [{to: a, via: /a, then: x}]'),
      _fails('contact_sheet/sheet.yaml, entries[0].then: a has no state x'),
    );
    expect(
      () => _parse(
        'pages: [{id: a, label: A, states: '
        '[{name: s, preview: a.dart#a, data: yes please}]}]',
      ),
      _fails(
        'contact_sheet/sheet.yaml, pages[0].states[0].data: '
        'should be true or false',
      ),
    );
  });

  test('conditions: a state of their values, an edge while and setting', () {
    final sheet = _parse('''
conditions:
  - {name: Login, values: [Guest, Member], source: lib/auth.dart}
pages:
  - id: home
    label: Home
    states:
      - {name: Guest, preview: a.dart#a, if: {Login: Guest}}
      - {name: Member, preview: a.dart#a@1, if: {Login: Member}}
  - {id: cart, label: Cart, states: [{name: s, preview: c.dart#c}]}
  - {id: login, label: Log in, states: [{name: s, preview: l.dart#l}]}
edges:
  - {from: home, to: cart, trigger: label:Cart}
  - {from: cart, to: home, trigger: text:Buy, if: {Login: Member}, kind: go}
  - {from: cart, to: login, trigger: text:Buy, if: {Login: [Guest]}, kind: redirect}
  - {from: login, to: home, trigger: text:Log in, set: {Login: Member}, kind: go}
entries:
  - {to: home, via: /home, if: {Login: Member}}
''');
    final [homeCart, cartHome, cartLogin, loginHome] = sheet.edges;
    expect(sheet.conditions.single.values, ['Guest', 'Member']);
    expect(sheet.conditions.single.source, 'lib/auth.dart');
    expect(sheet.pages.first.states.last.conditions, {'Login': 'Member'});
    expect(cartLogin.guard, {
      'Login': ['Guest'],
    });
    expect(loginHome.sets, {'Login': 'Member'});
    expect(cartHome.key, 'cart>home text:Buy {Login=Member} go');
    expect(sheet.entries.single.key, 'home</home {Login=Member}');
    // Home follows the condition: no then is needed.
    expect(sheet.arrivals(loginHome), {
      's': ['Member'],
    });
    expect(sheet.arrivals(cartHome), {
      's': ['Member'],
    });
    expect(sheet.arrivals(homeCart), {
      'Guest': ['s'],
      'Member': ['s'],
    });
    expect(sheet.opening(sheet.entries.single), ['Member']);

    const conditions = 'conditions: [{name: L, values: [g, m]}]\n';
    const page =
        '{id: a, label: A, states: '
        '[{name: s, preview: a.dart#a, if: {L: g}}, '
        '{name: t, preview: a.dart#a@1, if: {L: m}}]}';
    void fails(String yaml, String said) =>
        expect(() => _parse(yaml), _fails('contact_sheet/sheet.yaml, $said'));
    fails(
      'conditions: [{name: L, values: [g]}, {name: L, values: [m]}]',
      'conditions[1]: another condition is named L',
    );
    fails(
      'conditions: [{name: L, values: []}]',
      'conditions[0].values: needs at least one value',
    );
    fails(
      'conditions: [{name: L, values: [g, g]}]',
      'conditions[0].values[1]: g is listed twice',
    );
    fails(
      'pages: [{id: a, label: A, states: '
          '[{name: s, preview: a.dart#a, if: {X: g}}]}]',
      'pages[0].states[0].if.X: X is not in conditions',
    );
    fails(
      '${conditions}pages: [{id: a, label: A, states: '
          '[{name: s, preview: a.dart#a, if: {L: [g]}}]}]',
      'pages[0].states[0].if.L: should be text',
    );
    fails(
      '${conditions}pages: [$page]\nedges: [{from: a, to: a, if: {L: x}}]',
      'edges[0].if.L: x is not a value of L',
    );
    fails(
      '${conditions}pages: [$page]\n'
          'edges: [{from: a, to: a, set: {L: g}, then: t}]',
      'edges[0].then: t is a state of other values than set gives',
    );
    fails(
      '${conditions}pages: [$page]\n'
          'edges: [{from: a, to: a, when: s, if: {L: m}}]',
      'edges[0].if: no state it happens in is a state of these values: '
          'it never happens',
    );
    fails(
      '${conditions}pages: [$page]\nentries: [{to: a, via: /a, if: {L: x}}]',
      'entries[0].if.L: x is not a value of L',
    );
  });

  test(
    'a pop without to, and an edge from every page, are told when wrong',
    () {
      const pages =
          'pages: [{id: a, label: A, states: [{name: s, preview: a.dart#a}]}, '
          '{id: b, label: B, states: [{name: s, preview: b.dart#b}]}]\n';
      void fails(String yaml, String said) => expect(
        () => _parse('$pages$yaml'),
        _fails('contact_sheet/sheet.yaml, $said'),
      );
      fails(
        'edges: [{from: b, kind: pop}]',
        'edges[0].to: nothing puts b over another page: a pop without to goes '
            'back to the page under it, and there is none',
      );
      // Only a pop may leave its to out.
      fails('edges: [{from: a, kind: push}]', 'edges[0]: to is missing');
      fails(
        "edges: [{from: '*', to: b, when: s}]",
        'edges[0].when: from every page, when cannot name a page\'s states: '
            'write if',
      );
      fails("edges: [{from: '*', kind: pop}]", 'edges[0]: to is missing');
      // Reached by a replace from a page put over another, it is over that.
      final sheet = _parse(
        '${pages}edges: [{from: a, to: b, kind: replace}, '
        '{from: a, to: a, trigger: text:Again}, {from: b, kind: pop}]',
      );
      expect(
        [for (final e in sheet.edges) (e.from, e.to, e.under)],
        [('a', 'b', false), ('a', 'a', false), ('b', 'a', true)],
      );
    },
  );

  test('tabs that keep their histories: read, told when wrong, hinted', () {
    const pages = '''
pages:
  - {id: a, label: A, states: [{name: s, preview: a.dart#a}]}
  - {id: b, label: B, states: [{name: s, preview: b.dart#b}]}
  - {id: c, label: C, tab: [a, b], states: [{name: s, preview: c.dart#c}]}
  - {id: d, label: D, states: [{name: s, preview: d.dart#d}]}
''';
    const bar =
        'tabs: [{retap: first, source: lib/r.dart, pages: '
        '[{page: a, trigger: text:A}, {page: b, trigger: label:B}]}]\n';
    final sheet = _parse('$bar$pages');
    final [tabs] = sheet.tabBars;
    expect(tabs.tabs.map((t) => '${t.page} ${t.trigger}'), [
      'a text:A',
      'b label:B',
    ]);
    expect((tabs.retapFirst, tabs.source), (true, 'lib/r.dart'));
    expect(sheet.pageOf('c')!.tabs, ['a', 'b']);
    expect(sheet.tabOf('a'), tabs.tabs.first);
    void fails(String yaml, String said) =>
        expect(() => _parse(yaml), _fails('contact_sheet/sheet.yaml, $said'));
    fails(
      'tabs: [{retap: twice, pages: [{page: a, trigger: text:A}]}]\n$pages',
      'tabs[0].retap: twice is not what tapping the tab shown again does: '
          'first or stay',
    );
    fails(
      'tabs: [{pages: [{page: a, trigger: text:A}, {page: a, trigger: text:B}]}]\n'
          '$pages',
      'tabs[0].pages[1]: a is listed twice',
    );
    fails(
      'tabs: [{pages: [{page: c, trigger: text:C}]}]\n$pages',
      'pages[2].tab: a tab\'s first page is in no other tab: tabs inside '
          'tabs are not drawn',
    );
    fails(
      'tabs: [{pages: [{page: a, trigger: text:A}]}]\n$pages',
      'pages[2].tab: b is not the first page of a tab in tabs',
    );
    fails(
      '$bar${pages}edges: [{from: d, to: c, tab: a}]',
      'edges[0].tab: only a go (or a deep link) says which tab it opens its '
          'page in',
    );
    fails(
      '$bar${pages}edges: [{from: d, to: d, kind: go, tab: a}]',
      'edges[0].tab: d is not shown in the tab of a',
    );
    fails(
      '$bar${pages}entries: [{to: d, via: /d, tab: b}]',
      'entries[0].tab: d is not shown in the tab of b',
    );
    expect(
      lintSheet(
        _parse('''
$bar$pages
  - {id: e, label: E, tab: b, states: [{name: s, preview: e.dart#e}]}
edges:
  - {from: a, to: b, trigger: label:B, kind: replace}
  - {from: a, to: e, trigger: text:E}
  - {from: d, to: c, trigger: text:C}
  - {from: a, to: d, trigger: text:D}
  - {from: d, to: c, trigger: text:Go, kind: go}
  - {from: a, to: a, trigger: text:Again, kind: replace}
  - {from: a, to: b, trigger: text:Open B, kind: go}
entries:
  - {to: c, via: /c}
'''),
        _m,
      ),
      [
        ('edges[0] goes between two tabs of one bar: the bar switches them, '
            'from every page in its tabs; leave it out'),
        ('edges[1]: E is not shown in the tab it is opened from, so it goes '
            'over the bar: if it is shown in that tab, add the tab to its tab'),
        ('edges[2]: C is shown in a tab, and opened from a page over the '
            'bar: it goes over the bar too; if the app opens it in its tab, '
            'write kind: go'),
        ('edges[4] opens C, shown in several tabs, in the tab of a, the '
            'first: name the tab with tab'),
        ('entries[0] opens C, shown in several tabs, in the tab of a, the '
            'first: name the tab with tab'),
      ],
    );
  });

  test(
    'a go\'s or a deep link\'s tab is a tab, though the page be its own',
    () {
      const pages = '''
pages:
  - {id: a, label: A, states: [{name: s, preview: a.dart#a}]}
  - {id: b, label: B, states: [{name: s, preview: b.dart#b}]}
''';
      expect(
        () => _parse('${pages}edges: [{from: a, to: b, kind: go, tab: b}]'),
        _fails(
          'contact_sheet/sheet.yaml, edges[0].tab: '
          'b is not the first page of a tab in tabs',
        ),
      );
      expect(
        () => _parse('${pages}entries: [{to: b, via: /b, tab: b}]'),
        _fails(
          'contact_sheet/sheet.yaml, entries[0].tab: '
          'b is not the first page of a tab in tabs',
        ),
      );
    },
  );

  test('an edge from every page is drawn once, from outside', () {
    final sheet = _parse('''
pages:
  - {id: home, label: Home, states: [{name: s, preview: a.dart#a}]}
  - {id: deep, label: Deep, states: [{name: s, preview: b.dart#b}]}
  - {id: login, label: Log in, states: [{name: s, preview: c.dart#c}]}
edges:
  - {from: home, to: deep, trigger: text:Deep}
  - {from: '*', to: login, trigger: other:Expired, kind: go}
''');
    final json = SheetMap(sheet, shots: const {}, m: _m).json(app: 'x');
    final edges = (json['edges']! as List).cast<Map<String, Object?>>();
    expect(edges.map((e) => e['anywhere']), [false, true, true]);
    expect(edges.map((e) => e.containsKey('curve')), [true, false, false]);
    expect(json['bundles'], [
      containsPair('edges', [1, 2]),
    ]);
    expect(
      (json['bundles']! as List).single,
      containsPair('label', 'Expired / go From any page'),
    );
    // Its pages are not laid out after every page.
    expect(lintSheet(sheet, _m), isEmpty);
  });

  test('lint tells what the conditions show may be wrong', () {
    final sheet = _parse('''
conditions:
  - {name: Login, values: [Guest, Member, Banned, Unused]}
pages:
  - id: home
    label: Home
    states:
      - {name: Member, preview: a.dart#a, if: {Login: Member}}
      - {name: Banned, preview: a.dart#a@1, if: {Login: Banned}}
      - {name: Also, preview: a.dart#a@2, if: {Login: Banned}}
  - {id: shop, label: Shop, states: [{name: s, preview: s.dart#s}]}
edges:
  - {from: home, to: shop, trigger: text:Shop, when: [Member, Banned], if: {Login: Member}}
  - {from: shop, to: home, trigger: text:Home, if: {Login: Banned}, kind: go}
''');
    expect(lintSheet(sheet, _m), [
      'Also of Home: none of the page\'s arrows leaves from it',
      'Guest of Login: no state, if or set names it',
      ('Member of Login: it is not the first, and nothing gives it (a set, '
          'or a then of a state of it): the app is never in it'),
      ('Banned of Login: it is not the first, and nothing gives it (a set, '
          'or a then of a state of it): the app is never in it'),
      'Unused of Login: no state, if or set names it',
      ('Home: the app launches here, and none of its states is its look '
          'with the conditions\' first values'),
      ('Home: none of its states is its look while Login: Guest (one of '
          'those values, its first or a data state): an arrow there that '
          'says no state does not happen'),
      ('Home: none of its states is its look while Login: Unused (one of '
          'those values, its first or a data state): an arrow there that '
          'says no state does not happen'),
      ('Banned and Also of Home: the same values of the conditions; where '
          'an arrow says no state, the map shows the first'),
      ('edges[0]: Banned is a state of other values than its if: it does '
          'not happen in it'),
      ('edges[1] from Shop: no way through the app reaches it there while '
          'its if holds'),
    ]);
  });

  test('lint tells a bar of one tab', () {
    final sheet = _parse('''
pages:
  - {id: feed, label: Feed, states: [{name: s, preview: f.dart#f}]}
tabs:
  - pages: [{page: feed, trigger: text:Feed}]
''');
    expect(
      [for (final hint in lintHints(sheet, _m)) (hint.key, hint.message)],
      [('one-tab feed', 'tabs[0]: a bar of one tab')],
    );
  });

  test('a deep link\'s then gives its state\'s values: an if met only from '
      'it is met', () {
    const sheet = '''
conditions:
  - {name: Login, values: [Guest, Member]}
pages:
  - {id: home, label: Home, states: [{name: s, preview: h.dart#h}]}
  - id: welcome
    label: Welcome
    states:
      - {name: Guest, preview: w.dart#w, if: {Login: Guest}}
      - {name: Member, preview: w.dart#w@1, if: {Login: Member}}
  - {id: shop, label: Shop, states: [{name: s, preview: s.dart#s}]}
edges:
  - {from: home, to: welcome, trigger: text:Welcome}
  - {from: welcome, to: shop, trigger: text:Shop, if: {Login: Member}}
''';
    List<String> keys(String yaml) => [
      for (final hint in lintHints(_parse(yaml), _m)) hint.key,
    ];
    // Without the link, nothing gives Member, and the edge never happens.
    expect(
      keys(sheet),
      containsAll([
        'value-not-given Login=Member',
        'if-never-met welcome>shop text:Shop {Login=Member} push',
      ]),
    );
    final linked = keys(
      '$sheet\nentries:\n  - {to: welcome, via: /welcome, then: Member}\n',
    );
    expect(linked, isNot(contains('value-not-given Login=Member')));
    expect(linked.where((k) => k.startsWith('if-never-met')), isEmpty);
  });

  test('lint tells an item no way meets once from its page, though it be an '
      'edge to each page under it', () {
    final sheet = _parse('''
conditions:
  - {name: Login, values: [Guest, Member]}
pages:
  - {id: a, label: A, states: [{name: s, preview: a.dart#a}]}
  - {id: b, label: B, states: [{name: s, preview: b.dart#b}]}
  - {id: c, label: C, states: [{name: s, preview: c.dart#c}]}
edges:
  - {from: a, to: b, trigger: text:B}
  - {from: a, to: c, trigger: text:C}
  - {from: b, to: c, trigger: text:C}
  - {from: c, trigger: text:Save, kind: pop, if: {Login: Member}}
''');
    expect(lintSheet(sheet, _m).where((f) => f.startsWith('edges[3]')), [
      'edges[3] from C: no way through the app reaches it there while its if holds',
    ]);
  });

  test('lint tells what the sheet itself shows may be missing or twice', () {
    final sheet = _parse('''
pages:
  - id: home
    label: Home
    states: [{name: s, preview: a.dart#a}]
  - id: cart
    label: Cart
    states:
      - {name: full, preview: c.dart#c}
      - {name: empty, preview: c.dart#c@1}
      - {name: gone, preview: c.dart#c@2}
      - {name: loading, preview: c.dart#c@3, data: true}
  - id: lost
    label: Lost
    states: [{name: s, preview: l.dart#l}]
  - id: linked
    label: Linked
    states: [{name: s, preview: k.dart#k}]
edges:
  - {from: home, to: cart, trigger: text:Cart}
  - {from: home, to: cart, trigger: text:Cart}
  - {from: cart, to: home, trigger: text:Buy, when: full}
  - {from: cart, to: home, trigger: text:Buy, when: empty}
  - {from: home, to: cart, trigger: text:Empty, then: empty}
entries:
  - {to: linked, via: /linked}
  - {to: linked, via: /linked}
''');
    expect(lintSheet(sheet, _m), [
      ('Lost (lost): no arrow leads to it from the first page, and no deep '
          'link opens it'),
      'gone of Cart: none of the page\'s arrows leaves from it',
      'loading of Cart: none of the page\'s arrows leaves from it',
      // What the page loads decides loading: arriving in it is not told.
      ('gone of Cart: no arrow arrives in it and no deep link opens it (a '
          'then, or the state left having its name), nor is it data: true '
          '(what the page loads decides it): the map shows it only when it '
          'is chosen'),
      'edges[1] is edges[0] again',
      ('edges[3] is edges[2] in other states: one edge, its when both\'s '
          'states, its then by the state it leaves'),
      'entries[1] is entries[0] again',
    ]);
    expect(lintSheet(_parse(''), _m), isEmpty);
  });

  test('lint tells a tag no page has, and one most pages have that some do '
      'not', () {
    String page(String id, String tags) =>
        '  - {id: $id, label: ${id.toUpperCase()}, tags: {$tags}, '
        'states: [{name: s, preview: $id.dart#$id}]}';
    final sheet = _parse('''
tags: [{name: Analytics}, {name: Figma}, {name: Unused}]
pages:
${page('a', 'Analytics: a, Figma: a')}
${page('b', 'Analytics: b')}
${page('c', 'Analytics: c')}
${page('d', '')}
edges:
  - {from: a, to: b, trigger: text:B}
  - {from: a, to: c, trigger: text:C}
  - {from: a, to: d, trigger: text:D}
''');
    expect(lintSheet(sheet, _m), [
      'the tag Analytics: 3 of the 4 pages have it, not D',
      'the tag Unused: no page has it',
    ]);
  });

  test('triggers are named as shutter names targets', () {
    expect('${Trigger.parse('text:購入する')}', 'text:購入する');
    expect(Trigger.parse('other:スワイプで削除')!.what, 'スワイプで削除');
    expect(Trigger.parse('back')!.isBack, isTrue);
    expect(Trigger.parse('tap:x'), isNull);
    expect(Trigger.parse('key:'), isNull);
  });
}
