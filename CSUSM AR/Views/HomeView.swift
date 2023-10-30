//
//  HomeView.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 10/22/23.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                pageBackground()
                VStack(alignment: .center) {
                    headerView()
                    menuTray()
                }
            }.ignoresSafeArea()
        }
    }
}

extension HomeView {
    
    @ViewBuilder
    func menuTrayItem(_ text: String, systemIcon: String) -> some View {
        RoundedRectangle(cornerRadius: 25, style: .circular)
            .overlay {
                VStack {
                    Image(systemName: systemIcon)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.thickMaterial)
                        .font(.largeTitle.weight(.light))
                        .padding(.bottom, 5)
                    Text(text)
                        .foregroundStyle(.thickMaterial)
                        .font(.callout.bold())
                }
            }
            .frame(minWidth: 100, maxHeight: 100)
    }
    
    @ViewBuilder
    func menuTray() -> some View {
        VStack(alignment: .leading) {
            Text("Resources")
                .font(.title3.bold())
                .padding(.top)
            LazyHGrid(rows: [GridItem(.flexible(minimum: 100))], alignment: .top, content: {
                
                NavigationLink(destination: EventFeedView()) {
                    menuTrayItem("Events", systemIcon: "calendar")
                        .foregroundStyle(Constants.Colors.cougarBlue.gradient)
                }.buttonStyle(.plain)
                
                NavigationLink(destination: Concept3DCategoryListView()) {
                    menuTrayItem("Buildings", systemIcon: "building.2")
                        .foregroundStyle(Constants.Colors.universityBlue.gradient)
                }.buttonStyle(.plain)
                
                menuTrayItem("Explore", systemIcon: "arkit")
                    .foregroundStyle(Constants.Colors.spiritBlue.gradient)
            })
        }
    }
    
    @ViewBuilder
    func pageBackground() -> some View {
        LinearGradient(gradient: Gradient(colors: [Color(.systemGray5), Color(.systemBackground)]), startPoint: .top, endPoint: .bottomTrailing)
            .frame(maxHeight: .infinity)
            .clipped()
    }
    
    @ViewBuilder
    func headerView() -> some View {
        LinearGradient(colors: [Constants.Colors.universityBlue, .black], startPoint: .topLeading, endPoint: .bottomTrailing).background(.ultraThickMaterial)
            .clipShape(UnevenRoundedRectangle(cornerRadii: .init(bottomLeading: 50, bottomTrailing: 50), style: .circular))
            .frame(height: 250)
            .overlay {
                VStack {
                    HStack(alignment: .center, spacing: 18) {
                        Image("user")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 75, height: 75)
                            .clipShape(Circle())
                            .overlay {
                                Circle()
                                    .inset(by: 1.0)
                                    .stroke(lineWidth: 2.0)
                                    .foregroundStyle(.thickMaterial)
                                    .opacity(0.50)
                                    .background(.clear)
                            }
                        VStack(alignment: .leading) {
                            Text("Hi, Salman!")
                                .font(.largeTitle)
                                .foregroundStyle(.thickMaterial)
                            Text("How can we help?")
                                .font(.headline)
                                .foregroundStyle(.regularMaterial)
                        }
                        Spacer()
                    }
                    .padding(.bottom)
                    HStack {
                        Text("Search...")
                            .foregroundStyle(.regularMaterial)
                        Spacer()
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.regularMaterial)
                    }
                    .padding()
                    .background(.ultraThinMaterial.opacity(0.35), in: Capsule(style: .circular))
                }
                .padding([.leading, .trailing, .top])
            }
    }
}

#Preview {
    HomeView()
}
