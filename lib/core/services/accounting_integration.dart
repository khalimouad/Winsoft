import '../database/database_helper.dart';
import '../models/accounting_country.dart';
import '../models/invoice.dart';
import '../models/purchase_order.dart';
import '../models/payroll_slip.dart';
import '../models/pos_sale.dart';
import '../models/supplier_invoice.dart';
import '../models/journal_entry.dart';
import '../repositories/accounting_repository.dart';

/// Automatically posts journal entries for business transactions.
/// Account codes are resolved from the active [AccountingCountry] setting,
/// making this compatible with PCM (Morocco), PCG (France), SCF (Algeria),
/// PCG-TN (Tunisia), SYSCOHADA, and IFRS.
class AccountingIntegration {
  AccountingIntegration._();

  static final _repo = AccountingRepository();

  static Future<int?> _accountId(String code) async {
    final rows = await DatabaseHelper.instance
        .query('account_chart', where: 'code = ?', whereArgs: [code]);
    if (rows.isEmpty) return null;
    return rows.first['id'] as int?;
  }

  static Future<int> _nextSeq() => _repo.nextSequence();

  // ── Invoice posted (sales journal VTE) ───────────────────────────────────
  static Future<void> postInvoice(Invoice invoice) async {
    final c = await AccountingCountry.fromSettings();
    await _repo.seedForCountry(c);

    final clientId = await _accountId(c.accounts.client);
    final salesId  = await _accountId(c.accounts.sales);
    final tvaId    = await _accountId(c.accounts.vatCollected);
    if (clientId == null || salesId == null || tvaId == null) return;

    final seq = await _nextSeq();
    final now = DateTime.now().millisecondsSinceEpoch;

    await _repo.insertEntry(JournalEntry(
      reference: 'VTE-${DateTime.now().year}-${seq.toString().padLeft(4, '0')}',
      date: invoice.issuedDate.millisecondsSinceEpoch,
      description: 'Facture ${invoice.reference}',
      journal: 'VTE',
      createdAt: now,
      lines: [
        JournalEntryLine(entryId: 0, accountId: clientId,
            label: invoice.reference, debit: invoice.totalTtc),
        JournalEntryLine(entryId: 0, accountId: salesId,
            label: invoice.reference, credit: invoice.totalHt),
        JournalEntryLine(entryId: 0, accountId: tvaId,
            label: 'TVA ${invoice.reference}', credit: invoice.totalTva),
      ],
    ));
  }

  // ── Purchase received (purchase journal ACH) ─────────────────────────────
  static Future<void> postPurchaseReceived(PurchaseOrder order) async {
    final c = await AccountingCountry.fromSettings();
    await _repo.seedForCountry(c);

    final purchasesId = await _accountId(c.accounts.purchases);
    final tvaRecId    = await _accountId(c.accounts.vatDeductible);
    final supplId     = await _accountId(c.accounts.supplier);
    if (purchasesId == null || tvaRecId == null || supplId == null) return;

    final seq = await _nextSeq();
    final now = DateTime.now().millisecondsSinceEpoch;

    await _repo.insertEntry(JournalEntry(
      reference: 'ACH-${DateTime.now().year}-${seq.toString().padLeft(4, '0')}',
      date: order.date,
      description: 'Bon achat ${order.reference}',
      journal: 'ACH',
      createdAt: now,
      lines: [
        JournalEntryLine(entryId: 0, accountId: purchasesId,
            label: order.reference, debit: order.totalHt),
        JournalEntryLine(entryId: 0, accountId: tvaRecId,
            label: 'TVA ${order.reference}', debit: order.totalTva),
        JournalEntryLine(entryId: 0, accountId: supplId,
            label: order.reference, credit: order.totalTtc),
      ],
    ));
  }

  // ── Payroll validated (salary journal SAL) ────────────────────────────────
  static Future<void> postPayroll(PayrollSlip slip) async {
    final c = await AccountingCountry.fromSettings();
    await _repo.seedForCountry(c);

    final remuId    = await _accountId(c.accounts.wages);
    final chargesId = await _accountId(c.accounts.employerCharges);
    final duePersId = await _accountId(c.accounts.wagesDue);
    final orgSocId  = await _accountId(c.accounts.socialOrgs);
    final etatTaxId = await _accountId(c.accounts.incomeTax);
    if (remuId == null || chargesId == null || duePersId == null ||
        orgSocId == null || etatTaxId == null) return;

    final employerCharges = slip.cnssEmployer + slip.amoEmployer;
    final employeeCharges = slip.cnssEmployee + slip.amoEmployee;
    final seq = await _nextSeq();
    final now = DateTime.now().millisecondsSinceEpoch;

    await _repo.insertEntry(JournalEntry(
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
            label: 'Charges sociales', credit: employeeCharges + employerCharges),
        JournalEntryLine(entryId: 0, accountId: etatTaxId,
            label: 'Impôt sur revenu', credit: slip.igr),
      ],
    ));
  }

  // ── Supplier invoice validated (purchase journal ACH) ────────────────────
  static Future<void> postSupplierInvoice(SupplierInvoice invoice) async {
    final c = await AccountingCountry.fromSettings();
    await _repo.seedForCountry(c);

    final purchasesId = await _accountId(c.accounts.purchases);
    final tvaRecId    = await _accountId(c.accounts.vatDeductible);
    final supplId     = await _accountId(c.accounts.supplier);
    if (purchasesId == null || tvaRecId == null || supplId == null) return;

    final seq = await _nextSeq();
    final now = DateTime.now().millisecondsSinceEpoch;

    await _repo.insertEntry(JournalEntry(
      reference: 'ACH-${DateTime.now().year}-${seq.toString().padLeft(4, '0')}',
      date: invoice.issuedDate,
      description: 'Facture fournisseur ${invoice.reference}',
      journal: 'ACH',
      createdAt: now,
      lines: [
        JournalEntryLine(entryId: 0, accountId: purchasesId,
            label: invoice.reference, debit: invoice.totalHt),
        JournalEntryLine(entryId: 0, accountId: tvaRecId,
            label: 'TVA ${invoice.reference}', debit: invoice.totalTva),
        JournalEntryLine(entryId: 0, accountId: supplId,
            label: invoice.reference, credit: invoice.totalTtc),
      ],
    ));
  }

  // ── POS sale (sales journal VTE) ─────────────────────────────────────────
  static Future<void> postPosSale(PosSale sale) async {
    final c = await AccountingCountry.fromSettings();
    await _repo.seedForCountry(c);

    final isCash     = sale.paymentMethod == 'Espèces';
    final treasuryId = await _accountId(isCash ? c.accounts.cash : c.accounts.bank);
    final salesId    = await _accountId(c.accounts.sales);
    final tvaId      = await _accountId(c.accounts.vatCollected);
    if (treasuryId == null || salesId == null || tvaId == null) return;

    final seq = await _nextSeq();
    final now = DateTime.now().millisecondsSinceEpoch;

    await _repo.insertEntry(JournalEntry(
      reference: 'VTE-${DateTime.now().year}-${seq.toString().padLeft(4, '0')}',
      date: sale.saleDate,
      description: 'Vente POS ${sale.reference}',
      journal: 'VTE',
      createdAt: now,
      lines: [
        JournalEntryLine(entryId: 0, accountId: treasuryId,
            label: sale.reference, debit: sale.totalTtc),
        JournalEntryLine(entryId: 0, accountId: salesId,
            label: sale.reference, credit: sale.totalHt),
        JournalEntryLine(entryId: 0, accountId: tvaId,
            label: 'TVA ${sale.reference}', credit: sale.totalTva),
      ],
    ));
  }
}
