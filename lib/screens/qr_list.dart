import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sabang_es/screens/function/qr_listf.dart';

class QRListScreen extends StatefulWidget {
  const QRListScreen({super.key});

  @override
  State<QRListScreen> createState() => _QRListScreenState();
}

class _QRListScreenState extends State<QRListScreen> {
  final QRListFunctions _functions = QRListFunctions();
  final TextEditingController _searchController = TextEditingController();
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    _functions.loadQRCodes((qrCodes, selectedQRs) {
      setState(() {
        _functions.qrCodes = qrCodes;
        _functions.selectedQRs = selectedQRs;
        _selectAll = false;
      });
    });
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _functions.filterQRCodes(_searchController.text);
      _selectAll =
          _functions.selectedQRs.length == _functions.filteredQRCodes.length;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        title: const Text(
          'QR Code List',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),

      // Main list
      body:
          _functions.filteredQRCodes.isEmpty
              ? const Center(
                child: Text(
                  'No QR codes found',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _functions.filteredQRCodes.length,
                itemBuilder: (context, index) {
                  final qr = _functions.filteredQRCodes[index];
                  final isSelected = _functions.selectedQRs.contains(qr);

                  return Card(
                    color: isSelected ? Colors.blue[50] : Colors.white,
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Checkbox(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            _functions.toggleSelection(qr);
                            _selectAll =
                                _functions.selectedQRs.length ==
                                _functions.filteredQRCodes.length;
                          });
                        },
                      ),
                      title: Text(
                        qr.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email: ${qr.email}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            'Year: ${qr.year}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: Colors.blueAccent,
                            ),
                            onPressed:
                                () => _functions.showEditDialog(
                                  context,
                                  qr,
                                  setState,
                                ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                            ),
                            onPressed: () async {
                              await _functions.showDeleteDialog(
                                context,
                                qr,
                                setState,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

      // Bottom bar for batch actions
      bottomNavigationBar:
          _functions.selectedQRs.isNotEmpty
              ? BottomAppBar(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                        icon: Icon(
                          _selectAll ? Icons.deselect : Icons.select_all,
                          color: Colors.blue,
                        ),
                        tooltip: _selectAll ? 'Deselect All' : 'Select All',
                        onPressed: () {
                          setState(() {
                            _selectAll = !_selectAll;
                            _functions.selectAll(_selectAll);
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.document_scanner,
                          color: Colors.blue,
                        ),
                        tooltip: 'Export PDF',
                        onPressed: () => _functions.generateQRTablePdf(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.image, color: Colors.blue),
                        tooltip: 'Export Images',
                        onPressed: () => _functions.generateQRImages(context),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_forever,
                          color: Colors.red,
                        ),
                        tooltip: 'Delete Selected',
                        onPressed:
                            () => _functions.deleteSelectedQRCodes(
                              context,
                              setState,
                            ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        tooltip: 'Clear Selection',
                        onPressed: () {
                          setState(() {
                            _functions.selectAll(false);
                            _selectAll = false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              )
              : null,
    );
  }
}
