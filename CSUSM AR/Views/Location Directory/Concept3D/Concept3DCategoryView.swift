//
//  Concept3DCategoryView.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 10/21/23.
//

import MapKit
import SwiftUI

#Preview {
  Concept3DCategoryView(category: .init(name: "Category Name"))
}

/// A view that displays a category of Concept3D objects.
///
/// This view is responsible for rendering the subcategories and locations associated with the category.
/// It also includes a toolbar item for navigating to the AR view.
///
/// - Parameters:
///   - concept3D: The shared instance of the Concept3D service.
///   - category: The category of Concept3D objects to display.
///
/// - Note: This view automatically loads the details of the category and its associated objects.
///
/// - SeeAlso: `Concept3D.shared`
/// - SeeAlso: `Concept3DCategory`
/// - SeeAlso: `Concept3DLocation`
///
struct Concept3DCategoryView: View {

  /// The shared instance of the Concept3D service.
  @State var concept3D = Concept3D.shared

  /// The category of Concept3D objects to display.
  @State var category: Concept3DCategory

  /// The subcategories of the category.
  @State var children = [Concept3DCategory]()

  /// The locations associated with the category.
  @State var locations = [Concept3DLocation]()

  /// The body of the view.
  ///
  /// Creates a view that displays a category of Concept3D objects.
  var body: some View {
    NavigationStack {
      ZStack {
        LinearGradient(
          gradient: Gradient(colors: [Color(.systemGray5), Color(.systemBackground)]),
          startPoint: .top, endPoint: .bottomTrailing
        )
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
              locationsMapView()
              Spacer()
              locationListView()
            }
          }.padding(.horizontal)
        }
      }.ignoresSafeArea()
    }
    .task { await self.loadDetails() }
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        NavigationLink {
          //ExploreARView(self.locations)
          CatalogARView(self.locations, category: self.category)
        } label: {
          Image(systemName: "arkit")
        }

      }
    }
  }
}

// MARK: - View Rendering

/// Extension for rendering the view.
extension Concept3DCategoryView {

  /**
 Renders a scroll view with a title and enclosed view.

 - Parameter enclosedView: A closure that returns the enclosed view to be rendered within the scroll view.
 - Returns: A view with a scrollable content area, a title, and the enclosed view.
 */
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

  /**
 A view that displays a list of child categories.

 This view is used to display a list of child categories in the Concept3DCategoryView. It shows the subcategories' names, icons, and a navigation link to their respective category views.

 - Returns: A SwiftUI view that displays the list of child categories.
 */
  @ViewBuilder
  func childrenListView() -> some View {
    Group {
      Text("Subcategories")
        .font(.headline)
        .fontWeight(.medium)
        .foregroundStyle(.secondary)
      ForEach(self.children) { child in
        NavigationLink(destination: Concept3DCategoryView(category: child)) {
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
                .foregroundStyle(Color.spiritBlue)
                .frame(width: 40, height: 40, alignment: .center).clipped()
                .background { Color.universityBlue }
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

  /**
 A view builder function that creates a list view of locations.

 - Returns: A view containing a list of locations.
 */
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

  /// A view that displays a map of locations.
  ///
  /// - Returns: A SwiftUI view that shows a map with markers for each location.
  @ViewBuilder
  func locationsMapView() -> some View {
    let region = MKCoordinateRegion(
      center: .init(
        latitude: 33.129996983381716, longitude: -117.1586831461883),
      span: .init(
        latitudeDelta: 0.009,
        longitudeDelta: 0.009))
    Group {
      Text("Campus Map")
        .font(.headline)
        .fontWeight(.medium)
        .foregroundStyle(.secondary)
      Map(initialPosition: .region(region)) {
        ForEach(self.locations) {
          Marker($0.name, coordinate: $0.location)
            .tint(Color.cougarBlue)
        }
      }.frame(height: 200)
    }
  }

  @available(*, deprecated, renamed: "locationListView")
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
              Text("CSUSM").fontWeight(.bold).minimumScaleFactor(0.75).foregroundStyle(
                Color.spiritBlue)
              Spacer()
            }
            .frame(width: 100, height: 120, alignment: .center).clipped()
            .background {
              Color.universityBlue
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
            .foregroundColor(Color.spiritBlue)
        }
        .padding(.horizontal)
      }
    }
  }
}

// MARK: - Data Loading

extension Concept3DCategoryView {
  func loadDetails() async {
    if let details = try? await self.concept3D.fetchDetails(for: self.category) {
      self.children = details.children
      self.locations = details.locations

      if let detailedLocations = try? await withThrowingTaskGroup(
        of: (Concept3DLocation, Concept3DLocationDetails).self, returning: [Concept3DLocation].self,
        body: { group in
          let locations = details.locations
          for location in locations {
            group.addTask { try await (location, self.concept3D.fetchDetails(for: location)) }
          }
          return try await group.reduce(into: [Concept3DLocation]()) {
            $0.append($1.0.copy(with: $1.1))
          }
        })
      {
        self.locations = detailedLocations.sorted(by: {
          $0.name.lowercased() < $1.name.lowercased()
        })
      }
    }
  }
}
