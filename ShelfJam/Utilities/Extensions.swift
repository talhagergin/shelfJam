import SwiftUI

extension Collection {
    var isNotEmpty: Bool { !isEmpty }
}

extension View {
    func cozyCard() -> some View {
        self
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous))
    }
}
