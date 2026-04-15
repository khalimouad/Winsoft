import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/product.dart';
import '../../core/models/warehouse.dart';
import '../../core/models/product_category.dart';
import '../../core/models/physical_inventory.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/morocco_format.dart';

class InventoryPage extends ConsumerStatefulWidget {
  const InventoryPage({super.key});

  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
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
            child: Text('Inventaire',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          TabBar(
            controller: _tab,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            tabs: const [
              Tab(text: 'Entrepôts'),
              Tab(text: 'Catégories produits'),
              Tab(text: 'Inventaire physique'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: const [
                _WarehousesTab(),
                _CategoriesTab(),
                _PhysicalInventoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Warehouses Tab ────────────────────────────────────────────────────────────

class _WarehousesTab extends ConsumerWidget {
  const _WarehousesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final warehousesAsync = ref.watch(warehouseProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [
          const Spacer(),
          FilledButton.icon(
            onPressed: () => _showDialog(context, ref, null),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Nouvel entrepôt'),
          ),
        ]),
        const SizedBox(height: 12),
        Expanded(
          child: warehousesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur: $e')),
            data: (warehouses) {
              if (warehouses.isEmpty) {
                return const Center(child: Text('Aucun entrepôt'));
              }
              return ListView.builder(
                itemCount: warehouses.length,
                itemBuilder: (ctx, i) {
                  final wh = warehouses[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: wh.isDefault
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.warehouse_outlined,
                          color: wh.isDefault
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                      title: Row(children: [
                        Text(wh.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                        if (wh.code != null) ...[
                          const SizedBox(width: 8),
                          Text('[${wh.code}]',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant)),
                        ],
                        if (wh.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Par défaut',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ]),
                      subtitle: Text(
                          [wh.city, wh.address]
                              .where((e) => e != null && e.isNotEmpty)
                              .join(' · '),
                          style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant)),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 18),
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                              value: 'edit',
                              child: ListTile(
                                  leading: Icon(Icons.edit_outlined),
                                  title: Text('Modifier'),
                                  dense: true,
                                  contentPadding: EdgeInsets.zero)),
                          if (!wh.isDefault)
                            const PopupMenuItem(
                                value: 'default',
                                child: ListTile(
                                    leading: Icon(Icons.star_outline),
                                    title: Text('Définir par défaut'),
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
                          if (v == 'edit') _showDialog(context, ref, wh);
                          if (v == 'default') {
                            ref
                                .read(warehouseProvider.notifier)
                                .setDefault(wh.id!);
                          }
                          if (v == 'delete') {
                            ref
                                .read(warehouseProvider.notifier)
                                .remove(wh.id!);
                          }
                        },
                      ),
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

  void _showDialog(BuildContext context, WidgetRef ref, Warehouse? warehouse) {
    final nameCtrl =
        TextEditingController(text: warehouse?.name ?? '');
    final codeCtrl =
        TextEditingController(text: warehouse?.code ?? '');
    final cityCtrl =
        TextEditingController(text: warehouse?.city ?? '');
    final addressCtrl =
        TextEditingController(text: warehouse?.address ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
            warehouse == null ? 'Nouvel entrepôt' : 'Modifier entrepôt'),
        content: SizedBox(
          width: 380,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Nom *'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: codeCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Code'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: cityCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Ville'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: addressCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Adresse'),
                  maxLines: 2,
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
              final wh = Warehouse(
                id: warehouse?.id,
                name: nameCtrl.text.trim(),
                code: codeCtrl.text.trim().isEmpty
                    ? null
                    : codeCtrl.text.trim().toUpperCase(),
                city: cityCtrl.text.trim().isEmpty
                    ? null
                    : cityCtrl.text.trim(),
                address: addressCtrl.text.trim().isEmpty
                    ? null
                    : addressCtrl.text.trim(),
                isDefault: warehouse?.isDefault ?? false,
                createdAt: warehouse?.createdAt ?? now,
              );
              if (warehouse == null) {
                await ref.read(warehouseProvider.notifier).add(wh);
              } else {
                await ref.read(warehouseProvider.notifier).edit(wh);
              }
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: Text(warehouse == null ? 'Créer' : 'Enregistrer'),
          ),
        ],
      ),
    );
  }
}

// ── Categories Tab ────────────────────────────────────────────────────────────

class _CategoriesTab extends ConsumerWidget {
  const _CategoriesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(productCategoryProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [
          const Spacer(),
          FilledButton.icon(
            onPressed: () => categoriesAsync.whenData(
                (cats) => _showDialog(context, ref, cats, null)),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Nouvelle catégorie'),
          ),
        ]),
        const SizedBox(height: 12),
        Expanded(
          child: categoriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur: $e')),
            data: (categories) {
              if (categories.isEmpty) {
                return const Center(child: Text('Aucune catégorie'));
              }
              return ListView.builder(
                itemCount: categories.length,
                itemBuilder: (ctx, i) {
                  final cat = categories[i];
                  final isChild = cat.parentId != null;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 4),
                    child: ListTile(
                      contentPadding: EdgeInsets.only(
                          left: isChild ? 32 : 16, right: 8),
                      leading: Icon(
                        isChild
                            ? Icons.subdirectory_arrow_right
                            : Icons.category_outlined,
                        color: isChild
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.primary,
                        size: 20,
                      ),
                      title: Text(cat.name,
                          style: TextStyle(
                              fontWeight: isChild
                                  ? FontWeight.normal
                                  : FontWeight.w600)),
                      subtitle: cat.parentName != null
                          ? Text('Sous-catégorie de ${cat.parentName}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      theme.colorScheme.onSurfaceVariant))
                          : null,
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => categoriesAsync.whenData(
                              (cats) =>
                                  _showDialog(context, ref, cats, cat)),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline,
                              size: 18,
                              color: theme.colorScheme.error),
                          onPressed: () => ref
                              .read(productCategoryProvider.notifier)
                              .remove(cat.id!),
                        ),
                      ]),
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

  void _showDialog(BuildContext context, WidgetRef ref,
      List<ProductCategory> allCategories, ProductCategory? category) {
    final nameCtrl =
        TextEditingController(text: category?.name ?? '');
    final descCtrl =
        TextEditingController(text: category?.description ?? '');
    int? parentId = category?.parentId;
    final formKey = GlobalKey<FormState>();
    final parents =
        allCategories.where((c) => c.id != category?.id).toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(category == null
              ? 'Nouvelle catégorie'
              : 'Modifier catégorie'),
          content: SizedBox(
            width: 360,
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Nom *'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int?>(
                  value: parentId,
                  decoration:
                      const InputDecoration(labelText: 'Catégorie parente'),
                  items: [
                    const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('— Aucune (catégorie racine) —')),
                    ...parents.map((c) => DropdownMenuItem<int?>(
                        value: c.id, child: Text(c.name))),
                  ],
                  onChanged: (v) => setState(() => parentId = v),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: descCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
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
                final cat = ProductCategory(
                  id: category?.id,
                  name: nameCtrl.text.trim(),
                  parentId: parentId,
                  description: descCtrl.text.trim().isEmpty
                      ? null
                      : descCtrl.text.trim(),
                );
                if (category == null) {
                  await ref
                      .read(productCategoryProvider.notifier)
                      .add(cat);
                } else {
                  await ref
                      .read(productCategoryProvider.notifier)
                      .edit(cat);
                }
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: Text(
                  category == null ? 'Créer' : 'Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Physical Inventory Tab ────────────────────────────────────────────────────

class _PhysicalInventoryTab extends ConsumerWidget {
  const _PhysicalInventoryTab();

  static const _statusColors = {
    'Brouillon': Colors.grey,
    'En cours':  Colors.blue,
    'Validé':    Colors.green,
    'Annulé':    Colors.red,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final inventoriesAsync = ref.watch(physicalInventoryProvider);
    final warehousesAsync = ref.watch(warehouseProvider);
    final productsAsync = ref.watch(productProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [
          const Spacer(),
          FilledButton.icon(
            onPressed: () {
              warehousesAsync.whenData((warehouses) =>
                  productsAsync.whenData((products) =>
                      _showCreateDialog(context, ref, warehouses, products)));
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Nouvel inventaire'),
          ),
        ]),
        const SizedBox(height: 12),
        Expanded(
          child: inventoriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur: $e')),
            data: (inventories) {
              if (inventories.isEmpty) {
                return const Center(
                    child: Text('Aucun inventaire physique'));
              }
              return ListView.builder(
                itemCount: inventories.length,
                itemBuilder: (ctx, i) {
                  final inv = inventories[i];
                  final color =
                      _statusColors[inv.status] ?? Colors.grey;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Row(children: [
                        Text(inv.reference,
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
                          child: Text(inv.status,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: color,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ]),
                      subtitle: Text(
                          '${inv.warehouseName ?? 'Tous entrepôts'} · '
                          '${MoroccoFormat.dateFromMs(inv.date)}',
                          style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant)),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 18),
                        itemBuilder: (_) => [
                          'Brouillon', 'En cours', 'Validé', 'Annulé'
                        ]
                            .map((s) => PopupMenuItem(
                                value: s, child: Text(s)))
                            .toList(),
                        onSelected: (s) => ref
                            .read(physicalInventoryProvider.notifier)
                            .updateStatus(inv.id!, s),
                      ),
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

  void _showCreateDialog(
      BuildContext context,
      WidgetRef ref,
      List<Warehouse> warehouses,
      List<Product> products) {
    int? selectedWarehouseId =
        warehouses.isNotEmpty ? warehouses.first.id : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Nouvel inventaire physique'),
          content: SizedBox(
            width: 380,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<int?>(
                value: selectedWarehouseId,
                decoration:
                    const InputDecoration(labelText: 'Entrepôt'),
                items: [
                  const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('— Tous les entrepôts —')),
                  ...warehouses.map((w) => DropdownMenuItem<int?>(
                      value: w.id, child: Text(w.name))),
                ],
                onChanged: (v) =>
                    setState(() => selectedWarehouseId = v),
              ),
              const SizedBox(height: 16),
              Text(
                'L\'inventaire sera créé avec tous les produits ayant un stock défini.',
                style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Annuler')),
            FilledButton(
              onPressed: () async {
                final repo =
                    ref.read(physicalInventoryRepoProvider);
                final seq = await repo.nextSequence();
                final now = DateTime.now();

                final inventory = PhysicalInventory(
                  reference:
                      'INV-${now.year}${now.month.toString().padLeft(2, '0')}-${seq.toString().padLeft(3, '0')}',
                  warehouseId: selectedWarehouseId,
                  date: now.millisecondsSinceEpoch,
                );

                // Create lines from all products with stock
                final lines = products
                    .where((p) => p.stock != null)
                    .map((p) => PhysicalInventoryLine(
                          productId: p.id,
                          productName: p.name,
                          expectedQty: p.stock!.toDouble(),
                          countedQty: p.stock!.toDouble(),
                        ))
                    .toList();

                await ref
                    .read(physicalInventoryProvider.notifier)
                    .add(inventory, lines);
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
