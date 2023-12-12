//
//  EventDetailsView.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 10/11/23.
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

  return EventDetailsView(sampleEvent)
}

/// A view that displays the details of an event.
///
/// The `EventDetailsView` struct represents a view that displays various details of an event, such as the event title, organization, description, start time, end time, location, event type, and event image. It also provides a button to add the event to the calendar.
///
/// The view is composed of several subviews, including `EventImageView` for displaying the event image, `EventBody` for displaying the event title, organization, and description, `EventHighlightsView` for displaying the event highlights such as start time, end time, location, and event type, and `CalendarAddButton` for adding the event to the calendar.
///
/// Usage:
/// ``` swift
/// let event = ICalEvent(...)
/// let eventDetailsView = EventDetailsView(event)
/// ```
struct EventDetailsView: View {
  /// The event associated with the view.
  var event: ICalEvent

  /// Initializes the `EventDetailsView` with the given event.
  /// - Parameter event: The event to display.
  init(_ event: ICalEvent) {
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

  /// The start time of the event. Returns "Start Time" if the start time is not available.
  var startTime: String {
    return event.dtstart?.date.formatted(date: .omitted, time: .shortened) ?? "Start Time"
  }

  /// The end time of the event. Returns "End Time" if the end time is not available.
  var endTime: String {
    return event.dtend?.date.formatted(date: .omitted, time: .shortened) ?? "End Time"
  }

  /// The date of the event. Returns "Event Date" if the date is not available.
  var date: String {
    return event.dtstart?.date.formatted(date: .complete, time: .omitted) ?? "Event Date"
  }

  /// The description of the event. Returns "Event Description" if the description is not available.
  var description: String {
    return event.description ?? "Event Description"
  }

  /// The type of the event. Returns "Event Type" if the event type is not available.
  var eventType: String {
    return event.eventType ?? "Event Type"
  }

  /// The URL of the event image.
  var eventImageURL: URL? {
    return event.imageURL
  }

  /// The accent color used in the view.
  let accentColor: Color = Color(
    .init(red: 0 / 255.0, green: 42 / 255.0, blue: 89 / 255.0, alpha: 1)
  )

  /// The action color used in the view.
  let actionColor: Color = Color(
    .init(red: 0 / 255.0, green: 96 / 255.0, blue: 252 / 255.0, alpha: 1)
  )

  /// The body of the view.
  var body: some View {
    ScrollView {
      VStack {
        EventImageView(imageURL: eventImageURL)
        EventBody(title, organization, description)
        EventHighlightsView(startTime, endTime, organization, location, eventType)
        CalendarAddButton(for: event)
      }
    }.ignoresSafeArea()
  }

  /// A view that represents the "Add to Calendar" button.
  struct CalendarAddButton: View {
    let event: ICalEvent

    /// Initializes the `CalendarAddButton` with the given event.
    /// - Parameter event: The event associated with the button.
    init(for event: ICalEvent) {
      self.event = event
    }

    /// The body of the button.
    var body: some View {
      VStack(spacing: 14) {
        Text("Add To Calendar")
          .font(.system(.title3, weight: .medium))
          .padding(.vertical, 12)
          .padding(.horizontal, 24)
          .background(Color.cougarBlue)
          .foregroundColor(.white)
          .mask {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
          }
      }.padding(.vertical, 28)
    }
  }

  /// A view that displays the event image.
  struct EventImageView: View {
    let imageURL: URL?

    var body: some View {
      AsyncImage(url: imageURL) { image in
        image.resizable().aspectRatio(contentMode: .fill)
      } placeholder: {
        VStack {
          Spacer()
          Text("CSUSM")
            .font(.largeTitle.bold())
            .foregroundStyle(Color.spiritBlue)
          Spacer()
        }.frame(maxWidth: .infinity).background {
          Color.universityBlue
        }
      }.frame(width: 390, height: 320).clipped()
    }
  }

  /// A view that displays the event title, organization, and description.
  struct EventBody: View {
    let title: String
    let organization: String
    let description: String

    /// Initializes the `EventBody` with the given title, organization, and description.
    /// - Parameters:
    ///   - title: The title of the event.
    ///   - organization: The organization hosting the event.
    ///   - description: The description of the event.
    init(_ title: String, _ organization: String, _ description: String) {
      self.title = title
      self.organization = organization
      self.description = description
    }

    /// The body of the view.
    var body: some View {
      VStack(alignment: .leading, spacing: 4) {
        HStack(alignment: .firstTextBaseline) {
          Text(title)
            .font(.system(size: 29, weight: .semibold, design: .default))
          Spacer()
        }
        Text(organization)
          .font(.system(.callout, weight: .medium))
        Text(description)
          .font(.system(.callout).width(.condensed))
          .padding(.vertical)
      }.padding(.horizontal, 24).padding(.top, 12)
    }
  }

  /// A view that displays the event highlights such as start time, end time, location, and event type.
  struct EventHighlightsView: View {

    /// The start time of the event.
    let startTime: String
    
    /// The end time of the event.
    let endTime: String
    
    /// The organization hosting the event.
    let organization: String
    
    /// The location of the event.
    let location: String
    
    /// The type of event.
    let eventType: String

    /// Initializes the `EventHighlightsView` with the given event details.
    /// - Parameters:
    ///   - startTime: The start time of the event.
    ///   - endTime: The end time of the event.
    ///   - organization: The organization hosting the event.
    ///   - location: The location of the event.
    ///   - eventType: The type of event.
    init(
      _ startTime: String, _ endTime: String, _ organization: String, _ location: String,
      _ eventType: String
    ) {
      self.startTime = startTime
      self.endTime = endTime
      self.organization = organization
      self.location = location
      self.eventType = eventType
    }

    /// The body of the view.
    var body: some View {
      VStack(alignment: .leading, spacing: 15) {
        Text("HIGHLIGHTS")
          .kerning(2.0)
          .font(.system(size: 12, weight: .medium, design: .default))
          .foregroundColor(.secondary)
        timeHighlight
        organizationHighlight
        locationHighlight
        eventTypeHighlight
      }.padding(.horizontal, 24)
    }

    /// The view that displays the start and end time of the event.
    var timeHighlight: some View {
      HStack(spacing: 9) {
        Image(systemName: "clock")
          .symbolRenderingMode(.monochrome)
          .foregroundStyle(Color.universityBlue)
          .frame(width: 20)
          .clipped()
        Text("\(startTime) to \(endTime)")
        Spacer()
      }.font(.subheadline)
    }

    /// The view that displays the organization hosting the event.
    var organizationHighlight: some View {
      HStack(spacing: 9) {
        Image(systemName: "person.3")
          .symbolRenderingMode(.monochrome)
          .foregroundColor(.universityBlue)
          .frame(width: 20)
          .clipped()
        Text(organization)
        Spacer()
      }.font(.subheadline)
    }

    /// The view that displays the location of the event.
    var locationHighlight: some View {
      HStack(spacing: 9) {
        Image(systemName: "location")
          .symbolRenderingMode(.monochrome)
          .foregroundColor(.universityBlue)
          .frame(width: 20)
          .clipped()
        Text(location)
        Spacer()
      }.font(.subheadline)
    }

    /// The view that displays the type of the event.
    var eventTypeHighlight: some View {
      HStack(spacing: 9) {
        Image(systemName: "tag")
          .symbolRenderingMode(.monochrome)
          .foregroundColor(.universityBlue)
          .frame(width: 20)
          .clipped()
        Text(eventType)
        Spacer()
      }.font(.subheadline)
    }
  }
}
