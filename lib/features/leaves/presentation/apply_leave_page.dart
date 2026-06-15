import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gears_flutter/features/leaves/data/leaves_api.dart';
import 'package:gears_flutter/features/leaves/data/models/leave.dart';
import 'package:gears_flutter/features/leaves/data/models/leave_attachment.dart';
import 'package:gears_flutter/features/leaves/data/models/leave_availability.dart';
import 'package:gears_flutter/features/leaves/data/models/leave_summary.dart';
import 'package:gears_flutter/features/leaves/data/models/leave_summary_item.dart';
import 'package:gears_flutter/features/leaves/presentation/widgets/leave_detail_date_chip.dart';
import 'package:gears_flutter/features/leaves/utils/apply_leave_summary_builder.dart';
import 'package:gears_flutter/features/leaves/utils/leave_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';

/// Mirrors iOS [ApplyLeaveView].
class ApplyLeavePage extends StatefulWidget {
  const ApplyLeavePage({
    this.leaveId,
    this.initialLeave,
    this.initialAttachments = const [],
    super.key,
  });

  final String? leaveId;
  final Leave? initialLeave;
  final List<LeaveAttachment> initialAttachments;

  bool get isUpdate => leaveId != null;

  @override
  State<ApplyLeavePage> createState() => _ApplyLeavePageState();
}

class _ApplyLeavePageState extends State<ApplyLeavePage> {
  final _api = LeavesApi();
  final _commentController = TextEditingController();
  final _imagePicker = ImagePicker();

  bool _isLoading = false;
  bool _isLoadedData = false;
  bool _coveringEmployeeRequired = false;
  int _empId = 0;
  String _employeeDisplayName = 'Employee';

  List<LeaveType> _leaveTypes = const [];
  List<LeaveEmployee> _coveringEmployees = const [];
  LeaveType? _leaveType;
  LeaveEmployee? _coveringEmployee;

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isHalfDay = false;
  LeaveShift? _shiftType = const LeaveShift(id: 1, name: 'Morning');
  int _shiftSegmentIndex = 0;
  bool _requireDelegation = false;

  LeaveSummary? _leaveSummary;
  LeaveAvailability? _leaveAvailability;
  List<LeaveSummaryItem> _summaryItems = const [];
  List<LeaveAttachment> _attachments = const [];

  int _coveringValidated = 0;
  int _coveringAvailabilityValidated = 0;

  int get _leaveMasterId => int.tryParse(widget.leaveId ?? '') ?? 0;

  @override
  void initState() {
    super.initState();
    _attachments = List.of(widget.initialAttachments);
    _loadForm();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadForm() async {
    setState(() => _isLoading = true);
    try {
      final initialData = await _api.getLeaveInitialData();
      if (!mounted) return;

      _leaveTypes = initialData.leaveTypes;
      _coveringEmployees = initialData.coveringEmployees;
      _coveringEmployeeRequired = initialData.coveringEmployeeRequired;
      _empId = initialData.empId;
      _employeeDisplayName =
          initialData.employeeDisplayName ?? _employeeDisplayName;

      if (widget.isUpdate && widget.initialLeave != null) {
        _populateFromLeave(widget.initialLeave!);
        final summary = await _api.getLeaveSummary(_summaryPayload());
        LeaveAvailability? availability;
        try {
          availability =
              await _api.checkLeaveAvailability(_availabilityPayload());
        } catch (_) {}
        if (!mounted) return;
        _leaveSummary = summary;
        _leaveAvailability = availability;
        _summaryItems = ApplyLeaveSummaryBuilder.build(
          summary: summary,
          availability: availability,
        );
      }

      setState(() {
        _isLoadedData = true;
        _isLoading = false;
      });
    } on LeavesApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('Something went wrong. Please try again.');
    }
  }

  void _populateFromLeave(Leave leave) {
    _commentController.text = leave.comment ?? '';
    _leaveType = leave.leaveType;
    _coveringEmployee = leave.coveringEmployee;
    _startDate = _parseDate(leave.startDate);
    _endDate = _parseDate(leave.endDate);
    _requireDelegation = (leave.leaveInfo?.requireDelegation ?? 0) == 1;
    _isHalfDay = leave.isHalfDay == 1;
    if (_isHalfDay) {
      _shiftType = leave.shiftType ??
          const LeaveShift(id: 1, name: 'Morning');
      _shiftSegmentIndex = (_shiftType?.id ?? 1) == 1 ? 0 : 1;
    }
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value) ??
        DateTime.tryParse(value.substring(0, 10));
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<bool> _confirm(String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  bool _validateForm({bool showError = false}) {
    String? error;
    if (_leaveType?.id == null) {
      error = 'Please select a leave type.';
    } else if (_startDate == null) {
      error = 'Please select a start date.';
    } else if (_endDate == null) {
      error = 'Please select an end date.';
    } else if (_isHalfDay && _shiftType == null) {
      error = 'Please select a shift.';
    }

    if (error != null && showError) {
      _showMessage(error);
      return false;
    }
    return error == null;
  }

  bool _validateSubmit() {
    if (!_validateForm(showError: true)) return false;
    if (_coveringEmployeeRequired && _coveringEmployee == null) {
      _showMessage('Please select a covering employee.');
      return false;
    }
    if ((_leaveType?.isAttachmentRequired ?? false) && _attachments.isEmpty) {
      _showMessage('Attachment is required for ${_leaveType?.name ?? 'leave'}.');
      return false;
    }
    return true;
  }

  bool get _canUseHalfDay {
    if (!_validateForm()) return false;
    if (_startDate == null || _endDate == null) return false;
    return LeaveUtils.toApiDate(_startDate!) ==
        LeaveUtils.toApiDate(_endDate!);
  }

  Map<String, dynamic> _summaryPayload() {
    final type = _leaveType!;
    return {
      'leaveTypeID': type.id,
      'value': type.id,
      'label': type.name,
      'isDailyBasisAccrual': type.isDailyBasisAccrual ?? 0,
      'annualEligibilityDays': type.annualEligibilityDays ?? 0,
      'stretchDays': type.stretchDays ?? 0,
      'policyMasterID': type.policyMasterId ?? 0,
      'isCalenderDays': type.isCalendarDays ?? false,
      'allowMinus': type.isAllowsMinus ?? 0,
      'leaveGroupID': type.leaveGroupId ?? 0,
      'balance': type.balance ?? 0,
      'attachmentRequired': type.isAttachmentRequired ?? false,
    };
  }

  Map<String, dynamic> _availabilityPayload() {
    final type = _leaveType!;
    final summary = _leaveSummary;
    final entitle = (summary?.isDailyBasisAccrual ?? 0) == 0
        ? summary?.balance ?? 0
        : summary?.balanceOnYearEnd ?? 0;
    return {
      'leaveTypeID': type.id,
      'value': type.id,
      'label': type.name,
      'startDate': LeaveUtils.toApiDate(_startDate!),
      'endDate': LeaveUtils.toApiDate(_endDate!),
      'entitle': entitle,
      'isHalfDay': _isHalfDay ? 1 : 0,
      'stretchDays': type.stretchDays ?? 0,
      'policyMasterID': type.policyMasterId ?? 0,
      'isCalenderDays': type.isCalendarDays ?? false,
      'allowMinus': type.isAllowsMinus ?? 0,
      'leaveGroupID': type.leaveGroupId ?? 0,
      'balance': type.balance ?? 0,
      'attachmentRequired': type.isAttachmentRequired ?? false,
    };
  }

  Map<String, dynamic> _savePayload({required int isConfirmed}) {
    final type = _leaveType!;
    final summary = _leaveSummary;
    final availability = _leaveAvailability;
    final entitle = type.policyMasterId == 1 &&
            (summary?.isDailyBasisAccrual ?? 0) == 1
        ? summary?.balanceOnYearEnd ?? 0
        : summary?.balance ?? 0;

    final payload = <String, dynamic>{
      'leaveTypeID': type.id,
      'policyMasterID': type.policyMasterId ?? 0,
      'leaveGroupID': type.leaveGroupId ?? 0,
      'startDate': LeaveUtils.toApiDate(_startDate!),
      'endDate': LeaveUtils.toApiDate(_endDate!),
      'entitle': entitle,
      'isHalfDay': _isHalfDay,
      'approvedYN': 0,
      'empID': [_empId],
      'applicationType': [1],
      'leaveType': type.id,
      'leaveAvailable': entitle,
      'leaveApplied': availability?.applied ?? 0,
      'workingDays': availability?.working ?? 0,
      'balance': availability?.balance ?? 0,
      'isConfirm': isConfirmed,
      'allowMinus': type.isAllowsMinus ?? 0,
      'comments': _commentController.text.trim(),
      'notify_to': <dynamic>[],
      'balanceToDate': summary?.balanceDueToDate ?? 0,
      'openingBalance': summary?.openingBalance ?? 0,
      'utilized': summary?.leaveTaken ?? 0,
      'finaceYearExist': summary?.finaceYearExist ?? 0,
      'isDailyBasisAccrual': summary?.isDailyBasisAccrual ?? 0,
      'isPayDeductionApplicable': availability?.deductionApplicable ?? 0,
      'lastYearCFBalance': summary?.lastYearCFBalance ?? 0,
      'annualEligibilityDays': summary?.entitled ?? 0,
      'totalBalance': summary?.entitled ?? 0,
      'value': type.value ?? 0,
      'requireDelegation': _requireDelegation ? 1 : 0,
    };

    if (_coveringEmployee != null) {
      payload['coveringEmpID'] = _coveringEmployee!.id ?? 0;
    }
    if (_isHalfDay) {
      payload['shift'] = _shiftType?.id ?? 1;
    }
    if (_coveringValidated != 0) {
      payload['coveringValidated'] = 1;
    }
    if (_coveringAvailabilityValidated != 0) {
      payload['coveringAvailabilityValidated'] = 1;
    }

    final files = <Map<String, dynamic>>[];
    for (final attachment in _attachments) {
      if (!attachment.isLocal || attachment.bytes == null) continue;
      files.add({
        'file': base64Encode(attachment.bytes!),
        'fileType': attachment.fileType ?? 'jpeg',
        'description': attachment.description ?? '',
        'myFileName': attachment.name ?? 'attachment',
        'sizeInKbs': attachment.bytes!.length / 1024,
      });
    }
    if (files.isNotEmpty) {
      payload['attachments'] = files;
    }
    return payload;
  }

  Future<void> _fetchSummaryAndAvailability({bool showLoader = true}) async {
    if (!_validateForm()) return;
    if (showLoader) setState(() => _isLoading = true);
    try {
      final summary = await _api.getLeaveSummary(_summaryPayload());
      final availability =
          await _api.checkLeaveAvailability(_availabilityPayload());
      if (!mounted) return;
      setState(() {
        _leaveSummary = summary;
        _leaveAvailability = availability;
        _summaryItems = ApplyLeaveSummaryBuilder.build(
          summary: summary,
          availability: availability,
        );
        _isLoading = false;
      });
    } on LeavesApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage(e.message);
    }
  }

  Future<void> _onLeaveTypeChanged(LeaveType type) async {
    if (_leaveType?.id != type.id) {
      setState(() {
        _leaveType = type;
        _startDate = null;
        _endDate = null;
        _leaveSummary = null;
        _leaveAvailability = null;
        _summaryItems = const [];
        _clearShift();
      });
      return;
    }
    setState(() => _leaveType = type);
    await _fetchSummaryAndAvailability();
  }

  void _clearShift() {
    _isHalfDay = false;
    _shiftType = const LeaveShift(id: 1, name: 'Morning');
    _shiftSegmentIndex = 0;
  }

  Future<void> _pickLeaveType() async {
    final selected = await showModalBottomSheet<LeaveType>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('Select leave type')),
            for (final type in _leaveTypes)
              ListTile(
                title: Text(type.name ?? ''),
                trailing: type.id == _leaveType?.id
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () => Navigator.pop(context, type),
              ),
          ],
        ),
      ),
    );
    if (selected != null) await _onLeaveTypeChanged(selected);
  }

  Future<void> _pickCoveringEmployee() async {
    final selected = await showModalBottomSheet<LeaveEmployee>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('Select covering employee')),
            for (final employee in _coveringEmployees)
              ListTile(
                title: Text(employee.name ?? ''),
                trailing: employee.id == _coveringEmployee?.id
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () => Navigator.pop(context, employee),
              ),
          ],
        ),
      ),
    );
    if (selected != null) setState(() => _coveringEmployee = selected);
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? _startDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_isHalfDay) _endDate = picked;
      } else {
        if (_isHalfDay) _startDate = picked;
        _endDate = picked;
      }
      if (!_canUseHalfDay) _clearShift();
    });
    await _fetchSummaryAndAvailability();
  }

  Future<void> _applyLeave({required int isConfirmed}) async {
    if (!_validateSubmit()) return;
    if (isConfirmed == 1) {
      final confirmed = await _confirm(
        'Are you sure you want to submit this leave application?',
      );
      if (!confirmed) return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _api.saveLeave(
        leaveId: _leaveMasterId,
        payload: _savePayload(isConfirmed: isConfirmed),
      );
      if (!mounted) return;

      if (response.success) {
        setState(() => _isLoading = false);
        _showMessage(
          response.message.isNotEmpty
              ? response.message
              : 'Leave saved successfully.',
        );
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (mounted) Navigator.of(context).pop(true);
        return;
      }

      if (response.leaveCoveringEmpStatus != 0) {
        setState(() => _isLoading = false);
        final proceed = await _confirm(response.message);
        if (!proceed) return;
        if (response.leaveCoveringEmpStatus == 1) {
          _coveringValidated = 1;
        } else if (response.leaveCoveringEmpStatus == 2) {
          _coveringAvailabilityValidated = 1;
        }
        await _applyLeave(isConfirmed: isConfirmed);
        return;
      }

      setState(() => _isLoading = false);
      _showMessage(response.message);
    } on LeavesApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage(e.message);
    }
  }

  Future<void> _pickAttachmentSource() async {
    final source = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, 0),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Photo library'),
              onTap: () => Navigator.pop(context, 1),
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file_outlined),
              title: const Text('Document'),
              onTap: () => Navigator.pop(context, 2),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    if (source == 2) {
      final result = await FilePicker.platform.pickFiles(withData: true);
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.bytes == null) return;
      _addLocalAttachment(
        name: file.name,
        bytes: file.bytes!,
        fileType: file.extension ?? 'pdf',
        isPhoto: false,
      );
      return;
    }

    final picked = await _imagePicker.pickImage(
      source: source == 0 ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    _addLocalAttachment(
      name: picked.name,
      bytes: bytes,
      fileType: 'jpeg',
      isPhoto: true,
    );
  }

  void _addLocalAttachment({
    required String name,
    required List<int> bytes,
    required String fileType,
    required bool isPhoto,
  }) {
    setState(() {
      _attachments = [
        ..._attachments,
        LeaveAttachment(
          id: _attachments.length,
          name: name,
          description: '',
          isLocal: true,
          bytes: bytes,
          fileType: fileType,
          isPhoto: isPhoto,
        ),
      ];
    });
    _showMessage('Attachment added.');
  }

  Future<void> _deleteAttachment(LeaveAttachment attachment) async {
    final confirmed =
        await _confirm('Are you sure you want to delete this attachment?');
    if (!confirmed) return;

    if (attachment.isLocal) {
      setState(() {
        _attachments =
            _attachments.where((item) => item.id != attachment.id).toList();
      });
      _showMessage('Attachment deleted.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final message = await _api.deleteAttachment(attachment.id ?? 0);
      if (!mounted) return;
      setState(() {
        _attachments =
            _attachments.where((item) => item.id != attachment.id).toList();
        _isLoading = false;
      });
      _showMessage(message.isNotEmpty ? message : 'Attachment deleted.');
    } on LeavesApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage(e.message);
    }
  }

  Future<void> _openAttachment(LeaveAttachment attachment) async {
    if (attachment.isLocal && attachment.bytes != null) {
      final dir = await Directory.systemTemp.createTemp('leave_attachment');
      final file = File('${dir.path}/${attachment.name ?? 'file'}');
      await file.writeAsBytes(attachment.bytes!);
      if (_isImageBytes(attachment.bytes!)) {
        if (!mounted) return;
        await _showImagePreview(file.path, attachment.name ?? 'Attachment');
        return;
      }
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done && mounted) {
        _showMessage(result.message);
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final path = await _api.downloadAttachment(attachment);
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (_isImageFile(path)) {
        await _showImagePreview(path, attachment.name ?? 'Attachment');
        return;
      }
      final result = await OpenFilex.open(path);
      if (result.type != ResultType.done && mounted) {
        _showMessage(result.message);
      }
    } on LeavesApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage(e.message);
    }
  }

  bool _isImageFile(String path) {
    final ext = path.split('.').last.toLowerCase();
    return {'jpg', 'jpeg', 'png', 'gif', 'webp'}.contains(ext);
  }

  bool _isImageBytes(List<int> bytes) {
    if (bytes.length < 4) return false;
    return bytes[0] == 0xFF && bytes[1] == 0xD8 ||
        bytes[0] == 0x89 && bytes[1] == 0x50;
  }

  Future<void> _showImagePreview(String filePath, String title) async {
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(title, overflow: TextOverflow.ellipsis),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.75,
              ),
              child: InteractiveViewer(
                child: Image.file(File(filePath), fit: BoxFit.contain),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isUpdate ? 'Update Leave' : 'Apply Leave'),
      ),
      body: Stack(
        children: [
          if (_isLoadedData)
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FormRow(
                        label: 'Employee name',
                        value: _employeeDisplayName,
                        onTap: null,
                      ),
                      _FormRow(
                        label: 'Leave type',
                        value: _leaveType?.name ?? 'Select leave type',
                        onTap: _pickLeaveType,
                      ),
                      _FormRow(
                        label: 'Covering employee',
                        value:
                            _coveringEmployee?.name ?? 'Select employee',
                        onTap: _pickCoveringEmployee,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Require delegation'),
                        value: _requireDelegation,
                        onChanged: (value) =>
                            setState(() => _requireDelegation = value),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _DatePickerTile(
                              title: 'Start Date',
                              date: _startDate,
                              onTap: () => _pickDate(isStart: true),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('to'),
                          ),
                          Expanded(
                            child: _DatePickerTile(
                              title: 'End Date',
                              date: _endDate,
                              onTap: () => _pickDate(isStart: false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Expanded(child: Text('Half day')),
                          Switch(
                            value: _isHalfDay,
                            onChanged: _canUseHalfDay
                                ? (value) {
                                    setState(() {
                                      _isHalfDay = value;
                                      if (value) {
                                        _shiftType = const LeaveShift(
                                          id: 1,
                                          name: 'Morning',
                                        );
                                        _shiftSegmentIndex = 0;
                                        if (_startDate != null) {
                                          _endDate = _startDate;
                                        }
                                      } else {
                                        _clearShift();
                                      }
                                    });
                                    _fetchSummaryAndAvailability();
                                  }
                                : null,
                          ),
                          SegmentedButton<int>(
                            segments: const [
                              ButtonSegment(value: 0, label: Text('Morning')),
                              ButtonSegment(value: 1, label: Text('Evening')),
                            ],
                            selected: {_shiftSegmentIndex},
                            onSelectionChanged: (!_isHalfDay || !_canUseHalfDay)
                                ? null
                                : (selection) {
                                    final index = selection.first;
                                    setState(() {
                                      _shiftSegmentIndex = index;
                                      _shiftType = index == 0
                                          ? const LeaveShift(
                                              id: 1,
                                              name: 'Morning',
                                            )
                                          : const LeaveShift(
                                              id: 2,
                                              name: 'Evening',
                                            );
                                    });
                                    _fetchSummaryAndAvailability();
                                  },
                          ),
                        ],
                      ),
                      if (_summaryItems.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _summaryItems.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.4,
                          ),
                          itemBuilder: (context, index) {
                            final item = _summaryItems[index];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: colorScheme.outlineVariant,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    item.title,
                                    textAlign: TextAlign.center,
                                    style:
                                        Theme.of(context).textTheme.labelMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    item.count,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: item.color,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          labelText: 'Comment',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Attachments',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton.filled(
                            onPressed: _pickAttachmentSource,
                            icon: const Icon(Icons.add),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  for (final attachment in _attachments)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: _AttachmentChip(
                                        attachment: attachment,
                                        onOpen: () => _openAttachment(attachment),
                                        onDelete: () =>
                                            _deleteAttachment(attachment),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _applyLeave(isConfirmed: 0),
                              child: const Text('Save draft'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => _applyLeave(isConfirmed: 1),
                              child: const Text('Get leave'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_isLoading)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.35),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

class _FormRow extends StatelessWidget {
  const _FormRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(value),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({
    required this.title,
    required this.date,
    required this.onTap,
  });

  final String title;
  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: LeaveDetailDateChip(
        title: title,
        date: date == null
            ? 'Select date'
            : LeaveUtils.formatDisplayDate(LeaveUtils.toApiDate(date!)),
      ),
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  const _AttachmentChip({
    required this.attachment,
    required this.onOpen,
    required this.onDelete,
  });

  final LeaveAttachment attachment;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            attachment.name ?? 'Attachment',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.download_outlined, size: 20),
                onPressed: onOpen,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
