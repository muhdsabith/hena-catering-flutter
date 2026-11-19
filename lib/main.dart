import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'event_detail_page.dart';

const coffee = Color(0xFF20251F);
const olive = Color(0xFF244438);
const cream = Color(0xFFF5F3ED);
const muted = Color(0xFF77786F);
const gold = Color(0xFFB6945A);
const surface = Color(0xFFFFFEFA);

void main() => runApp(const HenaApp());

class HenaApp extends StatelessWidget {
  const HenaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'HENA Catering',
    theme: ThemeData(
      useMaterial3: true,
      textTheme: GoogleFonts.manropeTextTheme().apply(bodyColor: coffee, displayColor: coffee),
      scaffoldBackgroundColor: cream,
      colorScheme: ColorScheme.fromSeed(seedColor: olive, surface: surface),
      appBarTheme: const AppBarTheme(backgroundColor: cream, foregroundColor: coffee),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: surface,
        labelStyle: const TextStyle(color: muted, fontSize: 13, fontWeight: FontWeight.w600),
        hintStyle: const TextStyle(color: Color(0xFFB2A89E), fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE8E3D8))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: gold, width: 1.4)),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFF0EAE2), thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, backgroundColor: const Color(0xFF202F29), contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
    ),
    home: const MainShell(),
  );
}

const defaultEquipment = [
  {'name':'Samavar set','checked':false},
  {'name':'Stove','checked':false},
  {'name':'Gas cylinder','checked':false},
  {'name':'Juice dispenser','checked':false},
  {'name':'Serving glasses','checked':false},
  {'name':'Herbal tea equipment','checked':false},
  {'name':'Popcorn machine','checked':false},
  {'name':'Cotton candy machine','checked':false},
];

class LocalStore {
  static Future<Map<String, dynamic>> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('hena_data_v1');
    if (raw == null) return {'events': [], 'staff': [], 'expenses': [], 'equipment': defaultEquipment};
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      data.putIfAbsent('events', () => []);
      data.putIfAbsent('staff', () => []);
      data.putIfAbsent('expenses', () => []);
      data.putIfAbsent('equipment', () => defaultEquipment);
      return data;
    } catch (_) {
      return {'events': [], 'staff': [], 'expenses': [], 'equipment': defaultEquipment};
    }
  }
  static Future<void> save(Map<String, dynamic> data) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('hena_data_v1', jsonEncode(data));
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override State<MainShell> createState() => _MainShellState();
}
class _MainShellState extends State<MainShell> {
  int tab = 0;
  String? selectedEventId;
  bool loading = true;
  Map<String, dynamic> data = {};
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    data = await LocalStore.load();
    if (mounted) setState(() => loading = false);
  }
  Future<void> refresh() async {
    await LocalStore.save(data);
    if (mounted) setState(() {});
  }
  void addRecord(String key, Map<String, dynamic> record) {
    (data[key] as List).insert(0, record);
    refresh();
  }
  void deleteEvent(String id) {
    (data['events'] as List).removeWhere((e) => e['id'] == id);
    selectedEventId = null;
    refresh();
  }
  void updateEvent(Map<String, dynamic> updated) {
    final events = data['events'] as List;
    final index = events.indexWhere((e) => e['id'] == updated['id']);
    if (index >= 0) { events[index] = updated; refresh(); }
  }
  @override Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child:CircularProgressIndicator()));
    final pages = [
      DashboardPage(data:data, onNavigate:(i)=>setState(()=>tab=i)),
      EventsPage(data:data, onAdd:(r)=>addRecord('events',r), onOpen:(id)=>setState(()=>selectedEventId=id)),
      StaffPage(data:data, onAdd:(r)=>addRecord('staff',r)),
      EquipmentPage(data:data, onSave:refresh),
      ExpensesPage(data:data, onAdd:(r)=>addRecord('expenses',r)),
      ReportsPage(data:data),
      SettingsPage(data:data, onRestore:(v){data=v;refresh();}),
    ];
    return Scaffold(
      body: SafeArea(child: selectedEventId == null ? IndexedStack(index:tab, children:pages) : EventDetailPage(event:(data['events'] as List).cast<Map<String,dynamic>>().firstWhere((e)=>e['id']==selectedEventId), staff:(data['staff'] as List).cast<Map<String,dynamic>>(), onBack:()=>setState(()=>selectedEventId=null), onUpdate:updateEvent, onDelete:()=>deleteEvent(selectedEventId!))),
      bottomNavigationBar: selectedEventId != null ? null : SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 5, 10, 9),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE8E1D4)),
              boxShadow: [BoxShadow(color: coffee.withOpacity(.09), blurRadius: 22, offset: const Offset(0, 6))],
            ),
            child: Row(children: [
              _navItem(0, Iconsax.element_3, 'Home'),
              _navItem(1, Iconsax.calendar_1, 'Events'),
              _navItem(2, Iconsax.people, 'Staff'),
              _navItem(3, Iconsax.box_1, 'Gear'),
              _navItem(4, Iconsax.receipt_2, 'Costs'),
              _navItem(5, Iconsax.chart_2, 'Reports'),
              _navItem(6, Iconsax.setting_2, 'Settings'),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final selected = tab == index;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Tooltip(
          message: label,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              if (tab != index) setState(() => tab = index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 7),
              decoration: BoxDecoration(
                color: selected ? olive : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedScale(
                    scale: selected ? 1.08 : 1,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(icon, size: 19, color: selected ? const Color(0xFFE8D5AD) : muted),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(label, maxLines: 1, style: TextStyle(
                      color: selected ? Colors.white : muted,
                      fontSize: 9,
                      letterSpacing: .1,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    )),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}

class PageTitle extends StatelessWidget {
  final String eyebrow, title;
  const PageTitle(this.eyebrow,this.title,{super.key});
  @override Widget build(BuildContext context)=>Padding(
    padding:const EdgeInsets.fromLTRB(20,22,20,18),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(eyebrow.toUpperCase(),style:const TextStyle(color:muted,fontSize:10,fontWeight:FontWeight.w800,letterSpacing:1.8)),
      const SizedBox(height:7),
      Text(title,style:const TextStyle(color:coffee,fontSize:27,fontWeight:FontWeight.w800,letterSpacing:-.7)),
    ]),
  );
}
Widget panel({required Widget child, EdgeInsets padding=const EdgeInsets.all(16)})=>Container(
  padding:padding, decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(15),border:Border.all(color:const Color(0xFFE8E3D8),width:.8),boxShadow:[BoxShadow(color:coffee.withOpacity(.035),blurRadius:14,offset:const Offset(0,4))]),
  child:child,
);
Widget actionButton(String label, IconData icon, VoidCallback onTap)=>FilledButton.icon(
  onPressed:onTap, icon:Icon(icon,size:18), label:Text(label),
  style:FilledButton.styleFrom(backgroundColor:olive,foregroundColor:Colors.white,padding:const EdgeInsets.symmetric(horizontal:17,vertical:13),textStyle:const TextStyle(fontSize:12,fontWeight:FontWeight.w800),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14)),elevation:0),
);

class HenaLogoMark extends StatelessWidget {
  final double size;
  const HenaLogoMark({super.key, this.size = 42});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _HenaLogoPainter()),
  );
}

class _HenaLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 100;
    canvas.save();
    canvas.scale(scale);
    final goldPaint = Paint()..color = const Color(0xFFC5A46B)..style = PaintingStyle.stroke..strokeWidth = 4..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    final ivoryPaint = Paint()..color = const Color(0xFFFFFEFA);
    final darkPaint = Paint()..color = olive;
    final goldFill = Paint()..color = const Color(0xFFD2B77E);

    // Deep green medallion with a fine champagne rim.
    canvas.drawCircle(const Offset(50, 50), 47, darkPaint);
    canvas.drawCircle(const Offset(50, 50), 45, goldPaint);

    // Chef hat: soft crown and band.
    final hat = Path()
      ..moveTo(31, 36)
      ..cubicTo(24, 30, 29, 20, 38, 22)
      ..cubicTo(40, 11, 58, 10, 62, 22)
      ..cubicTo(74, 21, 78, 32, 69, 37)
      ..lineTo(31, 37)
      ..close();
    canvas.drawPath(hat, ivoryPaint);
    final band = Path()..moveTo(31, 37)..quadraticBezierTo(50, 32, 69, 37)..lineTo(68, 43)..quadraticBezierTo(50, 39, 32, 43)..close();
    canvas.drawPath(band, goldFill);

    // Serving cloche with handle and domed lid.
    final dome = Path()
      ..moveTo(25, 59)
      ..cubicTo(28, 44, 40, 39, 50, 39)
      ..cubicTo(63, 39, 74, 47, 77, 59);
    canvas.drawPath(dome, goldPaint);
    canvas.drawLine(const Offset(23, 60), const Offset(79, 60), goldPaint);
    canvas.drawCircle(const Offset(50, 42), 3.2, goldFill);
    canvas.drawLine(const Offset(50, 60), const Offset(50, 67), goldPaint);
    canvas.drawLine(const Offset(31, 68), const Offset(69, 68), goldPaint);
    canvas.drawLine(const Offset(35, 73), const Offset(65, 73), goldPaint);

    // Small decorative steam strokes.
    final steam = Paint()..color = const Color(0xFFE7D4AE)..style = PaintingStyle.stroke..strokeWidth = 2.2..strokeCap = StrokeCap.round;
    canvas.drawPath(Path()..moveTo(43, 33)..quadraticBezierTo(40, 29, 44, 26), steam);
    canvas.drawPath(Path()..moveTo(56, 33)..quadraticBezierTo(60, 29, 56, 26), steam);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
