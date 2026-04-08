import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/supplier.dart';
import '../../core/models/purchase_order.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/morocco_format.dart';

class PurchasesPage extends ConsumerStatefulWidget {
  const PurchasesPage({super.key});

  @override
  ConsumerState<PurchasesPage> createState() => _PurchasesPageState();
}

class _PurchasesPageState extends ConsumerState<PurchasesPage>
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
            child: Text('Achats',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          TabBar(
            controller: _tab,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            tabs: const [
              Tab(text: 'Fournisseurs'),
              Tab(text: 'Bons de commande'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: const [
                _SuppliersTab(),
                _PurchaseOrdersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Suppliers Tab ─────────────────────────────────────────────────────────────

class _SuppliersTab extends ConsumerStatefulWidget {
  const _SuppliersTab();

  @override
  ConsumerState<_SuppliersTab> createState() => _SuppliersTabState();
}

class _SuppliersTabState extends ConsumerState<_SuppliersTab> {
  String _search = '';

  @override
  Widget build(BuildContext context) {

    final suppliersAsync = ref.watch(supplierProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher…',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: () => _showDialog(context, ref, null),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nouveau fournisseur'),
            ),
          ]),
          const SizedBox(height: 12),
          Expanded(
            child: suppliersAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
              data: (suppliers) {
                final filtered = _search.isEmpty
                    ? suppliers
                    : suppliers
                        .where((s) =>
                            s.name.toLowerCase().contains(_search.toLowerCase()) ||
                            (s.city?.toLowerCase().contains(_search.toLowerCase()) ?? false))
                        .toList();
                if (filtered.isEmpty) {
                  return const Center(child: Text('Aucun fournisseur'));
                }
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) => _SupplierTile(
                    supplier: filtered[i],
                    onEdit: () =>
                        _showDialog(context, ref, filtered[i]),
                    onDelete: () =>
                        _confirmDelete(context, ref, filtered[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDialog(
      BuildContext context, WidgetRef ref, Supplier? supplier) {
    final nameCtrl =
        TextEditingController(text: supplier?.name ?? '');
    final emailCtrl =
        TextEditingController(text: supplier?.email ?? '');
    final phoneCtrl =
        TextEditingController(text: supplier?.phone ?? '');
    final cityCtrl =
        TextEditingController(text: supplier?.city ?? '');
    final iceCtrl =
        TextEditingController(text: supplier?.ice ?? '');
    final ribCtrl =
        TextEditingController(text: supplier?.rib ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(supplier == null
            ? 'Nouveau fournisseur'
            : 'Modifier fournisseur'),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nom *'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: emailCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: phoneCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Téléphone'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: cityCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Ville'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: iceCtrl,
                  decoration: const InputDecoration(labelText: 'ICE'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: ribCtrl,
                  decoration: const InputDecoration(labelText: 'RIB'),
                ),
              ]),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final now = DateTime.now().millisecondsSinceEpoch;
              final s = Supplier(
                id: supplier?.id,
                name: nameCtrl.text.trim(),
                email: emailCtrl.text.trim().isEmpty
                    ? null
                    : emailCtrl.text.trim(),
                phone: phoneCtrl.text.trim().isEmpty
                    ? null
                    : phoneCtrl.text.trim(),
                city: cityCtrl.text.trim().isEmpty
                    ? null
                    : cityCtrl.text.trim(),
                ice: iceCtrl.text.trim().isEmpty
                    ? null
                    : iceCtrl.text.trim(),
                rib: ribCtrl.text.trim().isEmpty
                    ? null
                    : ribCtrl.text.trim(),
                createdAt: supplier?.createdAt ?? now,
              );
              if (supplier == null) {
                await ref.read(supplierProvider.notifier).add(s);
              } else {
                await ref.read(supplierProvider.notifier).edit(s);
              }
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: Text(
                supplier == null ? 'Ajouter' : 'Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, Supplier supplier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer fournisseur'),
        content:
            Text('Supprimer "${supplier.name}" ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor:
                    Theme.of(context).colorScheme.error),
            onPressed: () {
              ref
                  .read(supplierProvider.notifier)
                  .remove(supplier.id!);
              Navigator.of(ctx).pop();
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class _SupplierTile extends StatelessWidget {
  const _SupplierTile(
      {required this.supplier,
      required this.onEdit,
      required this.onDelete});

  final Supplier supplier;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              theme.colorScheme.primaryContainer,
          child: Text(
            supplier.name.isNotEmpty
                ? supplier.name[0].toUpperCase()
                : '?',
            style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(supplier.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            [supplier.city, supplier.email]
                .where((e) => e != null && e.isNotEmpty)
                .join(' · '),
            style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (supplier.ice != null && supplier.ice!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text('ICE: ${supplier.ice}',
                  style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant)),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18),
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Modifier'),
                      dense: true,
                      contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                      leading: Icon(Icons.delete_outline,
                          color: Colors.red),
                      title: Text('Supprimer',
                          style: TextStyle(color: Colors.red)),
                      dense: true,
                      contentPadding: EdgeInsets.zero)),
            ],
            onSelected: (v) {
              if (v == 'edit') onEdit();
              if (v == 'delete') onDelete();
            },
          ),
        ]),
      ),
    );
  }
}

// ── Purchase Orders Tab ───────────────────────────────────────────────────────

class _PurchaseOrdersTab extends ConsumerWidget {
  const _PurchaseOrdersTab();

  static const _statusColors = {
    'Brouillon': Colors.grey,
    'Envoyé': Colors.blue,
    'Reçu': Colors.green,
    'Partiel': Colors.orange,
    'Annulé': Colors.red,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ordersAsync = ref.watch(purchaseOrderProvider);
    final suppliersAsync = ref.watch(supplierProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(children: [
            const Spacer(),
            FilledButton.icon(
              onPressed: () => suppliersAsync.whenData((suppliers) =>
                  _showAddDialog(context, ref, suppliers)),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nouveau bon d\'achat'),
            ),
          ]),
          const SizedBox(height: 12),
          Expanded(
            child: ordersAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
              data: (orders) {
                if (orders.isEmpty) {
                  return const Center(
                      child: Text('Aucun bon de commande'));
                }
                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (ctx, i) {
                    final order = orders[i];
                    final color = _statusColors[order.status] ??
                        Colors.grey;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Row(children: [
                          Text(order.reference,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  color.withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                            child: Text(order.status,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: color,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ]),
                        subtitle: Text(
                            '${order.supplierName ?? ''} · ${MoroccoFormat.date(DateTime.fromMillisecondsSinceEpoch(order.date))}',
                            style: TextStyle(
                                fontSize: 12,
                                color: theme
                                    .colorScheme.onSurfaceVariant)),
                        trailing: Text(MoroccoFormat.mad(order.totalTtc),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        onTap: () =>
                            _showStatusMenu(context, ref, order),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusMenu(
      BuildContext context, WidgetRef ref, PurchaseOrder order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(order.reference),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: PurchaseOrder.statuses.map((s) {
            return ListTile(
              title: Text(s),
              leading: Radio<String>(
                value: s,
                groupValue: order.status,
                onChanged: (v) async {
                  if (v != null) {
                    await ref
                        .read(purchaseOrderProvider.notifier)
                        .updateStatus(order.id!, v);
                  }
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showAddDialog(
      BuildContext context, WidgetRef ref, List<Supplier> suppliers) {
    if (suppliers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Ajoutez d\'abord un fournisseur dans l\'onglet Fournisseurs')));
      return;
    }
    int? selectedSupplierId = suppliers.first.id;
    final descCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final priceCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Nouveau bon d\'achat'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                DropdownButtonFormField<int>(
                  value: selectedSupplierId,
                  decoration: const InputDecoration(
                      labelText: 'Fournisseur *'),
                  items: suppliers
                      .map((s) => DropdownMenuItem(
                          value: s.id, child: Text(s.name)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => selectedSupplierId = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Description article *'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: qtyCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Quantité'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: priceCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Prix HT *'),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Requis' : null,
                    ),
                  ),
                ]),
              ]),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Annuler')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final qty = double.tryParse(qtyCtrl.text) ?? 1;
                final price =
                    double.tryParse(priceCtrl.text) ?? 0;
                final ht = qty * price;
                final tva = ht * 0.20;
                final repo = ref.read(purchaseOrderRepoProvider);
                final seq = await repo.nextSequence();
                final order = PurchaseOrder(
                  reference:
                      'BA-${DateTime.now().year}-${seq.toString().padLeft(3, '0')}',
                  supplierId: selectedSupplierId!,
                  date: DateTime.now().millisecondsSinceEpoch,
                  totalHt: ht,
                  totalTva: tva,
                  totalTtc: ht + tva,
                  items: [
                    PurchaseOrderItem(
                      orderId: 0,
                      description: descCtrl.text.trim(),
                      quantity: qty,
                      unitPriceHt: price,
                    ),
                  ],
                );
                await ref
                    .read(purchaseOrderProvider.notifier)
                    .add(order);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }
}
