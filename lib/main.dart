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
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 9),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(color: coffee.withOpacity(.07), blurRadius: 16, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                _navItem(0, Iconsax.home, 'Dashboard'),
                _navItem(1, Iconsax.calendar, 'Events'),
                _navItem(2, Iconsax.profile_2user, 'Staff'),
                _navItem(3, Iconsax.box_1, 'Equipment'),
                _navItem(4, Iconsax.receipt_1, 'Expenses'),
                _navItem(5, Iconsax.chart_2, 'Reports'),
                _navItem(6, Iconsax.setting_2, 'Settings'),
              ],
            ),
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
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => setState(() => tab = index),
          child: SizedBox(
            height: 76,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: selected ? olive : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: selected ? Colors.white : muted),
                ),
                const SizedBox(height: 3),
                Text(label, maxLines: 1, style: TextStyle(
                  color: selected ? olive : muted,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                )),
              ],
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
String money(dynamic n)=>'₹${(n is num ? n : 0).toStringAsFixed(0)}';
String today()=>DateTime.now().toIso8601String().substring(0,10);

class DashboardPage extends StatelessWidget {
  final Map<String,dynamic> data; final ValueChanged<int> onNavigate;
  const DashboardPage({super.key,required this.data,required this.onNavigate});
  @override Widget build(BuildContext context) {
    final events=(data['events'] as List).cast<Map<String,dynamic>>();
    final staff=data['staff'] as List;
    final upcoming=events.where((e)=>(e['date']??'').toString().compareTo(today())>=0).toList()..sort((a,b)=>(a['date']??'').toString().compareTo((b['date']??'').toString()));
    final todayEvents=upcoming.where((e)=>e['date']==today()).toList();
    final wages=events.expand((e)=>((e['staffAssignments']??[]) as List)).where((a)=>a['attended']==true).fold<num>(0,(n,a)=>n+((a['wage'] as num?)??0));
    final expenses=events.expand((e)=>((e['expenses']??[]) as List)).fold<num>(0,(n,e)=>n+((e['amount'] as num?)??0))+(data['expenses'] as List).fold<num>(0,(n,e)=>n+((e['amount'] as num?)??0));
    return ListView(padding:EdgeInsets.zero,children:[
      Padding(padding:const EdgeInsets.fromLTRB(20,22,20,18),child:Row(children:[
        Container(width:38,height:38,decoration:BoxDecoration(color:gold,borderRadius:BorderRadius.circular(9)),child:const Center(child:Text('H',style:TextStyle(color:surface,fontFamily:'Georgia',fontSize:23,fontWeight:FontWeight.w700)))),
        const SizedBox(width:10),const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('HENA',style:TextStyle(color:coffee,fontFamily:'Georgia',fontSize:18,fontWeight:FontWeight.w700,letterSpacing:1.5)),Text('CATERING WORKSPACE',style:TextStyle(color:muted,fontSize:8,letterSpacing:1.5,fontWeight:FontWeight.w700))])),
        Text(today(),style:const TextStyle(color:muted,fontSize:10)),
      ])),
      Padding(padding:const EdgeInsets.fromLTRB(20,2,20,16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(DateTime.now().toLocal().toString().substring(0,10),style:const TextStyle(color:gold,fontSize:9,fontWeight:FontWeight.w800,letterSpacing:1.4)),
        const SizedBox(height:5),const Text('Good day, HENA.',style:TextStyle(color:coffee,fontFamily:'Georgia',fontSize:27,fontWeight:FontWeight.w700)),
        const SizedBox(height:4),const Text('Here is the overview of your catering operations.',style:TextStyle(color:muted,fontSize:11)),
      ])),
      Padding(padding:const EdgeInsets.symmetric(horizontal:18),child:GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,mainAxisSpacing:9,crossAxisSpacing:9,childAspectRatio:1.65,children:[
        _metric('Total events',events.length.toString(),'\${upcoming.length} upcoming'),
        _metric('Upcoming events',upcoming.length.toString(),'Scheduled jobs'),
        _metric('Staff wages',money(wages),'Recorded attendance'),
        _metric('Other expenses',money(expenses),'Across all events'),
      ])),
      Padding(padding:const EdgeInsets.fromLTRB(20,22,20,10),child:Row(children:[const Expanded(child:Text('Upcoming events',style:TextStyle(color:coffee,fontFamily:'Georgia',fontSize:17,fontWeight:FontWeight.w700))),TextButton(onPressed:()=>onNavigate(1),child:const Text('View all →',style:TextStyle(color:olive,fontSize:11,fontWeight:FontWeight.w700)))])),
      Padding(padding:const EdgeInsets.symmetric(horizontal:18),child:panel(child:Column(children:[
        if(upcoming.isEmpty) const Padding(padding:EdgeInsets.all(16),child:Text('No events scheduled. Create your first event to start tracking the work.',style:TextStyle(color:muted,fontSize:11))),
        ...upcoming.take(5).map((e)=>InkWell(onTap:()=>onNavigate(1),child:Padding(padding:const EdgeInsets.symmetric(vertical:9),child:Row(children:[
          Container(width:40,height:43,decoration:BoxDecoration(color:cream,borderRadius:BorderRadius.circular(8),border:Border.all(color:const Color(0xFFE8E3D8))),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Text((e['date']??'').toString().length>=10?(e['date'] as String).substring(8,10):'--',style:const TextStyle(color:olive,fontFamily:'Georgia',fontSize:17,fontWeight:FontWeight.w700)),Text((e['date']??'').toString().length>=7?(e['date'] as String).substring(5,7):'',style:const TextStyle(color:muted,fontSize:8))])),
          const SizedBox(width:11),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(e['name']??'Untitled event',style:const TextStyle(color:coffee,fontSize:12,fontWeight:FontWeight.w700)),Text(e['location']??'Location not added',style:const TextStyle(color:muted,fontSize:10))])),Text(e['time']??'',style:const TextStyle(color:olive,fontSize:10,fontWeight:FontWeight.w700)),
        ])))),
      ]))),
      Padding(padding:const EdgeInsets.fromLTRB(20,20,20,10),child:const Text("Today's work",style:TextStyle(color:coffee,fontFamily:'Georgia',fontSize:17,fontWeight:FontWeight.w700))),
      Padding(padding:const EdgeInsets.symmetric(horizontal:18),child:panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        if(todayEvents.isEmpty) const Text("Nothing on today's schedule.",style:TextStyle(color:muted,fontSize:11)),
        ...todayEvents.map((e)=>Padding(padding:const EdgeInsets.symmetric(vertical:7),child:Row(children:[Container(width:3,height:34,decoration:BoxDecoration(color:gold,borderRadius:BorderRadius.circular(2))),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(e['name']??'Event',style:const TextStyle(color:coffee,fontSize:12,fontWeight:FontWeight.w700)),Text('\${e['time']??''} · \${e['location']??''}',style:const TextStyle(color:muted,fontSize:10))]))]))),
      ]))),
      Padding(padding:const EdgeInsets.fromLTRB(20,20,20,10),child:const Text('Operating costs',style:TextStyle(color:coffee,fontFamily:'Georgia',fontSize:17,fontWeight:FontWeight.w700))),
      Padding(padding:const EdgeInsets.fromLTRB(18,0,18,25),child:panel(child:Column(children:[
        _moneyLine('Staff wages',wages),const Divider(height:18),_moneyLine('Other expenses',expenses),const Divider(height:18),
        Row(children:[const Expanded(child:Text('Total operating costs',style:TextStyle(color:coffee,fontSize:12,fontWeight:FontWeight.w800))),Text(money(wages+expenses),style:const TextStyle(color:olive,fontSize:17,fontWeight:FontWeight.w800))]),
      ]))),
    ]);
  }
  Widget _metric(String label,String value,String note)=>panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(value,style:const TextStyle(color:coffee,fontFamily:'Georgia',fontSize:22,fontWeight:FontWeight.w700)),Text(label,style:const TextStyle(color:coffee,fontSize:10,fontWeight:FontWeight.w700)),Text(note,style:const TextStyle(color:muted,fontSize:9))]),padding:const EdgeInsets.all(13));
  Widget _moneyLine(String label,num value)=>Row(children:[Expanded(child:Text(label,style:const TextStyle(color:muted,fontSize:11))),Text(money(value),style:const TextStyle(color:coffee,fontSize:12,fontWeight:FontWeight.w700))]);
}

class EventsPage extends StatelessWidget {
  final Map<String,dynamic> data; final ValueChanged<Map<String,dynamic>> onAdd; final ValueChanged<String> onOpen;
  const EventsPage({super.key,required this.data,required this.onAdd,required this.onOpen});
  @override Widget build(BuildContext context) {
    final events=data['events'] as List;
    return Column(children:[
      PageTitle('Plan & coordinate','Events'),
      Padding(padding:const EdgeInsets.symmetric(horizontal:18),child:Row(children:[
        Expanded(child:Text('${events.length} saved events',style:const TextStyle(color:muted,fontSize:12))),
        actionButton('New event',Icons.add,()=>_eventDialog(context,onAdd)),
      ])),
      const SizedBox(height:12),
      Expanded(child:events.isEmpty?_empty(Icons.event_note,'No events yet','Add your first catering event to get started.'):ListView.builder(
        padding:const EdgeInsets.fromLTRB(18,0,18,20),itemCount:events.length,itemBuilder:(c,i){
          final e=events[i];return Padding(padding:const EdgeInsets.only(bottom:10),child:InkWell(borderRadius:BorderRadius.circular(22),onTap:()=>onOpen(e['id'].toString()),child:panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Row(children:[Expanded(child:Text(e['name']??'Event',style:const TextStyle(color:coffee,fontSize:17,fontWeight:FontWeight.w700))),Text(e['date']??'',style:const TextStyle(color:olive,fontSize:11,fontWeight:FontWeight.w700))]),
            const SizedBox(height:8),Row(children:[const Icon(Icons.location_on_outlined,size:15,color:muted),const SizedBox(width:5),Expanded(child:Text(e['location']??'Location not added',style:const TextStyle(color:muted,fontSize:12)))]),
            if((e['services']??'').toString().isNotEmpty)...[const SizedBox(height:8),Text(e['services'],style:const TextStyle(color:coffee,fontSize:12))],
          ]))));
        })),
    ]);
  }
}

class StaffPage extends StatelessWidget {
  final Map<String,dynamic> data; final ValueChanged<Map<String,dynamic>> onAdd;
  const StaffPage({super.key,required this.data,required this.onAdd});
  @override Widget build(BuildContext context) {
    final staff=data['staff'] as List;
    return Column(children:[
      PageTitle('Your team','Staff'),
      Padding(padding:const EdgeInsets.symmetric(horizontal:18),child:Row(children:[
        Expanded(child:Text('${staff.length} team members',style:const TextStyle(color:muted,fontSize:12))),
        actionButton('Add staff',Icons.person_add_alt_1,()=>_simpleDialog(context,'Add staff member','Full name','name',onAdd)),
      ])),
      const SizedBox(height:12),
      Expanded(child:staff.isEmpty?_empty(Icons.groups_outlined,'No staff added','Add staff members by name. Assign their roles per event.'):ListView.builder(
        padding:const EdgeInsets.symmetric(horizontal:18),itemCount:staff.length,itemBuilder:(c,i){
          final personId=staff[i]['id'];
          final assignments=(data['events'] as List).expand((event)=>((event['staffAssignments']??[]) as List)).where((a)=>a['staffId']==personId).toList();
          final wages=assignments.where((a)=>a['attended']==true).fold<num>(0,(sum,a)=>sum+((a['wage'] as num?)??0));
          final roles=assignments.map((a)=>a['role']).where((r)=>r!=null).toSet().join(', ');
          return Padding(padding:const EdgeInsets.only(bottom:9),child:panel(child:Row(children:[
            CircleAvatar(backgroundColor:olive.withOpacity(.13),child:Text((staff[i]['name']??'?').toString().substring(0,1).toUpperCase(),style:const TextStyle(color:olive,fontWeight:FontWeight.bold))),
            const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(staff[i]['name']??'',style:const TextStyle(color:coffee,fontWeight:FontWeight.w700)),
              Text(roles.isEmpty?'No event role assigned':roles,style:const TextStyle(color:muted,fontSize:10)),
              Text(assignments.length.toString()+' assignments · '+money(wages)+' wages',style:const TextStyle(color:olive,fontSize:10,fontWeight:FontWeight.w700)),
            ])),
          ])));
        })),
    ]);
  }
}

class EquipmentPage extends StatelessWidget {
  final Map<String,dynamic> data; final VoidCallback onSave;
  const EquipmentPage({super.key,required this.data,required this.onSave});
  @override Widget build(BuildContext context) {
    final events=(data['events'] as List).cast<Map<String,dynamic>>();
    final rows=events.expand((event)=>((event['equipment']??[]) as List).map((item)=>{'event':event,'item':item})).toList();
    final missing=rows.fold<num>(0,(n,row){final item=row['item'] as Map;return n+(((item['planned'] as num?)??0)-((item['returned'] as num?)??0)-((item['damaged'] as num?)??0)).clamp(0,999999);});
    final damaged=rows.fold<num>(0,(n,row)=>n+(((row['item'] as Map)['damaged'] as num?)??0));
    return ListView(padding:EdgeInsets.zero,children:[
      const PageTitle('Event preparation','Equipment & inventory'),
      Padding(padding:const EdgeInsets.symmetric(horizontal:18),child:GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,mainAxisSpacing:9,crossAxisSpacing:9,childAspectRatio:1.6,children:[
        _metric('Tracked items',rows.length.toString()),_metric('Missing quantity',missing.toString()),_metric('Damaged quantity',damaged.toString()),_metric('Events',events.where((e)=>((e['equipment']??[]) as List).isNotEmpty).length.toString()),
      ])),
      Padding(padding:const EdgeInsets.fromLTRB(18,15,18,28),child:panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('Equipment by event',style:TextStyle(color:coffee,fontSize:16,fontWeight:FontWeight.w700)),
        const SizedBox(height:8),
        if(rows.isEmpty) const Text('Create an event and select its services to generate the equipment checklist.',style:TextStyle(color:muted,fontSize:12,height:1.5)),
        ...events.where((e)=>((e['equipment']??[]) as List).isNotEmpty).map((event)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Padding(padding:const EdgeInsets.only(top:12,bottom:6),child:Text(event['name']??'Event',style:const TextStyle(color:olive,fontWeight:FontWeight.w800))),
          ...((event['equipment']??[]) as List).map((raw){final item=raw as Map<String,dynamic>;final planned=(item['planned'] as num?)??0;final returned=(item['returned'] as num?)??0;final damaged=(item['damaged'] as num?)??0;return Padding(padding:const EdgeInsets.symmetric(vertical:7),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(item['name']??'Item',style:const TextStyle(color:coffee,fontSize:12,fontWeight:FontWeight.w700)),
            Text(item['category']??'Equipment',style:const TextStyle(color:muted,fontSize:10)),
            const SizedBox(height:5),
            Row(children:[Expanded(child:Text('Take: $planned',style:const TextStyle(fontSize:10,color:muted))),Expanded(child:Text('Returned: $returned',style:const TextStyle(fontSize:10,color:muted))),Expanded(child:Text('Damaged: $damaged',style:const TextStyle(fontSize:10,color:muted))),Text('Missing: \${(planned-returned-damaged).clamp(0,999999)}',style:const TextStyle(fontSize:10,color:coffee,fontWeight:FontWeight.w700))]),
          ]));}),
          const Divider(height:15),
        ])),
      ]))),
    ]);
  }
  Widget _metric(String label,String value)=>panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(value,style:const TextStyle(color:coffee,fontSize:22,fontWeight:FontWeight.w700)),Text(label,style:const TextStyle(color:muted,fontSize:11))]),padding:const EdgeInsets.all(14));
}

class ExpensesPage extends StatelessWidget {
  final Map<String,dynamic> data; final ValueChanged<Map<String,dynamic>> onAdd;
  const ExpensesPage({super.key,required this.data,required this.onAdd});
  @override Widget build(BuildContext context) {
    final eventRows=(data['events'] as List).expand((event)=>((event['expenses']??[]) as List).map((expense)=>{'event':event,'expense':expense})).toList();
    final other=(data['expenses'] as List).map((expense)=>{'event':{'name':'General'},'expense':expense}).toList();
    final rows=[...eventRows,...other];
    final total=rows.fold<num>(0,(n,row)=>n+((((row['expense'] as Map)['amount']) as num?)??0));
    return ListView(padding:EdgeInsets.zero,children:[
      const PageTitle('Track spending','Expenses'),
      Padding(padding:const EdgeInsets.symmetric(horizontal:18),child:panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('TOTAL RECORDED EXPENSES',style:TextStyle(color:muted,fontSize:10,letterSpacing:1.3,fontWeight:FontWeight.w700)),
        const SizedBox(height:7),Text(money(total),style:const TextStyle(color:coffee,fontSize:26,fontWeight:FontWeight.w700)),
        const SizedBox(height:5),Text('\${rows.length} expense entries',style:const TextStyle(color:muted,fontSize:11)),
      ]))),
      Padding(padding:const EdgeInsets.fromLTRB(18,16,18,8),child:const Text('Expense ledger',style:TextStyle(color:coffee,fontSize:17,fontWeight:FontWeight.w700))),
      Padding(padding:const EdgeInsets.symmetric(horizontal:18),child:panel(child:Column(children:[
        if(rows.isEmpty) const Padding(padding:EdgeInsets.all(18),child:Text('Open an event and add travel, supplies, food or other costs.',style:TextStyle(color:muted,fontSize:12))),
        ...rows.map((row){final e=row['expense'] as Map;final event=row['event'] as Map;return Padding(padding:const EdgeInsets.symmetric(vertical:9),child:Row(children:[
          const Icon(Icons.receipt_long_outlined,color:gold,size:19),const SizedBox(width:10),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(e['title']??e['description']??'Expense',style:const TextStyle(color:coffee,fontWeight:FontWeight.w700,fontSize:12)),Text('\${event['name']} · \${e['category']??'Other'} · \${e['date']??''}',style:const TextStyle(color:muted,fontSize:10))])),
          Text(money(e['amount']),style:const TextStyle(color:coffee,fontWeight:FontWeight.w800,fontSize:12)),
        ]));}),
      ]))),
      const SizedBox(height:24),
    ]);
  }
}

Widget _empty(IconData icon,String title,String subtitle)=>Center(child:Padding(padding:const EdgeInsets.all(32),child:Column(mainAxisSize:MainAxisSize.min,children:[
  Container(width:76,height:76,decoration:BoxDecoration(color:olive.withOpacity(.09),shape:BoxShape.circle),child:Icon(icon,color:olive.withOpacity(.75),size:34)),const SizedBox(height:16),
  Text(title,textAlign:TextAlign.center,style:const TextStyle(color:coffee,fontSize:17,fontWeight:FontWeight.w800)),
  const SizedBox(height:7),Text(subtitle,textAlign:TextAlign.center,style:const TextStyle(color:muted,fontSize:12,height:1.45)),
])));

Future<void> _simpleDialog(BuildContext context,String title,String hint,String key,ValueChanged<Map<String,dynamic>> onSubmit) async {
  final ctrl=TextEditingController();
  await showDialog(context:context,builder:(ctx)=>AlertDialog(
    backgroundColor:cream,title:Text(title,style:const TextStyle(color:coffee)),
    content:TextField(controller:ctrl,decoration:InputDecoration(hintText:hint)),
    actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel')),FilledButton(
      style:FilledButton.styleFrom(backgroundColor:olive),onPressed:(){if(ctrl.text.trim().isNotEmpty){onSubmit({key:ctrl.text.trim(),'id':DateTime.now().microsecondsSinceEpoch.toString()});Navigator.pop(ctx);}},child:const Text('Save'))],
  ));
}
List<Map<String,dynamic>> _equipmentForServices(Set<String> selected) {
  const templates = <String,List<String>>{
    'Juice':['Glass','Mixie','Jar','Knife','Cutting board','Code wire','Aripa','Andaav','Tray'],
    'Samavar tea':['Samavar set','Stove','Gas'],
    'Snacks':['Chatti','Stove','Gas','Tray'],
    'Popcorn':['Popcorn machine','Code wire'],
    'Cotton candy':['Cotton candy machine','Code wire'],
    'Herbal tea':['Big stove set (3-stove set)','Small stove set (4-stove set)','Gas','Ceramic glass','Disposable glass','Small kettle','Big kettle'],
  };
  final result = <Map<String,dynamic>>[];
  for (final service in selected) {
    for (final item in templates[service] ?? <String>[]) {
      result.add({'id':DateTime.now().microsecondsSinceEpoch.toString() + result.length.toString(),'category':service,'name':item,'planned':1,'returned':0,'damaged':0});
    }
  }
  return result;
}

Future<void> _eventDialog(BuildContext context,ValueChanged<Map<String,dynamic>> onSubmit) async {
  final name=TextEditingController(),location=TextEditingController();
  const serviceOptions=['Juice','Samavar tea','Herbal tea','Snacks','Popcorn','Cotton candy'];
  final selectedServices=<String>{};
  DateTime date=DateTime.now();
  TimeOfDay time=TimeOfDay.now();
  final notes=TextEditingController();
  String venueType='Auditorium';
  await showDialog(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setD)=>AlertDialog(
    backgroundColor:cream,title:const Text('New event',style:TextStyle(color:coffee)),
    content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:name,decoration:const InputDecoration(hintText:'Event name')),
      const SizedBox(height:9),TextField(controller:location,decoration:const InputDecoration(hintText:'Venue / location')),
      const SizedBox(height:9),DropdownButtonFormField<String>(value:venueType,decoration:const InputDecoration(labelText:'Venue type'),items:['Auditorium','House','Outdoor','Other'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>setD(()=>venueType=v??'Auditorium')),
      const SizedBox(height:9),TextField(controller:notes,decoration:const InputDecoration(hintText:'Event notes / instructions')),
      const SizedBox(height:12),
      const Align(alignment:Alignment.centerLeft,child:Text('Select services',style:TextStyle(color:coffee,fontWeight:FontWeight.w700))),
      const SizedBox(height:6),
      ...serviceOptions.map((service)=>CheckboxListTile(
        dense:true,contentPadding:EdgeInsets.zero,controlAffinity:ListTileControlAffinity.leading,
        activeColor:olive,value:selectedServices.contains(service),
        title:Text(service,style:const TextStyle(color:coffee,fontSize:13)),
        onChanged:(checked)=>setD((){if(checked==true){selectedServices.add(service);}else{selectedServices.remove(service);}}),
      )),
      const SizedBox(height:4),ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.calendar_month,color:olive),title:Text('${date.day}/${date.month}/${date.year}'),onTap:()async{final d=await showDatePicker(context:ctx,firstDate:DateTime(2020),lastDate:DateTime(2100),initialDate:date);if(d!=null)setD(()=>date=d);}),
      ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.access_time,color:olive),title:Text(time.format(ctx)),onTap:()async{final t=await showTimePicker(context:ctx,initialTime:time);if(t!=null)setD(()=>time=t);}),
    ])),
    actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel')),FilledButton(style:FilledButton.styleFrom(backgroundColor:olive),onPressed:(){
      if(name.text.trim().isEmpty)return;
      onSubmit({'id':DateTime.now().microsecondsSinceEpoch.toString(),'name':name.text.trim(),'location':location.text.trim(),'venueType':venueType,'services':selectedServices.join(', '),'date':date.toIso8601String().substring(0,10),'time':time.format(ctx),'notes':notes.text.trim(),'staffAssignments':[],'expenses':[],'equipment':_equipmentForServices(selectedServices)});
      Navigator.pop(ctx);
    },child:const Text('Save event'))],
  )));
}
Future<void> _expenseDialog(BuildContext context,ValueChanged<Map<String,dynamic>> onSubmit) async {
  final title=TextEditingController(),amount=TextEditingController();
  String category='Staff';
  const categories=['Staff','Supplies','Travel','Fuel','Food','Equipment','Other'];
  await showDialog(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setD)=>AlertDialog(
    backgroundColor:cream,title:const Text('Add expense',style:TextStyle(color:coffee)),
    content:Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:title,decoration:const InputDecoration(hintText:'Expense description')),
      const SizedBox(height:9),TextField(controller:amount,keyboardType:TextInputType.number,decoration:const InputDecoration(hintText:'Amount (₹)')),
      const SizedBox(height:9),DropdownButtonFormField<String>(value:category,decoration:const InputDecoration(),items:categories.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setD(()=>category=v??'Other')),
    ]),
    actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel')),FilledButton(style:FilledButton.styleFrom(backgroundColor:olive),onPressed:(){
      final n=num.tryParse(amount.text.trim());if(title.text.trim().isEmpty||n==null)return;
      onSubmit({'id':DateTime.now().microsecondsSinceEpoch.toString(),'title':title.text.trim(),'amount':n,'category':category,'date':today()});Navigator.pop(ctx);
    },child:const Text('Save'))],
  )));
}


class ReportsPage extends StatelessWidget {
  final Map<String,dynamic> data;
  const ReportsPage({super.key,required this.data});
  @override Widget build(BuildContext context) {
    final events=(data['events'] as List).cast<Map<String,dynamic>>();
    final wages=events.expand((e)=>((e['staffAssignments']??[]) as List)).where((a)=>a['attended']==true).fold<num>(0,(n,a)=>n+((a['wage'] as num?)??0));
    final expenses=events.expand((e)=>((e['expenses']??[]) as List)).fold<num>(0,(n,e)=>n+((e['amount'] as num?)??0))+(data['expenses'] as List).fold<num>(0,(n,e)=>n+((e['amount'] as num?)??0));
    final costs=wages+expenses;
    return ListView(padding:EdgeInsets.zero,children:[
      const PageTitle('Business overview','Reports & costs'),
      Padding(padding:const EdgeInsets.symmetric(horizontal:18),child:GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,mainAxisSpacing:10,crossAxisSpacing:10,childAspectRatio:1.5,children:[
        _reportMetric('Staff wages',money(wages)),_reportMetric('Other expenses',money(expenses)),_reportMetric('Operating costs',money(costs)),_reportMetric('Events recorded',events.length.toString()),
      ])),
      Padding(padding:const EdgeInsets.fromLTRB(18,18,18,8),child:panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('Cost breakdown',style:TextStyle(fontSize:16,fontWeight:FontWeight.w700,color:coffee)),
        const SizedBox(height:16),
        _costBar('Staff wages',wages,costs,gold),const SizedBox(height:14),_costBar('Other expenses',expenses,costs,olive),
      ]))),
      Padding(padding:const EdgeInsets.fromLTRB(18,10,18,24),child:panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('Cost per event',style:TextStyle(fontSize:16,fontWeight:FontWeight.w700,color:coffee)),
        const SizedBox(height:8),
        ...events.map((e){final w=((e['staffAssignments']??[]) as List).where((a)=>a['attended']==true).fold<num>(0,(n,a)=>n+((a['wage'] as num?)??0));final x=((e['expenses']??[]) as List).fold<num>(0,(n,a)=>n+((a['amount'] as num?)??0));return Padding(padding:const EdgeInsets.symmetric(vertical:9),child:Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(e['name']??'Event',style:const TextStyle(fontWeight:FontWeight.w700,color:coffee)),Text('\${e['date']??''} · \${e['location']??''}',style:const TextStyle(color:muted,fontSize:10))])),Text(money(w+x),style:const TextStyle(fontWeight:FontWeight.w800,color:olive))]));}),
        if(events.isEmpty) const Text('Create events to start building reports.',style:TextStyle(color:muted,fontSize:12)),
      ]))),
    ]);
  }
  Widget _reportMetric(String label,String value)=>panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(value,style:const TextStyle(fontSize:21,fontWeight:FontWeight.w700,color:coffee)),Text(label,style:const TextStyle(fontSize:11,color:muted))]),padding:const EdgeInsets.all(14));
  Widget _costBar(String label,num amount,num total,Color color)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text(label,style:const TextStyle(color:muted,fontSize:12))),Text(money(amount),style:const TextStyle(color:coffee,fontWeight:FontWeight.w700))]),const SizedBox(height:7),ClipRRect(borderRadius:BorderRadius.circular(5),child:LinearProgressIndicator(value:total==0?0:amount/total,minHeight:7,color:color,backgroundColor:cream))]);
}

class SettingsPage extends StatelessWidget {
  final Map<String,dynamic> data;
  final ValueChanged<Map<String,dynamic>> onRestore;
  const SettingsPage({super.key,required this.data,required this.onRestore});
  @override Widget build(BuildContext context)=>ListView(padding:EdgeInsets.zero,children:[
    const PageTitle('Workspace preferences','Settings & backup'),
    Padding(padding:const EdgeInsets.symmetric(horizontal:18),child:panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Icon(Icons.cloud_done_outlined,color:olive,size:25),const SizedBox(height:10),
      const Text('Device storage',style:TextStyle(color:coffee,fontSize:16,fontWeight:FontWeight.w700)),
      const SizedBox(height:5),const Text('Your event records are saved locally on this phone.',style:TextStyle(color:muted,fontSize:12)),
      const SizedBox(height:12),const Row(children:[Icon(Icons.check_circle,color:olive,size:15),SizedBox(width:7),Text('Local storage active',style:TextStyle(color:olive,fontSize:11,fontWeight:FontWeight.w700))]),
    ]))),
    Padding(padding:const EdgeInsets.fromLTRB(18,12,18,0),child:panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Icon(Icons.backup_outlined,color:gold,size:25),const SizedBox(height:10),
      const Text('Local backup',style:TextStyle(color:coffee,fontSize:16,fontWeight:FontWeight.w700)),
      const SizedBox(height:5),const Text('Export your events, staff, wages, expenses and equipment records as a JSON backup.',style:TextStyle(color:muted,fontSize:12)),
      const SizedBox(height:12),
      SizedBox(width:double.infinity,child:OutlinedButton.icon(onPressed:()async{final json=const JsonEncoder.withIndent('  ').convert(data);await showDialog(context:context,builder:(ctx)=>AlertDialog(title:const Text('Backup data'),content:SingleChildScrollView(child:SelectableText(json,style:const TextStyle(fontSize:10))),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Close'))]));},icon:const Icon(Icons.download),label:const Text('View / copy backup data'))),
      SizedBox(width:double.infinity,child:OutlinedButton.icon(onPressed:()async{final controller=TextEditingController();final result=await showDialog<String>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Restore backup'),content:TextField(controller:controller,maxLines:8,decoration:const InputDecoration(hintText:'Paste backup JSON here')),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,controller.text),child:const Text('Restore'))]));if(result!=null){try{final decoded=jsonDecode(result) as Map<String,dynamic>;decoded.putIfAbsent('events',()=>[]);decoded.putIfAbsent('staff',()=>[]);decoded.putIfAbsent('expenses',()=>[]);decoded.putIfAbsent('equipment',()=>defaultEquipment);onRestore(decoded);if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Backup restored')));}catch(_){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Invalid backup JSON')));}}},icon:const Icon(Icons.restore),label:const Text('Restore from JSON'))),
    ]))),
    Padding(padding:const EdgeInsets.fromLTRB(18,12,18,30),child:panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Icon(Icons.info_outline,color:gold,size:25),const SizedBox(height:10),const Text('HENA CATERING',style:TextStyle(color:coffee,fontWeight:FontWeight.w800,letterSpacing:1.2)),const Text('Operations workspace · Offline-first',style:TextStyle(color:muted,fontSize:11)),
    ]))),
  ]);
}
