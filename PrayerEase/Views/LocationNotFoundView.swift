//
//  LocationNotFoundView.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 10/30/24.
//

import SwiftUI

struct LocationNotFoundView: View {
    var body: some View {
        VStack(spacing: 30){
            Image(systemName: "location.fill")
                .font(.system(size: 90))
                .foregroundColor(.accent)
            
            HStack{
                Text("Correct")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Location")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.accent)
            }
            Text("To access the most accurate prayer times instantly through the Salah app, you need to allow location access.")
                .font(.callout)
                .fontWeight(.light)
                .multilineTextAlignment(.center)
                .padding()
            
            Text("We only need your location information while you are using the app. This enables us to provide prayer times specific to your location and is not shared with any other parties.")
                .font(.callout)
                .fontWeight(.light)
                .multilineTextAlignment(.center)
                .padding()
            
            Spacer()

            Text("Enable Location Access from Settings")
                .font(.callout)
                .foregroundColor(.secondary)

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString){
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
                
            } label: {
                Label("Allow location access", systemImage: "location.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .buttonSizing(.automatic)
            .controlSize(.large)

        }
        .padding()
    }
}

#Preview {
    LocationNotFoundView()
}
