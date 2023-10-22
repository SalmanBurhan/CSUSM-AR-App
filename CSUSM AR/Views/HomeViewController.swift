//
//  HomeViewController.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 9/27/23.
//

import SwiftUI
import XMLCoder


struct HomeViewController: View {
    var body: some View {
        
        NavigationStack {
            VStack {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Good Morning!")
                            .font(.system(.title2, weight: .medium))
                        Text("What can we help you find?")
                            .font(.title3)
                    }
                    Spacer()
                }
                HStack(alignment: .top) {
                    Image(systemName: "location.fill.viewfinder")
                        .symbolRenderingMode(.monochrome)
                    Text("Explore Campus")
                    Spacer()
                }
                .background {
                    Group {
                        
                    }
                }
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.blue)
                }
                .foregroundColor(.white)
                NavigationLink(destination: EventFeedView()) {
                    HStack(alignment: .top) {
                        Image(systemName: "calendar")
                            .symbolRenderingMode(.monochrome)
                        Text("Find Nearby Events")
                        Spacer()
                    }
                    .background {
                        Group {
                            
                        }
                    }
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(.blue)
                    }
                    .foregroundColor(.white)
                }
                NavigationLink(destination: Concept3DCategoryListView()) {
                    HStack(alignment: .top) {
                        Image(systemName: "building.2")
                            .symbolRenderingMode(.monochrome)
                        Text("Find a Building")
                        Spacer()
                    }
                    .background {
                        Group {
                            
                        }
                    }
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(.blue)
                    }
                    .foregroundColor(.white)
                }
            }
            .padding(.leading, 60)
        }
    }
}

#Preview {
    HomeViewController()
}
