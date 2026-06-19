import 'package:flutter/material.dart';
import 'package:gears_flutter/core/network/api_exception.dart';
import 'package:gears_flutter/core/storage/session_storage.dart';
import 'package:gears_flutter/features/profile/data/models/profile_details_std_response.dart';
import 'package:gears_flutter/features/profile/data/profile_api.dart';
import 'package:gears_flutter/features/profile/presentation/profile_format_utils.dart';

const _darkGrey = Color(0xFF2A2C2F);
const _grey1 = Color(0xFF666666);
const _grey2 = Color(0xFF8F8F8F);

/// Bottom-nav tab — mirrors Android [ProfileFragment] layout.
class ProfileTabPage extends StatefulWidget {
  const ProfileTabPage({super.key});

  @override
  State<ProfileTabPage> createState() => _ProfileTabPageState();
}

class _ProfileTabPageState extends State<ProfileTabPage> {
  bool _isLoading = false;
  ProfileEmployee? _employee;

  static const _dashboardWidgets = [
    _DashboardWidget(label: 'Payslips', icon: Icons.receipt_long_outlined),
    _DashboardWidget(label: 'Leaves', icon: Icons.date_range_outlined),
    _DashboardWidget(label: 'Claims', icon: Icons.payments_outlined),
    _DashboardWidget(label: 'Attendance', icon: Icons.access_time_outlined),
    _DashboardWidget(label: 'Requests', icon: Icons.description_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _employee = SessionStorage.userProfileStd?.data?.employee;
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final baseUrl = SessionStorage.subdomainUrl;
    if (baseUrl == null || baseUrl.isEmpty) return;

    setState(() => _isLoading = _employee == null);

    try {
      final response = await ProfileApi(baseUrl).getProfileDetailsStd();
      if (response.success != true || response.data?.employee == null) {
        throw ApiException(response.message ?? 'Failed to load profile');
      }

      await SessionStorage.setUserProfileStd(response);

      if (!mounted) return;
      setState(() => _employee = response.data!.employee);
    } on ApiException catch (e) {
      if (mounted) _showMessage(e.message);
    } catch (e) {
      if (mounted) _showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final employee = _employee;

    final fullName = employee?.ename1 ?? '';
    final email = employee?.eEmail ?? '';
    final companyName = employee?.company?.companyName ?? '';
    final employeeCode = employee?.eCode ?? '';
    final joinedDate = formatProfileJoinedDate(employee?.eDOJ);
    final profileDetails = [
      _ProfileDetailItem(
        label: 'Mobile Number',
        value: profileDetailValue(employee?.ecMobile),
      ),
      _ProfileDetailItem(
        label: 'Telephone',
        value: profileDetailValue(employee?.epTelephone),
      ),
    ];

    return ColoredBox(
      color: Colors.white,
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProfileHeader(
                  primary: primary,
                  fullName: fullName,
                  email: email,
                  imageUrl: employee?.empImageUrl,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 74,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _dashboardWidgets.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 15),
                    itemBuilder: (context, index) {
                      final widget = _dashboardWidgets[index];
                      return _DashboardWidgetTile(
                        widget: widget,
                        primary: primary,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${widget.label} — coming soon'),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _CompanyCard(
                    companyName: companyName,
                    primary: primary,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _EmployeeCodeCard(
                          employeeCode: employeeCode,
                          primary: primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _DateJoinedCard(joinedDate: joinedDate),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                  child: Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Column(
                        children: [
                          for (var i = 0; i < profileDetails.length; i++)
                            _ProfileDetailRow(
                              item: profileDetails[i],
                              showDivider: i < profileDetails.length - 1,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const ColoredBox(
              color: Colors.white54,
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.primary,
    required this.fullName,
    required this.email,
    this.imageUrl,
  });

  final Color primary;
  final String fullName;
  final String email;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 213,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _ProfileBannerPainter(color: primary),
            ),
          ),
          Positioned(
            left: 100,
            right: 50,
            top: 35,
            child: Center(
              child: Container(
                width: 143,
                height: 143,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 6,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: -10,
            top: 67,
            child: Container(
              width: 79,
              height: 79,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 6,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 33.5,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
                        ? NetworkImage(imageUrl!)
                        : null,
                    child: imageUrl == null || imageUrl!.isEmpty
                        ? Icon(
                            Icons.person,
                            size: 36,
                            color: Colors.grey.shade500,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileBannerPainter extends CustomPainter {
  _ProfileBannerPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 361;
    final scaleY = size.height / 213;

    final path = Path()
      ..moveTo(0, 183.074 * scaleY)
      ..lineTo(0, 0)
      ..lineTo(361 * scaleX, 0)
      ..lineTo(361 * scaleX, 183.074 * scaleY)
      ..cubicTo(
        328.333 * scaleX,
        194.81 * scaleY,
        236.6 * scaleX,
        213 * scaleY,
        179 * scaleX,
        213 * scaleY,
      )
      ..cubicTo(
        121.4 * scaleX,
        213 * scaleY,
        38.667 * scaleX,
        194.81 * scaleY,
        0,
        183.074 * scaleY,
      )
      ..close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _ProfileBannerPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _DashboardWidgetTile extends StatelessWidget {
  const _DashboardWidgetTile({
    required this.widget,
    required this.primary,
    required this.onTap,
  });

  final _DashboardWidget widget;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(37),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 84,
          height: 74,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, size: 20, color: primary),
                const SizedBox(height: 4),
                Text(
                  widget.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompanyCard extends StatelessWidget {
  const _CompanyCard({
    required this.companyName,
    required this.primary,
  });

  final String companyName;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: SizedBox(
        height: 115,
        child: Padding(
          padding: const EdgeInsets.only(left: 13),
          child: Row(
            children: [
              Expanded(
                flex: 8,
                child: Padding(
                  padding: const EdgeInsets.only(top: 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Company',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _darkGrey,
                        ),
                      ),
                      Text(
                        companyName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _grey2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(top: 20, right: 20.4),
                  child: Icon(
                    Icons.apartment_outlined,
                    size: 72,
                    color: primary.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmployeeCodeCard extends StatelessWidget {
  const _EmployeeCodeCard({
    required this.employeeCode,
    required this.primary,
  });

  final String employeeCode;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Employee Code',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              employeeCode,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateJoinedCard extends StatelessWidget {
  const _DateJoinedCard({required this.joinedDate});

  final String joinedDate;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        child: Column(
          children: [
            const Text(
              'Date Joined',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _darkGrey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              joinedDate,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: _grey1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileDetailRow extends StatelessWidget {
  const _ProfileDetailRow({
    required this.item,
    required this.showDivider,
  });

  final _ProfileDetailItem item;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _darkGrey,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  item.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _grey1,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 0.5,
            thickness: 0.5,
            indent: 32,
            color: Colors.black.withValues(alpha: 0.1),
          ),
      ],
    );
  }
}

class _DashboardWidget {
  const _DashboardWidget({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _ProfileDetailItem {
  const _ProfileDetailItem({required this.label, required this.value});

  final String label;
  final String value;
}
