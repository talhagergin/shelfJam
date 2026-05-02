import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void
    @State private var page = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "square.grid.3x3.fill",
            title: "Sort the Shelves",
            body: "Move one item into an empty slot. Make three matching items touch on the same shelf to clear them."
        ),
        OnboardingPage(
            icon: "timer",
            title: "Moves and Time Matter",
            body: "Every move costs one move. Some levels are rush challenges, some are precision challenges, and failed attempts cost a life."
        ),
        OnboardingPage(
            icon: "lock.fill",
            title: "Locked Items",
            body: "When locks appear, unlock them by matching the same item beside the lock or by making a five-item match of that type."
        ),
        OnboardingPage(
            icon: "bag.fill",
            title: "Use Boosts Wisely",
            body: "Earn diamonds from stars and rewards, then spend them on Undo, Tip, Shuffle, or extra lives in the shop."
        )
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.09, blue: 0.27),
                    Color(red: 0.13, green: 0.37, blue: 0.49),
                    Color(red: 1.00, green: 0.57, blue: 0.34)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                VStack(spacing: 18) {
                    Image(systemName: pages[page].icon)
                        .font(.system(size: 54, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 106, height: 106)
                        .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 32, style: .continuous))

                    Text(pages[page].title)
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text(pages[page].body)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.white.opacity(0.82))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .frame(maxWidth: 340)
                }
                .padding(.horizontal, 24)
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
                .id(page)

                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { index in
                        Capsule()
                            .fill(index == page ? .white : .white.opacity(0.32))
                            .frame(width: index == page ? 26 : 8, height: 8)
                    }
                }

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                        if page < pages.count - 1 {
                            page += 1
                        } else {
                            onFinish()
                        }
                    }
                } label: {
                    Text(page < pages.count - 1 ? "Next" : "Start Playing")
                        .font(.headline.weight(.black))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundStyle(Color(red: 0.16, green: 0.11, blue: 0.27))
                .padding(.horizontal, 28)

                Button("Skip") {
                    onFinish()
                }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white.opacity(0.74))
                .padding(.bottom, 28)
            }
        }
    }
}

private struct OnboardingPage {
    let icon: String
    let title: String
    let body: String
}

