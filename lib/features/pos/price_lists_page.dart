import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/pos_sale.dart';
import '../../core/providers/providers.dart';

class PriceListsPage extends ConsumerWidget {
  const PriceListsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final priceListsAsync = ref.watch(priceListProvider);

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
                Text('Listes de prix',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                FilledButton.icon(
                  onPressed: () => _showDialog(context, ref),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nouvelle liste'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: priceListsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erreur: $e')),
                data: (lists) {
                  if (lists.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.price_change_outlined,
                              size: 48,
                              color: theme.colorScheme.outlineVariant),
                          const SizedBox(height: 8),
                          const Text('Aucune liste de prix'),
                          const SizedBox(height: 4),
                          Text(
                              'Créez des tarifs spéciaux (grossiste, VIP, promo…)',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: theme
                                      .colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    );
                  }
                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.5,
                    ),
                    itemCount: lists.length,
                    itemBuilder: (ctx, i) =>
                        _PriceListCard(pl: lists[i], ref: ref),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final discountCtrl = TextEditingController(text: '0');
    final formKey = GlobalKey<FormState>();
    final productsAsync = ref.read(productProvider);
    // Per-product overrides
    final overrides = <int, double>{};

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouvelle liste de prix'),
        content: SizedBox(
          width: 480,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child:
                  Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Nom *'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Description'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: discountCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Remise globale (%)',
                      suffixText: '%'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                const Divider(),
                const Text('Remises par produit (optionnel)',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                productsAsync.maybeWhen(
                  data: (products) => Column(
                    children: products.map((p) {
                      final ctrl = TextEditingController(
                          text: overrides[p.id]?.toString() ?? '');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(children: [
                          Expanded(
                              child: Text(p.name,
                                  style: const TextStyle(
                                      fontSize: 12))),
                          SizedBox(
                            width: 80,
                            child: TextField(
                              controller: ctrl,
                              decoration: const InputDecoration(
                                  labelText: '%',
                                  isDense: true,
                                  contentPadding:
                                      EdgeInsets.all(8)),
                              keyboardType: TextInputType.number,
                              onChanged: (v) {
                                final d = double.tryParse(v);
                                if (d != null && d > 0) {
                                  overrides[p.id!] = d;
                                } else {
                                  overrides.remove(p.id);
                                }
                              },
                            ),
                          ),
                        ]),
                      );
                    }).toList(),
                  ),
                  orElse: () => const SizedBox.shrink(),
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
              final discount =
                  double.tryParse(discountCtrl.text) ?? 0;

              final items = overrides.entries
                  .map((e) => PriceListItem(
                        priceListId: 0,
                        productId: e.key,
                        discountPercent: e.value,
                      ))
                  .toList();

              final pl = PriceList(
                name: nameCtrl.text.trim(),
                description: descCtrl.text.trim().isEmpty
                    ? null
                    : descCtrl.text.trim(),
                discountPercent: discount,
                createdAt: now,
                items: items,
              );
              await ref.read(priceListProvider.notifier).add(pl);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }
}

class _PriceListCard extends StatelessWidget {
  const _PriceListCard({required this.pl, required this.ref});
  final PriceList pl;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(Icons.price_change,
                  color: theme.colorScheme.primary, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(pl.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600)),
              if (pl.description != null)
                Text(pl.description!,
                    style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis),
              if (pl.discountPercent > 0)
                Text('Remise: -${pl.discountPercent.toStringAsFixed(0)}%',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.green)),
              Text('${pl.items.length} remise(s) produit',
                  style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSurfaceVariant)),
            ]),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: Colors.red, size: 18),
            onPressed: () =>
                ref.read(priceListProvider.notifier).remove(pl.id!),
          ),
        ]),
      ),
    );
  }
}
