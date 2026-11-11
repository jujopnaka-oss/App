import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =====================================================================
//  ตั้งค่าหลัก (แก้ตรงนี้ได้เลย)
// =====================================================================
const bool kUseAstonScript = false; // เปลี่ยนเป็น true หลังใส่ฟอนต์ AstonScript.ttf แล้ว
const bool kDevMode = true; // true = มีปุ่มจำลอง "ผู้พัฒนาตรวจจาน" (ปิดเป็น false ก่อนปล่อยจริง)
const String kImgExt = 'png'; // นามสกุลไฟล์รูปใน assets/images/
const int kMaxLevel = 20;
const int kDishesPerLevel = 1; // กี่จานต่อ 1 เลเวล

// =====================================================================
//  สี / สไตล์
// =====================================================================
const cream = Color(0xFFFFF8EC);
const mint = Color(0xFFE4F6EA);
const mintDark = Color(0xFF2F7A55);
const orange = Color(0xFFF7B267);
const orangeDark = Color(0xFFA24E0E);
const sky = Color(0xFFEAF5FD);
const skyDark = Color(0xFF1F5C8E);
const ink = Color(0xFF3B3A36);
const h2 = TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: ink);
const sub = TextStyle(fontSize: 12, color: Color(0xFF6B675F));

TextStyle brand(double size, {Color color = orangeDark}) => kUseAstonScript
    ? TextStyle(fontFamily: 'AstonScript', fontSize: size, color: color)
    : GoogleFonts.greatVibes(fontSize: size, color: color);

Widget img(String name,
        {double? w, double? h, BoxFit fit = BoxFit.contain, Widget? fallback}) =>
    Image.asset(
      'assets/images/$name.$kImgExt',
      width: w,
      height: h,
      fit: fit,
      errorBuilder: (c, e, s) => fallback ?? SizedBox(width: w, height: h),
    );

Widget card(Widget child, {Color color = Colors.white}) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Color(0x14785A28), blurRadius: 10, offset: Offset(0, 2))
        ],
      ),
      child: child,
    );

Widget chip(String t, Color bg, Color fg) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
    );

void snack(BuildContext c, String m) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));

String ago(int ms) {
  final m = (DateTime.now().millisecondsSinceEpoch - ms) ~/ 60000;
  if (m < 1) return 'เมื่อสักครู่';
  if (m < 60) return '$m นาทีที่แล้ว';
  final h = m ~/ 60;
  if (h < 24) return '$h ชม. ที่แล้ว';
  return '${h ~/ 24} วันที่แล้ว';
}

// =====================================================================
//  ข้อมูลอาหาร
// =====================================================================
class Recipe {
  final String name, emoji;
  final List<String> ing;
  final int kcal;
  final List<String> steps;
  const Recipe(this.name, this.emoji, this.ing, this.kcal, this.steps);
}

const allIngredients = [
  'ไข่ไก่', 'หมูสับ', 'เนื้อสับ', 'อกไก่', 'กุ้ง', 'เต้าหู้', 'ใบกะเพรา', 'พริก',
  'กระเทียม', 'มะเขือเทศ', 'ข้าวสวย', 'เส้นเล็ก', 'ถั่วงอก', 'ผักบุ้ง',
  'หอมหัวใหญ่', 'ต้นหอม', 'มะนาว', 'ถั่วลิสง', 'ตะไคร้', 'ข่า', 'ใบมะกรูด', 'กะทิ',
];

const recipes = [
  Recipe('ผัดกะเพราหมูสับไข่ดาว', '🍳',
      ['หมูสับ', 'ใบกะเพรา', 'พริก', 'กระเทียม', 'ไข่ไก่', 'ข้าวสวย'], 560, [
    'โขลกพริกกับกระเทียมให้พอแหลก',
    'ผัดหมูสับจนสุก ปรุงรสด้วยซอสหอยนางรม ซีอิ๊วขาว น้ำตาล',
    'ใส่ใบกะเพราผัดให้หอม',
    'ทอดไข่ดาวกรอบๆ แล้วราดบนข้าวสวย',
  ]),
  Recipe('ผัดกะเพราเนื้อสับ', '🥩',
      ['เนื้อสับ', 'ใบกะเพรา', 'พริก', 'กระเทียม', 'ไข่ไก่', 'ข้าวสวย'], 520, [
    'โขลกพริกกับกระเทียม',
    'ผัดเนื้อสับไฟแรงจนสุก ปรุงรส',
    'ใส่ใบกะเพราแล้วปิดไฟ',
    'เสิร์ฟกับไข่ดาวและข้าวสวย',
  ]),
  Recipe('ไข่เจียวฟู', '🥚', ['ไข่ไก่', 'ข้าวสวย'], 430, [
    'ตีไข่กับน้ำปลาให้ขึ้นฟู',
    'ทอดในน้ำมันร้อนจัดจนเหลืองกรอบ',
    'เสิร์ฟกับข้าวสวยร้อนๆ',
  ]),
  Recipe('ข้าวผัดไข่', '🍚', ['ไข่ไก่', 'ข้าวสวย', 'กระเทียม', 'ต้นหอม'], 480, [
    'ผัดกระเทียมให้หอม ใส่ไข่คนให้แตก',
    'ใส่ข้าวสวย ผัดไฟแรง',
    'ปรุงรส โรยต้นหอม',
  ]),
  Recipe('ผัดผักบุ้งไฟแดง', '🥬', ['ผักบุ้ง', 'กระเทียม', 'พริก'], 150, [
    'โขลกกระเทียมกับพริก',
    'ผัดไฟแรงสุดๆ ใส่ผักบุ้ง',
    'ปรุงรสด้วยเต้าเจี้ยว ซอสหอยนางรม',
  ]),
  Recipe('ต้มยำกุ้ง', '🍲', ['กุ้ง', 'ตะไคร้', 'ข่า', 'ใบมะกรูด', 'มะนาว', 'พริก'], 180, [
    'ต้มน้ำใส่ตะไคร้ ข่า ใบมะกรูด',
    'ใส่กุ้ง รอสุก',
    'ปรุงรสน้ำปลา พริก และบีบมะนาวตอนปิดไฟ',
  ]),
  Recipe('ผัดไทยกุ้งสด', '🍜',
      ['เส้นเล็ก', 'ไข่ไก่', 'กุ้ง', 'ถั่วงอก', 'ถั่วลิสง', 'ต้นหอม', 'มะนาว'], 620, [
    'แช่เส้นให้นิ่ม ผัดกับซอสผัดไทย',
    'ใส่กุ้งและไข่ ผัดให้เข้ากัน',
    'ใส่ถั่วงอก ต้นหอม เสิร์ฟกับถั่วป่นและมะนาว',
  ]),
  Recipe('ไข่เจียวหมูสับ', '🍳', ['ไข่ไก่', 'หมูสับ', 'หอมหัวใหญ่', 'ข้าวสวย'], 520, [
    'ผสมไข่กับหมูสับและหอมหัวใหญ่ซอย',
    'ทอดไฟกลางจนสุกเหลือง',
    'เสิร์ฟกับข้าวสวย',
  ]),
  Recipe('ไข่ผัดมะเขือเทศ', '🍅', ['ไข่ไก่', 'มะเขือเทศ', 'ต้นหอม', 'กระเทียม'], 260, [
    'ผัดกระเทียมให้หอม ใส่มะเขือเทศ',
    'ใส่ไข่ ผัดให้สุกพอดี',
    'ปรุงรส โรยต้นหอม',
  ]),
  Recipe('แกงเขียวหวานไก่', '🍛', ['อกไก่', 'กะทิ', 'พริก', 'ใบมะกรูด', 'ข้าวสวย'], 540, [
    'ผัดพริกแกงกับกะทิให้หอม',
    'ใส่ไก่ ต้มจนสุก',
    'ปรุงรส ใส่ใบมะกรูด เสิร์ฟกับข้าว',
  ]),
  Recipe('ไก่ผัดพริกกระเทียม', '🍗', ['อกไก่', 'พริก', 'กระเทียม', 'ข้าวสวย'], 450, [
    'โขลกพริกกับกระเทียม',
    'ผัดไก่ให้สุก ปรุงรส',
    'เสิร์ฟกับข้าวสวย',
  ]),
  Recipe('ต้มจืดเต้าหู้หมูสับ', '🥣', ['เต้าหู้', 'หมูสับ', 'ต้นหอม', 'กระเทียม'], 210, [
    'ต้มน้ำซุปกับกระเทียม',
    'ปั้นหมูสับเป็นก้อนลงต้ม ใส่เต้าหู้',
    'ปรุงรส โรยต้นหอม',
  ]),
  Recipe('ผัดถั่วงอกเต้าหู้', '🌱', ['ถั่วงอก', 'เต้าหู้', 'กระเทียม', 'ต้นหอม'], 190, [
    'ผัดกระเทียมกับเต้าหู้ให้เหลือง',
    'ใส่ถั่วงอก ผัดไฟแรงสั้นๆ',
    'ปรุงรส โรยต้นหอม',
  ]),
  Recipe('ไข่ยัดไส้', '🥚', ['ไข่ไก่', 'หมูสับ', 'หอมหัวใหญ่', 'มะเขือเทศ'], 320, [
    'ผัดหมูสับกับหอมใหญ่และมะเขือเทศเป็นไส้',
    'ทอดแผ่นไข่บางๆ',
    'ห่อไส้ในแผ่นไข่ ทอดให้สุก',
  ]),
];

const _allergyMap = {
  'อาหารทะเล': ['กุ้ง'],
  'ถั่ว': ['ถั่วลิสง'],
  'ไข่': ['ไข่ไก่'],
  'หมู': ['หมูสับ'],
  'เนื้อ': ['เนื้อสับ'],
  'ไก่': ['อกไก่'],
  'ถั่วเหลือง': ['เต้าหู้'],
};

List<String> allergenHits(Recipe r) {
  final a = app.allergy;
  if (a.isEmpty || a == 'ไม่มี') return [];
  return r.ing.where((i) {
    if (a.contains(i)) return true;
    for (final e in _allergyMap.entries) {
      if (a.contains(e.key) && e.value.contains(i)) return true;
    }
    return false;
  }).toList();
}

// =====================================================================
//  สถานะแอป (เก็บในเครื่องด้วย shared_preferences)
// =====================================================================
class Submission {
  final int id, time;
  String status, comment;
  Submission(this.id, this.time, {this.status = 'pending', this.comment = ''});
  Map<String, dynamic> toJson() =>
      {'id': id, 'time': time, 'status': status, 'comment': comment};
  factory Submission.fromJson(Map<String, dynamic> j) => Submission(
        j['id'] as int,
        j['time'] as int,
        status: j['status'] as String,
        comment: j['comment'] as String,
      );
}

class Notice {
  final String title, body;
  final int time;
  bool read;
  Notice(this.title, this.body, this.time, {this.read = false});
  Map<String, dynamic> toJson() =>
      {'title': title, 'body': body, 'time': time, 'read': read};
  factory Notice.fromJson(Map<String, dynamic> j) => Notice(
        j['title'] as String,
        j['body'] as String,
        j['time'] as int,
        read: j['read'] as bool,
      );
}

class AppState extends ChangeNotifier {
  late SharedPreferences p;
  bool onboarded = false;
  String nick = '', username = '', gender = 'm', allergy = '', skill = '';
  int age = 0, xp = 0;
  Uint8List? avatar;
  List<Submission> subs = [];
  List<Notice> notices = [];
  Set<String> liked = {}, saved = {};

  int get level => math.min(kMaxLevel, 1 + xp ~/ kDishesPerLevel);
  int get maxXp => (kMaxLevel - 1) * kDishesPerLevel;
  String get rank => level <= 10 ? 'เชฟฝึกหัด' : 'เชฟระดับเซียน';
  int get unread => notices.where((n) => !n.read).length;

  List<Map<String, dynamic>> _readList(String k) {
    final s = p.getString(k);
    if (s == null) return [];
    return (jsonDecode(s) as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> load() async {
    p = await SharedPreferences.getInstance();
    onboarded = p.getBool('onboarded') ?? false;
    nick = p.getString('nick') ?? '';
    username = p.getString('username') ?? '';
    gender = p.getString('gender') ?? 'm';
    allergy = p.getString('allergy') ?? '';
    skill = p.getString('skill') ?? '';
    age = p.getInt('age') ?? 0;
    xp = p.getInt('xp') ?? 0;
    final a = p.getString('avatar');
    avatar = a == null ? null : base64Decode(a);
    subs = _readList('subs').map(Submission.fromJson).toList();
    notices = _readList('notices').map(Notice.fromJson).toList();
    liked = (p.getStringList('liked') ?? []).toSet();
    saved = (p.getStringList('saved') ?? []).toSet();
    notifyListeners();
  }

  Future<void> saveProfile({
    required String nick,
    required String username,
    required String gender,
    required int age,
    required String allergy,
    required String skill,
  }) async {
    this.nick = nick;
    this.username = username;
    this.gender = gender;
    this.age = age;
    this.allergy = allergy;
    this.skill = skill;
    onboarded = true;
    await p.setBool('onboarded', true);
    await p.setString('nick', nick);
    await p.setString('username', username);
    await p.setString('gender', gender);
    await p.setInt('age', age);
    await p.setString('allergy', allergy);
    await p.setString('skill', skill);
    notifyListeners();
  }

  Future<void> setAvatar(Uint8List b) async {
    avatar = b;
    await p.setString('avatar', base64Encode(b));
    notifyListeners();
  }

  Future<void> toggleLike(int id) async {
    final k = '$id';
    liked.contains(k) ? liked.remove(k) : liked.add(k);
    await p.setStringList('liked', liked.toList());
    notifyListeners();
  }

  Future<void> toggleSave(int id) async {
    final k = '$id';
    saved.contains(k) ? saved.remove(k) : saved.add(k);
    await p.setStringList('saved', saved.toList());
    notifyListeners();
  }

  Future<void> _saveSubs() =>
      p.setString('subs', jsonEncode(subs.map((e) => e.toJson()).toList()));
  Future<void> _saveNotices() =>
      p.setString('notices', jsonEncode(notices.map((e) => e.toJson()).toList()));

  Future<void> addSubmission() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    subs.insert(0, Submission(now, now));
    await _saveSubs();
    notifyListeners();
  }

  /// เรียกตอนผู้พัฒนาตรวจจานแล้ว: +1 XP และส่งการแจ้งเตือน
  Future<void> approve(Submission s, String comment) async {
    s.status = 'approved';
    s.comment = comment;
    xp += 1;
    notices.insert(
      0,
      Notice('อัพเลเวลเชฟของคุณ! 🎉', 'ผู้พัฒนาตรวจจานของคุณแล้ว: $comment',
          DateTime.now().millisecondsSinceEpoch),
    );
    await p.setInt('xp', xp);
    await _saveSubs();
    await _saveNotices();
    notifyListeners();
  }

  Future<void> markRead() async {
    for (final n in notices) {
      n.read = true;
    }
    await _saveNotices();
    notifyListeners();
  }

  Future<void> reset() async {
    await p.clear();
    onboarded = false;
    nick = username = allergy = skill = '';
    gender = 'm';
    age = xp = 0;
    avatar = null;
    subs = [];
    notices = [];
    liked = {};
    saved = {};
    notifyListeners();
  }
}

final app = AppState();

// =====================================================================
//  main
// =====================================================================
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GoodMealApp());
}

class GoodMealApp extends StatelessWidget {
  const GoodMealApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Good Meal',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: orange,
          scaffoldBackgroundColor: cream,
          // ภาษาไทยทั้งแอปใช้ฟอนต์ Sarabun (สารบัญ)
          textTheme: GoogleFonts.sarabunTextTheme(),
        ),
        home: const Gate(),
      );
}

enum Stage { boot, onboarding, photo, entering, home }

class Gate extends StatefulWidget {
  const Gate({super.key});
  @override
  State<Gate> createState() => _GateState();
}

class _GateState extends State<Gate> {
  Stage stage = Stage.boot;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await Future.wait([
      app.load(),
      Future.delayed(const Duration(milliseconds: 2400)),
    ]);
    if (!mounted) return;
    setState(() => stage = app.onboarded ? Stage.home : Stage.onboarding);
  }

  Future<void> _enter() async {
    setState(() => stage = Stage.entering);
    await Future.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;
    setState(() => stage = Stage.home);
  }

  @override
  Widget build(BuildContext context) {
    final Widget page;
    switch (stage) {
      case Stage.boot:
      case Stage.entering:
        page = const LoadingView();
        break;
      case Stage.onboarding:
        page = Onboarding(onDone: () => setState(() => stage = Stage.photo));
        break;
      case Stage.photo:
        page = PhotoScreen(onDone: _enter);
        break;
      case Stage.home:
        page = HomeShell(onReset: () async {
          await app.reset();
          if (mounted) setState(() => stage = Stage.onboarding);
        });
        break;
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: KeyedSubtree(key: ValueKey(stage == Stage.entering ? Stage.boot : stage), child: page),
    );
  }
}

// =====================================================================
//  วิดเจ็ตช่วยเหลือ: โหลดดิ้ง / พื้นหลังขยับ / ลอยขึ้นลง / ตัวละครพิกเซล
// =====================================================================
class LoadingView extends StatefulWidget {
  const LoadingView({super.key});
  @override
  State<LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<LoadingView> with SingleTickerProviderStateMixin {
  late final AnimationController c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
        ..repeat(reverse: true);

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: cream,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ScaleTransition(
              scale: Tween(begin: 0.9, end: 1.08)
                  .animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)),
              child: img('loading',
                  w: 220,
                  fallback: const Text('Loading', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: orangeDark))),
            ),
            const SizedBox(height: 18),
            const SizedBox(
                width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3, color: orange)),
          ]),
        ),
      );
}

class MovingBg extends StatefulWidget {
  const MovingBg({super.key});
  @override
  State<MovingBg> createState() => _MovingBgState();
}

class _MovingBgState extends State<MovingBg> with SingleTickerProviderStateMixin {
  late final AnimationController c =
      AnimationController(vsync: this, duration: const Duration(seconds: 14))
        ..repeat(reverse: true);

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRect(
        child: AnimatedBuilder(
          animation: c,
          builder: (context, _) {
            final t = Curves.easeInOut.transform(c.value);
            return Transform.translate(
              offset: Offset((t - 0.5) * 50, (0.5 - t) * 40),
              child: Transform.scale(
                scale: 1.25,
                child: SizedBox.expand(
                  child: img('bg1',
                      fit: BoxFit.cover,
                      fallback: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFFFE3C2), Color(0xFFE4F6EA)],
                          ),
                        ),
                      )),
                ),
              ),
            );
          },
        ),
      );
}

class Floaty extends StatefulWidget {
  final Widget child;
  final double amp;
  final int ms;
  const Floaty({super.key, required this.child, this.amp = 8, this.ms = 1600});
  @override
  State<Floaty> createState() => _FloatyState();
}

class _FloatyState extends State<Floaty> with SingleTickerProviderStateMixin {
  late final AnimationController c =
      AnimationController(vsync: this, duration: Duration(milliseconds: widget.ms))
        ..repeat(reverse: true);

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: c,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, -widget.amp * Curves.easeInOut.transform(c.value)),
          child: child,
        ),
        child: widget.child,
      );
}

// ตัวละครพิกเซล 12x16 (วาดด้วยโค้ด ไม่ต้องใช้รูป)
const _male = [
  '....wwww....',
  '...wwwwww...',
  '...wwwwww...',
  '...hhhhhh...',
  '..hssssssh..',
  '..hsessesh..',
  '...ssmmss...',
  '.....ss.....',
  '..bbbbbbbb..',
  'sbbbbbbbbbbs',
  'sbbbbbbbbbbs',
  '.sbbbbbbbbs.',
  '...pppppp...',
  '..ppp..ppp..',
  '..ppp..ppp..',
  '.kkkk..kkkk.',
];

const _female = [
  '....wwww....',
  '...wwwwww...',
  '...wwwwww...',
  '..hhhhhhhh..',
  '.hhsssssshh.',
  '.hhsesseshh.',
  '.hhssmmsshh.',
  '.hh..ss..hh.',
  '.hddddddddh.',
  'sddddddddddd',
  'sdddddddddds',
  '.dddddddddd.',
  'dddddddddddd',
  '...ss..ss...',
  '...ss..ss...',
  '..kkk..kkk..',
];

class _PixelPainter extends CustomPainter {
  final String gender;
  _PixelPainter(this.gender);

  Color? _color(String ch) {
    final f = gender == 'f';
    switch (ch) {
      case 'w':
        return const Color(0xFFFFFFFF);
      case 'h':
        return f ? const Color(0xFF7A3E1D) : const Color(0xFF3B2A20);
      case 's':
        return const Color(0xFFF6C9A0);
      case 'e':
        return const Color(0xFF2A2A2A);
      case 'm':
        return const Color(0xFFD2574B);
      case 'b':
        return const Color(0xFF4DA3E0);
      case 'd':
        return const Color(0xFFF08BB0);
      case 'p':
        return const Color(0xFF3C4F7A);
      case 'k':
        return const Color(0xFF3B3A36);
    }
    return null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rows = gender == 'f' ? _female : _male;
    final px = size.width / 12;
    for (var r = 0; r < rows.length; r++) {
      for (var c = 0; c < 12; c++) {
        final col = _color(rows[r][c]);
        if (col == null) continue;
        canvas.drawRect(
          Rect.fromLTWH(c * px, r * px, px + 0.6, px + 0.6),
          Paint()
            ..color = col
            ..isAntiAlias = false,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PixelPainter old) => old.gender != gender;
}

class PixelChar extends StatelessWidget {
  final String gender;
  final double width;
  final bool bounce;
  final double amp;
  const PixelChar({super.key, required this.gender, this.width = 60, this.bounce = false, this.amp = 6});

  @override
  Widget build(BuildContext context) {
    final paint = CustomPaint(size: Size(width, width * 16 / 12), painter: _PixelPainter(gender));
    return bounce ? Floaty(amp: amp, ms: 450, child: paint) : paint;
  }
}

class UserAvatar extends StatelessWidget {
  final double r;
  const UserAvatar({super.key, this.r = 20});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: app,
        builder: (context, _) => CircleAvatar(
          radius: r,
          backgroundColor: app.gender == 'f' ? const Color(0xFFFFE0EC) : sky,
          child: ClipOval(
            child: SizedBox(
              width: r * 2,
              height: r * 2,
              child: app.avatar != null
                  ? Image.memory(app.avatar!, fit: BoxFit.cover, width: r * 2, height: r * 2)
                  : Padding(
                      padding: EdgeInsets.all(r * 0.18),
                      child: FittedBox(child: PixelChar(gender: app.gender, width: 60)),
                    ),
            ),
          ),
        ),
      );
}

Future<Uint8List?> pickPhoto(BuildContext context, ImageSource src, {double max = 1024}) async {
  try {
    final x = await ImagePicker()
        .pickImage(source: src, maxWidth: max, maxHeight: max, imageQuality: 80);
    if (x == null) return null;
    return await x.readAsBytes();
  } catch (e) {
    if (context.mounted) {
      snack(context, 'เปิดกล้อง/แกลเลอรีไม่ได้ ลองอนุญาตสิทธิ์ในการตั้งค่าของมือถือนะ');
    }
    return null;
  }
}

Future<void> choosePhoto(BuildContext context) async {
  final src = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: cream,
    builder: (ctx) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          leading: const Icon(Icons.photo_camera),
          title: const Text('ถ่ายรูปด้วยกล้อง'),
          onTap: () => Navigator.pop(ctx, ImageSource.camera),
        ),
        ListTile(
          leading: const Icon(Icons.photo_library),
          title: const Text('เลือกจากแกลเลอรี'),
          onTap: () => Navigator.pop(ctx, ImageSource.gallery),
        ),
      ]),
    ),
  );
  if (src == null || !context.mounted) return;
  final b = await pickPhoto(context, src, max: 512);
  if (b != null) await app.setAvatar(b);
}

// =====================================================================
//  หน้าแรกเข้าแอป: ตรวจสอบข้อมูล
// =====================================================================
const _skills = ['ทำเก่งมากเลยค่ะ', 'ไม่เคยทำอาหารเลย', 'ก็พอทำได้อยู่นะคร้าบ'];
const _allergyExamples = ['กุ้ง', 'ถั่วลิสง', 'นมวัว', 'ไข่', 'อาหารทะเล', 'แป้งสาลี'];

class Onboarding extends StatefulWidget {
  final VoidCallback onDone;
  const Onboarding({super.key, required this.onDone});
  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  final _form = GlobalKey<FormState>();
  final nick = TextEditingController();
  final user = TextEditingController();
  final age = TextEditingController();
  final allergy = TextEditingController();
  String? gender;
  String? skill;
  bool showErr = false;

  @override
  void dispose() {
    nick.dispose();
    user.dispose();
    age.dispose();
    allergy.dispose();
    super.dispose();
  }

  InputDecoration deco(String label, {String? helper, IconData? icon}) => InputDecoration(
        labelText: label,
        helperText: helper,
        helperMaxLines: 2,
        helperStyle: const TextStyle(fontSize: 11, color: Color(0xFF6B675F)),
        prefixIcon: icon == null ? null : Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      );

  void addAllergy(String t) {
    if (t == 'ไม่มี') {
      allergy.text = 'ไม่มี';
    } else {
      final cur = allergy.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty && e != 'ไม่มี')
          .toList();
      cur.contains(t) ? cur.remove(t) : cur.add(t);
      allergy.text = cur.join(', ');
    }
    setState(() {});
  }

  Future<void> submit() async {
    final ok = _form.currentState!.validate();
    if (!ok || gender == null || skill == null) {
      setState(() => showErr = true);
      snack(context, 'กรอกข้อมูลให้ครบก่อนนะ ถึงจะไปต่อได้');
      return;
    }
    await app.saveProfile(
      nick: nick.text.trim(),
      username: user.text.trim(),
      gender: gender!,
      age: int.parse(age.text.trim()),
      allergy: allergy.text.trim(),
      skill: skill!,
    );
    widget.onDone();
  }

  Widget genderTile(String g, String label) {
    final sel = gender == g;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => gender = g),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: sel ? mint : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: sel ? mintDark : const Color(0xFFE8E2D6), width: 2),
          ),
          child: Column(children: [
            PixelChar(gender: g, width: 66, bounce: true, amp: sel ? 10 : 4),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: sel ? mintDark : ink)),
          ]),
        ),
      ),
    );
  }

  Widget skillTile(int i) {
    final label = _skills[i];
    final sel = skill == label;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => skill = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: sel ? const Color(0xFFFFE3C2) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: sel ? orangeDark : const Color(0xFFE8E2D6), width: 2),
          ),
          child: Row(children: [
            Icon(sel ? Icons.radio_button_checked : Icons.radio_button_off,
                color: sel ? orangeDark : Colors.grey),
            const SizedBox(width: 10),
            Expanded(child: Text('${i + 1}. $label', style: const TextStyle(fontSize: 15))),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(children: [
          const Positioned.fill(child: MovingBg()),
          const Positioned.fill(child: ColoredBox(color: Color(0x66FFF8EC))),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Form(
                key: _form,
                autovalidateMode:
                    showErr ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
                child: Column(children: [
                  Text('Good Meal', style: brand(56)),
                  Floaty(
                    amp: 10,
                    child: img('bear_naruk',
                        h: 170,
                        fallback: const Text('🐻', style: TextStyle(fontSize: 110))),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ยินดีต้อนรับเข้าสู่ Application Good Meal\nมาเป็นเชฟไปด้วยกันนะ',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: ink, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  card(
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('เลือกตัวละครของคุณ', style: h2),
                      const SizedBox(height: 10),
                      Row(children: [
                        genderTile('m', 'ชาย'),
                        const SizedBox(width: 12),
                        genderTile('f', 'หญิง'),
                      ]),
                      if (showErr && gender == null)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text('เลือกตัวละครก่อนนะ',
                              style: TextStyle(color: Color(0xFFB3261E), fontSize: 12)),
                        ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nick,
                        decoration: deco('ชื่อเล่น',
                            helper: 'ชื่อนี้จะแสดงในแอป เป็นชื่อสาธารณะที่คนอื่นเห็น',
                            icon: Icons.face),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'ใส่ชื่อเล่นก่อนนะ' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: user,
                        decoration: deco('Username',
                            helper: 'ตัวพิมพ์ใหญ่ ตัวพิมพ์เล็ก และตัวเลขได้ (3-20 ตัว) เช่น GoodChef99',
                            icon: Icons.alternate_email),
                        validator: (v) => RegExp(r'^[A-Za-z0-9]{3,20}$').hasMatch((v ?? '').trim())
                            ? null
                            : 'ใช้ได้เฉพาะ A-Z a-z 0-9 ยาว 3-20 ตัว',
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: age,
                        keyboardType: TextInputType.number,
                        decoration: deco('อายุ', icon: Icons.cake),
                        validator: (v) {
                          final n = int.tryParse((v ?? '').trim());
                          return (n == null || n < 5 || n > 99) ? 'ใส่อายุเป็นตัวเลข (5-99)' : null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: allergy,
                        decoration: deco('อาหารที่แพ้',
                            helper: 'ตัวอย่าง: กุ้ง, ถั่วลิสง, นมวัว (ถ้าไม่มี กดปุ่ม "ไม่มี" ด้านล่าง)',
                            icon: Icons.warning_amber_rounded),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'ใส่อาหารที่แพ้ (หรือกด "ไม่มี")' : null,
                      ),
                      const SizedBox(height: 8),
                      Wrap(spacing: 6, runSpacing: 0, children: [
                        for (final t in [..._allergyExamples, 'ไม่มี'])
                          ActionChip(
                            label: Text(t, style: const TextStyle(fontSize: 12)),
                            backgroundColor: t == 'ไม่มี' ? mint : const Color(0xFFFFF1DD),
                            side: BorderSide.none,
                            onPressed: () => addAllergy(t),
                          ),
                      ]),
                      const SizedBox(height: 16),
                      const Text('คุณทำอาหารเก่งแค่ไหน?', style: h2),
                      const SizedBox(height: 8),
                      for (var i = 0; i < _skills.length; i++) skillTile(i),
                      if (showErr && skill == null)
                        const Text('เลือกระดับฝีมือก่อนนะ',
                            style: TextStyle(color: Color(0xFFB3261E), fontSize: 12)),
                    ]),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: orange,
                      foregroundColor: const Color(0xFF3B2410),
                      minimumSize: const Size.fromHeight(54),
                      textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    child: const Text('เริ่มต้นใช้แอปกัน'),
                  ),
                ]),
              ),
            ),
          ),
        ]),
      );
}

// =====================================================================
//  หน้าใส่รูปโปรไฟล์
// =====================================================================
class PhotoScreen extends StatelessWidget {
  final VoidCallback onDone;
  const PhotoScreen({super.key, required this.onDone});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(children: [
          const Positioned.fill(child: MovingBg()),
          const Positioned.fill(child: ColoredBox(color: Color(0x88FFF8EC))),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AnimatedBuilder(
                  animation: app,
                  builder: (context, _) => Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('Good Meal', style: brand(48)),
                    const SizedBox(height: 10),
                    const Text('ใส่รูปโปรไฟล์ของคุณ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: ink)),
                    const SizedBox(height: 4),
                    Text('สวัสดี ${app.nick}! รูปนี้จะแสดงมุมขวาบนของแอป', style: sub),
                    const SizedBox(height: 22),
                    GestureDetector(
                      onTap: () => choosePhoto(context),
                      child: Stack(alignment: Alignment.bottomRight, children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const UserAvatar(r: 82),
                        ),
                        const CircleAvatar(
                          radius: 22,
                          backgroundColor: orange,
                          child: Icon(Icons.add_a_photo, color: Color(0xFF3B2410)),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () => choosePhoto(context),
                      icon: const Icon(Icons.photo_camera),
                      label: const Text('ถ่ายรูป / เลือกรูป'),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: onDone,
                      style: FilledButton.styleFrom(
                        backgroundColor: orange,
                        foregroundColor: const Color(0xFF3B2410),
                        minimumSize: const Size.fromHeight(52),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      child: Text(app.avatar == null ? 'ข้ามไปก่อน (ใช้ตัวละครแทน)' : 'ไปต่อเลย'),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ]),
      );
}

// =====================================================================
//  โครงหลัก + แถบเมนูล่าง
// =====================================================================
Widget navIcon(String asset, IconData fallback) =>
    SizedBox(width: 28, height: 28, child: img(asset, w: 28, h: 28, fallback: Icon(fallback)));

class HomeShell extends StatefulWidget {
  final VoidCallback onReset;
  const HomeShell({super.key, required this.onReset});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int tab = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(index: tab, children: [
          FeedPage(onProfile: () => setState(() => tab = 3)),
          const FridgePage(),
          const CameraPage(),
          ProfilePage(onReset: widget.onReset),
        ]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (i) => setState(() => tab = i),
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFFFE3C2),
          destinations: [
            NavigationDestination(icon: navIcon('home', Icons.home_outlined), label: 'หน้าแรก'),
            NavigationDestination(icon: navIcon('fridge', Icons.kitchen_outlined), label: 'ตู้เย็น'),
            const NavigationDestination(
                icon: Icon(Icons.photo_camera_outlined),
                selectedIcon: Icon(Icons.photo_camera),
                label: 'ถ่ายอาหาร'),
            const NavigationDestination(
                icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'โปรไฟล์'),
          ],
        ),
      );
}

// =====================================================================
//  หน้า 1: หน้าแรก (ฟีดเมนูแนะนำจากเพื่อน ๆ + ค้นหาสูตร)
// =====================================================================
class Post {
  final int id, minsAgo, likes, comments;
  final String nick, user, text, emoji;
  final Color color;
  const Post(this.id, this.nick, this.user, this.text, this.emoji, this.minsAgo, this.likes,
      this.comments, this.color);
}

const posts = [
  Post(1, 'Noi', 'noi_cooks', 'ผัดกะเพราหมูสับไข่ดาว วันนี้เผ็ดสะใจ! ใครมีเคล็ดลับให้ใบกะเพราหอมๆ บ้าง', '🍳', 12, 24, 3,
      Color(0xFFBFE8CF)),
  Post(2, 'Mint', 'mint99', 'ลองทำต้มยำกุ้งครั้งแรก น้ำใสมาก ภูมิใจสุดๆ เลยค่ะ', '🍲', 45, 58, 9, Color(0xFFFFE3C2)),
  Post(3, 'Ploy', 'ploy_eats', 'ข้าวผัดไข่ฝีมือเชฟฝึกหัด เคล็ดลับคือไฟแรงๆ ผัดเร็วๆ', '🍚', 120, 17, 2, Color(0xFFDCEEFB)),
  Post(4, 'Tee', 'teekitchen', 'ไข่เจียวฟูๆ ตีไข่ให้เยอะๆ น้ำมันต้องร้อนจัดนะ', '🥚', 300, 41, 6, Color(0xFFFFF1DD)),
  Post(5, 'Aom', 'aom_baan', 'ผัดไทยกุ้งสด ทำเองได้ไม่ต้องรอที่ร้าน อร่อยกว่าเยอะ', '🍜', 600, 73, 12, Color(0xFFE4F6EA)),
];

class FeedPage extends StatefulWidget {
  final VoidCallback onProfile;
  const FeedPage({super.key, required this.onProfile});
  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final Map<int, List<String>> comments = {};
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void openSearch(String q) {
    if (q.trim().isEmpty) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => SearchPage(query: q.trim())));
  }

  void openComments(Post p) {
    final c = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cream,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setM) {
        final list = comments[p.id] ?? [];
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('คอมเมนต์', style: h2),
            const SizedBox(height: 8),
            if (list.isEmpty) const Text('ยังไม่มีคอมเมนต์ เป็นคนแรกเลย!', style: sub),
            for (final t in list)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Text.rich(TextSpan(children: [
                  TextSpan(text: '${app.nick}  ', style: const TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: t),
                ])),
              ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: c,
                  decoration: InputDecoration(
                    hintText: 'เขียนคอมเมนต์...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: orangeDark),
                onPressed: () {
                  final t = c.text.trim();
                  if (t.isEmpty) return;
                  setState(() => (comments[p.id] ??= []).add(t));
                  setM(() {});
                  c.clear();
                },
              ),
            ]),
          ]),
        );
      }),
    );
  }

  Widget act(IconData i, String t, Color c, VoidCallback f) => InkWell(
        onTap: f,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(children: [
            Icon(i, size: 20, color: c),
            const SizedBox(width: 4),
            Text(t, style: TextStyle(fontSize: 13, color: c)),
          ]),
        ),
      );

  Widget tile(Post p) {
    final liked = app.liked.contains('${p.id}');
    final saved = app.saved.contains('${p.id}');
    final cm = comments[p.id] ?? [];
    final ms = DateTime.now().millisecondsSinceEpoch - p.minsAgo * 60000;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: p.color,
          child: Text(p.nick[0], style: const TextStyle(fontWeight: FontWeight.w700, color: ink)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(p.nick, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(width: 6),
              Flexible(
                child: Text('@${p.user} · ${ago(ms)}', style: sub, overflow: TextOverflow.ellipsis),
              ),
            ]),
            const SizedBox(height: 4),
            Text(p.text, style: const TextStyle(fontSize: 15, height: 1.4)),
            const SizedBox(height: 10),
            Container(
              height: 220,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(colors: [p.color, const Color(0xFFFFF1DD)]),
              ),
              child: Text(p.emoji, style: const TextStyle(fontSize: 84)), // TODO: ใส่รูปอาหารจริง
            ),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              act(Icons.chat_bubble_outline, '${p.comments + cm.length}', ink, () => openComments(p)),
              act(liked ? Icons.favorite : Icons.favorite_border, '${p.likes + (liked ? 1 : 0)}',
                  liked ? Colors.red : ink, () => app.toggleLike(p.id)),
              act(saved ? Icons.bookmark : Icons.bookmark_border, saved ? 'บันทึกแล้ว' : 'บันทึก',
                  saved ? orangeDark : ink, () => app.toggleSave(p.id)),
            ]),
          ]),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: app,
        builder: (context, _) => Scaffold(
          appBar: AppBar(
            backgroundColor: cream,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: false,
            title: Text('Good Meal', style: brand(38)),
            actions: [
              IconButton(
                icon: Badge(
                  isLabelVisible: app.unread > 0,
                  label: Text('${app.unread}'),
                  child: const Icon(Icons.notifications_none, size: 28),
                ),
                onPressed: () =>
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const NoticePage())),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 14, left: 4),
                child: GestureDetector(onTap: widget.onProfile, child: const UserAvatar(r: 18)),
              ),
            ],
          ),
          body: ListView(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: search,
                textInputAction: TextInputAction.search,
                onSubmitted: openSearch,
                decoration: InputDecoration(
                  hintText: 'ค้นหาสูตรอาหาร เช่น กะเพรา, ต้มยำ, ไข่',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_forward), onPressed: () => openSearch(search.text)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Text('เมนูแนะนำจากเพื่อนๆ', style: h2),
            ),
            for (final p in posts) ...[
              tile(p),
              const Divider(height: 1, color: Color(0xFFE8E2D6)),
            ],
            const SizedBox(height: 16),
          ]),
        ),
      );
}

// ---------- ค้นหา + รายละเอียดสูตร ----------
class SearchPage extends StatelessWidget {
  final String query;
  const SearchPage({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    final res = recipes.where((r) => r.name.contains(query) || r.ing.any((i) => i.contains(query))).toList();
    return Scaffold(
      appBar: AppBar(backgroundColor: cream, title: Text('ผลค้นหา: $query')),
      body: res.isEmpty
          ? const Center(child: Text('ยังไม่เจอสูตรนี้ ลองคำอื่นดูนะ', style: sub))
          : ListView(padding: const EdgeInsets.all(16), children: [
              for (final r in res) recipeTile(context, r),
            ]),
    );
  }
}

Widget recipeTile(BuildContext context, Recipe r, {List<String> missing = const []}) {
  final hits = allergenHits(r);
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => showRecipe(context, r),
      child: card(Row(children: [
        Text(r.emoji, style: const TextStyle(fontSize: 40)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.name, style: h2),
            const SizedBox(height: 4),
            Text('≈ ${r.kcal} kcal', style: sub),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 4, children: [
              if (missing.isEmpty)
                chip('มีวัตถุดิบครบ ✓', mint, mintDark)
              else
                chip('ขาด: ${missing.join(', ')}', const Color(0xFFFFE3C2), orangeDark),
              if (hits.isNotEmpty) chip('⚠ มี ${hits.join(', ')} (คุณแพ้)', const Color(0xFFFDE0DD), const Color(0xFFB3261E)),
            ]),
          ]),
        ),
      ])),
    ),
  );
}

void showRecipe(BuildContext context, Recipe r) {
  final hits = allergenHits(r);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: cream,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Text(r.emoji, style: const TextStyle(fontSize: 64))),
          const SizedBox(height: 6),
          Center(child: Text(r.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: ink))),
          Center(child: Text('≈ ${r.kcal} kcal ต่อจาน (โดยประมาณ)', style: sub)),
          if (hits.isNotEmpty) ...[
            const SizedBox(height: 10),
            card(Text('⚠ สูตรนี้มี ${hits.join(', ')} ซึ่งตรงกับอาหารที่คุณแพ้',
                style: const TextStyle(color: Color(0xFFB3261E), fontWeight: FontWeight.w600)),
                color: const Color(0xFFFDE0DD)),
          ],
          const SizedBox(height: 14),
          const Text('วัตถุดิบ', style: h2),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: [for (final i in r.ing) chip(i, mint, mintDark)]),
          const SizedBox(height: 14),
          const Text('วิธีทำ', style: h2),
          const SizedBox(height: 6),
          for (var i = 0; i < r.steps.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text('${i + 1}. ${r.steps[i]}', style: const TextStyle(fontSize: 15, height: 1.4)),
            ),
        ]),
      ),
    ),
  );
}

// ---------- การแจ้งเตือน ----------
class NoticePage extends StatefulWidget {
  const NoticePage({super.key});
  @override
  State<NoticePage> createState() => _NoticePageState();
}

class _NoticePageState extends State<NoticePage> {
  late final List<bool> wasUnread = app.notices.map((n) => !n.read).toList();

  @override
  void initState() {
    super.initState();
    app.markRead();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(backgroundColor: cream, title: const Text('การแจ้งเตือน')),
        body: app.notices.isEmpty
            ? const Center(child: Text('ยังไม่มีการแจ้งเตือน', style: sub))
            : ListView(padding: const EdgeInsets.all(16), children: [
                for (var i = 0; i < app.notices.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: card(
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(app.notices[i].title, style: h2),
                        const SizedBox(height: 4),
                        Text(app.notices[i].body),
                        const SizedBox(height: 4),
                        Text(ago(app.notices[i].time), style: sub),
                      ]),
                      color: i < wasUnread.length && wasUnread[i] ? const Color(0xFFFFF1DD) : Colors.white,
                    ),
                  ),
              ]),
      );
}

// =====================================================================
//  หน้า 2: ตู้เย็น
// =====================================================================
class _Match {
  final Recipe r;
  final List<String> miss;
  _Match(this.r, this.miss);
}

class FridgePage extends StatefulWidget {
  const FridgePage({super.key});
  @override
  State<FridgePage> createState() => _FridgePageState();
}

class _FridgePageState extends State<FridgePage> {
  final Set<String> sel = {};
  bool ran = false;
  List<_Match> results = [];

  void run() {
    final out = <_Match>[];
    for (final r in recipes) {
      final have = r.ing.where(sel.contains).length;
      if (have == 0 || have / r.ing.length < 0.5) continue;
      out.add(_Match(r, r.ing.where((i) => !sel.contains(i)).toList()));
    }
    out.sort((a, b) => a.miss.length.compareTo(b.miss.length));
    setState(() {
      results = out;
      ran = true;
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: app,
        builder: (context, _) => Scaffold(
          appBar: AppBar(
              backgroundColor: cream,
              title: const Text('ตู้เย็นของฉัน', style: TextStyle(fontWeight: FontWeight.w700))),
          body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
            card(
              Center(
                child: Floaty(
                  amp: 6,
                  child: img('fridgewithrecip',
                      h: 210, fallback: const Text('🧊', style: TextStyle(fontSize: 110))),
                ),
              ),
              color: mint,
            ),
            const SizedBox(height: 16),
            const Text('เลือกวัตถุดิบที่มีในตู้เย็น', style: h2),
            const Text('แตะเพื่อเลือกได้หลายอย่าง', style: sub),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 2, children: [
              for (final i in allIngredients)
                FilterChip(
                  label: Text(i),
                  selected: sel.contains(i),
                  selectedColor: mint,
                  checkmarkColor: mintDark,
                  backgroundColor: Colors.white,
                  side: BorderSide.none,
                  onSelected: (v) => setState(() {
                    v ? sel.add(i) : sel.remove(i);
                    ran = false;
                  }),
                ),
            ]),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: sel.isEmpty ? null : run,
              icon: const Icon(Icons.restaurant_menu),
              label: Text(sel.isEmpty ? 'เลือกวัตถุดิบก่อนนะ' : 'รันอาหาร (${sel.length} อย่าง)'),
              style: FilledButton.styleFrom(
                backgroundColor: orange,
                foregroundColor: const Color(0xFF3B2410),
                minimumSize: const Size.fromHeight(52),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            if (ran) ...[
              const SizedBox(height: 16),
              if (results.isEmpty)
                const Center(child: Text('ยังไม่เจอเมนูที่ตรง ลองเพิ่มวัตถุดิบดูนะ', style: sub))
              else ...[
                Text('เมนูที่ทำได้ ${results.length} เมนู', style: h2),
                const SizedBox(height: 8),
                for (final m in results) recipeTile(context, m.r, missing: m.miss),
              ],
            ],
          ]),
        ),
      );
}

// =====================================================================
//  หน้า 3: ถ่ายรูปอาหาร
// =====================================================================
void showLevelUp(BuildContext context) {
  showDialog(
    context: context,
    builder: (dctx) => AlertDialog(
      backgroundColor: cream,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        PixelChar(gender: app.gender, width: 84, bounce: true, amp: 12),
        const SizedBox(height: 12),
        const Text('อัพเลเวลเชฟของคุณ!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: orangeDark)),
        const SizedBox(height: 6),
        Text('เลเวล ${app.level} · ${app.rank}', style: h2),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('เยี่ยมเลย!'))],
    ),
  );
}

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});
  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  Uint8List? shot;

  Future<void> take() async {
    final b = await pickPhoto(context, ImageSource.camera);
    if (b != null) setState(() => shot = b);
  }

  Future<void> send() async {
    await app.addSubmission();
    setState(() => shot = null);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('ส่งจานของคุณแล้ว! 🍽️'),
        content: const Text(
            'ระบบยังไม่ตรวจอัตโนมัติ ผู้พัฒนาจะเป็นคนตรวจให้เอง\nตรวจเสร็จแล้วจะแจ้งเตือนพร้อมคอมเมนต์ และเลเวลเชฟของคุณจะเพิ่มขึ้น'),
        actions: [TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('ตกลง'))],
      ),
    );
  }

  Future<void> fakeApprove(Submission s) async {
    await app.approve(s, 'จานสวยมาก! น่ากินสุดๆ เลย 😋');
    if (mounted) showLevelUp(context);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: app,
        builder: (context, _) => Scaffold(
          appBar: AppBar(
              backgroundColor: cream,
              title: const Text('ถ่ายรูปอาหาร', style: TextStyle(fontWeight: FontWeight.w700))),
          body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
            card(Column(children: [
              Container(
                height: 280,
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1DD),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: shot == null
                    ? const Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Text('🍽️', style: TextStyle(fontSize: 64)),
                          SizedBox(height: 6),
                          Text('ถ่ายรูปจานที่คุณทำเอง\nเพื่อรับ 1 XP ต่อ 1 จาน', textAlign: TextAlign.center, style: sub),
                        ]),
                      )
                    : Image.memory(shot!, fit: BoxFit.cover),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: take,
                icon: const Icon(Icons.photo_camera),
                label: Text(shot == null ? 'ถ่ายรูปอาหาร' : 'ถ่ายใหม่'),
                style: FilledButton.styleFrom(
                  backgroundColor: orange,
                  foregroundColor: const Color(0xFF3B2410),
                  minimumSize: const Size.fromHeight(50),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              if (shot != null) ...[
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: send,
                  icon: const Icon(Icons.send),
                  label: const Text('ส่งให้ผู้พัฒนาตรวจ'),
                  style: FilledButton.styleFrom(
                    backgroundColor: mintDark,
                    minimumSize: const Size.fromHeight(50),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ])),
            const SizedBox(height: 16),
            const Text('จานที่ส่งตรวจ', style: h2),
            const SizedBox(height: 8),
            if (app.subs.isEmpty) const Text('ยังไม่มีจานที่ส่ง', style: sub),
            for (final s in app.subs)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: card(Row(children: [
                  Text(s.status == 'approved' ? '✅' : '⏳', style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s.status == 'approved' ? 'ตรวจแล้ว +1 XP' : 'รอผู้พัฒนาตรวจ',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(s.status == 'approved' && s.comment.isNotEmpty ? s.comment : ago(s.time), style: sub),
                    ]),
                  ),
                  if (kDevMode && s.status == 'pending')
                    TextButton(onPressed: () => fakeApprove(s), child: const Text('จำลองตรวจ')),
                ])),
              ),
            if (kDevMode)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('โหมดทดสอบ: ปุ่ม "จำลองตรวจ" ใช้ลองดูตอนผู้พัฒนาตรวจจาน (ต่อ backend จริงภายหลัง)', style: sub),
              ),
          ]),
        ),
      );
}

// =====================================================================
//  หน้า 4: โปรไฟล์ (สไตล์ทวิตเตอร์) + เลเวลเชฟ
// =====================================================================
class ProfilePage extends StatelessWidget {
  final VoidCallback onReset;
  const ProfilePage({super.key, required this.onReset});

  Widget node(bool reached, IconData icon, String title, String range) => Expanded(
        child: Column(children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: reached ? orange : const Color(0xFFEDE8DD),
            child: Icon(icon, color: ink),
          ),
          const SizedBox(height: 4),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          Text(range, style: sub),
        ]),
      );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: app,
        builder: (context, _) {
          final lv = app.level;
          final String goal;
          if (lv >= kMaxLevel) {
            goal = 'เลเวลสูงสุดแล้ว 🎉';
          } else if (lv < 11) {
            goal = 'อีก ${10 * kDishesPerLevel - app.xp} จาน ถึงเลเวล 11 (เชฟระดับเซียน)';
          } else {
            goal = 'อีก ${app.maxXp - app.xp} จาน ถึงเลเวลสูงสุด $kMaxLevel';
          }
          return Scaffold(
            body: ListView(padding: EdgeInsets.zero, children: [
              Stack(clipBehavior: Clip.none, children: [
                Container(
                  height: 140,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Color(0xFFFFD9A8), Color(0xFFBFE8CF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                  ),
                ),
                Positioned(
                  left: 20,
                  bottom: -46,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: cream, shape: BoxShape.circle),
                    child: const UserAvatar(r: 44),
                  ),
                ),
              ]),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    onPressed: () => choosePhoto(context),
                    child: const Text('แก้ไขรูปโปรไฟล์'),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(app.nick, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: ink)),
                  Text('@${app.username}', style: const TextStyle(fontSize: 14, color: Color(0xFF6B675F))),
                  const SizedBox(height: 10),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    chip('Lv.$lv ${app.rank}', const Color(0xFFFFE3C2), orangeDark),
                    chip('อายุ ${app.age} ปี', sky, skyDark),
                    chip(app.skill, mint, mintDark),
                    chip('แพ้: ${app.allergy.isEmpty ? '-' : app.allergy}', const Color(0xFFFDE0DD), const Color(0xFFB3261E)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Text('${app.xp}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    const Text(' จานที่ทำสำเร็จ', style: sub),
                    const SizedBox(width: 16),
                    Text('${app.saved.length}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    const Text(' โพสต์ที่บันทึก', style: sub),
                  ]),
                ]),
              ),
              const Padding(padding: EdgeInsets.only(top: 14), child: Divider(height: 1, color: Color(0xFFE8E2D6))),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('เลเวลเชฟ', style: h2),
                      Text('Lv.$lv / $kMaxLevel', style: const TextStyle(fontWeight: FontWeight.w800, color: orangeDark)),
                    ]),
                    const SizedBox(height: 12),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      node(lv >= 1, Icons.restaurant, 'เชฟฝึกหัด', 'Lv.1 - 10'),
                      node(lv >= 11, Icons.workspace_premium, 'เชฟระดับเซียน', 'Lv.11 - 20'),
                    ]),
                    const SizedBox(height: 14),
                    Text(goal, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: (app.xp / app.maxXp).clamp(0.0, 1.0),
                        minHeight: 12,
                        color: const Color(0xFFF29A4A),
                        backgroundColor: const Color(0xFFFFE3C2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('1 จานที่ทำสำเร็จ = 1 XP', style: sub),
                  ])),
                  if (kDevMode) ...[
                    const SizedBox(height: 14),
                    TextButton.icon(
                      onPressed: onReset,
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('รีเซ็ตข้อมูลทั้งหมด (โหมดทดสอบ)'),
                    ),
                  ],
                ]),
              ),
            ]),
          );
        },
      );
}