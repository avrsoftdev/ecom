import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/fresh_veggie_header.dart';
import '../../../../core/widgets/location_autocomplete_field.dart';

class SavedAddressesPage extends StatefulWidget {
  const SavedAddressesPage({super.key});

  @override
  State<SavedAddressesPage> createState() => _SavedAddressesPageState();
}

class _SavedAddressesPageState extends State<SavedAddressesPage> {
  late Future<List<_SavedAddress>> _addressesFuture;

  @override
  void initState() {
    super.initState();
    _addressesFuture = _loadAddresses();
  }

  void _refresh() {
    setState(() {
      _addressesFuture = _loadAddresses();
    });
  }

  Future<List<_SavedAddress>> _loadAddresses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const [];

    final firestore = FirebaseFirestore.instance;
    final userDocRef = firestore.collection('users').doc(user.uid);
    final results = await Future.wait([
      userDocRef.get(),
      firestore
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .limit(20)
          .get(),
    ]);

    final profileDoc = results[0] as DocumentSnapshot<Map<String, dynamic>>;
    final ordersSnapshot = results[1] as QuerySnapshot<Map<String, dynamic>>;
    final profileData = profileDoc.data() ?? const <String, dynamic>{};

    final addresses = <_SavedAddress>[];
    final profileAddress = profileData['address'] as String?;
    if (profileAddress != null && profileAddress.trim().isNotEmpty) {
      addresses.add(_SavedAddress(
        id: 'profile',
        title: 'Account address',
        address: profileAddress.trim(),
        phone: profileData['phone'] as String?,
        source: 'Profile',
        canDelete: false,
      ));
    }

    final savedAddresses = (profileData['savedAddresses'] as List?)
            ?.whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList() ??
        const <Map<String, dynamic>>[];
    addresses.addAll(savedAddresses.map((data) {
      return _SavedAddress(
        id: (data['id'] as String?) ?? '',
        title: _addressTitleFromData(data),
        address: _addressFromData(data),
        phone: data['phoneNumber'] as String?,
        source: 'Saved',
        canDelete: true,
      );
    }));

    addresses.addAll(ordersSnapshot.docs.map((doc) {
      final data = doc.data();
      final structured = data['checkoutContact'];
      return _SavedAddress(
        id: 'order-${doc.id}',
        title: (data['customerName'] as String?)?.trim().isNotEmpty == true
            ? (data['customerName'] as String).trim()
            : 'Recent order address',
        address: structured is Map<String, dynamic>
            ? _addressFromData(structured)
            : ((data['shippingAddress'] as String?) ?? ''),
        phone: structured is Map<String, dynamic>
            ? structured['phoneNumber'] as String?
            : data['phone'] as String?,
        source: 'Recent order',
        canDelete: false,
      );
    }));

    final seen = <String>{};
    return addresses.where((address) {
      final key =
          '${address.title}|${address.address}|${address.phone ?? ''}'
              .toLowerCase();
      return address.address.trim().isNotEmpty && seen.add(key);
    }).toList();
  }

  Future<void> _deleteAddress(_SavedAddress address) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !address.canDelete) return;

    final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snapshot = await userDocRef.get();
    final savedAddresses = (snapshot.data()?['savedAddresses'] as List?)
            ?.whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList() ??
        const <Map<String, dynamic>>[];
    final updatedAddresses = savedAddresses
        .where((entry) => entry['id'] != address.id)
        .toList();

    await userDocRef.set(
      {
        'savedAddresses': updatedAddresses,
        'updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    _refresh();
  }

  Future<void> _openAddAddressSheet() async {
    final didSave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const _AddAddressSheet(),
    );

    if (didSave == true) {
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: FreshVeggieHeader(
        showBackButton: true,
        onBackPressed: () => context.pop(),
      ),
      body: FutureBuilder<List<_SavedAddress>>(
        future: _addressesFuture,
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final addresses = snapshot.data ?? const <_SavedAddress>[];

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 96),
              children: [
                _AddAddressHeroButton(
                  onTap: _openAddAddressSheet,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Saved Address',
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Addresses linked to your account for faster checkout.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 18),
                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (addresses.isEmpty)
                  _EmptyAddressState(onAdd: _openAddAddressSheet)
                else
                  ...addresses.map(
                    (address) => _AddressCard(
                      address: address,
                      onDelete: address.canDelete
                          ? () => _deleteAddress(address)
                          : null,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AddAddressHeroButton extends StatelessWidget {
  const _AddAddressHeroButton({
    required this.onTap,
    required this.colorScheme,
  });

  final VoidCallback onTap;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.add_location_alt_rounded,
                    color: colorScheme.onPrimary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add new address',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Save a delivery location for faster checkout',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onPrimary
                                  .withValues(alpha: 0.82),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: colorScheme.onPrimary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddAddressSheet extends StatefulWidget {
  const _AddAddressSheet();

  @override
  State<_AddAddressSheet> createState() => _AddAddressSheetState();
}

class _AddAddressSheetState extends State<_AddAddressSheet> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _nameController = TextEditingController();
  final _houseController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _labelController.dispose();
    _nameController.dispose();
    _houseController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _landmarkController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      final addressId = DateTime.now().microsecondsSinceEpoch.toString();
      final address = {
        'id': addressId,
        'label': _labelController.text.trim(),
        'name': _nameController.text.trim(),
        'houseFlatBuilding': _houseController.text.trim(),
        'streetAreaColony': _streetController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'landmark': _landmarkController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {
          'savedAddresses': FieldValue.arrayUnion([address]),
          'updated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save address. Try again.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Add address',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed:
                        _isSaving ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _TextInput(
                controller: _labelController,
                label: 'Label',
                icon: Icons.bookmark_border_rounded,
                hint: 'Home, Work, Parents',
              ),
              const SizedBox(height: 12),
              _TextInput(
                controller: _nameController,
                label: 'Receiver name',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 12),
              _TextInput(
                controller: _houseController,
                label: 'House / Flat / Building No.',
                icon: Icons.home_outlined,
                isRequired: true,
              ),
              const SizedBox(height: 12),
              LocationAutocompleteField(
                controller: _streetController,
                label: 'Street / Area / Colony Name',
                icon: Icons.location_on_outlined,
                onChanged: (_) {},
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
                onSuggestionSelected: (suggestion) {
                  if (suggestion.city != null) {
                    _cityController.text = suggestion.city!;
                  }
                  if (suggestion.state != null) {
                    _stateController.text = suggestion.state!;
                  }
                  if (suggestion.pincode != null) {
                    _pincodeController.text = suggestion.pincode!;
                  }
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _TextInput(
                      controller: _cityController,
                      label: 'City',
                      icon: Icons.location_city_outlined,
                      isRequired: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TextInput(
                      controller: _stateController,
                      label: 'State',
                      icon: Icons.map_outlined,
                      isRequired: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _TextInput(
                      controller: _pincodeController,
                      label: 'Pincode',
                      icon: Icons.pin_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      isRequired: true,
                      validator: _validatePincode,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TextInput(
                      controller: _phoneController,
                      label: 'Phone',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      validator: _validatePhone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _TextInput(
                controller: _landmarkController,
                label: 'Landmark',
                icon: Icons.near_me_outlined,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveAddress,
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(_isSaving ? 'Saving...' : 'Save address'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validatePincode(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Required';
    if (!RegExp(r'^\d{6}$').hasMatch(trimmed)) return 'Invalid';
    return null;
  }

  String? _validatePhone(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(trimmed)) return 'Invalid';
    return null;
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.onDelete,
  });

  final _SavedAddress address;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.location_on_rounded,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          address.title,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                      _SourceChip(label: address.source),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    address.address,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.25,
                        ),
                  ),
                  if (address.phone?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 6),
                    Text(
                      address.phone!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Delete address',
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyAddressState extends StatelessWidget {
  const _EmptyAddressState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 64),
      child: Column(
        children: [
          Icon(
            Icons.add_location_alt_outlined,
            size: 64,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 14),
          Text(
            'No saved addresses yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add a delivery address to reuse it during checkout.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add address'),
          ),
        ],
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.isRequired = false,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool isRequired;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator ??
          (isRequired
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  return null;
                }
              : null),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _SavedAddress {
  const _SavedAddress({
    required this.id,
    required this.title,
    required this.address,
    required this.source,
    required this.canDelete,
    this.phone,
  });

  final String id;
  final String title;
  final String address;
  final String source;
  final bool canDelete;
  final String? phone;
}

String _addressFromData(Map<String, dynamic> data) {
  final address = [
    data['houseFlatBuilding'],
    data['streetAreaColony'],
    data['landmark'],
    data['city'],
    data['state'],
    data['pincode'],
  ]
      .whereType<String>()
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .join(', ');

  return address.isNotEmpty ? address : ((data['address'] as String?) ?? '');
}

String _addressTitleFromData(Map<String, dynamic> data) {
  final label = (data['label'] as String?)?.trim();
  if (label != null && label.isNotEmpty) return label;

  final name = (data['name'] as String?)?.trim();
  if (name != null && name.isNotEmpty) return name;

  return 'Saved address';
}
