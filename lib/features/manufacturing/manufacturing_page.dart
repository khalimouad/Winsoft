import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/manufacturing_bom.dart';
import '../../core/models/product.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/morocco_format.dart';

class ManufacturingPage extends ConsumerStatefulWidget {
  const ManufacturingPage({super.key});

  @override
  ConsumerState<ManufacturingPage> createState() =>
      _ManufacturingPageState();
}

class _ManufacturingPageState extends ConsumerState<ManufacturingPage>
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
            child: Text('Production',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          TabBar(
            controller: _tab,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            tabs: const [
              Tab(text: 'Nomenclatures (BOM)'),
              Tab(text: 'Ordres de fabrication'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: const [
                _BomTab(),
                _ProductionOrdersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── BOM Tab ───────────────────────────────────────────────────────────────────

class _BomTab extends ConsumerWidget {
  const _BomTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bomsAsync = ref.watch(bomProvider);
    final productsAsync = ref.watch(productProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [
          const Spacer(),
          FilledButton.icon(
            onPressed: () => productsAsync.whenData(
                (products) =>
                    _showAddBom(context, ref, products)),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Nouvelle nomenclature'),
          ),
        ]),
        const SizedBox(height: 12),
        Expanded(
          child: bomsAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur: $e')),
            data: (boms) {
              if (boms.isEmpty) {
                return const Center(
                    child: Text('Aucune nomenclature'));
              }
              return ListView.builder(
                itemCount: boms.length,
                itemBuilder: (ctx, i) =>
                    _BomCard(bom: boms[i], ref: ref),
              );
            },
          ),
        ),
      ]),
    );
  }

  void _showAddBom(BuildContext context, WidgetRef ref,
      List<Product> products) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    // Inputs: list of {product, qty}
    final inputs = <_BomLine>[];
    final outputs = <_BomLine>[];

    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Ajoutez d\'abord des produits dans le catalogue')));
      return;
    }

    inputs.add(_BomLine(productId: products.first.id!));
    outputs.add(_BomLine(productId: products.first.id!));
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Nouvelle nomenclature'),
          content: SizedBox(
            width: 500,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Nom de la nomenclature *'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Requis' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: descCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 16),
                  // Inputs section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Matières premières (intrants)',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                      TextButton.icon(
                        onPressed: () => setState(() => inputs.add(
                            _BomLine(productId: products.first.id!))),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Ajouter'),
                      ),
                    ],
                  ),
                  ...inputs.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final line = entry.value;
                    return _BomLineRow(
                      line: line,
                      products: products,
                      roleLabel: 'Intrant',
                      onRemove: () =>
                          setState(() => inputs.removeAt(idx)),
                      onChange: () => setState(() {}),
                    );
                  }),
                  const SizedBox(height: 16),
                  // Outputs section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Produits finis (extrants)',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                      TextButton.icon(
                        onPressed: () => setState(() => outputs.add(
                            _BomLine(productId: products.first.id!))),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Ajouter'),
                      ),
                    ],
                  ),
                  ...outputs.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final line = entry.value;
                    return _BomLineRow(
                      line: line,
                      products: products,
                      roleLabel: 'Produit fini',
                      onRemove: () =>
                          setState(() => outputs.removeAt(idx)),
                      onChange: () => setState(() {}),
                    );
                  }),
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
                final components = [
                  ...inputs.map((l) => BomComponent(
                      bomId: 0,
                      productId: l.productId,
                      quantity: l.qty,
                      role: 'input')),
                  ...outputs.map((l) => BomComponent(
                      bomId: 0,
                      productId: l.productId,
                      quantity: l.qty,
                      role: 'output')),
                ];
                final bom = ManufacturingBom(
                  name: nameCtrl.text.trim(),
                  description: descCtrl.text.trim().isEmpty
                      ? null
                      : descCtrl.text.trim(),
                  createdAt: now,
                  components: components,
                );
                await ref.read(bomProvider.notifier).add(bom);
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

class _BomLine {
  int productId;
  double qty;
  _BomLine({required this.productId, this.qty = 1});
}

class _BomLineRow extends StatelessWidget {
  const _BomLineRow({
    required this.line,
    required this.products,
    required this.roleLabel,
    required this.onRemove,
    required this.onChange,
  });

  final _BomLine line;
  final List<Product> products;
  final String roleLabel;
  final VoidCallback onRemove;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final qtyCtrl =
        TextEditingController(text: line.qty.toString());
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Expanded(
          flex: 3,
          child: DropdownButtonFormField<int>(
            value: line.productId,
            isExpanded: true,
            decoration: const InputDecoration(
                isDense: true, contentPadding: EdgeInsets.all(10)),
            items: products
                .map((p) => DropdownMenuItem(
                    value: p.id,
                    child: Text(p.name,
                        overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                line.productId = v;
                onChange();
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: TextFormField(
            controller: qtyCtrl,
            decoration: const InputDecoration(
                labelText: 'Qté',
                isDense: true,
                contentPadding: EdgeInsets.all(10)),
            keyboardType: TextInputType.number,
            onChanged: (v) {
              line.qty = double.tryParse(v) ?? 1;
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline,
              size: 18, color: Colors.red),
          onPressed: onRemove,
        ),
      ]),
    );
  }
}

class _BomCard extends StatelessWidget {
  const _BomCard({required this.bom, required this.ref});

  final ManufacturingBom bom;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.account_tree_outlined,
                size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(bom.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 18, color: Colors.red),
              onPressed: () =>
                  ref.read(bomProvider.notifier).remove(bom.id!),
            ),
          ]),
          if (bom.description != null) ...[
            const SizedBox(height: 4),
            Text(bom.description!,
                style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant)),
          ],
          const SizedBox(height: 10),
          if (bom.inputs.isNotEmpty) ...[
            Text('Intrants:',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: bom.inputs
                  .map((c) => Chip(
                        label: Text(
                            '${c.productName ?? 'P#${c.productId}'} × ${c.quantity}',
                            style: const TextStyle(fontSize: 11)),
                        backgroundColor: Colors.orange.withValues(alpha: 0.1),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ))
                  .toList(),
            ),
          ],
          if (bom.outputs.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Produits finis:',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: bom.outputs
                  .map((c) => Chip(
                        label: Text(
                            '${c.productName ?? 'P#${c.productId}'} × ${c.quantity}',
                            style: const TextStyle(fontSize: 11)),
                        backgroundColor: Colors.green.withValues(alpha: 0.1),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ))
                  .toList(),
            ),
          ],
        ]),
      ),
    );
  }
}

// ── Production Orders Tab ─────────────────────────────────────────────────────

class _ProductionOrdersTab extends ConsumerWidget {
  const _ProductionOrdersTab();

  static const _statusColors = {
    'Brouillon': Colors.grey,
    'Planifié': Colors.blue,
    'En cours': Colors.orange,
    'Terminé': Colors.green,
    'Annulé': Colors.red,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(productionOrderProvider);
    final bomsAsync = ref.watch(bomProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [
          const Spacer(),
          FilledButton.icon(
            onPressed: () => bomsAsync.whenData(
                (boms) => _showAddDialog(context, ref, boms)),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Nouvel ordre'),
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
                    child:
                        Text('Aucun ordre de fabrication'));
              }
              return ListView.builder(
                itemCount: orders.length,
                itemBuilder: (ctx, i) {
                  final order = orders[i];
                  final color =
                      _statusColors[order.status] ?? Colors.grey;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            color.withValues(alpha: 0.15),
                        radius: 20,
                        child: Icon(Icons.precision_manufacturing,
                            size: 18, color: color),
                      ),
                      title: Row(children: [
                        Text(order.reference,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(order.status,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: color,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ]),
                      subtitle: Text(
                          '${order.bomName ?? ''} · Planifié: ${MoroccoFormat.dateFromMs(order.plannedDate)}',
                          style: TextStyle(
                              fontSize: 12,
                              color: theme
                                  .colorScheme.onSurfaceVariant)),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 18),
                        itemBuilder: (_) =>
                            ProductionOrder.statuses
                                .map((s) => PopupMenuItem(
                                    value: s,
                                    child: Text(s)))
                                .toList(),
                        onSelected: (s) => ref
                            .read(productionOrderProvider.notifier)
                            .updateStatus(order.id!, s),
                      ),
                      onLongPress: () => ref
                          .read(productionOrderProvider.notifier)
                          .remove(order.id!),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }

  void _showAddDialog(
      BuildContext context, WidgetRef ref, List<ManufacturingBom> boms) {
    if (boms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Créez d\'abord une nomenclature (BOM)')));
      return;
    }
    int? selectedBomId = boms.first.id;
    final dateCtrl = TextEditingController(
        text: MoroccoFormat.date(DateTime.now().add(const Duration(days: 7))));
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Nouvel ordre de fabrication'),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                DropdownButtonFormField<int>(
                  value: selectedBomId,
                  decoration: const InputDecoration(
                      labelText: 'Nomenclature *'),
                  isExpanded: true,
                  items: boms
                      .map((b) => DropdownMenuItem(
                          value: b.id, child: Text(b.name)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => selectedBomId = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: dateCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Date planifiée (JJ/MM/AAAA) *'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Requis' : null,
                ),
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
                final parts = dateCtrl.text.split('/');
                DateTime? planned;
                if (parts.length == 3) {
                  planned = DateTime(int.parse(parts[2]),
                      int.parse(parts[1]), int.parse(parts[0]));
                }
                planned ??=
                    DateTime.now().add(const Duration(days: 7));

                final mfgRepo =
                    ref.read(manufacturingRepoProvider);
                final seq = await mfgRepo.nextSequence();
                final now = DateTime.now().millisecondsSinceEpoch;

                // Build outputs from selected BOM
                final bom = boms.firstWhere(
                    (b) => b.id == selectedBomId);
                final outputs = bom.outputs
                    .map((c) => ProductionOutput(
                          productionOrderId: 0,
                          productId: c.productId,
                          plannedQty: c.quantity,
                        ))
                    .toList();

                final order = ProductionOrder(
                  reference:
                      'OF-${DateTime.now().year}-${seq.toString().padLeft(3, '0')}',
                  bomId: selectedBomId!,
                  plannedDate: planned.millisecondsSinceEpoch,
                  createdAt: now,
                  outputs: outputs,
                );
                await ref
                    .read(productionOrderProvider.notifier)
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
