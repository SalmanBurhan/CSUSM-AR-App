//
//  Concept3DCategoryView.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 10/21/23.
//

import SwiftUI

struct Concept3DCategoryView: View {
    
    @State var concept3D = Concept3D.shared
    @State var category: Concept3DCategory
    
    @State var children = [Concept3DCategory]()
    @State var locations = [Concept3DLocation]()
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color(.systemGray5), Color(.systemBackground)]), startPoint: .top, endPoint: .bottomTrailing)
                    .frame(maxHeight: .infinity)
                    .clipped()
                renderScrollView {
                    Group {
                        if self.children.count > 0 {
                            Spacer()
                            childrenListView()
                        }
                        if self.locations.count > 0 {
                            Spacer()
                            locationListView()
                        }
                    }.padding(.horizontal)
                }
            }.ignoresSafeArea()
        }.task { await self.loadDetails() }
    }
}

extension Concept3DCategoryView {
    
    @ViewBuilder
    func renderScrollView(_ enclosedView: () -> (some View)) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading) {
                Text("California State University San Marcos")
                    .font(.largeTitle)
                    .padding(.horizontal)
                Text(self.category.name)
                    .font(.title2)
                    .padding(.horizontal)
                    .foregroundColor(.secondary)
                enclosedView()
            }
        }
        .frame(maxWidth: .infinity)
        .clipped()
        .padding(.top, 100)
        .padding(.bottom)
    }
    
    @ViewBuilder
    func childrenListView() -> some View {
        Group {
            Text("Subcategories")
                .font(.headline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            ForEach(self.children) { child in
                NavigationLink(destination: Concept3DCategoryView(category: child).withCustomBackButton()) {
                    HStack {
                        AsyncImage(url: category.iconURL) { image in
                            image.renderingMode(.original)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 40, height: 40, alignment: .center)
                                .clipped()
                        } placeholder: {
                            Image(systemName: "questionmark.circle.fill")
                                .symbolRenderingMode(.hierarchical)
                                .imageScale(.large)
                                .foregroundStyle(Constants.Colors.spiritBlue)
                                .frame(width: 40, height: 40, alignment: .center).clipped()
                                .background { Color(Constants.Colors.universityBlue) }
                                .mask { RoundedRectangle(cornerRadius: 16, style: .continuous) }
                        }

                        Text(child.name).lineLimit(2).font(.title2)
                        Spacer()
                        Image(systemName: "arrow.down.right.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .font(.title)
                            .foregroundStyle(.secondary)
                    }.padding(.horizontal)
                }.buttonStyle(.plain)

            }
        }
    }
    
    @ViewBuilder
    func locationListView() -> some View {
        Group {
            Text("Locations")
                .font(.headline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            ForEach(self.locations) { location in
                LocationCollectionCardView(for: location, with: category)
                    .padding(.bottom, 5)
            }
            
        }
    }
    
    @ViewBuilder
    func _locationListView() -> some View {
        Group {
            Text("Locations")
                .font(.headline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            ForEach(self.locations) { location in
                HStack {
                    AsyncImage(url: location.details?.images[.tiny] ?? nil) { image in
                        image
                            .renderingMode(.original)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 120, alignment: .center)
                            .clipped()
                            .mask { RoundedRectangle(cornerRadius: 16, style: .continuous) }
                            .padding(.trailing, 8)
                    } placeholder: {
                        VStack {
                            Spacer()
                            Text("CSUSM").fontWeight(.bold).minimumScaleFactor(0.75).foregroundStyle(Constants.Colors.spiritBlue)
                            Spacer()
                        }
                        .frame(width: 100, height: 120, alignment: .center).clipped()
                        .background {
                            Color(Constants.Colors.universityBlue)
                        }
                        .mask { RoundedRectangle(cornerRadius: 16, style: .continuous) }
                    }
                    VStack(alignment: .leading) {
                        Text(location.name)
                            .lineLimit(2)
                            .font(.title2)
                        Text("Category")
                            .lineLimit(1)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "arrow.down.right.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .font(.title)
                        .foregroundColor(Constants.Colors.spiritBlue)
                }
                .padding(.horizontal)
            }
        }
    }
}

extension Concept3DCategoryView {
    func loadDetails() async {
        if let details = try? await self.concept3D.fetchDetails(for: self.category) {
            self.children = details.children
            self.locations = details.locations
            
            if let detailedLocations = try? await withThrowingTaskGroup(of: (Concept3DLocation, Concept3DLocationDetails).self, returning: [Concept3DLocation].self, body: { group in
                let locations = details.locations
                for location in locations { group.addTask { try await (location, self.concept3D.fetchDetails(for: location)) } }
                return try await group.reduce(into: [Concept3DLocation]()) { $0.append($1.0.copy(with: $1.1)) }
            }) {
                self.locations = detailedLocations.sorted(by: { $0.name.lowercased() < $1.name.lowercased() })
            }
        }
    }
}

#Preview {
    Concept3DCategoryView(category: .init(name: "Category Name"))
}
