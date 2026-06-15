import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_theme.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _captionController = TextEditingController();
  final _venueController   = TextEditingController();
  final _eventController   = TextEditingController();

  double     _rating     = 0;
  bool       _submitting = false;
  bool       _puked      = false;
  DateTime   _date       = DateTime.now();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void dispose() {
    _captionController.dispose();
    _venueController.dispose();
    _eventController.dispose();
    super.dispose();
  }

  double _hoursOut() {
    if (_startTime == null || _endTime == null) return 0;
    final base  = DateTime(_date.year, _date.month, _date.day);
    var start   = base.add(Duration(hours: _startTime!.hour, minutes: _startTime!.minute));
    var end     = base.add(Duration(hours: _endTime!.hour,   minutes: _endTime!.minute));
    if (end.isBefore(start)) end = end.add(const Duration(days: 1));
    return end.difference(start).inMinutes / 60.0;
  }

  String _formatTime(TimeOfDay t) {
    final h  = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m  = t.minute.toString().padLeft(2, '0');
    final pm = t.period == DayPeriod.pm ? 'PM' : 'AM';
    return '$h:$m $pm';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: kAccent),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime(bool isStart) async {
    final initial = isStart
        ? (_startTime ?? const TimeOfDay(hour: 22, minute: 0))
        : (_endTime   ?? const TimeOfDay(hour: 2,  minute: 0));

    TimeOfDay selected = initial;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: 300,
        decoration: const BoxDecoration(
          color: Color(0xFF130228),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  Text(
                    isStart ? 'Arrived at' : 'Left at',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('Done', style: TextStyle(color: kAccent, fontSize: 16, fontWeight: FontWeight.w600)),
                    onPressed: () {
                      setState(() => isStart ? _startTime = selected : _endTime = selected);
                      Navigator.of(ctx).pop();
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoTheme(
                data: const CupertinoThemeData(
                  textTheme: CupertinoTextThemeData(
                    dateTimePickerTextStyle: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: DateTime(2000, 1, 1, initial.hour, initial.minute),
                  use24hFormat: false,
                  backgroundColor: Colors.transparent,
                  onDateTimeChanged: (dt) {
                    selected = TimeOfDay(hour: dt.hour, minute: dt.minute);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final caption = _captionController.text.trim();
    if (caption.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write something about your night first.')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final user     = FirebaseAuth.instance.currentUser!;
      final username = user.displayName ?? user.email?.split('@').first ?? 'Raver';
      final venue    = _venueController.text.trim();
      final hours    = _hoursOut();

      await FirebaseFirestore.instance.collection('posts').add({
        'uid':           user.uid,
        'username':      username,
        'caption':       caption,
        'venue_tag':     venue,
        'event_tag':     _eventController.text.trim(),
        'rating':        _rating > 0 ? _rating : null,
        'image_url':     '',
        'likes':         [],
        'comment_count': 0,
        'puked':         _puked,
        'night_date':    '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
        'start_time':    _startTime != null ? _formatTime(_startTime!) : null,
        'end_time':      _endTime   != null ? _formatTime(_endTime!)   : null,
        'hours_out':     hours > 0 ? hours : null,
        'created_at':    FieldValue.serverTimestamp(),
      });

      final Map<String, dynamic> updates = {
        'events_this_month': FieldValue.increment(1),
        'total_events':      FieldValue.increment(1),
      };
      if (hours > 0) updates['hours_this_month'] = FieldValue.increment(hours);
      if (_puked)    updates['puke_count']        = FieldValue.increment(1);
      if (venue.isNotEmpty) updates['clubs_visited'] = FieldValue.arrayUnion([venue]);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(updates);

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hours = _hoursOut();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: kBgDecoration,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'Log your night',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    _submitting
                        ? const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            ),
                          )
                        : TextButton(
                            onPressed: _submit,
                            child: const Text(
                              'Post',
                              style: TextStyle(color: kAccent, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: kBorder),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'WHEN WERE YOU OUT?',
                              style: TextStyle(color: kDim, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2),
                            ),
                            const SizedBox(height: 14),
                            _timeRow(icon: Icons.calendar_today, label: 'Date',
                                value: '${_date.day}/${_date.month}/${_date.year}', onTap: _pickDate),
                            const Divider(height: 20, color: kBorder),
                            _timeRow(icon: Icons.login, label: 'Arrived',
                                value: _startTime != null ? _formatTime(_startTime!) : 'Tap to set',
                                onTap: () => _pickTime(true)),
                            const Divider(height: 20, color: kBorder),
                            _timeRow(icon: Icons.logout, label: 'Left',
                                value: _endTime != null ? _formatTime(_endTime!) : 'Tap to set',
                                onTap: () => _pickTime(false)),
                            if (hours > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: kAccent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: kAccent.withValues(alpha: 0.35)),
                                  ),
                                  child: Text(
                                    '${hours.toStringAsFixed(1)} hours out',
                                    style: const TextStyle(color: kAccent, fontSize: 12),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      _card(
                        child: TextField(
                          controller: _captionController,
                          maxLines: 5,
                          minLines: 3,
                          maxLength: 300,
                          style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
                          decoration: const InputDecoration(
                            hintText: 'How was your night? Tell the crew...',
                            hintStyle: TextStyle(color: kDim),
                            border: InputBorder.none,
                            counterStyle: TextStyle(color: kDim),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      _card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'RATE YOUR NIGHT',
                              style: TextStyle(color: kDim, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(5, (i) {
                                final star   = i + 1.0;
                                final filled = star <= _rating;
                                return GestureDetector(
                                  onTap: () => setState(() => _rating = star),
                                  child: Icon(
                                    filled ? Icons.star : Icons.star_border,
                                    color: filled ? kAccent : const Color(0x44FFFFFF),
                                    size: 34,
                                  ),
                                );
                              }),
                            ),
                            if (_rating > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Center(
                                  child: Text(
                                    _ratingLabel(_rating),
                                    style: const TextStyle(color: kMuted, fontSize: 12),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      GestureDetector(
                        onTap: () => setState(() => _puked = !_puked),
                        child: _card(
                          child: Row(
                            children: [
                              Text('🤮', style: TextStyle(fontSize: 22, color: _puked ? null : const Color(0x55FFFFFF))),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Did you puke?',
                                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                    Text(
                                      _puked ? 'Yep… happens to the best of us' : 'Tap to mark the moment',
                                      style: const TextStyle(color: kDim, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _puked ? kAccent : Colors.transparent,
                                  border: Border.all(
                                    color: _puked ? kAccent : const Color(0x44FFFFFF),
                                    width: 2,
                                  ),
                                ),
                                child: _puked
                                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      _card(
                        child: Column(
                          children: [
                            _tagField(controller: _venueController, icon: Icons.location_on,
                                hint: 'Venue (e.g. Fabric)', divider: true),
                            _tagField(controller: _eventController, icon: Icons.confirmation_number,
                                hint: 'Event name (optional)', divider: false),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      GestureDetector(
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Photo upload coming soon!')),
                        ),
                        child: _card(
                          child: const Row(
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, color: kAccent, size: 20),
                              SizedBox(width: 12),
                              Text('Add a photo', style: TextStyle(color: kMuted, fontSize: 14)),
                              Spacer(),
                              Icon(Icons.chevron_right, color: kDim, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: Container(
                          decoration: kPrimaryButtonDecoration,
                          child: ElevatedButton(
                            onPressed: _submitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            child: const Text('Post to feed'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: child,
    );
  }

  Widget _timeRow({required IconData icon, required String label, required String value, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Icon(icon, color: kAccent, size: 17),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: kMuted, fontSize: 14)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: kDim, size: 17),
        ],
      ),
    );
  }

  Widget _tagField({required TextEditingController controller, required IconData icon,
      required String hint, required bool divider}) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: kAccent, size: 17),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(color: kDim),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
        if (divider) const Divider(height: 20, color: kBorder),
      ],
    );
  }

  String _ratingLabel(double rating) {
    switch (rating.toInt()) {
      case 1:  return 'Awful night';
      case 2:  return 'Not great';
      case 3:  return 'Decent';
      case 4:  return 'Great night';
      case 5:  return 'All-timer 🔥';
      default: return '';
    }
  }
}
