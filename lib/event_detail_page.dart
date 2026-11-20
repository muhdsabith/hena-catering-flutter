import 'package:flutter/material.dart';

const _coffee = Color(0xFF20251F);
const _olive = Color(0xFF244438);
const _muted = Color(0xFF77786F);
const _cream = Color(0xFFF5F3ED);
const _gold = Color(0xFFB6945A);
const _surface = Color(0xFFFFFEFA);

class EventDetailPage extends StatefulWidget {
  final Map<String, dynamic> event;
  final List<Map<String, dynamic>> staff;
  final VoidCallback onBack;
  final ValueChanged<Map<String, dynamic>> onUpdate;
  final VoidCallback onDelete;
  const EventDetailPage({super.key, required this.event, required this.staff, required this.onBack, required this.onUpdate, required this.onDelete});
  @override State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  static const roles = ['Juicier','Samavar tea maker','Samavar helper','Herbal tea maker','Popcorn and Cotton Candy maker','Snack maker','Boys','Juice helper'];
  static const categories = ['Staff','Supplies','Travel','Fuel','Food','Equipment','Other'];
  late Map<String,dynamic> event;
  @override void initState() { super.initState(); event = Map<String,dynamic>.from(widget.event); event.putIfAbsent('staffAssignments', () => []); event.putIfAbsent('expenses', () => []); event.putIfAbsent('equipment', () => []); }
  List<Map<String,dynamic>> get assignments => (event['staffAssignments'] as List).cast<Map<String,dynamic>>();
  List<Map<String,dynamic>> get expenses => (event['expenses'] as List).cast<Map<String,dynamic>>();
  List<Map<String,dynamic>> get equipment => (event['equipment'] as List).cast<Map<String,dynamic>>();
  void patch(String key, dynamic value) { setState(() => event[key] = value); widget.onUpdate(event); }
  String money(dynamic n) => '₹' + ((n is num ? n : 0).toStringAsFixed(0));
  num get wageTotal => assignments.where((a) => a['attended'] == true).fold<num>(0, (n,a) => n + ((a['wage'] as num?) ?? 0));
  num get expenseTotal => expenses.fold<num>(0, (n,e) => n + ((e['amount'] as num?) ?? 0));

  @override Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
    children: [
      Row(children: [
        Expanded(child: Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back, color: _coffee), label: const Text('All events', style: TextStyle(color: _coffee))))),
        TextButton.icon(onPressed: () async {
          final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
            title: const Text('Delete event?'),
            content: const Text('This will delete this event and its records.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
            ],
          ));
          if (confirm == true) widget.onDelete();
        }, icon: const Icon(Icons.delete_outline, color: Colors.redAccent), label: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
      ]),
      _panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.calendar_today_outlined, size: 14, color: _olive),
          const SizedBox(width: 7),
          Text((event['date'] ?? '').toString(), style: const TextStyle(color: _olive, fontWeight: FontWeight.w800, fontSize: 11)),
          if ((event['time'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(width: 12),
            const Icon(Icons.schedule_rounded, size: 14, color: _olive),
            const SizedBox(width: 5),
            Text(event['time'].toString(), style: const TextStyle(color: _olive, fontWeight: FontWeight.w700, fontSize: 11)),
          ],
        ]),
        const SizedBox(height: 5), Text(event['name'] ?? 'Event', style: const TextStyle(color: _coffee, fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.location_on_outlined, size: 16, color: _muted), const SizedBox(width: 5), Expanded(child: Text(event['location'] ?? 'Location not added', style: const TextStyle(color: _muted, fontSize: 12)))]),
        if ((event['services'] ?? '').toString().isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 6, runSpacing: 6, children: (event['services'] as String).split(', ').map((service) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: _olive.withOpacity(.09), borderRadius: BorderRadius.circular(8)), child: Text(service, style: const TextStyle(color: _olive, fontSize: 10, fontWeight: FontWeight.w700)))).toList()),
        ],
        if ((event['notes'] ?? '').toString().trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _cream, borderRadius: BorderRadius.circular(14)), child: Text(event['notes'].toString(), style: const TextStyle(color: _coffee, fontSize: 12, height: 1.45))),
        ],
      ])),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _metric('Staff present', assignments.where((a) => a['attended'] == true).length.toString())),
        const SizedBox(width: 8), Expanded(child: _metric('Staff wages', money(wageTotal))),
        const SizedBox(width: 8), Expanded(child: _metric('Expenses', money(expenseTotal))),
      ]),
      const SizedBox(height: 20),
      _heading('Staff & wages', 'Assign staff, roles, attendance and payments'),
      if (assignments.isEmpty) const Text('No staff assigned yet.', style: TextStyle(color: _muted)),
      ...assignments.map(_assignmentTile),
      const SizedBox(height: 8),
      _action('Assign staff', Icons.person_add_alt_1, _addAssignment),
      const SizedBox(height: 20),
      _heading('Equipment checklist', 'Track taken, returned, damaged and missing'),
      if (equipment.isEmpty) const Text('No equipment items. Select services when creating the event.', style: TextStyle(color: _muted)),
      ...equipment.map(_equipmentTile),
      const SizedBox(height: 20),
      _heading('Event expenses', 'Staff, supplies, travel, fuel, food and other costs'),
      if (expenses.isEmpty) const Text('No event expenses recorded.', style: TextStyle(color: _muted)),
      ...expenses.map((e) => _panel(Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(e['title'] ?? 'Expense', style: const TextStyle(color: _coffee, fontWeight: FontWeight.w700)),
          Text((e['category'] ?? 'Other').toString() + ' · ' + (e['date'] ?? '').toString(), style: const TextStyle(color: _muted, fontSize: 11)),
        ])),
        Text(money(e['amount']), style: const TextStyle(color: _coffee, fontWeight: FontWeight.w800)),
        IconButton(onPressed: () => patch('expenses', expenses.where((x) => x['id'] != e['id']).toList()), icon: const Icon(Icons.close, color: _muted)),
      ]))),
      const SizedBox(height: 8),
      _action('Add expense', Icons.add, _addExpense),
    ],
  );

  Widget _panel(Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0xFFE8E3D8), width: .8),
      boxShadow: [BoxShadow(color: _coffee.withOpacity(.035), blurRadius: 14, offset: const Offset(0, 4))],
    ),
    child: child,
  );
  Widget _metric(String label, String value) => _panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(color: _coffee, fontWeight: FontWeight.w800, fontSize: 16)), Text(label, style: const TextStyle(color: _muted, fontSize: 10, height: 1.35))]));
  Widget _heading(String title, String subtitle) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: _coffee, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -.3)), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(color: _muted, fontSize: 11, height: 1.4))]));
  Widget _action(String label, IconData icon, VoidCallback onTap) => SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: onTap, icon: Icon(icon, color: _olive), label: Text(label, style: const TextStyle(color: _olive)), style: OutlinedButton.styleFrom(side: const BorderSide(color: _olive), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.all(13))));
  Widget _assignmentTile(Map<String,dynamic> a) {
    final person = widget.staff.firstWhere((p) => p['id'] == a['staffId'], orElse: () => {'name':'Removed staff'});
    final wage = (a['wage'] as num?) ?? 0;
    final advance = (a['advance'] as num?) ?? 0;
    return _panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text(person['name'] ?? 'Staff', style: const TextStyle(color: _coffee, fontWeight: FontWeight.w800))), IconButton(onPressed: () => patch('staffAssignments', assignments.where((x) => x['id'] != a['id']).toList()), icon: const Icon(Icons.close, color: _muted))]),
      Text(a['role'] ?? 'Role not selected', style: const TextStyle(color: _olive, fontSize: 12, fontWeight: FontWeight.w700)),
      if ((a['work'] ?? '').toString().isNotEmpty) Text('Work: ' + a['work'].toString(), style: const TextStyle(color: _muted, fontSize: 11)),
      SwitchListTile(contentPadding: EdgeInsets.zero, activeColor: _olive, title: const Text('Present', style: TextStyle(color: _coffee, fontSize: 12)), value: a['attended'] == true, onChanged: (v) => patch('staffAssignments', assignments.map((x) => x['id'] == a['id'] ? {...x,'attended':v} : x).toList())),
      if (a['workCompleted'] == true || (a['workCompleted'] == null && wage > 0)) ...[
        Row(children: [
          Expanded(child: _editNumber('Final wage ₹', wage, (v) => _patchAssignment(a,'wage',v))),
          const SizedBox(width: 8), Expanded(child: _editNumber('Advance ₹', advance, (v) => _patchAssignment(a,'advance',v))),
        ]),
        Align(alignment: Alignment.centerRight, child: Text('Balance: ' + money(wage - advance), style: const TextStyle(color: _olive, fontWeight: FontWeight.w800))),
        Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () => _completeAssignment(a), icon: const Icon(Icons.edit_outlined, size: 16), label: const Text('Update final payment'))),
      ] else ...[
        SizedBox(width: double.infinity, child: OutlinedButton.icon(
          onPressed: () => _completeAssignment(a),
          icon: const Icon(Icons.task_alt, size: 18),
          label: const Text('Mark work completed & add wage'),
          style: OutlinedButton.styleFrom(foregroundColor: _olive, side: const BorderSide(color: _olive)),
        )),
      ],
    ]));
  }
  Widget _editNumber(String label, num value, ValueChanged<num> changed) => TextFormField(initialValue: value.toString(), keyboardType: TextInputType.number, decoration: InputDecoration(labelText: label, isDense: true), onChanged: (v) { final n = num.tryParse(v); if (n != null) changed(n); });
  void _patchAssignment(Map<String,dynamic> a, String key, num value) => patch('staffAssignments', assignments.map((x) => x['id'] == a['id'] ? {...x,key:value} : x).toList());
  Future<void> _completeAssignment(Map<String,dynamic> assignment) async {
    final wage = TextEditingController(text: ((assignment['wage'] as num?) ?? 0).toString());
    final advance = TextEditingController(text: ((assignment['advance'] as num?) ?? 0).toString());
    final result = await showDialog<List<num>>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: _surface,
      title: const Text('Work completed', style: TextStyle(color: _coffee)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Enter the final wage and any advance already paid.', style: TextStyle(color: _muted, fontSize: 12)),
        const SizedBox(height: 12),
        TextField(controller: wage, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Final wage ₹')),
        const SizedBox(height: 8),
        TextField(controller: advance, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Advance paid ₹')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () {
          final w = num.tryParse(wage.text.trim());
          final a = num.tryParse(advance.text.trim());
          if (w == null || a == null || w < 0 || a < 0) return;
          Navigator.pop(ctx, [w, a]);
        }, child: const Text('Save payment')),
      ],
    ));
    if (result == null) return;
    patch('staffAssignments', assignments.map((x) => x['id'] == assignment['id'] ? {...x, 'workCompleted': true, 'wage': result[0], 'advance': result[1]} : x).toList());
  }

  Widget _equipmentTile(Map<String,dynamic> item) {
    final planned = (item['planned'] as num?) ?? 0;
    final returned = (item['returned'] as num?) ?? 0;
    final damaged = (item['damaged'] as num?) ?? 0;
    return _panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(item['name'] ?? 'Equipment', style: const TextStyle(color: _coffee, fontWeight: FontWeight.w700)),
      Text(item['category'] ?? 'Equipment', style: const TextStyle(color: _muted, fontSize: 10)),
      Row(children: [
        Expanded(child: _editNumber('Take', planned, (v) => _patchEquipment(item,'planned',v))),
        const SizedBox(width: 7), Expanded(child: _editNumber('Returned', returned, (v) => _patchEquipment(item,'returned',v))),
        const SizedBox(width: 7), Expanded(child: _editNumber('Damaged', damaged, (v) => _patchEquipment(item,'damaged',v))),
      ]),
      Align(alignment: Alignment.centerRight, child: Text('Missing: ' + (planned - returned - damaged).clamp(0,999999).toString(), style: const TextStyle(color: _olive, fontWeight: FontWeight.w800))),
    ]));
  }
  void _patchEquipment(Map<String,dynamic> item, String key, num value) => patch('equipment', equipment.map((x) => x['id'] == item['id'] ? {...x,key:value} : x).toList());

  Future<void> _addAssignment() async {
    if (widget.staff.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add staff members first.'))); return; }
    String? staffId; String role = roles.first;
    final work = TextEditingController();
    await showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx,setD) => AlertDialog(
      backgroundColor: _surface, title: const Text('Assign staff', style: TextStyle(color: _coffee)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(value: staffId, decoration: const InputDecoration(labelText: 'Staff member'), items: widget.staff.map((p) => DropdownMenuItem(value: p['id'].toString(), child: Text(p['name'] ?? ''))).toList(), onChanged: (v) => setD(() => staffId = v)),
        const SizedBox(height: 8), DropdownButtonFormField<String>(value: role, decoration: const InputDecoration(labelText: 'Event role'), items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(), onChanged: (v) => setD(() => role = v ?? roles.first)),
        const SizedBox(height: 8), TextField(controller: work, decoration: const InputDecoration(labelText: 'Work / duty assigned')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: () { if (staffId == null) return; patch('staffAssignments', [...assignments, {'id':DateTime.now().microsecondsSinceEpoch.toString(),'staffId':staffId,'role':role,'wage':0,'advance':0,'work':work.text.trim(),'attended':true,'workCompleted':false}]); Navigator.pop(ctx); }, child: const Text('Assign'))],
    )));
  }
  Future<void> _addExpense() async {
    final title = TextEditingController(); final amount = TextEditingController();
    String category = 'Staff'; String? staffId;
    await showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx,setD) => AlertDialog(
      backgroundColor: _cream, title: const Text('Add event expense', style: TextStyle(color: _coffee)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(value: category, decoration: const InputDecoration(labelText: 'Category'), items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) => setD(() => category = v ?? 'Other')),
        const SizedBox(height: 8), TextField(controller: title, decoration: const InputDecoration(labelText: 'Description')),
        const SizedBox(height: 8), TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount ₹')),
        if (widget.staff.isNotEmpty && category == 'Staff') ...[
          const SizedBox(height: 8), DropdownButtonFormField<String>(value: staffId, decoration: const InputDecoration(labelText: 'Staff (optional)'), items: widget.staff.map((p) => DropdownMenuItem(value: p['id'].toString(), child: Text(p['name'] ?? ''))).toList(), onChanged: (v) => setD(() => staffId = v)),
        ],
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: () { final n = num.tryParse(amount.text); if (title.text.trim().isEmpty || n == null) return; patch('expenses', [...expenses, {'id':DateTime.now().microsecondsSinceEpoch.toString(),'title':title.text.trim(),'category':category,'amount':n,'date':DateTime.now().toIso8601String().substring(0,10),'staffId':staffId}]); Navigator.pop(ctx); }, child: const Text('Save'))],
    )));
  }
}
