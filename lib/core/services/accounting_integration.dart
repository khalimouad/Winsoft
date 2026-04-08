import '../database/database_helper.dart';
import '../models/invoice.dart';
import '../models/purchase_order.dart';
import '../models/payroll_slip.dart';
import '../models/pos_sale.dart';
import '../models/journal_entry.dart';
import '../repositories/accounting_repository.dart';

/// Automatically posts journal entries for business transactions.
/// Called from notifiers after each operation.
class AccountingIntegration {
  AccountingIntegration._();

  static final _repo = AccountingRepository();

  // ── Account codes (PCM standard) ──────────────────────────────────────────

  static Future<int?> _accountId(String code) async {
    final rows = await DatabaseHelper.instance
        .query('account_chart', where: 'code = ?', whereArgs: [code]);
    if (rows.isEmpty) return null;
    return rows.first['id'] as int?;
  }

  static Future<int> _nextSeq() => _repo.nextSequence();

  // ── Invoice posted (sales journal VTE) ───────────────────────────────────
  //  Dr 3421 Clients (TTC)
  //  Cr 7141 Ventes (HT)
  //  Cr 4441 TVA facturée (TVA)

  static Future<void> postInvoice(Invoice invoice) async {
    await _repo.seedPcm(); // ensure accounts exist
    final clientId = await _accountId('3421');
    final ventesId = await _accountId('7141');
    final tvaId    = await _accountId('4441');
    if (clientId == null || ventesId == null || tvaId == null) return;

    final seq = await _nextSeq();
    final now = DateTime.now().millisecondsSinceEpoch;

    final entry = JournalEntry(
      reference: 'VTE-${DateTime.now().year}-${seq.toString().padLeft(4, '0')}',
      date: invoice.issuedDate.millisecondsSinceEpoch,
      description: 'Facture ${invoice.reference}',
      journal: 'VTE',
      createdAt: now,
      lines: [
        JournalEntryLine(entryId: 0, accountId: clientId,
            label: invoice.reference, debit: invoice.totalTtc),
        JournalEntryLine(entryId: 0, accountId: ventesId,
            label: invoice.reference, credit: invoice.totalHt),
        JournalEntryLine(entryId: 0, accountId: tvaId,
            label: 'TVA ${invoice.reference}', credit: invoice.totalTva),
      ],
    );
    await _repo.insertEntry(entry);
  }

  // ── Purchase received (purchase journal ACH) ─────────────────────────────
  //  Dr 6121 Achats matières / 6141 Prestations (HT)
  //  Dr 3455 TVA récupérable (TVA)
  //  Cr 4411 Fournisseurs (TTC)

  static Future<void> postPurchaseReceived(PurchaseOrder order) async {
    await _repo.seedPcm();
    final achatsId  = await _accountId('6121');
    final tvaRecId  = await _accountId('3455');
    final foursId   = await _accountId('4411');
    if (achatsId == null || tvaRecId == null || foursId == null) return;

    final seq = await _nextSeq();
    final now = DateTime.now().millisecondsSinceEpoch;

    final entry = JournalEntry(
      reference: 'ACH-${DateTime.now().year}-${seq.toString().padLeft(4, '0')}',
      date: order.date,
      description: 'Bon achat ${order.reference}',
      journal: 'ACH',
      createdAt: now,
      lines: [
        JournalEntryLine(entryId: 0, accountId: achatsId,
            label: order.reference, debit: order.totalHt),
        JournalEntryLine(entryId: 0, accountId: tvaRecId,
            label: 'TVA ${order.reference}', debit: order.totalTva),
        JournalEntryLine(entryId: 0, accountId: foursId,
            label: order.reference, credit: order.totalTtc),
      ],
    );
    await _repo.insertEntry(entry);
  }

  // ── Payroll validated (salary journal SAL) ────────────────────────────────
  //  Dr 6321 Rémunérations (brut)
  //  Dr 6322 Charges sociales employer (CNSS+AMO employer)
  //  Cr 4432 Rémunérations dues (net)
  //  Cr 4455 Organismes sociaux (CNSS+AMO total)
  //  Cr 4441 État IGR (IGR)

  static Future<void> postPayroll(PayrollSlip slip) async {
    await _repo.seedPcm();
    final remuId    = await _accountId('6321');
    final chargesId = await _accountId('6322');
    final duePersId = await _accountId('4432');
    final orgSocId  = await _accountId('4455');
    final etatIgrId = await _accountId('4443');
    if (remuId == null || chargesId == null || duePersId == null ||
        orgSocId == null || etatIgrId == null) return;

    final employerCharges = slip.cnssEmployer + slip.amoEmployer;
    final employeeCharges = slip.cnssEmployee + slip.amoEmployee;
    final seq = await _nextSeq();
    final now = DateTime.now().millisecondsSinceEpoch;

    final entry = JournalEntry(
      reference: 'SAL-${DateTime.now().year}-${seq.toString().padLeft(4, '0')}',
      date: now,
      description: 'Paie ${slip.periodMonth}/${slip.periodYear} — ${slip.employeeName ?? 'Employé ${slip.employeeId}'}',
      journal: 'SAL',
      createdAt: now,
      lines: [
        JournalEntryLine(entryId: 0, accountId: remuId,
            label: 'Salaire brut', debit: slip.salaryBrut),
        JournalEntryLine(entryId: 0, accountId: chargesId,
            label: 'Charges patronales', debit: employerCharges),
        JournalEntryLine(entryId: 0, accountId: duePersId,
            label: 'Net à payer', credit: slip.salaryNet),
        JournalEntryLine(entryId: 0, accountId: orgSocId,
            label: 'CNSS + AMO', credit: employeeCharges + employerCharges),
        JournalEntryLine(entryId: 0, accountId: etatIgrId,
            label: 'IGR', credit: slip.igr),
      ],
    );
    await _repo.insertEntry(entry);
  }

  // ── POS sale (sales journal VTE) ─────────────────────────────────────────
  //  Dr 5161 Caisse (TTC cash) OR 5141 Banque (card/transfer)
  //  Cr 7141 Ventes (HT)
  //  Cr 4441 TVA facturée (TVA)

  static Future<void> postPosSale(PosSale sale) async {
    await _repo.seedPcm();
    final isCash = sale.paymentMethod == 'Espèces';
    final treasuryId = await _accountId(isCash ? '5161' : '5141');
    final ventesId   = await _accountId('7141');
    final tvaId      = await _accountId('4441');
    if (treasuryId == null || ventesId == null || tvaId == null) return;

    final seq = await _nextSeq();
    final now = DateTime.now().millisecondsSinceEpoch;

    final entry = JournalEntry(
      reference: 'VTE-${DateTime.now().year}-${seq.toString().padLeft(4, '0')}',
      date: sale.saleDate,
      description: 'Vente POS ${sale.reference}',
      journal: 'VTE',
      createdAt: now,
      lines: [
        JournalEntryLine(entryId: 0, accountId: treasuryId,
            label: sale.reference, debit: sale.totalTtc),
        JournalEntryLine(entryId: 0, accountId: ventesId,
            label: sale.reference, credit: sale.totalHt),
        JournalEntryLine(entryId: 0, accountId: tvaId,
            label: 'TVA ${sale.reference}', credit: sale.totalTva),
      ],
    );
    await _repo.insertEntry(entry);
  }
}
