import AVKit
import SwiftUI

struct ContentView: View {
    @StateObject var player = Player()
    
    var body: some View {
        VStack {
            
            VideoPlayer(player: player.player)
                .frame(height: 400)
            
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
