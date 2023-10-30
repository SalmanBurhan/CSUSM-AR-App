//
//  EventRowView.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 10/22/23.
//

import SwiftUI

struct EventRowView: View {
    
    var event: ICalEvent
    
    init(for event: ICalEvent) {
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
    
    var date: String {
        return event.dtstart?.date.formatted(date: .abbreviated,time: .omitted) ?? "Event Date"
    }

    var startTime: String {
        return event.dtstart?.date.formatted(date: .omitted,time: .shortened) ?? "Start Time"
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
                        .foregroundStyle(Constants.Colors.spiritBlue)
                        .padding()
                    Spacer()
                }
                .frame(width: 100)
                .background {
                    LinearGradient(colors: [
                        Constants.Colors.universityBlue, .black
                    ], startPoint: .topLeading, endPoint: .bottomTrailing).background(.ultraThickMaterial)
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
                    icon: { Image(systemName: "location.circle").symbolRenderingMode(.monochrome) .foregroundStyle(Constants.Colors.spiritBlue).font(.caption)
                    }
                )
                HStack {
                    Label(
                        title: { Text(date).font(.caption) },
                        icon: { Image(systemName: "calendar").symbolRenderingMode(.monochrome).foregroundStyle(Constants.Colors.spiritBlue) }
                    )
                    .padding([.top, .bottom], 5)
                    .padding([.leading, .trailing], 8)
                    .background(.ultraThickMaterial, in: Capsule(style: .circular))

                    Label(
                        title: { Text(startTime).font(.caption) },
                        icon: { Image(systemName: "clock").symbolRenderingMode(.monochrome).foregroundStyle(Constants.Colors.spiritBlue) }
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
