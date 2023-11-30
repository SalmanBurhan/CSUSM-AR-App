//
//  CardNodeView.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 11/29/23.
//

import SwiftUI

struct CardNodeView: View {
    
    let text: Text
    let image: Image
    
    init(text: String, systemImage: String) {
        self.text = Text(text)
        self.image = Image(systemName: systemImage)
    }
    
    init(text: String, image: UIImage) {
        self.text = Text(text)
        self.image = Image(uiImage: image)
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .center) {
                Spacer()
                self.text
                    .font(.title.bold())
                    .layoutPriority(1)
                Spacer()
                self.image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(.white)
                    .font(.largeTitle)
                    .padding()
                    .frame(width: geometry.size.width * 0.25, height: geometry.size.height)
                    .background(Color.universityBlue.gradient)
            }.frame(height: geometry.size.height)
        }
    }
}

#Preview {
    CardNodeView(
        text: "Some Name",
        systemImage: "building.2.crop.circle"
    ).frame(width: 300, height: 175).border(Color.black)
}
