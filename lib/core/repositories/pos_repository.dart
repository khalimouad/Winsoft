import '../database/database_helper.dart';
import '../models/pos_sale.dart';

class PosRepository {
  final _db = DatabaseHelper.instance;

  // ── Price lists ────────────────────────────────────────────────────────────

  Future<List<PriceList>> getAllPriceLists() async {
    final rows = await _db.query('price_lists', orderBy: 'name ASC');
    final lists = <PriceList>[];
    for (final row in rows) {
      final id = row['id'] as int;
      final items = await _getPriceListItems(id);
      lists.add(PriceList.fromMap(row, items: items));
    }
    return lists;
  }

  Future<List<PriceListItem>> _getPriceListItems(int priceListId) async {
    final rows = await _db.rawQuery('''
      SELECT pli.*, p.name AS product_name
      FROM price_list_items pli
      JOIN products p ON pli.product_id = p.id
      WHERE pli.price_list_id = ?
    ''', [priceListId]);
    return rows.map(PriceListItem.fromMap).toList();
  }

  Future<int> insertPriceList(PriceList pl) async {
    final db = await _db.database;
    return db.transaction((txn) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final map = pl.toMap();
      map['created_at'] = now;
      map.remove('id');
      final id = await txn.insert('price_lists', map);
      for (final item in pl.items) {
        final im = item.toMap();
        im['price_list_id'] = id;
        im.remove('id');
        await txn.insert('price_list_items', im);
      }
      return id;
    });
  }

  Future<void> deletePriceList(int id) async =>
      _db.delete('price_lists', id);

  // ── Sessions ───────────────────────────────────────────────────────────────

  Future<PosSession?> getOpenSession() async {
    final rows = await _db.rawQuery('''
      SELECT ps.*, u.name AS user_name
      FROM pos_sessions ps
      JOIN users u ON ps.user_id = u.id
      WHERE ps.status = 'open'
      ORDER BY ps.opened_at DESC
      LIMIT 1
    ''', []);
    if (rows.isEmpty) return null;
    return PosSession.fromMap(rows.first);
  }

  Future<List<PosSession>> getAllSessions() async {
    final rows = await _db.rawQuery('''
      SELECT ps.*, u.name AS user_name
      FROM pos_sessions ps
      JOIN users u ON ps.user_id = u.id
      ORDER BY ps.opened_at DESC
    ''', []);
    return rows.map(PosSession.fromMap).toList();
  }

  Future<int> openSession(int userId, double openingCash) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _db.insert('pos_sessions', {
      'opened_at': now,
      'opening_cash': openingCash,
      'status': 'open',
      'user_id': userId,
    });
  }

  Future<void> closeSession(int sessionId, double closingCash) async {
    final db = await _db.database;
    await db.update(
      'pos_sessions',
      {
        'closed_at': DateTime.now().millisecondsSinceEpoch,
        'closing_cash': closingCash,
        'status': 'closed',
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  // ── Sales ──────────────────────────────────────────────────────────────────

  Future<List<PosSale>> getSales({int? sessionId, int? limit}) async {
    final conds = <String>[];
    final args = <Object?>[];
    if (sessionId != null) {
      conds.add('ps.session_id = ?');
      args.add(sessionId);
    }
    final where = conds.isEmpty ? '' : 'WHERE ${conds.join(' AND ')}';
    final limitClause = limit != null ? 'LIMIT $limit' : '';
    final rows = await _db.rawQuery('''
      SELECT ps.*, c.name AS client_name
      FROM pos_sales ps
      LEFT JOIN clients c ON ps.client_id = c.id
      $where
      ORDER BY ps.sale_date DESC
      $limitClause
    ''', args);
    return rows.map((r) => PosSale.fromMap(r)).toList();
  }

  Future<PosSale?> getSaleById(int id) async {
    final rows = await _db.rawQuery('''
      SELECT ps.*, c.name AS client_name
      FROM pos_sales ps
      LEFT JOIN clients c ON ps.client_id = c.id
      WHERE ps.id = ?
    ''', [id]);
    if (rows.isEmpty) return null;
    final items = await _db.rawQuery('''
      SELECT psi.*, p.name AS product_name
      FROM pos_sale_items psi
      JOIN products p ON psi.product_id = p.id
      WHERE psi.sale_id = ?
    ''', [id]);
    return PosSale.fromMap(rows.first,
        items: items.map(PosSaleItem.fromMap).toList());
  }

  Future<int> insertSale(PosSale sale) async {
    final db = await _db.database;
    return db.transaction((txn) async {
      final map = sale.toMap();
      map.remove('id');
      final id = await txn.insert('pos_sales', map);
      for (final item in sale.items) {
        final im = item.toMap();
        im['sale_id'] = id;
        im.remove('id');
        await txn.insert('pos_sale_items', im);
      }
      return id;
    });
  }

  Future<int> nextSequence() async {
    final val = await _db.rawQueryScalar(
        'SELECT COUNT(*) FROM pos_sales', []);
    return (val ?? 0) + 1;
  }

  // ── Session summary ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> sessionSummary(int sessionId) async {
    final rows = await _db.rawQuery('''
      SELECT COUNT(*) AS count,
             SUM(total_ttc) AS total,
             SUM(CASE WHEN payment_method = 'Espèces' THEN total_ttc ELSE 0 END) AS cash,
             SUM(CASE WHEN payment_method = 'Carte'   THEN total_ttc ELSE 0 END) AS card,
             SUM(CASE WHEN payment_method = 'Chèque'  THEN total_ttc ELSE 0 END) AS cheque
      FROM pos_sales WHERE session_id = ?
    ''', [sessionId]);
    return rows.first;
  }
}
