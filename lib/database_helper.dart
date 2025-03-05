import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static const _databaseName = "CardDatabase.db";
  static const _databaseVersion = 1;
  
  // Folders table
  static const foldersTable = 'folders';
  static const folderId = '_id';
  static const folderName = 'name';
  static const folderTimestamp = 'timestamp';
  
  // Cards table
  static const cardsTable = 'cards';
  static const cardId = '_id';
  static const cardName = 'name';
  static const cardSuit = 'suit';
  static const cardImageUrl = 'image_url';
  static const cardFolderId = 'folder_id';
  
  late Database _db;

  Future<void> init() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    _db = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
    
    // Populate initial data
    await _populateInitialData();
  }

  Future _onCreate(Database db, int version) async {
    // Create folders table
    await db.execute('''
CREATE TABLE $foldersTable (
$folderId INTEGER PRIMARY KEY,
$folderName TEXT NOT NULL,
$folderTimestamp INTEGER NOT NULL
)
''');

    // Create cards table with foreign key
    await db.execute('''
CREATE TABLE $cardsTable (
$cardId INTEGER PRIMARY KEY,
$cardName TEXT NOT NULL,
$cardSuit TEXT NOT NULL,
$cardImageUrl TEXT NOT NULL,
$cardFolderId INTEGER NOT NULL,
FOREIGN KEY ($cardFolderId) REFERENCES $foldersTable ($folderId)
)
''');
  }

  Future<void> _populateInitialData() async {
    // Check if data already exists
    final folderCount = await queryFolderCount();
    if (folderCount > 0) return; // Data already populated

    // Insert default folders
    final folders = [
      {folderName: 'Hearts', folderTimestamp: DateTime.now().millisecondsSinceEpoch},
      {folderName: 'Spades', folderTimestamp: DateTime.now().millisecondsSinceEpoch},
      {folderName: 'Diamonds', folderTimestamp: DateTime.now().millisecondsSinceEpoch},
      {folderName: 'Clubs', folderTimestamp: DateTime.now().millisecondsSinceEpoch},
    ];

    for (var folder in folders) {
      await insertFolder(folder);
    }

    // Get folder IDs for reference
    final folderRows = await queryAllFolders();
    final folderIds = {
      'Hearts': folderRows.firstWhere((f) => f[folderName] == 'Hearts')[folderId],
      'Spades': folderRows.firstWhere((f) => f[folderName] == 'Spades')[folderId],
      'Diamonds': folderRows.firstWhere((f) => f[folderName] == 'Diamonds')[folderId],
      'Clubs': folderRows.firstWhere((f) => f[folderName] == 'Clubs')[folderId],
    };

    // Insert all cards
    final suits = ['Hearts', 'Spades', 'Diamonds', 'Clubs'];
    final cardNames = ['Ace', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'Jack', 'Queen', 'King'];

    for (var suit in suits) {
      for (var name in cardNames) {
        final card = {
          cardName: name,
          cardSuit: suit,
          cardImageUrl: '${name.toLowerCase()}_${suit.toLowerCase()}',
          cardFolderId: folderIds[suit],
        };
        await insertCard(card);
      }
    }
  }

  // Folder operations
  Future<int> insertFolder(Map<String, dynamic> folder) async {
    return await _db.insert(foldersTable, folder);
  }

  Future<List<Map<String, dynamic>>> queryAllFolders() async {
    return await _db.query(foldersTable);
  }

  Future<Map<String, dynamic>?> getFolder(int id) async {
    final results = await _db.query(
      foldersTable,
      where: '$folderId = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> queryFolderCount() async {
    final results = await _db.rawQuery('SELECT COUNT(*) FROM $foldersTable');
    return Sqflite.firstIntValue(results) ?? 0;
  }

  // Card operations
  Future<int> insertCard(Map<String, dynamic> card) async {
    return await _db.insert(cardsTable, card);
  }

  Future<List<Map<String, dynamic>>> queryAllCards() async {
    return await _db.query(cardsTable);
  }

  Future<List<Map<String, dynamic>>> getCardsByFolder(int folderId) async {
    return await _db.query(
      cardsTable,
      where: '$cardFolderId = ?',
      whereArgs: [folderId],
    );
  }

  Future<Map<String, dynamic>?> getCard(int id) async {
    final results = await _db.query(
      cardsTable,
      where: '$cardId = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  // Update operations
  Future<int> updateFolder(Map<String, dynamic> folder) async {
    int id = folder[folderId];
    return await _db.update(
      foldersTable,
      folder,
      where: '$folderId = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateCard(Map<String, dynamic> card) async {
    int id = card[cardId];
    return await _db.update(
      cardsTable,
      card,
      where: '$cardId = ?',
      whereArgs: [id],
    );
  }

  // Delete operations
  Future<int> deleteFolder(int id) async {
    return await _db.delete(
      foldersTable,
      where: '$folderId = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCard(int id) async {
    return await _db.delete(
      cardsTable,
      where: '$cardId = ?',
      whereArgs: [id],
    );
  }
}