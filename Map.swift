//
//  Map.swift
//  CSUSM AR
//
//  Created by Citlally Gomez on 11/12/23.
//map
// user can you can zoom in and out
//only runs on physical device or mac/ipad - tested on mac
import SwiftUI

struct Map: View {
        @State var magScale: CGFloat = 1
        @State var progressingScale: CGFloat = 1

        var magnification: some Gesture {
            MagnificationGesture()
                .onChanged { progressingScale = $0 }
                .onEnded {
                    magScale *= $0
                    progressingScale = 1
                }
        }

        var body: some View {
            Image("map")
                .resizable()
                .frame(width: 400, height: 300, alignment: .center)
                .scaleEffect(self.magScale * progressingScale)
                .gesture(magnification)
        }
    }
#Preview {
    Map()
}
