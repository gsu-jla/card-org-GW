import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' show Platform;
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
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
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
      home: FoldersScreen(dbHelper: dbHelper),
    );
  }
}

class FoldersScreen extends StatefulWidget {
  final DatabaseHelper dbHelper;

  FoldersScreen({required this.dbHelper});

  @override
  _FoldersScreenState createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  List<Map<String, dynamic>> folders = [];
  Map<int, int> cardCounts = {};
  Map<int, Map<String, dynamic>> previewCards = {};

  // Available suits for new folders
  final List<String> availableSuits = ['Hearts', 'Spades', 'Diamonds', 'Clubs'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final foldersData = await widget.dbHelper.queryAllFolders();
    setState(() {
      folders = foldersData;
    });

    // Load card counts and preview cards for each folder
    for (var folder in folders) {
      final folderId = folder[DatabaseHelper.folderId];
      final cards = await widget.dbHelper.getCardsByFolder(folderId);
      
      setState(() {
        cardCounts[folderId] = cards.length;
        if (cards.isNotEmpty) {
          previewCards[folderId] = cards.first;
        }
      });
    }
  }

  Widget _buildFolderCard(Map<String, dynamic> folder) {
    final folderId = folder[DatabaseHelper.folderId];
    final previewCard = previewCards[folderId];
    final cardCount = cardCounts[folderId] ?? 0;

    return Card(
      margin: EdgeInsets.all(8),
      child: Stack(
        children: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CardsScreen(
                    dbHelper: widget.dbHelper,
                    folder: folder,
                  ),
                ),
              );
            },
            child: Container(
              width: 200,
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Preview card
                  if (previewCard != null)
                    Container(
                      height: 100,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getSuitIcon(previewCard[DatabaseHelper.cardSuit]),
                              size: 40,
                              color: _getSuitColor(previewCard[DatabaseHelper.cardSuit]),
                            ),
                            Text(
                              previewCard[DatabaseHelper.cardName],
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _getSuitColor(previewCard[DatabaseHelper.cardSuit]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(height: 8),
                  // Folder name and card count
                  Text(
                    folder[DatabaseHelper.folderName],
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$cardCount cards',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteFolderConfirmation(folder),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteFolderConfirmation(Map<String, dynamic> folder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Folder'),
        content: Text('Are you sure you want to delete this folder and all its cards?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await widget.dbHelper.deleteFolder(folder[DatabaseHelper.folderId]);
              Navigator.pop(context);
              _loadData();
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  IconData _getSuitIcon(String suit) {
    switch (suit.toLowerCase()) {
      case 'hearts':
        return Icons.favorite;
      case 'spades':
        return Icons.arrow_downward;
      case 'diamonds':
        return Icons.diamond;
      case 'clubs':
        return Icons.circle;
      default:
        return Icons.help_outline;
    }
  }

  Color _getSuitColor(String suit) {
    switch (suit.toLowerCase()) {
      case 'hearts':
      case 'diamonds':
        return Colors.red;
      case 'spades':
      case 'clubs':
        return Colors.black;
      default:
        return Colors.grey;
    }
  }

  void _showAddFolderDialog() {
    String selectedSuit = availableSuits.first;
    
    // Check which suits are already used
    final existingSuits = folders.map((f) => f[DatabaseHelper.folderName] as String).toSet();
    final availableSuitsFiltered = availableSuits.where((suit) => !existingSuits.contains(suit)).toList();
    
    if (availableSuitsFiltered.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Cannot Create Folder'),
          content: Text('All suit folders have already been created.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    
    selectedSuit = availableSuitsFiltered.first;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Create New Folder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedSuit,
                decoration: InputDecoration(labelText: 'Select Suit'),
                items: availableSuitsFiltered.map((suit) {
                  return DropdownMenuItem(
                    value: suit,
                    child: Row(
                      children: [
                        Icon(
                          _getSuitIcon(suit),
                          color: _getSuitColor(suit),
                        ),
                        SizedBox(width: 8),
                        Text(suit),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedSuit = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await widget.dbHelper.insertFolder({
                  DatabaseHelper.folderName: selectedSuit,
                  DatabaseHelper.folderTimestamp: DateTime.now().toIso8601String(),
                });
                Navigator.pop(context);
                _loadData();
              },
              child: Text('Create'),
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
        title: Text('Card Folders'),
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: folders.length,
        itemBuilder: (context, index) => _buildFolderCard(folders[index]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFolderDialog,
        child: Icon(Icons.create_new_folder),
      ),
    );
  }
}

class CardsScreen extends StatefulWidget {
  final DatabaseHelper dbHelper;
  final Map<String, dynamic> folder;

  CardsScreen({
    required this.dbHelper,
    required this.folder,
  });

  @override
  _CardsScreenState createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  List<Map<String, dynamic>> cards = [];
  final TextEditingController nameController = TextEditingController();
  final TextEditingController suitController = TextEditingController();

  // Add constants for card limits
  static const int MIN_CARDS = 3;
  static const int MAX_CARDS = 6;

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

    // Check minimum card count after loading
    if (cards.length < MIN_CARDS) {
      _showWarningDialog("You need at least 3 cards in this folder.");
    }
  }

  void _showWarningDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Warning'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAddCardDialog() {
    // Check maximum card count before showing add dialog
    if (cards.length >= MAX_CARDS) {
      _showWarningDialog("This folder can only hold 6 cards.");
      return;
    }

    nameController.clear();
    suitController.text = widget.folder[DatabaseHelper.folderName];
    
    // Create a list of available cards
    final availableCards = [
      'Ace', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'Jack', 'Queen', 'King'
    ];
    
    String selectedCard = availableCards.first;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add New Card'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedCard,
                decoration: InputDecoration(labelText: 'Select Card'),
                items: availableCards.map((card) {
                  return DropdownMenuItem(
                    value: card,
                    child: Text('$card of ${widget.folder[DatabaseHelper.folderName]}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCard = value!;
                  });
                },
              ),
              SizedBox(height: 16),
              Text(
                'Suit: ${widget.folder[DatabaseHelper.folderName]}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
                      onPressed: () async {
                await widget.dbHelper.insertCard({
                  DatabaseHelper.cardName: selectedCard,
                  DatabaseHelper.cardSuit: widget.folder[DatabaseHelper.folderName],
                  DatabaseHelper.cardImageUrl: '${selectedCard.toLowerCase()}_of_${widget.folder[DatabaseHelper.folderName].toLowerCase()}',
                  DatabaseHelper.cardFolderId: widget.folder[DatabaseHelper.folderId],
                });
                Navigator.pop(context);
                _loadCards();
              },
              child: Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardWidget(Map<String, dynamic> card) {
    return Card(
      child: InkWell(
        onTap: () => _showEditCardDialog(card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getSuitIcon(card[DatabaseHelper.cardSuit]),
                      size: 40,
                      color: _getSuitColor(card[DatabaseHelper.cardSuit]),
                    ),
                    SizedBox(height: 8),
                    Text(
                      card[DatabaseHelper.cardName],
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getSuitColor(card[DatabaseHelper.cardSuit]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${card[DatabaseHelper.cardName]} of ${card[DatabaseHelper.cardSuit]}',
                    style: TextStyle(fontSize: 12),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, size: 20),
                    onPressed: () => _showDeleteConfirmation(card),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCardDialog(Map<String, dynamic> card) {
    nameController.text = card[DatabaseHelper.cardName];
    suitController.text = card[DatabaseHelper.cardSuit];
    
    // Create a list of available cards
    final availableCards = [
      'Ace', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'Jack', 'Queen', 'King'
    ];
    
    String selectedCard = card[DatabaseHelper.cardName];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Edit Card'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedCard,
                decoration: InputDecoration(labelText: 'Select Card'),
                items: availableCards.map((card) {
                  return DropdownMenuItem(
                    value: card,
                    child: Text('$card of ${widget.folder[DatabaseHelper.folderName]}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCard = value!;
                  });
                },
              ),
              SizedBox(height: 16),
              Text(
                'Suit: ${widget.folder[DatabaseHelper.folderName]}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await widget.dbHelper.updateCard({
                  DatabaseHelper.cardId: card[DatabaseHelper.cardId],
                  DatabaseHelper.cardName: selectedCard,
                  DatabaseHelper.cardSuit: widget.folder[DatabaseHelper.folderName],
                  DatabaseHelper.cardImageUrl: '${selectedCard.toLowerCase()}_of_${widget.folder[DatabaseHelper.folderName].toLowerCase()}',
                  DatabaseHelper.cardFolderId: widget.folder[DatabaseHelper.folderId],
                });
                Navigator.pop(context);
                _loadCards();
              },
              child: Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> card) {
    // Check if deletion would violate minimum card count
    if (cards.length <= MIN_CARDS) {
      _showWarningDialog("You need at least 3 cards in this folder.");
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Card'),
        content: Text('Are you sure you want to delete this card?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await widget.dbHelper.deleteCard(card[DatabaseHelper.cardId]);
              Navigator.pop(context);
              _loadCards();
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  IconData _getSuitIcon(String suit) {
    switch (suit.toLowerCase()) {
      case 'hearts':
        return Icons.favorite;
      case 'spades':
        return Icons.arrow_downward;
      case 'diamonds':
        return Icons.diamond;
      case 'clubs':
        return Icons.circle;
      default:
        return Icons.help_outline;
    }
  }

  Color _getSuitColor(String suit) {
    switch (suit.toLowerCase()) {
      case 'hearts':
      case 'diamonds':
        return Colors.red;
      case 'spades':
      case 'clubs':
        return Colors.black;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.folder[DatabaseHelper.folderName]} Cards'),
        actions: [
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${cards.length}/${MAX_CARDS} cards',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCardDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}