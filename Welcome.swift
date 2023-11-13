//
//  Welcome.swift
//  CSUSM AR
//
//  Created by Citlally Gomez on 11/12/23.
// Was unable to test it, only tested up until the logo

import SwiftUI

struct Welcome: View {
    var body: some View {
        NavigationView{
            ZStack{
                Image("home_background")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
                VStack{
                    Image("logo")
                        .scaledToFit()
                        .frame(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                    NavigationLink(destination: HomeView())
                    {
                        HStack{
                            Image(systemName: "camera")
                            Text("Explore")
                            Image(systemName:"chevron.forward")
                        }
                        .buttonStyle(.plain)
                        .padding(10)
                        .background(Color.white)
                    }
                }
            }
        }
    }
}
#Preview {
    Welcome()
}
