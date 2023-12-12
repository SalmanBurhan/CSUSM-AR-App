//
//  EventFeedScrollView.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 10/9/23.
//

import SwiftUI

#Preview {
  EventFeedView()
}

/// A view that displays a feed of featured events.
///
/// The `EventFeedView` struct is responsible for loading and displaying a feed of featured events. It fetches the event data from a remote server using a URL session and parses the data using an `ICalParser`. The parsed events are stored in the `events` property, which is observed by the view to update its content.
///
/// The view consists of a navigation stack with a background gradient and a content area. If there are no events available, a content unavailable view is displayed. Otherwise, a scrollable view with a list of events is shown.
///
/// The `EventFeedView` also provides helper methods for printing the event details and creating a custom event view.
struct EventFeedView: View {

  /**
    The array of iCal events displayed in the event feed.
  */
  @State var events: [ICalEvent] = []

  /**
   The body of the view, which defines the content and layout of the EventFeedScrollView.
   */
  var body: some View {
    NavigationStack {
      ZStack {
        LinearGradient(
          gradient: Gradient(colors: [Color(.systemGray5), Color(.systemBackground)]),
          startPoint: .top, endPoint: .bottomTrailing
        )
        .frame(maxHeight: .infinity)
        .clipped()
        if self.events.count == 0 {
          contentUnavailableView
        } else {
          eventsScrollView
        }
      }
      .ignoresSafeArea()
      .onAppear(perform: {
        self.loadEvents()
      })
    }
  }

  /**
     Loads the events from a remote server.

     This method performs a network request to fetch the event data from a specified URL. The response data is then parsed using an `ICalParser` to extract the event details. The parsed events are stored in the `events` property, which triggers a view update.
     */
  private func loadEvents() {
    let url = URL(string: "https://25livepub.collegenet.com/calendars/csusm-featured-events.ics")!
    URLSession.shared.dataTask(
      with: URLRequest(url: url)
    ) { data, response, error in
      guard let data = data,
        let ics = String(data: data, encoding: .utf8)
      else {
        print("Unable To Read HTTP Response Body")
        return
      }
      self.events = ICalParser().parseEvents(ics: ics)
    }.resume()
  }

  /**
     Prints the details of each event.

     This method iterates over the `events` array and prints the details of each event, including the event name, image URL, location, start and end dates, datestamp, event type, URL, organizer, and description.
    */
  internal func debugPrintEvents() {
    self.events.forEach { event in
      print("Event Name: \(String(describing: event.summary))")
      print("Event Image: \(String(describing: event.imageURL))")
      print("Event Location: \(String(describing: event.location))")
      print("Event Start: \(String(describing: event.dtstart))")
      print("Event End: \(String(describing: event.dtend))")
      print("Event Datestamp: \(String(describing: event.dtstamp))")
      print("Event Type: \(String(describing: event.eventType))")
      print("Event Link: \(String(describing: event.url))")
      print("Event Organizer: \(String(describing: event.organization))")
      print("Event Description: \(String(describing: event.description))")
      print("--------")
    }
  }

  /*
     Returns a view to display when no events are available.

     This computed property returns a view that indicates there are no events available. It uses the `ContentUnavailableView` introduced in iOS 17.0 if available, otherwise it falls back to a group of labels.

     - Returns: A view indicating that no events are available.
     */
  var contentUnavailableView: some View {
    if #available(iOS 17.0, *) {
      return ContentUnavailableView {
        Label("No Events", systemImage: "calendar")
      } description: {
        Text("Campus featured events will appear here.")
      }
    } else {
      // Fallback on earlier versions
      return Group {
        Label("No Events", systemImage: "calendar")
        Text("Campus featured events will appear here.")
      }
    }
  }

  /**
     Returns a scrollable view with a list of events.

     This computed property returns a scrollable view that displays a list of events. The events are rendered using the `EventRowView` and wrapped in a `NavigationLink` to navigate to the event details view. The view also includes a header with the university name and a title for the featured events.

     - Returns: A scrollable view with a list of events.
     */
  var eventsScrollView: some View {
    ScrollView {
      VStack(alignment: .leading) {
        Text("California State University San Marcos").font(.largeTitle).padding(.horizontal)
        Text("Featured Events").font(.title2).padding(.horizontal).foregroundColor(.secondary)
        LazyVGrid(columns: [GridItem(.flexible())]) {
          ForEach($events, id: \.uid) { event in
            NavigationLink(destination: EventDetailsView(event.wrappedValue)) {
              EventRowView(for: event.wrappedValue)
              //createEventView(for: event.wrappedValue)
            }.buttonStyle(.plain)
          }
        }.frame(maxWidth: .infinity).clipped()
      }.padding(.top, 100).padding(.bottom)
    }
  }

  /**
     Creates a custom event view for the given event.

     This method takes an `ICalEvent` object and creates a custom view to display the event details. The view includes labels for the date and time, the event location, and the event title. The labels are styled using the university colors.

     - Parameter event: The event for which to create the view.
     - Returns: A custom view displaying the event details.
     */
  internal func createEventView(for event: ICalEvent) -> some View {

    let location = event.location ?? "Location"
    let title = event.summary ?? "Event Name"
    let startTime = event.dtstart?.date.formatted(date: .omitted, time: .shortened) ?? "Time"
    let date = event.dtstart?.date.formatted(date: .abbreviated, time: .omitted) ?? "Date"

    return VStack(alignment: .leading) {

      HStack {
        dateLabel(date)
        timeLabel(startTime)
        Spacer()
      }.padding([.top, .leading, .trailing])

      VStack(alignment: .leading) {
        Text(location.uppercased()).font(.subheadline).foregroundStyle(Color.cougarBlue)
        Text(title).font(.system(.title, design: .rounded, weight: .semibold)).foregroundStyle(
          Color.universityBlue)
      }.padding()

    }.padding(5).background {
      RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color(.secondarySystemBackground))
    }
  }

  /**
     Creates a label for the event date.

     This method takes a date string and creates a label to display the event date. The label is styled with a background color and uppercase text.

     - Parameter date: The date string to display.
     - Returns: A label displaying the event date.
     */
  internal func dateLabel(_ date: String) -> some View {
    VStack {
      Text(date.uppercased())
        .padding([.top, .bottom], 5)
        .padding([.leading, .trailing], 10)
        .background {
          Capsule(style: .continuous)
            .fill(Color.universityBlue)
        }
        .foregroundColor(.white)
    }
  }

  /**
     Creates a label for the event time.

     This method takes a time string and creates a label to display the event time. The label is styled with a background color and uppercase text.

     - Parameter time: The time string to display.
     - Returns: A label displaying the event time.
     */
  internal func timeLabel(_ time: String) -> some View {
    VStack {
      Text(time.uppercased())
        .padding([.top, .bottom], 5)
        .padding([.leading, .trailing], 10)
        .background {
          Capsule(style: .continuous)
            .fill(Color.universityBlue)
        }
        .foregroundColor(.white)
    }
  }
}
