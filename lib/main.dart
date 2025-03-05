import 'package:flutter/material.dart';
import 'database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dbHelper = DatabaseHelper();
  await dbHelper.init();
  runApp(MyApp(dbHelper));
}

class MyApp extends StatelessWidget {
  final DatabaseHelper dbHelper;

  MyApp(this.dbHelper);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DatabaseScreen(dbHelper: dbHelper),
    );
  }
}

class DatabaseScreen extends StatefulWidget {
  final DatabaseHelper dbHelper;

  DatabaseScreen({required this.dbHelper});

  @override
  _DatabaseScreenState createState() => _DatabaseScreenState();
}

class _DatabaseScreenState extends State<DatabaseScreen> {
  List<Map<String, dynamic>> records = [];
  TextEditingController nameController = TextEditingController();
  TextEditingController ageController = TextEditingController();

  void _refreshRecords() async {
    final data = await widget.dbHelper.queryAllRows();
    setState(() {
      records = data;
    });
  }

  @override
  void initState() {
    super.initState();
    _refreshRecords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Flutter Database App')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: ageController,
              decoration: InputDecoration(labelText: 'Age'),
              keyboardType: TextInputType.number,
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text;
                final age = int.tryParse(ageController.text) ?? 0;
                if (name.isNotEmpty && age > 0) {
                  await widget.dbHelper.insert({
                    DatabaseHelper.columnName: name,
                    DatabaseHelper.columnAge: age,
                  });
                  _refreshRecords();
                }
              },
              child: Text('Record Entry'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final record = records[index];
                  return ListTile(
                    title: Text("${record['name']} (Age: ${record['age']})"),
                    subtitle: Text("ID: ${record['_id']}"),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () async {
                        await widget.dbHelper.delete(record['_id']);
                        _refreshRecords();
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}