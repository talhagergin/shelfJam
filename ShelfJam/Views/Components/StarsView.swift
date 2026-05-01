import SwiftUI

struct StarsView: View {
    let stars: Int
    var size: CGFloat = 16

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...3, id: \.self) { index in
                Image(systemName: index <= stars ? "star.fill" : "star")
                    .font(.system(size: size, weight: .semibold))
                    .foregroundStyle(index <= stars ? .yellow : .secondary)
            }
        }
        .accessibilityLabel("\(stars) out of 3 stars")
    }
}
