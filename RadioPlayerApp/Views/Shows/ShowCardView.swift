import SwiftUI
import RadioPlayer

struct ShowCardView: View {
    let doc: SearchDoc
    var size: CGFloat = 160

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            AsyncCachedImage(
                url: URL(string: "https://archive.org/services/img/\(doc.identifier)"),
                title: doc.title ?? doc.identifier,
                size: size
            )

            Text(doc.title ?? doc.identifier)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .frame(width: size, alignment: .leading)

            if let creator = doc.creator?.first {
                Text(creator)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(width: size, alignment: .leading)
            }
        }
    }
}
