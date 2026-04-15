import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/pos_sale.dart';
import '../../core/models/product.dart';
import '../../core/models/client.dart';
import '../../core/providers/providers.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/utils/morocco_format.dart';

class PosPage extends ConsumerStatefulWidget {
  const PosPage({super.key});

  @override
  ConsumerState<PosPage> createState() => _PosPageState();
}

class _PosPageState extends ConsumerState<PosPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Text('Point de Vente',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          TabBar(
            controller: _tab,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            tabs: const [
              Tab(text: 'Caisse'),
              Tab(text: 'Historique des ventes'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: const [
                _CaisseTab(),
                _HistoriqueTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cart item model ───────────────────────────────────────────────────────────

class _CartItem {
  _CartItem({
    required this.product,
    required this.unitPriceHt,
    this.quantity = 1,
    this.discountPercent = 0,
  });

  final Product product;
  double unitPriceHt;
  double quantity;
  double discountPercent;

  double get lineHt =>
      quantity * unitPriceHt * (1 - discountPercent / 100);
  double get lineTva => lineHt * (product.tvaRate / 100);
  double get lineTtc => lineHt + lineTva;
}

// ── Caisse (POS register) Tab ─────────────────────────────────────────────────

class _CaisseTab extends ConsumerStatefulWidget {
  const _CaisseTab();

  @override
  ConsumerState<_CaisseTab> createState() => _CaisseTabState();
}

class _CaisseTabState extends ConsumerState<_CaisseTab> {
  final List<_CartItem> _cart = [];
  String _search = '';
  Client? _selectedClient;
  PriceList? _selectedPriceList;
  String _paymentMethod = 'Espèces';
  double _amountTendered = 0;

  double get _totalHt =>
      _cart.fold(0, (s, i) => s + i.lineHt);
  double get _totalTva =>
      _cart.fold(0, (s, i) => s + i.lineTva);
  double get _totalTtc => _totalHt + _totalTva;
  double get _change =>
      (_amountTendered - _totalTtc).clamp(0, double.infinity);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productsAsync = ref.watch(productProvider);
    final clientsAsync = ref.watch(clientProvider);
    final priceListsAsync = ref.watch(priceListProvider);

    return Row(
      children: [
        // ── Left: Product catalog ──────────────────────────────────────────
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              // Search + filters
              Row(children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Rechercher produit…',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                const SizedBox(width: 8),
                priceListsAsync.maybeWhen(
                  data: (lists) => lists.isEmpty
                      ? const SizedBox.shrink()
                      : SizedBox(
                          width: 160,
                          child: DropdownButtonFormField<PriceList?>(
                            value: _selectedPriceList,
                            isExpanded: true,
                            isDense: true,
                            decoration: InputDecoration(
                              labelText: 'Tarif',
                              isDense: true,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            items: [
                              const DropdownMenuItem(
                                  value: null, child: Text('Standard')),
                              ...lists.map((pl) => DropdownMenuItem(
                                  value: pl, child: Text(pl.name))),
                            ],
                            onChanged: (v) =>
                                setState(() => _selectedPriceList = v),
                          ),
                        ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ]),
              const SizedBox(height: 12),
              Expanded(
                child: productsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Erreur: $e')),
                  data: (products) {
                    final filtered = products
                        .where((p) =>
                            p.status == 'Actif' &&
                            (_search.isEmpty ||
                                p.name.toLowerCase().contains(
                                    _search.toLowerCase()) ||
                                (p.reference?.toLowerCase().contains(
                                        _search.toLowerCase()) ??
                                    false)))
                        .toList();
                    return GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1.5,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final p = filtered[i];
                        final ht = _selectedPriceList != null
                            ? _selectedPriceList!
                                .effectivePrice(p.id ?? 0, p.priceHt)
                            : p.priceHt;
                        return _ProductCard(
                          product: p,
                          displayPriceHt: ht,
                          onTap: () => _addToCart(p, ht),
                        );
                      },
                    );
                  },
                ),
              ),
            ]),
          ),
        ),

        // ── Right: Cart + payment ──────────────────────────────────────────
        Container(
          width: 340,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
                left: BorderSide(
                    color: theme.colorScheme.outlineVariant)),
          ),
          child: Column(children: [
            // Client selector
            Padding(
              padding: const EdgeInsets.all(12),
              child: clientsAsync.maybeWhen(
                data: (clients) => DropdownButtonFormField<Client?>(
                  value: _selectedClient,
                  isExpanded: true,
                  isDense: true,
                  decoration: InputDecoration(
                    labelText: 'Client (optionnel)',
                    prefixIcon: const Icon(Icons.person_outlined, size: 18),
                    isDense: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  items: [
                    const DropdownMenuItem(
                        value: null,
                        child: Text('Client de passage')),
                    ...clients.map((c) => DropdownMenuItem(
                        value: c, child: Text(c.name))),
                  ],
                  onChanged: (v) =>
                      setState(() => _selectedClient = v),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ),

            // Cart items
            Expanded(
              child: _cart.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shopping_cart_outlined,
                              size: 48,
                              color: theme.colorScheme.outlineVariant),
                          const SizedBox(height: 8),
                          Text('Panier vide',
                              style: TextStyle(
                                  color: theme
                                      .colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _cart.length,
                      itemBuilder: (ctx, i) => _CartItemTile(
                        item: _cart[i],
                        onRemove: () =>
                            setState(() => _cart.removeAt(i)),
                        onQtyChanged: (q) =>
                            setState(() => _cart[i].quantity = q),
                        onDiscountChanged: (d) => setState(
                            () => _cart[i].discountPercent = d),
                      ),
                    ),
            ),

            // Totals
            Container(
              padding: const EdgeInsets.all(12),
              color: theme.colorScheme.surfaceContainerLow,
              child: Column(children: [
                _TotalRow('Total HT', MoroccoFormat.mad(_totalHt)),
                _TotalRow('TVA', MoroccoFormat.mad(_totalTva)),
                const Divider(height: 8),
                _TotalRow('Total TTC', MoroccoFormat.mad(_totalTtc),
                    bold: true, large: true),
              ]),
            ),

            // Payment method
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                      value: 'Espèces',
                      icon: Icon(Icons.payments, size: 16),
                      label: Text('Espèces')),
                  ButtonSegment(
                      value: 'Carte',
                      icon: Icon(Icons.credit_card, size: 16),
                      label: Text('Carte')),
                  ButtonSegment(
                      value: 'Chèque',
                      icon: Icon(Icons.edit_note, size: 16),
                      label: Text('Chèque')),
                ],
                selected: {_paymentMethod},
                onSelectionChanged: (s) =>
                    setState(() => _paymentMethod = s.first),
                style: const ButtonStyle(
                    visualDensity: VisualDensity.compact),
              ),
            ),

            // Amount tendered (cash only)
            if (_paymentMethod == 'Espèces')
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Montant reçu (DH)',
                        isDense: true,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setState(() =>
                          _amountTendered = double.tryParse(v) ?? 0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                    const Text('Rendu',
                        style: TextStyle(fontSize: 11)),
                    Text(MoroccoFormat.mad(_change),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold)),
                  ]),
                ]),
              ),

            const SizedBox(height: 8),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                OutlinedButton(
                  onPressed: _cart.isEmpty
                      ? null
                      : () => setState(() => _cart.clear()),
                  child: const Text('Vider'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed:
                        _cart.isEmpty ? null : () => _completeSale(),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Valider'),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ],
    );
  }

  void _addToCart(Product product, double priceHt) {
    setState(() {
      final existing = _cart
          .where((i) => i.product.id == product.id)
          .firstOrNull;
      if (existing != null) {
        existing.quantity += 1;
      } else {
        _cart.add(_CartItem(product: product, unitPriceHt: priceHt));
      }
    });
  }

  Future<void> _completeSale() async {
    if (_cart.isEmpty) return;

    final auth = ref.read(authProvider);
    final repo = ref.read(posRepoProvider);

    // Get or open a session
    var session = await repo.getOpenSession();
    if (session == null) {
      final sid =
          await repo.openSession(auth.user!.id!, 0);
      session = await repo.getOpenSession() ??
          PosSession(
              id: sid,
              openedAt: DateTime.now().millisecondsSinceEpoch,
              status: 'open',
              userId: auth.user!.id!);
    }

    final seq = await repo.nextSequence();
    final now = DateTime.now().millisecondsSinceEpoch;

    final items = _cart
        .map((c) => PosSaleItem(
              saleId: 0,
              productId: c.product.id!,
              description: c.product.name,
              quantity: c.quantity,
              unitPriceHt: c.unitPriceHt,
              tvaRate: c.product.tvaRate,
              discountPercent: c.discountPercent,
            ))
        .toList();

    final sale = PosSale(
      reference:
          'POS-${DateTime.now().year}-${seq.toString().padLeft(4, '0')}',
      sessionId: session.id!,
      clientId: _selectedClient?.id,
      saleDate: now,
      totalHt: _totalHt,
      totalTva: _totalTva,
      totalTtc: _totalTtc,
      paymentMethod: _paymentMethod,
      amountTendered:
          _paymentMethod == 'Espèces' ? _amountTendered : _totalTtc,
      change: _change,
      priceListId: _selectedPriceList?.id,
      items: items,
    );

    await ref.read(posSaleProvider.notifier).completeSale(sale);

    if (mounted) {
      _showReceipt(sale);
      setState(() {
        _cart.clear();
        _amountTendered = 0;
        _selectedClient = null;
      });
    }
  }

  void _showReceipt(PosSale sale) {
    showDialog(
      context: context,
      builder: (ctx) => _ReceiptDialog(sale: sale),
    );
  }
}

// ── Product card ──────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.displayPriceHt,
    required this.onTap,
  });

  final Product product;
  final double displayPriceHt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: theme.colorScheme.outlineVariant, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: Icon(
                  product.isService
                      ? Icons.miscellaneous_services
                      : Icons.inventory_2_outlined,
                  size: 28,
                  color: theme.colorScheme.primary
                      .withValues(alpha: 0.7),
                ),
              ),
            ),
            Text(product.name,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(MoroccoFormat.mad(displayPriceHt),
                style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
            if (product.reference != null)
              Text(product.reference!,
                  style: TextStyle(
                      fontSize: 9,
                      color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

// ── Cart item tile ────────────────────────────────────────────────────────────

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({
    required this.item,
    required this.onRemove,
    required this.onQtyChanged,
    required this.onDiscountChanged,
  });

  final _CartItem item;
  final VoidCallback onRemove;
  final ValueChanged<double> onQtyChanged;
  final ValueChanged<double> onDiscountChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(children: [
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(item.product.name,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 12),
                overflow: TextOverflow.ellipsis),
            Row(children: [
              // Qty controls
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 16,
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: item.quantity > 1
                    ? () => onQtyChanged(item.quantity - 1)
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text('${item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 1)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 12)),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 16,
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => onQtyChanged(item.quantity + 1),
              ),
              const SizedBox(width: 4),
              if (item.discountPercent > 0)
                Text('-${item.discountPercent.toStringAsFixed(0)}%',
                    style: const TextStyle(
                        fontSize: 10, color: Colors.green)),
            ]),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(MoroccoFormat.mad(item.lineTtc),
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 12)),
          GestureDetector(
            onTap: () => _showDiscountDialog(context),
            child: Text(
                'HT: ${MoroccoFormat.mad(item.lineHt)}',
                style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant)),
          ),
        ]),
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32),
          iconSize: 16,
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: onRemove,
        ),
      ]),
    );
  }

  void _showDiscountDialog(BuildContext context) {
    final ctrl = TextEditingController(
        text: item.discountPercent.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remise — ${item.product.name}'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
              labelText: 'Remise (%)', suffixText: '%'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler')),
          FilledButton(
            onPressed: () {
              onDiscountChanged(double.tryParse(ctrl.text) ?? 0);
              Navigator.of(ctx).pop();
            },
            child: const Text('Appliquer'),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow(this.label, this.value,
      {this.bold = false, this.large = false});
  final String label, value;
  final bool bold, large;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
        Text(label,
            style: TextStyle(
                fontSize: large ? 14 : 12,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        Text(value,
            style: TextStyle(
                fontSize: large ? 16 : 12,
                fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

// ── Receipt Dialog ────────────────────────────────────────────────────────────

class _ReceiptDialog extends StatelessWidget {
  const _ReceiptDialog({required this.sale});
  final PosSale sale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Row(children: [
        Icon(Icons.receipt, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text('Ticket — ${sale.reference}'),
      ]),
      content: SizedBox(
        width: 320,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(children: [
              Text(MoroccoFormat.dateFromMs(sale.saleDate),
                  style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant)),
              if (sale.clientName != null) Text(sale.clientName!),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              ...sale.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                      Expanded(
                        child: Text(
                            '${item.description} × ${item.quantity}',
                            style: const TextStyle(fontSize: 11),
                            overflow: TextOverflow.ellipsis),
                      ),
                      Text(MoroccoFormat.mad(item.lineTtc),
                          style: const TextStyle(fontSize: 11)),
                    ]),
                  )),
              const Divider(height: 8),
              _ReceiptLine('Total HT', MoroccoFormat.mad(sale.totalHt)),
              _ReceiptLine('TVA', MoroccoFormat.mad(sale.totalTva)),
              _ReceiptLine('TOTAL TTC',
                  MoroccoFormat.mad(sale.totalTtc),
                  bold: true),
              const SizedBox(height: 6),
              _ReceiptLine('Paiement', sale.paymentMethod),
              if (sale.paymentMethod == 'Espèces') ...[
                _ReceiptLine('Reçu',
                    MoroccoFormat.mad(sale.amountTendered)),
                _ReceiptLine(
                    'Rendu', MoroccoFormat.mad(sale.change)),
              ],
              const SizedBox(height: 8),
              Text('Merci pour votre achat !',
                  style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                      color: theme.colorScheme.primary)),
            ]),
          ),
        ]),
      ),
      actions: [
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.check, size: 16),
          label: const Text('Fermer'),
        ),
      ],
    );
  }
}

class _ReceiptLine extends StatelessWidget {
  const _ReceiptLine(this.label, this.value, {this.bold = false});
  final String label, value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        Text(value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      ]),
    );
  }
}

// ── Historique Tab ────────────────────────────────────────────────────────────

class _HistoriqueTab extends ConsumerWidget {
  const _HistoriqueTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final salesAsync = ref.watch(posSaleProvider);
    final posRepo = ref.read(posRepoProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Session management
        FutureBuilder<PosSession?>(
          future: posRepo.getOpenSession(),
          builder: (ctx, snap) {
            final session = snap.data;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  Icon(
                    session != null
                        ? Icons.radio_button_on
                        : Icons.radio_button_off,
                    color: session != null
                        ? Colors.green
                        : theme.colorScheme.outlineVariant,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      session != null
                          ? 'Session ouverte depuis ${MoroccoFormat.dateFromMs(session.openedAt)}'
                          : 'Aucune session active',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  if (session != null)
                    TextButton(
                      onPressed: () =>
                          _showCloseSessionDialog(ctx, ref, posRepo, session),
                      child: const Text('Fermer session'),
                    ),
                ]),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Expanded(
          child: salesAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur: $e')),
            data: (sales) {
              if (sales.isEmpty) {
                return const Center(
                    child: Text('Aucune vente POS enregistrée'));
              }
              return Column(children: [
                // Summary row
                FutureBuilder<Map<String, dynamic>>(
                  future: posRepo.sessionSummary(
                      sales.first.sessionId),
                  builder: (ctx, snap) {
                    if (!snap.hasData) return const SizedBox.shrink();
                    final d = snap.data!;
                    return Card(
                      color: theme.colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceAround,
                          children: [
                            _SummaryChip(
                                '${d['count'] ?? 0} ventes',
                                Icons.receipt),
                            _SummaryChip(
                                MoroccoFormat.mad(
                                    (d['total'] as num?)?.toDouble() ??
                                        0),
                                Icons.payments),
                            _SummaryChip(
                                'Espèces: ${MoroccoFormat.mad((d['cash'] as num?)?.toDouble() ?? 0)}',
                                Icons.money),
                            _SummaryChip(
                                'Carte: ${MoroccoFormat.mad((d['card'] as num?)?.toDouble() ?? 0)}',
                                Icons.credit_card),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: sales.length,
                    itemBuilder: (ctx, i) {
                      final sale = sales[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: _paymentColor(
                                    sale.paymentMethod)
                                .withValues(alpha: 0.15),
                            child: Icon(
                              _paymentIcon(sale.paymentMethod),
                              size: 16,
                              color: _paymentColor(
                                  sale.paymentMethod),
                            ),
                          ),
                          title: Text(sale.reference,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12)),
                          subtitle: Text(
                              '${sale.clientName ?? 'Client passage'} · ${MoroccoFormat.dateFromMs(sale.saleDate)}',
                              style: const TextStyle(fontSize: 11)),
                          trailing: Text(
                              MoroccoFormat.mad(sale.totalTtc),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          onTap: () => _showSaleDetail(
                              context, ref, sale.id!),
                        ),
                      );
                    },
                  ),
                ),
              ]);
            },
          ),
        ),
      ]),
    );
  }

  Color _paymentColor(String method) {
    switch (method) {
      case 'Carte': return Colors.blue;
      case 'Chèque': return Colors.orange;
      default: return Colors.green;
    }
  }

  IconData _paymentIcon(String method) {
    switch (method) {
      case 'Carte': return Icons.credit_card;
      case 'Chèque': return Icons.edit_note;
      default: return Icons.payments;
    }
  }

  void _showCloseSessionDialog(BuildContext context, WidgetRef ref,
      dynamic posRepo, PosSession session) {
    final cashCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final entered = double.tryParse(cashCtrl.text) ?? 0;

          return FutureBuilder<Map<String, dynamic>>(
            future: posRepo.sessionSummary(session.id!),
            builder: (ctx, snap) {
              final d = snap.data ?? {};
              final cashSales = (d['cash'] as num?)?.toDouble() ?? 0;
              final expectedCash = session.openingCash + cashSales;
              final diff = entered - expectedCash;

              return AlertDialog(
                title: const Text('Clôture de session'),
                content: SizedBox(
                  width: 360,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SessionRow('Ventes totales',
                          MoroccoFormat.mad((d['total'] as num?)?.toDouble() ?? 0)),
                      _SessionRow('Paiements espèces',
                          MoroccoFormat.mad(cashSales)),
                      _SessionRow('Paiements carte',
                          MoroccoFormat.mad((d['card'] as num?)?.toDouble() ?? 0)),
                      _SessionRow('Fond de caisse initial',
                          MoroccoFormat.mad(session.openingCash)),
                      _SessionRow('Caisse théorique',
                          MoroccoFormat.mad(expectedCash), bold: true),
                      const Divider(height: 20),
                      TextField(
                        controller: cashCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Caisse comptée (DH)',
                          prefixIcon: Icon(Icons.calculate_outlined),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                      if (cashCtrl.text.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: (diff.abs() < 0.5
                                    ? Colors.green
                                    : diff < 0
                                        ? Colors.red
                                        : Colors.orange)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(children: [
                            Icon(
                              diff.abs() < 0.5
                                  ? Icons.check_circle_outline
                                  : Icons.warning_amber_outlined,
                              size: 16,
                              color: diff.abs() < 0.5
                                  ? Colors.green
                                  : diff < 0
                                      ? Colors.red
                                      : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              diff.abs() < 0.5
                                  ? 'Caisse équilibrée'
                                  : '${diff > 0 ? 'Excédent' : 'Manque'}: ${MoroccoFormat.mad(diff.abs())}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: diff.abs() < 0.5
                                    ? Colors.green
                                    : diff < 0
                                        ? Colors.red
                                        : Colors.orange,
                              ),
                            ),
                          ]),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Annuler')),
                  FilledButton.icon(
                    icon: const Icon(Icons.lock_outline, size: 16),
                    label: const Text('Clôturer'),
                    onPressed: () async {
                      final closingCash = cashCtrl.text.isNotEmpty
                          ? (double.tryParse(cashCtrl.text) ?? 0)
                          : expectedCash;
                      await posRepo.closeSession(session.id!, closingCash);
                      if (ctx.mounted) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                            content: Text('Session clôturée avec succès')));
                      }
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showSaleDetail(BuildContext context, WidgetRef ref, int saleId) {
    final repo = ref.read(posRepoProvider);
    showDialog(
      context: context,
      builder: (ctx) => FutureBuilder<PosSale?>(
        future: repo.getSaleById(saleId),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const AlertDialog(
                content: Center(child: CircularProgressIndicator()));
          }
          return _ReceiptDialog(sale: snap.data!);
        },
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow(this.label, this.value, {this.bold = false});
  final String label, value;
  final bool bold;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: bold ? FontWeight.bold : FontWeight.w500)),
          ],
        ),
      );
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip(this.label, this.icon);
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: theme.colorScheme.primary),
      const SizedBox(width: 4),
      Text(label,
          style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600)),
    ]);
  }
}
