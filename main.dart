import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:async';

void main() async {
  await GetStorage.init();
  runApp(const MaterialApp(
    home: SplashScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

// --- واجهة النجوم والمحرك الذكي (Splash) ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    Timer(const Duration(seconds: 4), () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const MainHost())));
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020409), // أسود ملكي
      body: Stack(
        children: [
          // تأثير النجوم (خلفية)
          ...List.generate(20, (i) => Positionchild(
            top: (i * 50).toDouble(), left: (i * 20).toDouble(),
            child: Icon(Icons.star, color: Colors.white.withOpacity(0.1), size: 10),
          )),
          Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              ScaleTransition(
                scale: _animation,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.orangeAccent.withOpacity(0.3), blurRadius: 40, spreadRadius: 10)],
                  ),
                  child: const Icon(Icons.auto_awesome_motion, size: 100, color: Colors.orangeAccent),
                ),
              ),
              const SizedBox(height: 30),
              const Text("SMART", style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 10)),
              const Text("STOCK", style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.orangeAccent, letterSpacing: 10)),
              const SizedBox(height: 20),
              const CircularProgressIndicator(color: Colors.orangeAccent, strokeWidth: 2),
            ]),
          ),
        ],
      ),
    );
  }
}

class MainHost extends StatefulWidget {
  const MainHost({super.key});
  @override
  State<MainHost> createState() => _MainHostState();
}

class _MainHostState extends State<MainHost> {
  int _currentIndex = 2;
  final List<Widget> _pages = [const AnalyticsPage(), const SalesPage(), const SuperStorePro()];

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.orangeAccent.withOpacity(0.2), width: 0.5))),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: const Color(0xFF0D1B2A),
          selectedItemColor: Colors.orangeAccent,
          unselectedItemColor: Colors.white38,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          type: BottomNavigationBarType.fixed,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: "السجل"),
            BottomNavigationBarItem(icon: Icon(Icons.point_of_sale_rounded), label: "المبيعات"),
            BottomNavigationBarItem(icon: Icon(Icons.inventory_2_rounded), label: "المخزن"),
          ],
        ),
      ),
    ));
  }
}

// --- صفحة المخزن الرئيسة (التصميم المطور) ---
class SuperStorePro extends StatefulWidget {
  const SuperStorePro({super.key});
  @override
  State<SuperStorePro> createState() => _SuperStoreProState();
}

class _SuperStoreProState extends State<SuperStorePro> {
  final box = GetStorage();
  List _inventory = [];
  String _currency = "د.ع";
  String _search = "";
  final nameCtrl = TextEditingController(), barcodeCtrl = TextEditingController(), companyCtrl = TextEditingController();
  final boxesCtrl = TextEditingController(text: "0"), pPerBoxCtrl = TextEditingController(text: "1");
  final jomlaPriceCtrl = TextEditingController(), mofradPriceCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _refresh(); }
  _refresh() { setState(() => _inventory = box.read('items') ?? []); }

  void _showForm({Map? item, int? index}) {
    if (item != null) {
      nameCtrl.text = item['name']; barcodeCtrl.text = item['barcode']; companyCtrl.text = item['company'];
      boxesCtrl.text = item['boxes'].toString(); pPerBoxCtrl.text = item['pPerBox'].toString();
      jomlaPriceCtrl.text = item['jPrice'].toString(); mofradPriceCtrl.text = item['mPrice'].toString();
    } else { _clear(); }

    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (ctx) => Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 20, left: 20, right: 20),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
        const SizedBox(height: 20),
        Text(item == null ? "إضافة مادة للمخزن" : "تعديل البيانات", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        _inp(barcodeCtrl, "باركود المادة", icon: Icons.qr_code),
        _inp(nameCtrl, "اسم المنتج بالكامل", icon: Icons.shopping_basket),
        _inp(companyCtrl, "الشركة المصنعة", icon: Icons.business),
        const Divider(),
        Row(children: [
          Expanded(child: _inp(boxesCtrl, "الكراتين", isNum: true)),
          const SizedBox(width: 10),
          Expanded(child: _inp(pPerBoxCtrl, "القطع داخلها", isNum: true)),
        ]),
        Row(children: [
          Expanded(child: _inp(jomlaPriceCtrl, "سعر الجملة", isNum: true)),
          const SizedBox(width: 10),
          Expanded(child: _inp(mofradPriceCtrl, "سعر المفرد", isNum: true)),
        ]),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 55, child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D1B2A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
          onPressed: () {
            int b = int.tryParse(boxesCtrl.text) ?? 0;
            int p = int.tryParse(pPerBoxCtrl.text) ?? 1;
            var data = {
              'name': nameCtrl.text, 'barcode': barcodeCtrl.text, 'company': companyCtrl.text,
              'boxes': b, 'pPerBox': p, 'totalPieces': b * p,
              'jPrice': double.tryParse(jomlaPriceCtrl.text) ?? 0, 'mPrice': double.tryParse(mofradPriceCtrl.text) ?? 0,
            };
            List current = List.from(_inventory);
            if (index == null) current.add(data); else current[index] = data;
            box.write('items', current); Navigator.pop(ctx); _refresh();
          },
          child: const Text("حـفـظ الـمـادة", style: TextStyle(color: Colors.orangeAccent, fontSize: 18, fontWeight: FontWeight.bold)),
        )),
        const SizedBox(height: 20),
      ])),
    ));
  }

  _clear() { nameCtrl.clear(); barcodeCtrl.clear(); companyCtrl.clear(); boxesCtrl.text="0"; pPerBoxCtrl.text="1"; jomlaPriceCtrl.clear(); mofradPriceCtrl.clear(); }
  Widget _inp(TextEditingController c, String l, {bool isNum = false, IconData? icon}) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: TextField(controller: c, keyboardType: isNum ? TextInputType.number : TextInputType.text, decoration: InputDecoration(labelText: l, prefixIcon: Icon(icon, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))));

  @override
  Widget build(BuildContext context) {
    var filtered = _inventory.where((e) => e['name'].contains(_search) || e['barcode'].contains(_search)).toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text("SMART STOCK", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 24, color: Colors.orangeAccent)),
        centerTitle: true,
        backgroundColor: const Color(0xFF0D1B2A),
        elevation: 10,
        actions: [IconButton(onPressed: () => setState(() => _currency = _currency == "د.ع" ? "\$" : "د.ع"), icon: CircleAvatar(backgroundColor: Colors.orangeAccent, child: Text(_currency, style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold))))],
      ),
      body: Column(children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: const BoxDecoration(color: Color(0xFF0D1B2A), borderRadius: BorderRadius.vertical(bottom: Radius.circular(25))),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(hintText: "ابحث عن مادة أو امسح باركود...", hintStyle: const TextStyle(color: Colors.white38), prefixIcon: const Icon(Icons.search, color: Colors.orangeAccent), filled: true, fillColor: Colors.white.withOpacity(0.1), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
          ),
        ),
        Expanded(child: filtered.isEmpty 
          ? Center(child: Opacity(opacity: 0.2, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.inventory_2_rounded, size: 120), const Text("المخزن فارغ حالياً", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)) ]))) 
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: filtered.length,
              itemBuilder: (ctx, i) {
                bool low = (filtered[i]['totalPieces'] ?? 0) <= 2;
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  color: low ? Colors.red[50] : (i % 2 == 0 ? Colors.white : Colors.grey[50]),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: low ? Colors.red : Colors.transparent, width: 1)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(filtered[i]['name'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0D1B2A))),
                        Text(filtered[i]['company'], style: const TextStyle(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.w600)),
                      ])),
                      Expanded(flex: 2, child: Column(children: [
                        Text("كرتون: ${filtered[i]['boxes']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text("قطع: ${filtered[i]['pPerBox']}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ])),
                      Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text("${filtered[i]['jPrice']} $_currency", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        Text("${filtered[i]['mPrice']} $_currency", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.green)),
                      ])),
                      const SizedBox(width: 5),
                      PopupMenuButton(
                        icon: const Icon(Icons.more_vert, color: Color(0xFF0D1B2A)),
                        onSelected: (v) { if (v == 'e') _showForm(item: filtered[i], index: i); else { _inventory.removeAt(i); box.write('items', _inventory); _refresh(); } },
                        itemBuilder: (ctx) => [const PopupMenuItem(value: 'e', child: Text("تعديل")), const PopupMenuItem(value: 'd', child: Text("حذف"))],
                      ),
                    ]),
                  ),
                );
              },
            )),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0D1B2A),
        onPressed: () => _showForm(),
        label: const Text("إضافة مادة", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.orangeAccent),
      ),
    );
  }
}

// --- قسم المبيعات المتطور ---
class SalesPage extends StatefulWidget {
  const SalesPage({super.key});
  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final scanCtrl = TextEditingController();
  final box = GetStorage();
  List cart = [];
  
  _onScan(String code) {
    List items = box.read('items') ?? [];
    int idx = items.indexWhere((e) => e['barcode'].toString() == code);
    if (idx != -1) {
      var item = items[idx];
      if (item['totalPieces'] > 0) {
        setState(() { item['totalPieces'] -= 1; item['boxes'] = item['totalPieces'] ~/ item['pPerBox']; items[idx] = item; box.write('items', items); cart.insert(0, item); scanCtrl.clear(); });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("نظام المبيعات السريع", style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.green[800], centerTitle: true),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(15), child: TextField(controller: scanCtrl, onSubmitted: _onScan, autofocus: true, decoration: InputDecoration(hintText: "امسح الباركود للبيع المباشر...", prefixIcon: const Icon(Icons.qr_code_scanner, color: Colors.green), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))))),
        Expanded(child: cart.isEmpty ? const Center(child: Text("بانتظار عملية بيع...")) : ListView.builder(itemCount: cart.length, itemBuilder: (ctx, i) => Card(margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), child: ListTile(leading: const Icon(Icons.check_circle, color: Colors.green), title: Text(cart[i]['name'], style: const TextStyle(fontWeight: FontWeight.bold)), trailing: Text("${cart[i]['mPrice']} د.ع", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w900)))))),
      ]),
    );
  }
}

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("التقارير والسجل")), body: const Center(child: Icon(Icons.bar_chart_rounded, size: 100, color: Colors.grey)));
}

// كلاس مساعد لتحديد موقع النجوم
class Positionchild extends StatelessWidget {
  final double top, left; final Widget child;
  const Positionchild({super.key, required this.top, required this.left, required this.child});
  @override
  Widget build(BuildContext context) => Positioned(top: top, left: left, child: child);
}
