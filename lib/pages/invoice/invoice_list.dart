import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/invoice.dart';
import 'invoice_detail.dart';

class InvoiceList extends StatefulWidget {
  final List<Invoice> invoices;

  const InvoiceList({super.key, required this.invoices});

  @override
  State<InvoiceList> createState() => _InvoiceListState();
}

class _InvoiceListState extends State<InvoiceList> {
  // Multi-select filter values
  String? selectedFilterType; // Vehicle, Customer, Mechanic
  String? selectedFilterValue; // The actual ID value
  String? selectedStatus;
  String? selectedPaymentStatus;
  List<Invoice> filteredInvoices = [];
  bool _isFilterExpanded = false; // Add this for collapsible filter

  @override
  void initState() {
    super.initState();
    filteredInvoices = widget.invoices;
  }

  void _applyFilters() {
    setState(() {
      filteredInvoices = widget.invoices.where((invoice) {
        bool matchesFilter =
            selectedFilterType == null ||
            selectedFilterValue == null ||
            selectedFilterValue == 'All' ||
            _checkFilterMatch(invoice);

        bool matchesStatus =
            selectedStatus == null ||
            selectedStatus == 'All' ||
            invoice.status == selectedStatus;

        bool matchesPaymentStatus =
            selectedPaymentStatus == null ||
            selectedPaymentStatus == 'All' ||
            invoice.paymentStatus == selectedPaymentStatus;

        return matchesFilter && matchesStatus && matchesPaymentStatus;
      }).toList();
    });
  }

  bool _checkFilterMatch(Invoice invoice) {
    switch (selectedFilterType) {
      case 'Vehicle':
        return invoice.vehicleId == selectedFilterValue;
      case 'Customer':
        return invoice.customerId == selectedFilterValue;
      case 'Mechanic':
        return invoice.assignedMechanicId == selectedFilterValue;
      default:
        return true;
    }
  }

  void _clearAllFilters() {
    setState(() {
      selectedFilterType = null;
      selectedFilterValue = null;
      selectedStatus = null;
      selectedPaymentStatus = null;
      filteredInvoices = widget.invoices;
    });
  }

  List<String> get _filterTypes {
    return ['Vehicle', 'Customer', 'Mechanic'];
  }

  List<String> get _filterValues {
    if (selectedFilterType == null) return [];

    Set<String> values = {};
    for (var invoice in widget.invoices) {
      switch (selectedFilterType) {
        case 'Vehicle':
          values.add(invoice.vehicleId);
          break;
        case 'Customer':
          values.add(invoice.customerId);
          break;
        case 'Mechanic':
          values.add(invoice.assignedMechanicId);
          break;
      }
    }

    List<String> sortedValues = values.toList()..sort();
    return ['All', ...sortedValues];
  }

  List<String> get _statuses {
    return ['All', 'Pending', 'Approved', 'Rejected'];
  }

  List<String> get _paymentStatuses {
    return ['All', 'Paid', 'Unpaid'];
  }

  String _getActiveFiltersText() {
    List<String> activeFilters = [];
    if (selectedFilterValue != null && selectedFilterValue != 'All') {
      activeFilters.add(selectedFilterValue!);
    }
    if (selectedStatus != null && selectedStatus != 'All') {
      activeFilters.add(selectedStatus!);
    }
    if (selectedPaymentStatus != null && selectedPaymentStatus != 'All') {
      activeFilters.add(selectedPaymentStatus!);
    }

    if (activeFilters.isEmpty) {
      return 'No filters applied';
    }
    return 'Active: ${activeFilters.join(', ')}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPaymentStatusColor(String paymentStatus) {
    switch (paymentStatus.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'unpaid':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice List'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Compact Filter Section
          Container(
            padding: const EdgeInsets.all(12.0),
            color: Colors.grey[100],
            child: Column(
              children: [
                // Filter Header with Expand/Collapse
                Row(
                  children: [
                    Icon(Icons.filter_list, color: Colors.blue[600], size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Active filters indicator
                    if (_getActiveFiltersText() != 'No filters applied')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _getActiveFiltersText(),
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    const Spacer(),
                    // Results count
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${filteredInvoices.length} results',
                        style: TextStyle(
                          color: Colors.green[800],
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Clear All Button
                    ElevatedButton(
                      onPressed: _clearAllFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        minimumSize: const Size(0, 0),
                      ),
                      child: const Text(
                        'Clear',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Expand/Collapse button
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isFilterExpanded = !_isFilterExpanded;
                        });
                      },
                      icon: Icon(
                        _isFilterExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: Colors.blue[600],
                      ),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),

                // Quick Filter Buttons (Always Visible)
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedStatus = 'Pending';
                            selectedPaymentStatus = null;
                            _applyFilters();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedStatus == 'Pending'
                              ? Colors.orange
                              : Colors.orange[100],
                          foregroundColor: selectedStatus == 'Pending'
                              ? Colors.white
                              : Colors.orange[800],
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          minimumSize: const Size(0, 0),
                        ),
                        child: const Text(
                          'Pending',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedPaymentStatus = 'Unpaid';
                            selectedStatus = null;
                            _applyFilters();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedPaymentStatus == 'Unpaid'
                              ? Colors.red
                              : Colors.red[100],
                          foregroundColor: selectedPaymentStatus == 'Unpaid'
                              ? Colors.white
                              : Colors.red[800],
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          minimumSize: const Size(0, 0),
                        ),
                        child: const Text(
                          'Unpaid',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),

                // Expandable Advanced Filters
                if (_isFilterExpanded) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Filter Type Selection Row
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedFilterType,
                          decoration: const InputDecoration(
                            labelText: 'Filter By',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            isDense: true,
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                          dropdownColor: Colors.white,
                          items: _filterTypes
                              .map(
                                (filterType) => DropdownMenuItem(
                                  value: filterType,
                                  child: Text(
                                    filterType,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedFilterType = value;
                              selectedFilterValue = null;
                              _applyFilters();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Autocomplete<String>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text == '') {
                              return _filterValues.where(
                                (option) => option != 'All',
                              );
                            }
                            return _filterValues
                                .where((String option) {
                                  return option.toLowerCase().contains(
                                    textEditingValue.text.toLowerCase(),
                                  );
                                })
                                .where((option) => option != 'All');
                          },
                          onSelected: (String selection) {
                            setState(() {
                              selectedFilterValue = selection;
                              _applyFilters();
                            });
                          },
                          fieldViewBuilder:
                              (
                                BuildContext context,
                                TextEditingController textEditingController,
                                FocusNode focusNode,
                                VoidCallback onFieldSubmitted,
                              ) {
                                // Set initial value if selectedFilterValue is not null
                                if (selectedFilterValue != null &&
                                    selectedFilterValue != 'All' &&
                                    textEditingController.text.isEmpty) {
                                  textEditingController.text =
                                      selectedFilterValue!;
                                  // Move cursor to end without selecting text
                                  textEditingController
                                      .selection = TextSelection.fromPosition(
                                    TextPosition(
                                      offset: textEditingController.text.length,
                                    ),
                                  );
                                }

                                return TextFormField(
                                  controller: textEditingController,
                                  focusNode: focusNode,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Type or Select Value',
                                    border: const OutlineInputBorder(),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    isDense: true,
                                    hintText: 'Start typing...',
                                    suffixIcon:
                                        textEditingController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(
                                              Icons.clear,
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              textEditingController.clear();
                                              selectedFilterValue = null;
                                              setState(() {
                                                _applyFilters();
                                              });
                                            },
                                          )
                                        : null,
                                  ),
                                  onChanged: (value) {
                                    // Only update selectedFilterValue, don't call setState here
                                    selectedFilterValue = value.isEmpty
                                        ? null
                                        : value;
                                    // Apply filters with a slight delay to avoid rebuilding on every keystroke
                                    Future.delayed(
                                      const Duration(milliseconds: 300),
                                      () {
                                        if (mounted &&
                                            selectedFilterValue ==
                                                (value.isEmpty
                                                    ? null
                                                    : value)) {
                                          setState(() {
                                            // Just trigger a rebuild for the results count, don't touch the text field
                                          });
                                          _applyFilters();
                                        }
                                      },
                                    );
                                  },
                                  onFieldSubmitted: (value) {
                                    // Apply filters immediately when user presses enter
                                    setState(() {
                                      selectedFilterValue = value.isEmpty
                                          ? null
                                          : value;
                                      _applyFilters();
                                    });
                                  },
                                );
                              },
                          optionsViewBuilder:
                              (
                                BuildContext context,
                                AutocompleteOnSelected<String> onSelected,
                                Iterable<String> options,
                              ) {
                                return Align(
                                  alignment: Alignment.topLeft,
                                  child: Material(
                                    elevation: 4.0,
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                    child: Container(
                                      constraints: const BoxConstraints(
                                        maxHeight: 200,
                                      ),
                                      width:
                                          MediaQuery.of(context).size.width *
                                          0.4,
                                      child: ListView.builder(
                                        padding: EdgeInsets.zero,
                                        shrinkWrap: true,
                                        itemCount: options.length,
                                        itemBuilder:
                                            (BuildContext context, int index) {
                                              final String option = options
                                                  .elementAt(index);
                                              return InkWell(
                                                onTap: () => onSelected(option),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8,
                                                      ),
                                                  child: Text(
                                                    option,
                                                    style: const TextStyle(
                                                      color: Colors.black87,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                      ),
                                    ),
                                  ),
                                );
                              },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Status Filters Row
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedStatus,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            isDense: true,
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                          dropdownColor: Colors.white,
                          items: _statuses
                              .map(
                                (status) => DropdownMenuItem(
                                  value: status,
                                  child: Row(
                                    children: [
                                      if (status != 'All')
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(status),
                                            shape: BoxShape.circle,
                                          ),
                                          margin: const EdgeInsets.only(
                                            right: 6,
                                          ),
                                        ),
                                      Text(
                                        status,
                                        style: const TextStyle(
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedStatus = value;
                              _applyFilters();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedPaymentStatus,
                          decoration: const InputDecoration(
                            labelText: 'Payment',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            isDense: true,
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                          dropdownColor: Colors.white,
                          items: _paymentStatuses
                              .map(
                                (paymentStatus) => DropdownMenuItem(
                                  value: paymentStatus,
                                  child: Row(
                                    children: [
                                      if (paymentStatus != 'All')
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: _getPaymentStatusColor(
                                              paymentStatus,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          margin: const EdgeInsets.only(
                                            right: 6,
                                          ),
                                        ),
                                      Text(
                                        paymentStatus,
                                        style: const TextStyle(
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedPaymentStatus = value;
                              _applyFilters();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Invoice List
          Expanded(
            child: filteredInvoices.isEmpty
                ? const Center(
                    child: Text(
                      'No invoices found',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: filteredInvoices.length,
                    itemBuilder: (context, index) {
                      final invoice = filteredInvoices[index];
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  InvoiceDetail(invoice: invoice),
                            ),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header Row
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      invoice.invoiceId,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'RM ${invoice.grandTotal.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Status Badges
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                          invoice.status,
                                        ).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _getStatusColor(
                                            invoice.status,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        invoice.status,
                                        style: TextStyle(
                                          color: _getStatusColor(
                                            invoice.status,
                                          ),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getPaymentStatusColor(
                                          invoice.paymentStatus,
                                        ).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _getPaymentStatusColor(
                                            invoice.paymentStatus,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        invoice.paymentStatus,
                                        style: TextStyle(
                                          color: _getPaymentStatusColor(
                                            invoice.paymentStatus,
                                          ),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Details
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Customer: ${invoice.customerId}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            'Vehicle: ${invoice.vehicleId}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            'Mechanic: ${invoice.assignedMechanicId}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Issue: ${invoice.issueDate.day}/${invoice.issueDate.month}/${invoice.issueDate.year}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 13,
                                          ),
                                        ),
                                        if (invoice.paymentDate != null)
                                          Text(
                                            'Paid: ${invoice.paymentDate!.day}/${invoice.paymentDate!.month}/${invoice.paymentDate!.year}',
                                            style: TextStyle(
                                              color: Colors.green[600],
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),

                                if (invoice.notes.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Note: ${invoice.notes}',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
