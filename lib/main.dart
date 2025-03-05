import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'database_helper.dart';

// Card icons mapping
final Map<String, IconData> suitIcons = {
  'hearts': Icons.favorite,
  'spades': Icons.arrow_downward,
  'diamonds': Icons.diamond,
  'clubs': Icons.circle,
};

final Map<String, String> cardValues = {
  'ace': 'A',
  '2': '2',
  '3': '3',
  '4': '4',
  '5': '5',
  '6': '6',
  '7': '7',
  '8': '8',
  '9': '9',
  '10': '10',
  'jack': 'J',
  'queen': 'Q',
  'king': 'K',
};

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize FFI for desktop
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  
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
      title: 'Card Organizer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(dbHelper: dbHelper),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final DatabaseHelper dbHelper;

  HomeScreen({required this.dbHelper});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> folders = [];
  List<Map<String, dynamic>> cards = [];

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    final foldersData = await widget.dbHelper.queryAllFolders();
    final cardsData = await widget.dbHelper.queryAllCards();
    setState(() {
      folders = foldersData;
      cards = cardsData;
    });
  }

  Widget _buildCardWidget(Map<String, dynamic> card) {
    final suit = card[DatabaseHelper.cardSuit].toString().toLowerCase();
    final name = card[DatabaseHelper.cardName].toString().toLowerCase();
    
    return Card(
      child: InkWell(
        onTap: () {
          // Show card details
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      suitIcons[suit] ?? Icons.help_outline,
                      size: 40,
                      color: (suit == 'hearts' || suit == 'diamonds') ? Colors.red : Colors.black,
                    ),
                    SizedBox(height: 8),
                    Text(
                      cardValues[name] ?? name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: (suit == 'hearts' || suit == 'diamonds') ? Colors.red : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                '${card[DatabaseHelper.cardName]} of ${card[DatabaseHelper.cardSuit]}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Card Organizer'),
      ),
      body: Column(
        children: [
          // Folders section
          Container(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: folders.length,
              itemBuilder: (context, index) {
                final folder = folders[index];
                return Card(
                  margin: EdgeInsets.all(8),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FolderDetailScreen(
                            dbHelper: widget.dbHelper,
                            folder: folder,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 150,
                      padding: EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            suitIcons[folder[DatabaseHelper.folderName].toString().toLowerCase()] ?? Icons.folder,
                            size: 40,
                            color: (folder[DatabaseHelper.folderName].toString().toLowerCase() == 'hearts' || 
                                   folder[DatabaseHelper.folderName].toString().toLowerCase() == 'diamonds') 
                                   ? Colors.red : Colors.black,
                          ),
                          SizedBox(height: 8),
                          Text(
                            folder[DatabaseHelper.folderName],
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Divider(),
          // Cards section
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.7,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: cards.length,
              itemBuilder: (context, index) => _buildCardWidget(cards[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class FolderDetailScreen extends StatefulWidget {
  final DatabaseHelper dbHelper;
  final Map<String, dynamic> folder;

  FolderDetailScreen({
    required this.dbHelper,
    required this.folder,
  });

  @override
  _FolderDetailScreenState createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends State<FolderDetailScreen> {
  List<Map<String, dynamic>> cards = [];

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final cardsData = await widget.dbHelper.getCardsByFolder(widget.folder[DatabaseHelper.folderId]);
    setState(() {
      cards = cardsData;
    });
  }

  Widget _buildCardWidget(Map<String, dynamic> card) {
    final suit = card[DatabaseHelper.cardSuit].toString().toLowerCase();
    final name = card[DatabaseHelper.cardName].toString().toLowerCase();
    
    return Card(
      child: InkWell(
        onTap: () {
          // Show card details
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      suitIcons[suit] ?? Icons.help_outline,
                      size: 40,
                      color: (suit == 'hearts' || suit == 'diamonds') ? Colors.red : Colors.black,
                    ),
                    SizedBox(height: 8),
                    Text(
                      cardValues[name] ?? name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: (suit == 'hearts' || suit == 'diamonds') ? Colors.red : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                '${card[DatabaseHelper.cardName]} of ${card[DatabaseHelper.cardSuit]}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.folder[DatabaseHelper.folderName]} Cards'),
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.7,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: cards.length,
        itemBuilder: (context, index) => _buildCardWidget(cards[index]),
      ),
    );
  }
}