import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';

class AddBusScreen extends StatefulWidget {
  final String? editKey;
  final Map? busData;
  final String institute;

  const AddBusScreen({super.key, this.editKey, this.busData, required this.institute});

  @override
  State<AddBusScreen> createState() => _AddBusScreenState();
}

class _AddBusScreenState extends State<AddBusScreen> {
  final _formKey = GlobalKey<FormState>();
  final _busNameController = TextEditingController();
  final _busNoController = TextEditingController();
  final _driverMobileController = TextEditingController();
  final _monitorNameController = TextEditingController();
  final _monitorMobileController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  String _selectedRoute = "Select Route";
  String _selectedStatus = "Select Status";
  List<String> _filteredRoutes = ["Select Route"];
  final busStatus = ["Select Status", "Active", "Not Active"];
  final _ref = FirebaseDatabase.instance.ref().child("buses");
  final _route = FirebaseDatabase.instance.ref().child("Routs");

  @override
  void initState() {
    super.initState();
    if (widget.editKey != null && widget.busData != null) {
      _busNameController.text = widget.editKey!;
      _busNoController.text = widget.busData!['driverName'] ?? '';
      _driverMobileController.text = widget.busData!['driverMobile'].toString() ?? '';
      _monitorNameController.text = widget.busData!['monitorName'] ?? '';
      _monitorMobileController.text = widget.busData!['monitorMobile'] ?? '';
      _vehicleModelController.text = widget.busData!['vehicleModel'] ?? '';
      _vehicleNumberController.text = widget.busData!['vehicleNumber'] ?? '';
      _busNoController.text = widget.busData!['routeIdentityNumber'] ?? '';
      _selectedStatus = widget.busData!['Status'] ?? '';
    }
    loadRouts();
  }

  loadRouts()async{
    final snapshot = await _route.get();
    if (snapshot.exists) {
      final data = snapshot.value as Map;
      data.forEach((key, value) {
        _filteredRoutes.add(key);
      });
    }
    _selectedRoute = widget.busData!['Route'] ?? '';
    setState(() {});
  }

  Future<void> _saveBus() async {
    if (!_formKey.currentState!.validate()) return;

    final busName = _busNameController.text.trim();
    final data = {
      "vehicleModel": _vehicleModelController.text.trim(),
      "vehicleNumber": _vehicleNumberController.text.trim(),
      "routeIdentityNumber": _busNoController.text.trim(),
      "Status": _selectedStatus == "Select Status" ? "" : _selectedStatus,
      "Route": _selectedRoute == "Select Route" ? "" : _selectedRoute,
      "location": {"lat": "", "lng": ""},
      "institute": widget.institute
    };
    if(widget.editKey == null){
      data["isRunning"] = false;
      data["driverName"] = "";
      data["driverMobile"] = "";
      data["monitorName"] = "";
      data["monitorMobile"] = "";
    }

    await _ref.child(busName).set(data);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.editKey != null ? "Bus updated" : "Bus added")));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editKey != null;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(isEditing ? "Update Bus" : "Add Bus"),
        titleTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold,fontSize: 20),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _busNameController,
                enabled: !isEditing,
                decoration: const InputDecoration(labelText: "Bus Name"),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _busNoController,
                decoration: const InputDecoration(labelText: "Bus No"),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedRoute,
                decoration: const InputDecoration(labelText: "Route"),
                items: _filteredRoutes.map((bus) {
                  return DropdownMenuItem(value: bus, child: Text(bus));
                }).toList(),
                onChanged: (val) => setState(() => _selectedRoute = val.toString()),
                validator: (val) => val == null ? "Select Route" : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(labelText: "Status"),
                items: busStatus.map((bus) {
                  return DropdownMenuItem(value: bus, child: Text(bus));
                }).toList(),
                onChanged: (val) => setState(() => _selectedStatus = val.toString()),
                validator: (val) => val == null ? "Select Status" : null,
              ),
              const SizedBox(height: 10),
              // TextFormField(
              //   keyboardType: TextInputType.phone,
              //   inputFormatters: [
              //     FilteringTextInputFormatter.digitsOnly,
              //     LengthLimitingTextInputFormatter(10)],
              //   controller: _monitorMobileController,
              //   decoration: const InputDecoration(labelText: "Monitor Mobile"),
              //   validator: (val) => val!.isEmpty ? "Required" : null,
              // ),
              // const SizedBox(height: 10),
              TextFormField(
                controller: _vehicleModelController,
                decoration: const InputDecoration(labelText: "Vehicle Model"),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _vehicleNumberController,
                decoration: const InputDecoration(labelText: "Vehicle Number"),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveBus,
                child: Text(isEditing ? "Update" : "Create"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
