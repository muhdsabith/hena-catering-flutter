import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'event_detail_page.dart';

const coffee = Color(0xFF4B3023);
const olive = Color(0xFF59613A);
const cream = Color(0xFFF7F2E9);
const muted = Color(0xFF8C8176);

void main() => runApp(const HenaApp());

class HenaApp extends StatelessWidget {
  const HenaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'HENA Catering',
    theme: ThemeData(
      useMaterial3: true,
      textTheme: GoogleFonts.manropeTextTheme(),
      scaffoldBackgroundColor: cream,
      colorScheme: ColorScheme.fromSeed(seedColor: olive, surface: cream),
      appBarTheme: const AppBarTheme(backgroundColor: cream, foregroundColor: coffee),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
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
      ExpensesPage(data:data, onAdd:(r)=>addRecord('expenses',r)),
      EquipmentPage(data:data, onSave:refresh),
    ];
    return Scaffold(
      body: SafeArea(child: selectedEventId == null ? IndexedStack(index:tab, children:pages) : EventDetailPage(event:(data['events'] as List).cast<Map<String,dynamic>>().firstWhere((e)=>e['id']==selectedEventId), staff:(data['staff'] as List).cast<Map<String,dynamic>>(), onBack:()=>setState(()=>selectedEventId=null), onUpdate:updateEvent)),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 9),
          child: Container(
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(color: coffee.withOpacity(.10), blurRadius: 22, offset: const Offset(0, 7)),
              ],
            ),
            child: Row(
              children: [
                _navItem(0, Iconsax.home, 'Home'),
                _navItem(1, Iconsax.calendar, 'Events'),
                _navItem(2, Iconsax.profile_2user, 'Staff'),
                _navItem(3, Iconsax.receipt_1, 'Expenses'),
                _navItem(4, Iconsax.box_1, 'Equipment'),
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
                  width: 39,
                  height: 39,
                  decoration: BoxDecoration(
                    color: selected ? olive : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: selected ? Colors.white : muted),
                ),
                const SizedBox(height: 3),
                Text(label, maxLines: 1, style: TextStyle(
                  color: selected ? coffee : muted,
                  fontSize: 9,
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
    padding:const EdgeInsets.fromLTRB(20,18,20,16),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(eyebrow.toUpperCase(),style:const TextStyle(color:muted,fontSize:10,fontWeight:FontWeight.w700,letterSpacing:2)),
      const SizedBox(height:7),
      Text(title,style:const TextStyle(color:coffee,fontSize:29,fontWeight:FontWeight.w700,letterSpacing:-.8)),
    ]),
  );
}
Widget panel({required Widget child, EdgeInsets padding=const EdgeInsets.all(16)})=>Container(
  padding:padding, decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(22)),
  child:child,
);
Widget actionButton(String label, IconData icon, VoidCallback onTap)=>FilledButton.icon(
  onPressed:onTap, icon:Icon(icon,size:18), label:Text(label),
  style:FilledButton.styleFrom(backgroundColor:olive,foregroundColor:Colors.white,padding:const EdgeInsets.symmetric(horizontal:18,vertical:14),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(15))),
);
String money(dynamic n)=>'₹${(n is num ? n : 0).toStringAsFixed(0)}';
String today()=>DateTime.now().toIso8601String().substring(0,10);

class DashboardPage extends StatelessWidget {
  final Map<String,dynamic> data; final ValueChanged<int> onNavigate;
  const DashboardPage({super.key,required this.data,required this.onNavigate});
  @override Widget build(BuildContext context) {
    final events=data['events'] as List; final staff=data['staff'] as List; final expenses=data['expenses'] as List;
    final total=expenses.fold<num>(0,(s,e)=>s+((e['amount'] as num?)??0));
    final upcoming=events.where((e)=>((e['date']??'') as String).compareTo(today())>=0).toList();
    return ListView(padding:EdgeInsets.zero,children:[
      Padding(padding:const EdgeInsets.fromLTRB(20,18,20,20),child:Row(children:[
        Container(width:44,height:44,decoration:BoxDecoration(color:coffee,borderRadius:BorderRadius.circular(14)),child:const Icon(Icons.restaurant_menu,color:Colors.white)),
        const SizedBox(width:12),const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('HENA',style:TextStyle(color:coffee,fontSize:19,fontWeight:FontWeight.w800,letterSpacing:2)),
          Text('CATERING MANAGEMENT',style:TextStyle(color:muted,fontSize:9,letterSpacing:1.8,fontWeight:FontWeight.w700)),
        ])),
        const Icon(Icons.notifications_none_rounded,color:coffee,size:26),
      ])),
      Container(margin:const EdgeInsets.symmetric(horizontal:18),padding:const EdgeInsets.all(22),decoration:BoxDecoration(
        borderRadius:BorderRadius.circular(26),gradient:const LinearGradient(colors:[Color(0xFF62432F),Color(0xFF38251D)],begin:Alignment.topLeft,end:Alignment.bottomRight)),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('YOUR EVENTS, UNDER CONTROL',style:TextStyle(color:Color(0xFFD9C9B6),fontSize:10,letterSpacing:1.7,fontWeight:FontWeight.bold)),
          const SizedBox(height:12),const Text('Every detail.\nBeautifully managed.',style:TextStyle(color:Colors.white,fontSize:27,height:1.15,fontWeight:FontWeight.w600)),
          const SizedBox(height:18),Row(children:[
            const Icon(Icons.calendar_month,color:Color(0xFFE6D9C8),size:17),const SizedBox(width:7),
            Text('${upcoming.length} upcoming events',style:const TextStyle(color:Color(0xFFE6D9C8),fontSize:12)),
            const Spacer(),TextButton(onPressed:()=>onNavigate(1),child:const Text('View events →',style:TextStyle(color:Colors.white))),
          ]),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 17, 18, 0),
        child: Row(children: [
          Expanded(child: _imageMoment(
            'Fresh moments',
            'https://images.unsplash.com/photo-1555244162-803834f70033?w=700&q=80',
          )),
          const SizedBox(width: 10),
          Expanded(child: _imageMoment(
            'Beautiful setups',
            'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?w=700&q=80',
          )),
        ]),
      ),
      Padding(padding:const EdgeInsets.fromLTRB(20,24,20,12),child:Row(children:[
        const Expanded(child:Text('Overview',style:TextStyle(color:coffee,fontSize:20,fontWeight:FontWeight.w700))),
        Text('Today • ${today()}',style:const TextStyle(color:muted,fontSize:11)),
      ])),
      Padding(padding:const EdgeInsets.symmetric(horizontal:18),child:GridView.count(
        crossAxisCount:2,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),mainAxisSpacing:10,crossAxisSpacing:10,childAspectRatio:1.55,
        children:[
          _stat('Events',events.length,Icons.event_available,olive),
          _stat('Staff',staff.length,Icons.groups_2,coffee),
          _stat('Expenses',money(total),Icons.payments,const Color(0xFF9B6844)),
          _stat('Upcoming',upcoming.length,Icons.upcoming,const Color(0xFF777B50)),
        ],
      )),
      Padding(padding:const EdgeInsets.fromLTRB(20,24,20,12),child:const Text('Quick access',style:TextStyle(color:coffee,fontSize:20,fontWeight:FontWeight.w700))),
      Padding(padding:const EdgeInsets.symmetric(horizontal:18),child:Row(children:[
        _quick('Add event',Icons.add_circle_outline,()=>onNavigate(1)),
        const SizedBox(width:9),_quick('Add staff',Icons.person_add_alt_1,()=>onNavigate(2)),
        const SizedBox(width:9),_quick('Add expense',Icons.receipt_long,()=>onNavigate(3)),
      ])),
      const SizedBox(height:28),
    ]);
  }
  Widget _imageMoment(String label, String url) => ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: SizedBox(
      height: 104,
      child: Stack(fit: StackFit.expand, children: [
        Image.network(url, fit: BoxFit.cover, errorBuilder: (context, error, stack) =>
          Container(color: const Color(0xFFE9E0D4), child: const Icon(Icons.restaurant, color: olive, size: 28))),
        Container(decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(.62)]),
        )),
        Positioned(left: 11, bottom: 10, child: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800))),
      ]),
    ),
  );
  Widget _stat(String label,dynamic value,IconData icon,Color color)=>panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
    Icon(icon,color:color,size:21),Text('$value',style:const TextStyle(color:coffee,fontSize:23,fontWeight:FontWeight.w800)),Text(label,style:const TextStyle(color:muted,fontSize:12)),
  ]),padding:const EdgeInsets.all(14));
  Widget _quick(String label,IconData icon,VoidCallback tap)=>Expanded(child:InkWell(onTap:tap,borderRadius:BorderRadius.circular(18),child:panel(padding:const EdgeInsets.symmetric(vertical:17,horizontal:8),child:Column(children:[
    Icon(icon,color:olive,size:22),const SizedBox(height:8),Text(label,textAlign:TextAlign.center,style:const TextStyle(color:coffee,fontSize:10,fontWeight:FontWeight.w600)),
  ]))));
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
        }),
    ]);
  }
}

class ExpensesPage extends StatelessWidget {
  final Map<String,dynamic> data; final ValueChanged<Map<String,dynamic>> onAdd;
  const ExpensesPage({super.key,required this.data,required this.onAdd});
  @override Widget build(BuildContext context) {
    final expenses=data['expenses'] as List;
    final total=expenses.fold<num>(0,(s,e)=>s+((e['amount'] as num?)??0));
    return Column(children:[
      PageTitle('Track spending','Expenses'),
      Padding(padding:const EdgeInsets.symmetric(horizontal:18),child:Container(width:double.infinity,padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:coffee,borderRadius:BorderRadius.circular(22)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('TOTAL RECORDED EXPENSES',style:TextStyle(color:Color(0xFFD9C9B6),fontSize:10,letterSpacing:1.5)),
        const SizedBox(height:8),Text(money(total),style:const TextStyle(color:Colors.white,fontSize:29,fontWeight:FontWeight.w800)),
      ]))),
      Padding(padding:const EdgeInsets.fromLTRB(18,16,18,10),child:Row(children:[
        const Expanded(child:Text('Recent expenses',style:TextStyle(color:coffee,fontSize:18,fontWeight:FontWeight.w700))),
        actionButton('Add',Icons.add,()=>_expenseDialog(context,onAdd)),
      ])),
      Expanded(child:expenses.isEmpty?_empty(Icons.receipt_long,'No expenses yet','Record staff, supplies, travel, fuel or other expenses.'):ListView.builder(
        padding:const EdgeInsets.symmetric(horizontal:18),itemCount:expenses.length,itemBuilder:(c,i){
          final e=expenses[i];return Padding(padding:const EdgeInsets.only(bottom:9),child:panel(child:Row(children:[
            CircleAvatar(backgroundColor:olive.withOpacity(.12),child:const Icon(Icons.receipt,color:olive,size:19)),
            const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(e['title']??'Expense',style:const TextStyle(color:coffee,fontWeight:FontWeight.w700)),
              Text('${e['category']??'Other'} • ${e['date']??''}',style:const TextStyle(color:muted,fontSize:11)),
            ])),
            Text(money(e['amount']),style:const TextStyle(color:coffee,fontWeight:FontWeight.w800)),
          ])));
        })),
    ]);
  }
}

class EquipmentPage extends StatelessWidget {
  final Map<String,dynamic> data; final VoidCallback onSave;
  const EquipmentPage({super.key,required this.data,required this.onSave});
  @override Widget build(BuildContext context) {
    final items=data['equipment'] as List;
    final checked=items.where((x)=>x['checked']==true).length;
    return Column(children:[
      PageTitle('Event preparation','Equipment'),
      Padding(padding:const EdgeInsets.symmetric(horizontal:18),child:panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[const Expanded(child:Text('Packing checklist',style:TextStyle(color:coffee,fontSize:17,fontWeight:FontWeight.w700))),Text('$checked / ${items.length}',style:const TextStyle(color:olive,fontWeight:FontWeight.w700))]),
        const SizedBox(height:12),ClipRRect(borderRadius:BorderRadius.circular(20),child:LinearProgressIndicator(value:items.isEmpty?0:checked/items.length,minHeight:7,color:olive,backgroundColor:cream)),
      ]))),
      const SizedBox(height:12),
      Expanded(child:ListView.builder(padding:const EdgeInsets.symmetric(horizontal:18),itemCount:items.length,itemBuilder:(c,i){
        final item=items[i];return Padding(padding:const EdgeInsets.only(bottom:8),child:panel(child:CheckboxListTile(
          contentPadding:EdgeInsets.zero,activeColor:olive,value:item['checked']==true,
          title:Text(item['name'],style:TextStyle(color:coffee,fontWeight:FontWeight.w600,decoration:item['checked']==true?TextDecoration.lineThrough:null)),
          onChanged:(v){item['checked']=v??false;onSave();},
        )));
      })),
    ]);
  }
}

Widget _empty(IconData icon,String title,String subtitle)=>Center(child:Padding(padding:const EdgeInsets.all(32),child:Column(mainAxisSize:MainAxisSize.min,children:[
  Icon(icon,color:olive.withOpacity(.55),size:48),const SizedBox(height:12),
  Text(title,style:const TextStyle(color:coffee,fontSize:17,fontWeight:FontWeight.w700)),
  const SizedBox(height:6),Text(subtitle,textAlign:TextAlign.center,style:const TextStyle(color:muted,fontSize:12)),
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
  const serviceOptions=['Juice','Samavar tea','Herbal tea','Snacks','Popcorn','Cotton candy','Balloon decoration','Other'];
  final selectedServices=<String>{};
  DateTime date=DateTime.now();
  TimeOfDay time=TimeOfDay.now();
  final notes=TextEditingController();
  await showDialog(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setD)=>AlertDialog(
    backgroundColor:cream,title:const Text('New event',style:TextStyle(color:coffee)),
    content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:name,decoration:const InputDecoration(hintText:'Event name')),
      const SizedBox(height:9),TextField(controller:location,decoration:const InputDecoration(hintText:'Venue / location')),
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
      onSubmit({'id':DateTime.now().microsecondsSinceEpoch.toString(),'name':name.text.trim(),'location':location.text.trim(),'services':selectedServices.join(', '),'date':date.toIso8601String().substring(0,10),'time':time.format(ctx),'notes':notes.text.trim(),'staffAssignments':[],'expenses':[],'equipment':_equipmentForServices(selectedServices)});
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
