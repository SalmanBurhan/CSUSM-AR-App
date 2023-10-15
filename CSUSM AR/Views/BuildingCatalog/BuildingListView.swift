//
//  BuildingListView.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 10/15/23.
//

import SwiftUI

struct BuildingListView: View {
    @State var locations: [Location] = []
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color(.systemGray5), Color(.systemBackground)]), startPoint: .top, endPoint: .bottomTrailing)
                .frame(maxHeight: .infinity)
                .clipped()
            if self.locations.count == 0 {
                self.renderContentUnavailableView()
            } else {
                self.renderBuildingListView()
            }
        }
        .ignoresSafeArea()
        .onAppear(perform: {
            Task {
                self.locations = try await LocationCatalog.fetchLocations()
            }
        })
    }
}

extension BuildingListView {
        
    func renderContentUnavailableView() -> some View {
        return ContentUnavailableView {
            Label("Catalog Empty", systemImage: "list.number")
        } description: {
            Text("The catalog appears to be empty at the moment. Please try again in a few minutes.")
        }
    }
    
    func renderBuildingListView() -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading) {
                Text("California State University San Marcos")
                    .font(.largeTitle)
                    .padding(.horizontal)
                Text("Building Directory")
                    .font(.title2)
                    .padding(.horizontal)
                    .foregroundColor(.secondary)
                LazyVGrid(columns: [GridItem(.flexible())]) {
                    ForEach(self.locations, id: \.id) { location in
                        self.createRow(for: location)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .clipped()
            .padding(.top, 98)
            .padding(.bottom, 150)
        }
    }
    
    func createRow(for location: Location) -> some View {
        @State var imageURL: URL?
        return HStack {
            AsyncImage(url: imageURL) { image in
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
                    Text("CSUSM").font(.largeTitle.bold()).foregroundStyle(Constants.Colors.spiritBlue)
                    Spacer()
                }
                .frame(width: 100, height: 120, alignment: .center).clipped()
                .background {
                    Color(Constants.Colors.universityBlue)
                }
            }
            VStack(alignment: .leading) {
                Text(location.name)
                    .lineLimit(2)
                    .font(.title2)
                Text("Category \(location.categoryId)")
                    .lineLimit(1)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "arrow.down.right.circle.fill")
                .symbolRenderingMode(.hierarchical)
                .font(.title)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
}

#Preview {
    let location = Location(name: "Viasat Engineering Pavilion")
    let category = LocationCategory(name: "Academic Halls")
    return BuildingListView()
}
