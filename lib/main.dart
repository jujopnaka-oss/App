import 'package:flutter/material.dart';

void main() => runApp(const ChefMateApp());

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

class ChefMateApp extends StatelessWidget {
  const ChefMateApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'ChefMate Hub',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: orange,
          scaffoldBackgroundColor: cream,
        ),
        home: const Shell(),
      );
}

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

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;
  int water = 0;
  bool showAi = false;
  String? reaction;
  final Map<String, bool> fridge = {
    'ไข่ไก่ (Eggs)': true,
    'มะเขือเทศ (Tomatoes)': true,
    'เนื้อสับ (Minced Beef)': true,
    'ใบกะเพรา (Basil)': false,
  };

  static const pad = EdgeInsets.fromLTRB(20, 16, 20, 20);

  Widget home() => ListView(padding: pad, children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'AI Suggest & Gemini',
            prefixIcon: const Icon(Icons.auto_awesome, color: Color(0xFFF29A4A)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 14),
        card(
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('เคลียร์ตู้เย็น', style: h2),
            const Text('เลือกวัตถุดิบที่มีอยู่ตอนนี้', style: sub),
            for (final e in fridge.entries)
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: mintDark,
                title: Text(e.key),
                value: e.value,
                onChanged: (v) => setState(() => fridge[e.key] = v ?? false),
              ),
          ]),
          color: mint,
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: () => setState(() => showAi = true), // TODO: call Gemini API
          icon: const Icon(Icons.auto_awesome),
          label: const Text('ประยุกต์สูตร (AI)'),
          style: FilledButton.styleFrom(
            backgroundColor: orange,
            foregroundColor: const Color(0xFF3B2410),
            minimumSize: const Size.fromHeight(52),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        if (showAi) ...[
          const SizedBox(height: 14),
          card(
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                chip('AI แนะนำ', const Color(0xFFFFE3C2), orangeDark),
                const Text('อาหารตามสั่ง', style: sub),
              ]),
              const SizedBox(height: 10),
              const Text('กะเพราเนื้อสับ (ปรับสูตรตามวัตถุดิบที่มี)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ink)),
              const SizedBox(height: 4),
              const Text('เนื้อสับ 150 g · ไข่ 1 ฟอง · มะเขือเทศ 1 ลูก', style: sub),
              const SizedBox(height: 12),
              const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('งบแคลอรี่มื้อนี้ 650 kcal',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text('สูตรนี้ ≈ 520 kcal',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: mintDark)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: const LinearProgressIndicator(
                    value: 0.8, minHeight: 12, color: Color(0xFF7BD3A0), backgroundColor: mint),
              ),
            ]),
          ),
        ],
      ]);

  Widget waterCard() => card(
        Row(children: [
          const Icon(Icons.local_drink, size: 44, color: Color(0xFF4DA3E0)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('น้ำดื่มวันนี้', style: sub),
              Text('$water / 8 แก้ว',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: skyDark)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                    value: water / 8, minHeight: 12, color: const Color(0xFF4DA3E0), backgroundColor: Colors.white),
              ),
            ]),
          ),
          const SizedBox(width: 12),
          Column(children: [
            Icon(Icons.eco, size: 28.0 + water * 3, color: const Color(0xFF7BD3A0)),
            const Text('ต้นไม้จำลอง', style: TextStyle(fontSize: 11, color: Color(0xFF6B675F))),
            TextButton.icon(
              onPressed: () => setState(() => water = water < 8 ? water + 1 : 8),
              icon: const Icon(Icons.water_drop, size: 16),
              label: const Text('รดน้ำ'),
            ),
          ]),
        ]),
        color: sky,
      );

  Widget reactBtn(String label, String emoji) => Expanded(
        child: OutlinedButton(
          onPressed: () => setState(() => reaction = label),
          style: OutlinedButton.styleFrom(
            backgroundColor: reaction == label ? const Color(0xFFFFE3C2) : const Color(0xFFFFF1DD),
            foregroundColor: ink,
            side: BorderSide.none,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          child: Text('$emoji $label',
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      );

  Widget post() => card(
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            CircleAvatar(backgroundColor: Color(0xFFBFE8CF), child: Text('N')),
            SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Noi', style: TextStyle(fontWeight: FontWeight.w700)),
              Text('2 ชม. ที่แล้ว', style: sub),
            ]),
          ]),
          const SizedBox(height: 10),
          Container(
            height: 170,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(colors: [Color(0xFFFFE3C2), Color(0xFFFFF1DD)]),
            ),
            child: const Text('🍳', style: TextStyle(fontSize: 64)), // TODO: real photo
          ),
          const SizedBox(height: 10),
          const Text('ผัดกะเพราเนื้อสับ', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(children: [
            reactBtn('น่ากินมาก', '😋'),
            const SizedBox(width: 8),
            reactBtn('ยังต้องเรียนรู้อีกเยอะ!', '😜'),
          ]),
        ]),
      );

  Widget community() => ListView(padding: pad, children: [post()]);

  Widget waterTab() => ListView(padding: pad, children: [
        const Text('น้ำดื่ม & ชุมชน', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        waterCard(),
        const SizedBox(height: 14),
        post(),
      ]);

  Widget node(Color bg, IconData icon, String label) => Expanded(
        child: Column(children: [
          CircleAvatar(backgroundColor: bg, child: Icon(icon, color: ink)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      );

  Widget podium(Color crown, double r, String name, String dishes) => Column(children: [
        Icon(Icons.workspace_premium, color: crown, size: 28),
        CircleAvatar(
          radius: r,
          backgroundColor: Colors.white,
          child: Text(name[0], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        ),
        Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
        Text(dishes, style: sub),
      ]);

  Widget profile() => ListView(padding: pad, children: [
        card(
          Row(children: [
            const CircleAvatar(
                radius: 38,
                backgroundColor: Colors.white,
                child: Text('T', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: mintDark))),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Tana', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Row(children: [
                chip('Level 5', const Color(0xFFDCEEFB), skyDark),
                const SizedBox(width: 6),
                chip('เชฟฝึกหัด', const Color(0xFFFFE3C2), orangeDark),
              ]),
            ]),
          ]),
          color: mint,
        ),
        const SizedBox(height: 14),
        card(
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('เส้นทางเชฟ', style: h2),
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              node(const Color(0xFFBFE8CF), Icons.check, 'เชฟมือใหม่'),
              node(orange, Icons.star, 'เชฟฝึกหัด'),
              node(const Color(0xFFEDE8DD), Icons.workspace_premium, 'มาสเตอร์เชฟระดับตำนาน'),
            ]),
            const SizedBox(height: 14),
            const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('อีก 7 จาน ปลดล็อกระดับถัดไป',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Text('12 / 19', style: sub),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: const LinearProgressIndicator(
                  value: 12 / 19, minHeight: 12, color: Color(0xFFF29A4A), backgroundColor: Color(0xFFFFE3C2)),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        card(
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('เชฟเด่นประจำสัปดาห์', style: h2),
            const Text('Weekly Top Chefs', style: sub),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, crossAxisAlignment: CrossAxisAlignment.end, children: [
              podium(const Color(0xFFAAB4BE), 28, 'Mint', '27 จาน'),
              podium(const Color(0xFFF2B705), 34, 'Noi', '31 จาน'),
              podium(const Color(0xFFC98A4B), 28, 'Ploy', '24 จาน'),
            ]),
          ]),
          color: const Color(0xFFFFF1DD),
        ),
      ]);

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      home(),
      community(),
      const Center(child: Text('สูตรอาหาร (เร็วๆ นี้)')),
      waterTab(),
      profile(),
    ];
    return Scaffold(
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFFFE3C2),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'หน้าแรก'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'ชุมชน'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'สูตร'),
          NavigationDestination(icon: Icon(Icons.water_drop_outlined), selectedIcon: Icon(Icons.water_drop), label: 'น้ำดื่ม'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'โปรไฟล์'),
        ],
      ),
    );
  }
}
