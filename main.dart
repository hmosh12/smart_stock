import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';

void main() => runApp(const MaterialApp(
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    ));

// --- محرك قاعدة البيانات ---
class DB {
  static Database? _db;
  static Future<Database> get instance async {
    if (_db != null) return _db!;
    _db = await openDatabase(
      join(await getDatabasesPath(), 'smart_falcon_pro.db'),
      onCreate: (db, version) async {
        await db.execute(
            "CREATE TABLE inventory(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, barcode TEXT, company TEXT, boxes INTEGER, pPerBox INTEGER, totalPieces INTEGER, jPrice REAL, mPrice REAL)");
        await db.execute(
            "CREATE TABLE sales(id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT, amount REAL, itemName TEXT)");
      },
      version: 1,
    );
    return _db!;
  }
}

// --- واجهة النجوم ---
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
  int _currentIndex = 2;
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

// --- صفحة المخزن الذكي ---
class SuperStorePro extends StatefulWidget {
  const SuperStorePro({super.key});
  @override
  State<SuperStorePro> createState() => _SuperStoreProState();
}

class _SuperStoreProState extends State<SuperStorePro> {
  List<Map<String, dynamic>> _inventory = [];
  String _currency = "د.ع";
  String _search = "";
  final nameCtrl = TextEditingController(), barcodeCtrl = TextEditingController(), companyCtrl = TextEditingController();
  final boxesCtrl = TextEditingController(text: "0"), pPerBoxCtrl = TextEditingController(text: "1");
  final jomlaPriceCtrl = TextEditingController(), mofradPriceCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _refresh(); }
  _refresh() async {
    final db = await DB.instance;
    final res = await db.query('inventory', orderBy: "id DESC");
    setState(() => _inventory = res);
  }

  void _showForm({Map<String, dynamic>? item}) {
    if (item != null) {
      nameCtrl.text = item['name']; barcodeCtrl.text = item['barcode']; companyCtrl.text = item['company'];
      boxesCtrl.text = item['boxes'].toString(); pPerBoxCtrl.text = item['pPerBox'].toString();
      jomlaPriceCtrl.text = item['jPrice'].toString(); mofradPriceCtrl.text = item['mPrice'].toString();
    } else { _clear(); }

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (context, setS) => AlertDialog(
      title: Text(item == null ? "إضافة مادة" : "تعديل"),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        _inp(barcodeCtrl, "الباركود"), _inp(nameCtrl, "اسم المادة"), _inp(companyCtrl, "اسم الشركة"),
        _counter(boxesCtrl, "عدد الكراتين", setS), _counter(pPerBoxCtrl, "القطع في الكرتون", setS),
        _inp(jomlaPriceCtrl, "سعر الجملة", isNum: true), _inp(mofradPriceCtrl, "سعر المفرد", isNum: true),
      ])),
      actions: [ElevatedButton(onPressed: () async {
        final db = await DB.instance;
        int b = int.tryParse(boxesCtrl.text) ?? 0;
        int p = int.tryParse(pPerBoxCtrl.text) ?? 1;
        var data = {
          'name': nameCtrl.text, 'barcode': barcodeCtrl.text, 'company': companyCtrl.text,
          'boxes': b, 'pPerBox': p, 'totalPieces': b * p,
          'jPrice': double.tryParse(jomlaPriceCtrl.text) ?? 0, 'mPrice': double.tryParse(mofradPriceCtrl.text) ?? 0,
        };
        item == null ? await db.insert('inventory', data) : await db.update('inventory', data, where: "id=?", whereArgs: [item['id']]);
        Navigator.pop(ctx); _refresh();
      }, child: const Text("حفظ"))],
    )));
  }

  _clear() { nameCtrl.clear(); barcodeCtrl.clear(); companyCtrl.clear(); boxesCtrl.text="0"; pPerBoxCtrl.text="1"; jomlaPriceCtrl.clear(); mofradPriceCtrl.clear(); }
  Widget _inp(TextEditingController c, String l, {bool isNum = false}) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: TextField(controller: c, keyboardType: isNum ? TextInputType.number : TextInputType.text, decoration: InputDecoration(labelText: l, border: const OutlineInputBorder())));
  Widget _counter(TextEditingController c, String l, Function s) => Row(children: [Text(l), IconButton(onPressed: ()=>s(()=>c.text=(int.parse(c.text)-1).toString()), icon: const Icon(Icons.remove)), Expanded(child: TextField(controller: c, textAlign: TextAlign.center)), IconButton(onPressed: ()=>s(()=>c.text=(int.parse(c.text)+1).toString()), icon: const Icon(Icons.add))]);

  @override
  Widget build(BuildContext context) {
    var filtered = _inventory.where((e) => e['name'].contains(_search) || e['barcode'].contains(_search)).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text("SMART STOCK", style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D1B2A),
        actions: [TextButton(onPressed: ()=>setState(()=>_currency=_currency=="د.ع"?"\$":"د.ع"), child: Text(_currency, style: const TextStyle(color: Colors.orangeAccent, fontSize: 20, fontWeight: FontWeight.bold)))]
      ),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(8), child: TextField(onChanged: (v)=>setState(()=>_search=v), decoration: const InputDecoration(hintText: "بحث...", prefixIcon: Icon(Icons.search)))),
        Expanded(child: filtered.isEmpty ? Opacity(opacity: 0.2, child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.inventory_2_outlined, size: 100), const Text("المخزن فارغ")]))) : ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (ctx, i) {
            bool low = filtered[i]['totalPieces'] <= 2;
            return Container(
              color: low ? Colors.red[100] : (i % 2 == 0 ? Colors.white : Colors.grey[200]),
              child: ListTile(
                title: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(filtered[i]['name'], style: const TextStyle(fontWeight: FontWeight.bold)), Text(filtered[i]['company'], style: const TextStyle(fontSize: 12, color: Colors.blueGrey))]),
                  Column(crossAxisAlignment: CrossAxisAlignment.center, children: [Text("كرتون: ${filtered[i]['boxes']}"), Text("القطع: ${filtered[i]['pPerBox']}", style: const TextStyle(fontSize: 12))]),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text("${filtered[i]['jPrice']} $_currency"), Text("${filtered[i]['mPrice']} $_currency", style: const TextStyle(fontSize: 12, color: Colors.green))]),
                ]),
                trailing: PopupMenuButton(onSelected: (v) async {
                  if (v=='e') _showForm(item: filtered[i]);
                  else { await (await DB.instance).delete('inventory', where: "id=?", whereArgs: [filtered[i]['id']]); _refresh(); }
                }, itemBuilder: (ctx)=>[const PopupMenuItem(value: 'e', child: Text("تعديل")), const PopupMenuItem(value: 'd', child: Text("حذف"))]),
              ),
            );
          },
        )),
      ]),
      floatingActionButton: FloatingActionButton(backgroundColor: Colors.orangeAccent, onPressed: ()=>_showForm(), child: const Icon(Icons.add)),
    );
  }
}

// --- صفحة المبيعات ---
class SalesPage extends StatefulWidget {
  const SalesPage({super.key});
  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final scanCtrl = TextEditingController();
  List<Map<String, dynamic>> cart = [];
  _onScan(String code) async {
    final db = await DB.instance;
    final res = await db.query('inventory', where: "barcode = ?", whereArgs: [code]);
    if (res.isNotEmpty) {
      var item = Map<String, dynamic>.from(res.first);
      if (item['totalPieces'] > 0) {
        await db.update('inventory', {'totalPieces': item['totalPieces'] - 1}, where: "id = ?", whereArgs: [item['id']]);
        await db.insert('sales', {'date': DateTime.now().toIso8601String(), 'amount': item['mPrice'], 'itemName': item['name']});
        setState(() { cart.add(item); scanCtrl.clear(); });
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("قسم المبيعات"), backgroundColor: Colors.green[800]),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(10), child: TextField(controller: scanCtrl, onSubmitted: _onScan, autofocus: true, decoration: const InputDecoration(hintText: "مسح باركود (داخلي أو خارجي)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.qr_code_scanner)))),
        Expanded(child: ListView.builder(itemCount: cart.length, itemBuilder: (ctx, i) => ListTile(title: Text(cart[i]['name']), trailing: Text("${cart[i]['mPrice']}")))),
      ]),
    );
  }
}

// سجل المبيعات (نفسه بدون تغيير)
class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("سجل المبيعات")), body: const Center(child: Text("السجل محفوظ ويتم التحديث تلقائياً")));
}
