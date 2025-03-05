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
    await _populateInitialData();
  }

  Future _onCreate(Database db, int version) async {
    // Create folders table
    await db.execute('''
      CREATE TABLE $foldersTable (
        $folderId INTEGER PRIMARY KEY,
        $folderName TEXT NOT NULL,
        $folderTimestamp TEXT NOT NULL
      )
    ''');

    // Create cards table
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
    // Check if folders already exist
    final folders = await queryAllFolders();
    if (folders.isEmpty) {
      // Create default folders
      final defaultFolders = ['Hearts', 'Spades', 'Diamonds', 'Clubs'];
      for (var folderName in defaultFolders) {
        await insertFolder({
          folderName: folderName,
          folderTimestamp: DateTime.now().toIso8601String(),
        });
      }

      // Get the folder IDs
      final folderMap = {
        for (var folder in await queryAllFolders())
          folder[folderName]: folder[folderId]
      };

      // Populate cards for each folder
      final cardValues = [
        'Ace', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'Jack', 'Queen', 'King'
      ];

      for (var folderName in defaultFolders) {
        final folderId = folderMap[folderName];
        for (var value in cardValues) {
          await insertCard({
            cardName: value,
            cardSuit: folderName,
            cardImageUrl: '${value.toLowerCase()}_of_${folderName.toLowerCase()}',
            cardFolderId: folderId,
          });
        }
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
    final List<Map<String, dynamic>> maps = await _db.query(
      foldersTable,
      where: '$folderId = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<int> updateFolder(Map<String, dynamic> folder) async {
    int id = folder[folderId];
    return await _db.update(
      foldersTable,
      folder,
      where: '$folderId = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteFolder(int id) async {
    return await _db.delete(
      foldersTable,
      where: '$folderId = ?',
      whereArgs: [id],
    );
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
    final List<Map<String, dynamic>> maps = await _db.query(
      cardsTable,
      where: '$cardId = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
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

  Future<int> deleteCard(int id) async {
    return await _db.delete(
      cardsTable,
      where: '$cardId = ?',
      whereArgs: [id],
    );
  }
}