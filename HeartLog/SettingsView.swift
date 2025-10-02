
import SwiftUI
import StoreKit

struct SettingsView: View {
    // MARK: - Properties
    @Environment(\.openURL) var openURL
    @Environment(\.dismiss) var dismiss
    @State private var versionNumber: String = ""
    
    // MARK: - Body
    var body: some View {
        NavigationStack{
                List {
              
                    //rate us
                    Section{
                        Link(destination: writeReview(), label: {
                            Text("Rate the App")
                                .foregroundStyle(Color.primary)

                        
                        })
                        
                        
                    }
                    Section{
                        //Privacy Policy
                        Link(destination: URL(string: "https://sites.google.com/view/knot-not-privacy-policy/home")!, label: {
                            Text("Privacy Policy")
                                .foregroundStyle(Color.primary)

                        } )
                        //Terms & Condtions
                        Link(destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!, label: {
                            Text("Terms & Conditions")
                                .foregroundStyle(Color.primary)

                           
                        }
                        )
                        
                    }
                    Section{
                        //Support link
                        HStack{

                    
                            Text("Contact Me")
                                .foregroundColor(Color.primary)
                            Spacer()
                            Text("peizhengze@gmail.com")
                                .foregroundStyle(Color.secondary)
                                
                        }
                           
                        //Follow me on X
                        Link(destination: URL(string: "https://x.com/JeongtaeBae")!, label: {
                            HStack{
                                Text("Follow Me on X")
                                    .foregroundStyle(Color.primary)
                                Spacer()
                                Text("@JeongTaeBae")
                                    .foregroundStyle(Color.secondary)
                            }
                            

                           
                        })
                        //Ins link
                        Link(destination: URL(string: "https://www.instagram.com/jeongpei/")!, label: {
                            HStack{
                                Text("Instagram")
                                    .foregroundStyle(Color.primary)
                                Spacer()
                                Text("@JeongPei")
                                    .foregroundStyle(Color.secondary)
                            }

                        })
                       
                    }
                    
                    Section{
                        HStack{
                            Text("App Version")
                                .foregroundStyle(Color.primary)
                            Spacer()
                            Text("\(versionNumber)")
                                .foregroundStyle(Color.secondary)
                        }
                      
                    }
                    
                }
                .listStyle(.insetGrouped)
                
             
                
          
            
        }
        .navigationTitle("Settings")
        .onAppear(){
            getAppVersion()
        }
    }
    
    
    // MARK: Functions
    private func getAppVersion()->(){
        if let text = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            versionNumber = text
        }
    }
    
    private func writeReview()->URL {
        let appID = "6670250582"
        let url = "https://apps.apple.com/app/id\(appID)?action=write-review"
        guard let writeReviewURL = URL(string: url) else {
            fatalError("Expected a valid URL")
        }
        return writeReviewURL
    }
    
}

// MARK: - Row
struct Row: View {
    var icon: String
    var iconColor: Color
    var title: String

    var trailing: String?
    var customIcon: String?
    
    var body: some View {
        HStack() {
//            ZStack {
//                Image(systemName: icon)
//                    .resizable()
//                    .foregroundStyle(iconColor)
//                Image(customIcon ?? "")
//                    .resizable()
//                    .foregroundStyle(iconColor)
//            }
//            .frame(width: 26, height: 26)
    
            Text(title)
                .foregroundColor(Color.primary)
            Spacer()
            Text(trailing ?? "")
                .foregroundStyle(Color.secondary)
        }
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
      
    .preferredColorScheme(.light)
}


