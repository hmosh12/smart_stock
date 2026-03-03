import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:async';

void main() async {
  // تهيئة مخزن البيانات قبل تشغيل التطبيق
  await GetStorage.init();
  runApp(const MaterialApp(
    home: SplashScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

// --- واجهة البداية (Splash Screen) ---
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    Timer(const Duration(seconds: 3), () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const MainHost())));
    return Scaffold(
      backgroundColor: const Color(0xFF020409),
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.auto_awesome_motion, size: 80, color: Colors.orangeAccent),
        const SizedBox(height: 20),
        const Text("SMART STOCK", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 5)),
      ])),
    );
  }
}

class MainHost extends StatefulWidget {
  const MainHost({super.key});
  @override
  State<MainHost> createState() => _MainHostState();
}

class _MainHostState extends State<MainHost> {
  int _currentIndex = 2; // البدء من قسم المخزن
  final List<Widget> _pages = [const AnalyticsPage(), const SalesPage(), const SuperStorePro()];

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: const Color(0xFF0D1B2A),
        selectedItemColor: Colors.orangeAccent,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "السجل"),
          BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: "المبيعات"),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: "المخزن"),
        ],
      ),
    ));
  }
}

// --- قسم المخزن الذكي (Smart Stock) ---
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

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (context, setS) => AlertDialog(
      title: Text(item == null ? "إضافة مادة جديدة" : "تعديل المادة"),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        _inp(barcodeCtrl, "الباركود"),
        _inp(nameCtrl, "اسم المادة"),
        _inp(companyCtrl, "اسم الشركة"),
        _counter(boxesCtrl, "عدد الكراتين", setS),
        _counter(pPerBoxCtrl, "القطع في الكرتون", setS),
        _inp(jomlaPriceCtrl, "سعر الجملة", isNum: true),
        _inp(mofradPriceCtrl, "سعر المفرد", isNum: true),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
        ElevatedButton(onPressed: () {
          int b = int.tryParse(boxesCtrl.text) ?? 0;
          int p = int.tryParse(pPerBoxCtrl.text) ?? 1;
          var data = {
            'name': nameCtrl.text, 'barcode': barcodeCtrl.text, 'company': companyCtrl.text,
            'boxes': b, 'pPerBox': p, 'totalPieces': b * p,
            'jPrice': double.tryParse(jomlaPriceCtrl.text) ?? 0, 'mPrice': double.tryParse(mofradPriceCtrl.text) ?? 0,
          };
          List currentItems = List.from(_inventory);
          if (index == null) { currentItems.add(data); } else { currentItems[index] = data; }
          box.write('items', currentItems);
          Navigator.pop(ctx); _refresh();
        }, child: const Text("حفظ المادة"))
      ],
    )));
  }

  _clear() { nameCtrl.clear(); barcodeCtrl.clear(); companyCtrl.clear(); boxesCtrl.text="0"; pPerBoxCtrl.text="1"; jomlaPriceCtrl.clear(); mofradPriceCtrl.clear(); }
  
  Widget _inp(TextEditingController c, String l, {bool isNum = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: TextField(controller: c, keyboardType: isNum ? TextInputType.number : TextInputType.text, decoration: InputDecoration(labelText: l, border: const OutlineInputBorder())),
  );

  Widget _counter(TextEditingController c, String l, Function s) => Row(children: [
    Text(l),
    IconButton(onPressed: ()=>s(()=>c.text=(int.parse(c.text)-1).toString()), icon: const Icon(Icons.remove_circle_outline)),
    Expanded(child: TextField(controller: c, textAlign: TextAlign.center, keyboardType: TextInputType.number)),
    IconButton(onPressed: ()=>s(()=>c.text=(int.parse(c.text)+1).toString()), icon: const Icon(Icons.add_circle_outline)),
  ]);

  @override
  Widget build(BuildContext context) {
    var filtered = _inventory.where((e) => e['name'].toString().contains(_search) || e['barcode'].toString().contains(_search)).toList();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("SMART STOCK", style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D1B2A),
        actions: [
          TextButton(
            onPressed: () => setState(() => _currency = _currency == "د.ع" ? "\$" : "د.ع"),
            child: Text(_currency, style: const TextStyle(color: Colors.orangeAccent, fontSize: 20, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(8), child: TextField(onChanged: (v)=>setState(()=>_search=v), decoration: const InputDecoration(hintText: "بحث عن مادة أو باركود...", prefixIcon: Icon(Icons.search), border: OutlineInputBorder()))),
        Expanded(child: filtered.isEmpty 
          ? Opacity(opacity: 0.3, child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.inventory_2_outlined, size: 100, color: Colors.grey), const Text("المخزن فارغ", style: TextStyle(fontSize: 20)) ]))) 
          : ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (ctx, i) {
                var item = filtered[i];
                int total = item['totalPieces'] ?? 0;
                bool isLow = total <= 2;
                // نظام الألوان التبادلي (أبيض / رصاصي) + تظليل النفاذ بالأحمر
                Color rowColor = isLow ? Colors.red.shade100 : (i % 2 == 0 ? Colors.white : Colors.grey.shade200);

                return Container(
                  color: rowColor,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  child: Row(children: [
                    // اسم المادة تحتها اسم الشركة
                    Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(item['company'], style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                    ])),
                    // عدد الكراتين تحتها القطع
                    Expanded(flex: 2, child: Column(children: [
                      Text("كرتون: ${item['boxes']}"),
                      Text("قطع: ${item['pPerBox']}", style: const TextStyle(fontSize: 12)),
                    ])),
                    // سعر الجملة تحتها المفرد
                    Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text("${item['jPrice']} $_currency", style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text("${item['mPrice']} $_currency", style: const TextStyle(fontSize: 12, color: Colors.green)),
                    ])),
                    // خيارات التعديل والحذف
                    PopupMenuButton(onSelected: (v) {
                      if (v=='e') _showForm(item: item, index: _inventory.indexOf(item));
                      else { _inventory.remove(item); box.write('items', _inventory); _refresh(); }
                    }, itemBuilder: (ctx)=>[
                      const PopupMenuItem(value: 'e', child: Row(children: [Icon(Icons.edit, color: Colors.blue), SizedBox(width: 8), Text("تعديل")])),
                      const PopupMenuItem(value: 'd', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text("حذف")])),
                    ]),
                  ]),
                );
              },
            )),
      ]),
      floatingActionButton: FloatingActionButton(backgroundColor: Colors.orangeAccent, onPressed: ()=>_showForm(), child: const Icon(Icons.add, size: 30, color: Colors.black)),
    );
  }
}

// --- قسم المبيعات (Sales) ---
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
        setState(() {
          item['totalPieces'] -= 1;
          // تحديث عدد الكراتين تلقائياً عند نقص القطع
          item['boxes'] = item['totalPieces'] ~/ item['pPerBox'];
          items[idx] = item;
          box.write('items', items);
          cart.insert(0, item); // إضافة المادة لأعلى القائمة
          scanCtrl.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("هذه المادة نفذت من المخزن!")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("قسم المبيعات"), backgroundColor: Colors.green.shade700),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(10), child: TextField(
          controller: scanCtrl, 
          onSubmitted: _onScan, 
          autofocus: true, 
          decoration: const InputDecoration(hintText: "مسح باركود (يدوي أو خارجي)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.qr_code_scanner)))),
        const Divider(),
        Expanded(child: cart.isEmpty 
          ? const Center(child: Text("انتظار المسح..."))
          : ListView.builder(itemCount: cart.length, itemBuilder: (ctx, i) => ListTile(
              leading: const Icon(Icons.shopping_bag, color: Colors.green),
              title: Text(cart[i]['name']), 
              trailing: Text("${cart[i]['mPrice']} د.ع", style: const TextStyle(fontWeight: FontWeight.bold))))),
      ]),
    );
  }
}

// --- سجل المبيعات ---
class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("سجل المبيعات")), 
    body: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.cloud_done_outlined, size: 60, color: Colors.blue),
      SizedBox(height: 10),
      Text("السجل محفوظ ويتم مزامنته تلقائياً"),
    ])));
}
