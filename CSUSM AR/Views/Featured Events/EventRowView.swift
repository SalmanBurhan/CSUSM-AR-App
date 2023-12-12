//
//  EventRowView.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 10/22/23.
//

import SwiftUI

#Preview {
  let sampleEvent: ICalEvent = .init(
    description: "Some Long Sanitized and Tag-Stripped HTML Content",
    location: "Some CSUSM Building",
    summary: "Some Event Title",
    organization: "Some Organization",
    eventType: "Some Enum Value",
    imageURL: nil
  )

  return ScrollView {
    LazyVGrid(columns: [GridItem(.flexible())]) {
      EventRowView(for: sampleEvent)
    }
  }.background(.secondary)
}

///
/// A view that represents a row in a list of events.
///
/// Use `EventRowView` to display information about an event in a list or table view.
/// It provides details such as the event title, location, date, and start time.
///
/// Example usage:
/// ``` swift
/// struct ContentView: View {
///     var body: some View {
///         List(events) { event in
///             EventRowView(for: event)
///         }
///     }
/// }
/// ```
///
/// - Note: This view expects an `ICalEvent` object to display the event details.
///
/// - Parameters:
///   - event: The `ICalEvent` object representing the event.
struct EventRowView: View {

  /// The ICalEvent object representing the event.
  var event: ICalEvent

  /// Initializes the view model with the given ICalEvent.
  /// - Parameter event: The ICalEvent object representing the event.
  init(for event: ICalEvent) {
    self.event = event
  }

  /// The location of the event. Returns "Location" if the location is not available.
  var location: String {
    return event.location ?? "Location"
  }

  /// The title of the event. Returns "Event Name" if the title is not available.
  var title: String {
    event.summary ?? "Event Name"
  }

  /// The organization hosting the event. Returns "Organization" if the organization is not available.
  var organization: String {
    return event.organization ?? "Organization"
  }

  /// The date of the event. Returns "Event Date" if the date is not available.
  var date: String {
    return event.dtstart?.date.formatted(date: .abbreviated, time: .omitted) ?? "Event Date"
  }

  /// The start time of the event. Returns "Start Time" if the start time is not available.
  var startTime: String {
    return event.dtstart?.date.formatted(date: .omitted, time: .shortened) ?? "Start Time"
  }

  var body: some View {
    HStack {
      AsyncImage(url: event.imageURL) { image in
        image
          .resizable()
          .aspectRatio(contentMode: .fill)
      } placeholder: {
        VStack {
          Spacer()
          Text("CSUSM")
            .font(.callout)
            .fontWeight(.bold)
            .foregroundStyle(Color.spiritBlue)
            .padding()
          Spacer()
        }
        .frame(width: 100)
        .background {
          LinearGradient(
            colors: [
              .universityBlue, .black,
            ], startPoint: .topLeading, endPoint: .bottomTrailing
          ).background(.ultraThickMaterial)
        }
      }
      .frame(width: 90, height: 90)
      .mask(RoundedRectangle(cornerRadius: 16, style: .continuous))
      .clipped()
      .padding([.leading, .top, .bottom])

      Spacer()

      VStack(alignment: .leading) {
        Text(title)
          .bold()
          .lineLimit(2)
          .multilineTextAlignment(.leading)
        Label(
          title: { Text(location).font(.caption).lineLimit(1) },
          icon: {
            Image(systemName: "location.circle").symbolRenderingMode(.monochrome).foregroundStyle(
              Color.spiritBlue
            ).font(.caption)
          }
        )
        HStack {
          Label(
            title: { Text(date).font(.caption) },
            icon: {
              Image(systemName: "calendar").symbolRenderingMode(.monochrome).foregroundStyle(
                Color.spiritBlue)
            }
          )
          .padding([.top, .bottom], 5)
          .padding([.leading, .trailing], 8)
          .background(.ultraThickMaterial, in: Capsule(style: .circular))

          Label(
            title: { Text(startTime).font(.caption) },
            icon: {
              Image(systemName: "clock").symbolRenderingMode(.monochrome).foregroundStyle(
                Color.spiritBlue)
            }
          )
          .padding([.top, .bottom], 5)
          .padding([.leading, .trailing], 8)
          .background(.ultraThickMaterial, in: Capsule(style: .circular))
        }

      }
      Spacer()

    }
    .background(.background)
    .mask(RoundedRectangle(cornerRadius: 16, style: .continuous))
    .padding([.top, .bottom], 5)
    .padding([.leading, .trailing])
  }
}
