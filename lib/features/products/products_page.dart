import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/app_lists.dart';
import '../../core/models/product.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/morocco_format.dart';

class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key});
  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  String _search = '';
  String _categoryFilter = 'Tous';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final async = ref.watch(productProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Produits & Services',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    async.whenOrNull(
                            data: (list) => Text('${list.length} articles',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme
                                        .onSurfaceVariant))) ??
                        const SizedBox.shrink(),
                  ],
                ),
                FilledButton.icon(
                  onPressed: () => _showDialog(context,
                      lists: ref.read(appListsProvider).valueOrNull ?? AppLists.defaults),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nouveau produit'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                SizedBox(
                  width: 320,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Rechercher...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: theme.colorScheme.outlineVariant)),
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                const SizedBox(width: 12),
                async.maybeWhen(
                  data: (products) {
                    final cats = ['Tous', ...{
                      for (final p in products)
                        if (p.category != null) p.category!
                    }];
                    return DropdownButton<String>(
                      value: cats.contains(_categoryFilter)
                          ? _categoryFilter
                          : 'Tous',
                      items: cats
                          .map((c) => DropdownMenuItem(
                              value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _categoryFilter = v!),
                      underline: const SizedBox.shrink(),
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: async.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erreur: $e')),
                data: (products) {
                  final filtered = products
                      .where((p) =>
                          (_categoryFilter == 'Tous' ||
                              p.category == _categoryFilter) &&
                          (p.name
                                  .toLowerCase()
                                  .contains(_search.toLowerCase()) ||
                              (p.reference ?? '')
                                  .toLowerCase()
                                  .contains(_search.toLowerCase())))
                      .toList();
                  return Card(
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                            theme.colorScheme.surfaceContainerLowest),
                        columnSpacing: 20,
                        headingTextStyle:
                            theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                        columns: const [
                          DataColumn(label: Text('PRODUIT / SERVICE')),
                          DataColumn(label: Text('RÉFÉRENCE')),
                          DataColumn(label: Text('CATÉGORIE')),
                          DataColumn(
                              label: Text('PRIX HT'), numeric: true),
                          DataColumn(label: Text('TVA')),
                          DataColumn(
                              label: Text('PRIX TTC'), numeric: true),
                          DataColumn(label: Text('STOCK')),
                          DataColumn(label: Text('STATUT')),
                          DataColumn(label: Text('ACTIONS')),
                        ],
                        rows: filtered
                            .map((p) => DataRow(cells: [
                                  DataCell(Text(p.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500))),
                                  DataCell(Text(p.reference ?? '—',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: theme.colorScheme
                                              .onSurfaceVariant))),
                                  DataCell(p.category != null
                                      ? _CatChip(
                                          category: p.category!)
                                      : const Text('—')),
                                  DataCell(Text(
                                      MoroccoFormat.mad(p.priceHt),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500))),
                                  DataCell(Text(MoroccoFormat.tvaLabel(
                                      p.tvaRate))),
                                  DataCell(Text(
                                      MoroccoFormat.mad(p.priceTtc),
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: theme
                                              .colorScheme.primary))),
                                  DataCell(Text(p.isService
                                      ? 'Service'
                                      : '${p.stock}')),
                                  DataCell(_ProductStatus(
                                      status: p.status)),
                                  DataCell(Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                            Icons.edit_outlined,
                                            size: 18),
                                        onPressed: () =>
                                            _showDialog(context,
                                                product: p,
                                                lists: ref.read(appListsProvider).valueOrNull ?? AppLists.defaults),
                                        visualDensity:
                                            VisualDensity.compact,
                                      ),
                                      IconButton(
                                        icon: Icon(
                                            Icons.delete_outline,
                                            size: 18,
                                            color:
                                                theme.colorScheme.error),
                                        onPressed: () =>
                                            _confirmDelete(context, p),
                                        visualDensity:
                                            VisualDensity.compact,
                                      ),
                                    ],
                                  )),
                                ]))
                            .toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Product p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le produit'),
        content: Text('Supprimer "${p.name}" ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () {
              ref.read(productProvider.notifier).remove(p.id!);
              Navigator.of(ctx).pop();
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showDialog(BuildContext context, {Product? product, AppLists? lists}) {
    lists ??= AppLists.defaults;
    final nameCtrl =
        TextEditingController(text: product?.name ?? '');
    final refCtrl =
        TextEditingController(text: product?.reference ?? '');
    final priceCtrl = TextEditingController(
        text: product != null ? product.priceHt.toStringAsFixed(2) : '');
    final stockCtrl = TextEditingController(
        text: product?.stock?.toString() ?? '');
    String? selectedCategory = lists.productCategories.contains(product?.category)
        ? product!.category
        : null;
    String? selectedUnit = lists.productUnits.contains(product?.unit)
        ? product!.unit
        : null;
    final double defaultTva = lists.tvaRates.contains(20.0) ? 20.0 : lists.tvaRates.last;
    double selectedTva = lists.tvaRates.contains(product?.tvaRate ?? 20.0)
        ? (product?.tvaRate ?? defaultTva)
        : defaultTva;
    bool isService = product?.isService ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(
              product == null ? 'Nouveau produit' : 'Modifier'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Désignation *')),
                  const SizedBox(height: 12),
                  TextField(
                      controller: refCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Référence')),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    value: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Catégorie'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('— Choisir —')),
                      ...lists.productCategories.map((c) =>
                          DropdownMenuItem(value: c, child: Text(c))),
                    ],
                    onChanged: (v) => setState(() => selectedCategory = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Prix HT (DH)')),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<double>(
                    value: selectedTva,
                    decoration: const InputDecoration(labelText: 'Taux TVA'),
                    items: lists.tvaRates
                        .map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(MoroccoFormat.tvaLabel(r))))
                        .toList(),
                    onChanged: (v) => setState(() => selectedTva = v!),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Service (pas de stock)'),
                    value: isService,
                    onChanged: (v) =>
                        setState(() => isService = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (!isService) ...[
                    const SizedBox(height: 8),
                    TextField(
                        controller: stockCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Stock initial')),
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    value: selectedUnit,
                    decoration: const InputDecoration(labelText: 'Unité'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('— Choisir —')),
                      ...lists.productUnits.map((u) =>
                          DropdownMenuItem(value: u, child: Text(u))),
                    ],
                    onChanged: (v) => setState(() => selectedUnit = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Annuler')),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                final priceHt =
                    double.tryParse(priceCtrl.text) ?? 0;
                final stock = isService
                    ? null
                    : int.tryParse(stockCtrl.text) ?? 0;
                final now = DateTime.now().millisecondsSinceEpoch;
                final p = Product(
                  id: product?.id,
                  name: nameCtrl.text.trim(),
                  reference: refCtrl.text.trim().isEmpty
                      ? null
                      : refCtrl.text.trim(),
                  category: selectedCategory,
                  priceHt: priceHt,
                  tvaRate: selectedTva,
                  stock: stock,
                  unit: selectedUnit,
                  createdAt: product?.createdAt ?? now,
                );
                if (product == null) {
                  ref.read(productProvider.notifier).add(p);
                } else {
                  ref.read(productProvider.notifier).edit(p);
                }
                Navigator.of(ctx).pop();
              },
              child:
                  Text(product == null ? 'Ajouter' : 'Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  const _CatChip({required this.category});
  final String category;
  static const _colors = {
    'Services': Color(0xFF1565C0),
    'Logiciels': Color(0xFF6A1B9A),
    'Matériel': Color(0xFF2E7D32),
    'Support': Color(0xFFE65100),
  };
  @override
  Widget build(BuildContext context) {
    final color = _colors[category] ?? Colors.blueGrey.shade600;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Text(category,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _ProductStatus extends StatelessWidget {
  const _ProductStatus({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final isActive = status == 'Actif';
    final color =
        isActive ? Colors.green.shade700 : Colors.grey.shade500;
    final bg = isActive
        ? Colors.green.withValues(alpha: 0.1)
        : Colors.grey.withValues(alpha: 0.1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
