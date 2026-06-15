class LeaveFilterOption {
  const LeaveFilterOption({required this.id, required this.name});

  final String id;
  final String name;

  /// Mirrors iOS initial `selectedFilter` (`id: "0"`).
  static const initial = LeaveFilterOption(id: '0', name: 'All');

  static const all = LeaveFilterOption(id: 'all', name: 'All');

  static List<LeaveFilterOption> get defaults => const [
        all,
        LeaveFilterOption(id: 'draft', name: 'Draft'),
        LeaveFilterOption(id: 'confirmed', name: 'Confirmed'),
        LeaveFilterOption(id: 'approved', name: 'Approved'),
        LeaveFilterOption(id: 'canReq', name: 'Cancel request'),
        LeaveFilterOption(id: 'canApp', name: 'Canceled'),
        LeaveFilterOption(id: 'referBackApproval', name: 'Refer Back'),
      ];
}
