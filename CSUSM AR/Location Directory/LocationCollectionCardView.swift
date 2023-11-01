//
//  LocationCollectionCardView.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 10/22/23.
//

import SwiftUI

struct LocationCollectionCardView: View {
    
    var location: Concept3DLocation
    var category: Concept3DCategory
    
    init(for location: Concept3DLocation, with category: Concept3DCategory) {
        self.location = location
        self.category = category
    }
    
    var body: some View {
        
        ZStack(alignment: .bottom) {
            AsyncImage(url: self.location.details?.images[.tiny]) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                VStack {
                    Spacer()
                    Text("CSUSM\n")
                        .font(.title)
                        .fontWeight(.bold)
                        .minimumScaleFactor(0.90)
                        .foregroundStyle(Color.spiritBlue)
                        .padding()
                    Spacer()
                }
                .frame(minWidth: 100, maxWidth: .infinity)
                .background {
                    LinearGradient(colors: [
                        Color.universityBlue, .black
                    ], startPoint: .topLeading, endPoint: .bottomTrailing).background(.ultraThickMaterial)
                }
            }
            .frame(minWidth: 100, maxHeight: 200)
            .clipped()


            VStack {
                Text(self.location.name)
                    .bold()
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                Text(self.category.name)
                    .font(.footnote)
            }
            .padding() // .padding(16)?
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style:. continuous)
                    .inset(by: 1.0)
                    .stroke(lineWidth: 1.0)
                    .foregroundStyle(.thickMaterial)
                    .opacity(0.50)
                    .background(.clear)
            }
            .padding(.bottom, 10)
        }
        .frame(minWidth: 100, minHeight: 200, maxHeight: 200)
        .mask { RoundedRectangle(cornerRadius: 12, style: .continuous)}
    }
}

#Preview {
    let location = Concept3DLocation(name: "Markstein Hall")
    let category = Concept3DCategory(name: "Academic Halls")
    
    return LazyVGrid(columns: [GridItem(.adaptive(minimum: 100)), GridItem(.adaptive(minimum: 100))], spacing: 12, content: {
        LocationCollectionCardView(for: location, with: category)
        LocationCollectionCardView(for: location, with: category)
        LocationCollectionCardView(for: location, with: category)
        LocationCollectionCardView(for: location, with: category)
    }).padding()
}
