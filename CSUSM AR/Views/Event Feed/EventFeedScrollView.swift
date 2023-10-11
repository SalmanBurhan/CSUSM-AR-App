//
//  EventFeedScrollView.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 10/9/23.
//

import SwiftUI

struct EventFeedView: View {
    
    @State var events: [ICalEvent] = []
    
    var body: some View {
        NavigationStack {
            Group {
                if self.events.count == 0 {
                    contentUnavailableView
                } else {
                    eventsScrollView
                }
            }.onAppear(perform: {
                self.loadEvents()
            })
        }
    }
    
    private func loadEvents() {
        print("Tap Gesture Detected on \"Find Nearby Events\"")
        let url = URL(string: "https://25livepub.collegenet.com/calendars/csusm-featured-events.ics")!
        URLSession.shared.dataTask(
            with: URLRequest(url: url)) { data, response, error in
                guard let data = data,
                let ics = String(data: data, encoding: .utf8)
                else {
                    print("Unable To Read HTTP Response Body")
                    return
                }
                self.events = ICalParser().parseEvents(ics: ics)
        }.resume()
    }
    
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
}

extension EventFeedView {
    var contentUnavailableView: some View {
        ContentUnavailableView {
            Label("No Events", systemImage: "calendar")
        } description: {
            Text("Campus featured events will appear here.")
        }
    }
}

extension EventFeedView {
    var eventsScrollView: some View {
        ScrollView {
            VStack {
                LazyVGrid(columns: [GridItem(.flexible())]) {
                    ForEach($events, id: \.uid) { event in
                        NavigationLink(destination: EventDetailsView(event.wrappedValue).withCustomBackButton()) {
                            createEventView(for: event.wrappedValue)
                        }.buttonStyle(.plain)
                    }
                }.frame(maxWidth: .infinity).clipped()
            }
        }
    }
}

extension EventFeedView {
    
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
                Text(location.uppercased()).font(.subheadline).foregroundStyle(Constants.Colors.cougarBlue)
                Text(title).font(.system(.title, design: .rounded, weight: .semibold)).foregroundStyle(Constants.Colors.universityBlue)
            }.padding()
            
        }.padding(5).background {
            RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color(.secondarySystemBackground))
        }
    }
    
    internal func dateLabel(_ date: String) -> some View {
        VStack {
            Text(date.uppercased())
                .padding([.top, .bottom], 5)
                .padding([.leading, .trailing], 10)
                .background {
                    Capsule(style: .continuous)
                        .fill(Constants.Colors.universityBlue)
                }
                .foregroundColor(.white)
        }
    }
    
    internal func timeLabel(_ time: String) -> some View {
        VStack {
            Text(time.uppercased())
                .padding([.top, .bottom], 5)
                .padding([.leading, .trailing], 10)
                .background {
                    Capsule(style: .continuous)
                        .fill(Constants.Colors.universityBlue)
                }
                .foregroundColor(.white)
        }
    }
}

#Preview {
    EventFeedView()
}
