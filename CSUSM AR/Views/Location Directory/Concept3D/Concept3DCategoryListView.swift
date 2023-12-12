//
//  BuildingListView.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 10/15/23.
//

import SwiftUI

#Preview {
  return Concept3DCategoryListView()
}

struct Concept3DCategoryListView: View {

  @ObservedObject var locationCatalog = Concept3D.shared
  @State private var isPDFViewPresented = false

  var body: some View {
    NavigationStack {
      ZStack {
        LinearGradient(
          gradient: Gradient(colors: [Color(.systemGray5), Color(.systemBackground)]),
          startPoint: .top, endPoint: .bottomTrailing
        )
        .frame(maxHeight: .infinity)
        .clipped()
        if self.locationCatalog.categories.count == 0 {
          self.renderContentUnavailableView()
        } else {
          self.renderCategoryListView()
        }
      }.ignoresSafeArea()
    }
    .toolbar {
      Button("PDF", systemImage: "map") {
        isPDFViewPresented.toggle()
      }
    }
    .popover(
      isPresented: $isPDFViewPresented,
      content: {
        if let pdfURL = Bundle.main.url(forResource: "campus-map", withExtension: "pdf") {
          PDFViewWrapper(pdfURL: pdfURL)
        } else {
          ContentUnavailableView(
            "Not Found", image: "doc.questionmark", description: Text("Unable to load campus map."))
        }
      })
  }
}

extension Concept3DCategoryListView {

  @ViewBuilder
  func renderContentUnavailableView() -> some View {
    if #available(iOS 17.0, *) {
      ContentUnavailableView {
        Label("Catalog Empty", systemImage: "list.number")
      } description: {
        Text("The catalog appears to be empty at the moment. Please try again in a few minutes.")
      }
    } else {
      // Fallback on earlier versions
      Group {
        Label("Catalog Empty", systemImage: "list.number")
        Text("The catalog appears to be empty at the moment. Please try again in a few minutes.")
      }
    }
  }

  @ViewBuilder
  func renderCategoryListView() -> some View {
    ScrollView(showsIndicators: false) {
      VStack(alignment: .leading) {
        Text("California State University San Marcos").font(.largeTitle).padding(.horizontal)
        Text("Building Directory").font(.title2).padding(.horizontal).foregroundColor(.secondary)
        LazyVGrid(columns: [GridItem(.flexible())]) {
          ForEach(self.locationCatalog.categories) { category in
            NavigationLink(destination: Concept3DCategoryView(category: category)) {
              self.createRow(for: category)
            }.buttonStyle(.plain)
          }
        }
      }.frame(maxWidth: .infinity).clipped().padding(.top, 100).padding(.bottom)
    }
  }

  @ViewBuilder
  func createRow(for category: Concept3DCategory) -> some View {
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
          .background {
            Color.universityBlue
          }
          .mask { RoundedRectangle(cornerRadius: 16, style: .continuous) }
      }

      VStack(alignment: .leading) {
        Text(category.name)
          .lineLimit(2)
          .font(.title2)
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
