import SwiftUI

struct NotificationBanner: View {
    let notification: AppNotification
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(notification.color.opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: notification.icon)
                    .foregroundColor(notification.color)
                    .font(.system(size: 16, weight: .semibold))
            }

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(notification.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Text(notification.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            // Dismiss
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("Background"))
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
    }
}
