import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_service.dart';
import '../models/bus_model.dart';
import '../models/route_model.dart';

class AddBusScreen extends StatefulWidget {
  final String? editBusId;
  final BusModel? busData;
  final String institute;

  const AddBusScreen({
    super.key,
    this.editBusId,
    this.busData,
    required this.institute
  });

  @override
  State<AddBusScreen> createState() => _AddBusScreenState();
}

class _AddBusScreenState extends State<AddBusScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbService = DatabaseService();

  final _busIdController = TextEditingController();
  final _busNumberController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehicleNumberController = TextEditingController();

  String? _selectedRoute;
  String _selectedStatus = "Active";
  List<RouteModel> _routes = [];
  final List<String> busStatus = ["Active", "Not Active"];

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.editBusId != null && widget.busData != null) {
      _busIdController.text = widget.editBusId!;
      _busNumberController.text = widget.busData!.busNumber;
      _vehicleModelController.text = widget.busData!.vehicleModel;
      _vehicleNumberController.text = widget.busData!.vehicleNumber;
      _selectedRoute = widget.busData!.routeId;
      _selectedStatus = widget.busData!.status;
    }
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    _dbService.getRoutesByInstitute(widget.institute).listen((routes) {
      setState(() {
        _routes = routes;
      });
    });
  }

  Future<void> _saveBus() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final busId = _busIdController.text.trim();

      final bus = BusModel(
        busId: busId,
        busNumber: _busNumberController.text.trim(),
        instituteId: widget.institute,
        driverId: widget.busData?.driverId,
        driverName: widget.busData?.driverName,
        driverMobile: widget.busData?.driverMobile,
        monitorId: widget.busData?.monitorId,
        monitorName: widget.busData?.monitorName,
        monitorMobile: widget.busData?.monitorMobile,
        routeId: _selectedRoute,
        vehicleModel: _vehicleModelController.text.trim(),
        vehicleNumber: _vehicleNumberController.text.trim(),
        status: _selectedStatus,
        isActive: widget.busData?.isActive ?? false,
      );

      if (widget.editBusId == null) {
        await _dbService.createBus(bus);
      } else {
        await _dbService.updateBus(busId, bus.toJson());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    widget.editBusId != null ? "Bus updated" : "Bus added"
                )
            )
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editBusId != null;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(isEditing ? "Update Bus" : "Add Bus"),
        titleTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _busIdController,
                enabled: !isEditing,
                decoration: const InputDecoration(
                    labelText: "Bus ID",
                    hintText: "e.g., bus_01"
                ),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _busNumberController,
                decoration: const InputDecoration(
                    labelText: "Bus Number",
                    hintText: "e.g., TN09AB1234"
                ),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 10),
              if (_routes.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _selectedRoute,
                  decoration: const InputDecoration(labelText: "Route"),
                  items: _routes.map((route) {
                    return DropdownMenuItem(
                        value: route.routeId,
                        child: Text(route.name)
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedRoute = val),
                ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(labelText: "Status"),
                items: busStatus.map((status) {
                  return DropdownMenuItem(value: status, child: Text(status));
                }).toList(),
                onChanged: (val) => setState(() => _selectedStatus = val!),
              ),
              const SizedBox(height: 10),
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
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _saveBus,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(isEditing ? "Update" : "Create"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}