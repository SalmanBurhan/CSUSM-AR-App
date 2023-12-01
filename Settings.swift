//
//  Settings.swift
//  CSUSM AR
//
//  Created by Citlally Gomez on 12/1/23.
//

import SwiftUI

struct Settings: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    var body: some View {
        NavigationView {
            List{
                HStack{
                    Toggle("Dark Mode", isOn: $isDarkMode)
                }
                    VStack{
                        Text("Emergency Phone Numbers")
                            .bold()
                        HStack{
                            Text("CONTACT")
                            Spacer()
                            Text("PHONE")
                                .scenePadding()
                        }
                        HStack{
                            Text("Campus Emergencies")
                            Spacer()
                            Text("9-1-1")
                                .scenePadding()
                            
                        }
                        HStack{
                            Text("University Police")
                            Spacer()
                            Text("(760) 750-4567")
                                .scenePadding()
                            
                        }
                        HStack{
                            Text("Dept. of EM")
                            Spacer()
                            Text("(760) 750-4503")
                                .scenePadding()
                            
                        }
                        HStack{
                            Text("Campus Operator")
                            Spacer(minLength: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/)
                            Text("(760) 750-4000")
                                .scenePadding()
                            
                            
                        }
                        
                    }
                }
            }
        }
    }
#Preview {
    Settings()
}
