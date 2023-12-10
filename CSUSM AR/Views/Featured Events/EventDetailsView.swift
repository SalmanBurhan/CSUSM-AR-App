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

struct EventDetailsView: View {
        
    var event: ICalEvent
    
    init(_ event: ICalEvent) {
        self.event = event
    }
    
    var location: String {
        return event.location ?? "Location"
    }
    
    var title: String {
        event.summary ?? "Event Name"
    }
    
    var organization: String {
        return event.organization ?? "Organization"
    }
    
    var startTime: String {
        return event.dtstart?.date.formatted(date: .omitted,time: .shortened) ?? "Start Time"
    }
    
    var endTime: String {
        return event.dtend?.date.formatted(date: .omitted,time: .shortened) ?? "End Time"
    }
    
    var date: String {
        return event.dtstart?.date.formatted(date: .complete,time: .omitted) ?? "Event Date"
    }
    
    var description: String {
        return event.description ?? "Event Description"
    }
    
    var eventType: String {
        return event.eventType ?? "Event Type"
    }
    
    var eventImageURL: URL? {
        return event.imageURL
    }
    
    let accentColor: Color = Color(.init(red: 0/255.0, green: 42/255.0, blue: 89/255.0, alpha: 1))
    let actionColor: Color = Color(.init(red: 0/255.0, green: 96/255.0, blue: 252/255.0, alpha: 1))
    
    var body: some View {
        ScrollView {
            VStack {
                EventImageView(imageURL: eventImageURL)
                EventBody(title, organization, description)
                EventHighlightsView(startTime, endTime, organization, location, eventType)
                GuidanceButton(for: event)
            }
        }.ignoresSafeArea()
    }
}

struct EventImageView: View {
    let imageURL: URL?
    var body: some View {
        AsyncImage(url: imageURL) { image in
            image.resizable().aspectRatio(contentMode: .fill)
        } placeholder: {
            VStack {
                Spacer()
                Text("CSUSM").font(.largeTitle.bold()).foregroundStyle(Color.spiritBlue)
                Spacer()
            }.frame(maxWidth: .infinity) .background {
                Color.universityBlue
            }
        }.frame(width: 390, height: 320).clipped()
    }
}

struct EventBody: View {
    
    let title: String
    let organization: String
    let description: String
    
    init(_ title: String, _ organization: String, _ description: String) {
        self.title = title
        self.organization = organization
        self.description = description
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.system(size: 29, weight: .semibold, design: .default))
                Spacer()
            }
            Text(organization).font(.system(.callout, weight: .medium))
            Text(description).font(.system(.callout).width(.condensed)).padding(.vertical)
        }.padding(.horizontal, 24).padding(.top, 12)
    }
}

struct EventHighlightsView: View {
    
    let startTime: String
    let endTime: String
    let organization: String
    let location: String
    let eventType: String
    
    init(_ startTime: String, _ endTime: String, _ organization: String, _ location: String, _ eventType: String) {
        self.startTime = startTime
        self.endTime = endTime
        self.organization = organization
        self.location = location
        self.eventType = eventType
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("HIGHLIGHTS").kerning(2.0).font(.system(size: 12, weight: .medium, design: .default)).foregroundColor(.secondary)
            timeHighlight
            organizationHighlight
            locationHighlight
            eventTypeHighlight
        }.padding(.horizontal, 24)
    }
    
    var timeHighlight: some View {
        HStack(spacing: 9) {
            Image(systemName: "clock").symbolRenderingMode(.monochrome).foregroundStyle(Color.universityBlue).frame(width: 20).clipped()
            Text("\(startTime) to \(endTime)")
            Spacer()
        }.font(.subheadline)
    }
    
    var organizationHighlight: some View {
        HStack(spacing: 9) {
            Image(systemName: "person.3").symbolRenderingMode(.monochrome).foregroundColor(.universityBlue).frame(width: 20).clipped()
            Text(organization)
            Spacer()
        }.font(.subheadline)
    }
    
    var locationHighlight: some View {
        HStack(spacing: 9) {
            Image(systemName: "location").symbolRenderingMode(.monochrome).foregroundColor(.universityBlue).frame(width: 20).clipped()
            Text(location)
            Spacer()
        }.font(.subheadline)
    }
    
    var eventTypeHighlight: some View {
        HStack(spacing: 9) {
            Image(systemName: "info").symbolRenderingMode(.monochrome).foregroundColor(.universityBlue).frame(width: 20).clipped()
            Text(eventType)
            Spacer()
        }.font(.subheadline)
    }
}

struct GuidanceButton: View {
    let event: ICalEvent
    
    init(for event: ICalEvent) {
        self.event = event
    }
    
    var body: some View {
        VStack(spacing: 14) {
            Text("Add To Calendar").font(.system(.title3, weight: .medium)).padding(.vertical, 12).padding(.horizontal, 24).background(Color.cougarBlue).foregroundColor(.white).mask {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
            }
        }.padding(.vertical, 28)
    }
}
