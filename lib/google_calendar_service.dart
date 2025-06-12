import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'google_http_client.dart';

class GoogleCalendarService {
  final Map<String, String> eventIdMap = {};

  Future<void> insertEvent(String title, DateTime startTime, GoogleSignInAccount user) async {
    final authHeaders = await user.authHeaders;
    final httpClient = GoogleHttpClient(authHeaders);
    final calendarApi = calendar.CalendarApi(httpClient);

    final event = calendar.Event(
      summary: title,
      start: calendar.EventDateTime(dateTime: startTime, timeZone: "Asia/Jakarta"),
      end: calendar.EventDateTime(dateTime: startTime.add(Duration(hours: 1)), timeZone: "Asia/Jakarta"),
    );

    final createdEvent = await calendarApi.events.insert(event, "primary");
    eventIdMap[title] = createdEvent.id!;
  }

  Future<void> updateEvent(String oldTitle, String newTitle, GoogleSignInAccount user) async {
    final eventId = eventIdMap[oldTitle];
    if (eventId == null) return;

    final authHeaders = await user.authHeaders;
    final httpClient = GoogleHttpClient(authHeaders);
    final calendarApi = calendar.CalendarApi(httpClient);

    final event = await calendarApi.events.get("primary", eventId);
    event.summary = newTitle;
    await calendarApi.events.update(event, "primary", eventId);

    eventIdMap.remove(oldTitle);
    eventIdMap[newTitle] = eventId;
  }

  Future<void> deleteEvent(String title, GoogleSignInAccount user) async {
    final eventId = eventIdMap[title];
    if (eventId == null) return;

    final authHeaders = await user.authHeaders;
    final httpClient = GoogleHttpClient(authHeaders);
    final calendarApi = calendar.CalendarApi(httpClient);

    await calendarApi.events.delete("primary", eventId);
    eventIdMap.remove(title);
  }
}
