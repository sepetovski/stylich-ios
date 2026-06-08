import SwiftUI

struct ImageCropView: View {
    let image: UIImage
    let onCrop: (UIImage) -> Void
    let onCancel: () -> Void

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    let cropSize: CGFloat = UIScreen.main.bounds.width - 48

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {

                // Title
                Text("Crop your fit")
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                    .padding(.top, 60)
                    .padding(.bottom, 24)

                // Crop area
                ZStack {
                    Color.black

                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: cropSize * scale, height: cropSize * scale)
                        .offset(offset)

                    GridOverlay(size: cropSize)
                }
                .frame(width: cropSize, height: cropSize)
                .cornerRadius(12)
                .clipped()
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let maxOffset = (cropSize * (scale - 1)) / 2
                            let newX = lastOffset.width + value.translation.width
                            let newY = lastOffset.height + value.translation.height
                            offset = CGSize(
                                width: max(-maxOffset, min(maxOffset, newX)),
                                height: max(-maxOffset, min(maxOffset, newY))
                            )
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }
                )
                .simultaneousGesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = max(1.0, lastScale * value)
                        }
                        .onEnded { _ in
                            lastScale = scale
                        }
                )
                

                Spacer()

                // Zoom controls (helpful on simulator)
                HStack(spacing: 32) {
                    Button {
                        withAnimation { scale = max(1.0, scale - 0.25) }
                        lastScale = scale
                    } label: {
                        Image(systemName: "minus.magnifyingglass")
                            .font(.title2)
                            .foregroundColor(.white)
                    }

                    Text(String(format: "%.1fx", scale))
                        .foregroundColor(.gray)
                        .font(.caption)
                        .frame(width: 40)

                    Button {
                        withAnimation { scale = min(4.0, scale + 0.25) }
                        lastScale = scale
                    } label: {
                        Image(systemName: "plus.magnifyingglass")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                .padding(.bottom, 8)
                
                Spacer()
                
                
                Text("Pinch to zoom · Drag to reposition")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 16)

                // Bottom buttons
                HStack(spacing: 16) {
                    Button {
                        onCancel()
                    } label: {
                        Text("Cancel")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }

                    Button {
                        onCrop(cropImage())
                    } label: {
                        Text("Use photo")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("AccentColor"))
                            .foregroundColor(.black)
                            .cornerRadius(14)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }

    func cropImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: cropSize, height: cropSize))
        return renderer.image { _ in
            let aspectFit = max(cropSize / image.size.width, cropSize / image.size.height)
            let drawWidth = image.size.width * aspectFit * scale
            let drawHeight = image.size.height * aspectFit * scale
            let x = (cropSize - drawWidth) / 2 + offset.width
            let y = (cropSize - drawHeight) / 2 + offset.height
            image.draw(in: CGRect(x: x, y: y, width: drawWidth, height: drawHeight))
        }
    }
}

struct GridOverlay: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.8), lineWidth: 1)

            VStack(spacing: 0) {
                ForEach(0..<2) { _ in
                    Spacer()
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 0.5)
                }
                Spacer()
            }

            HStack(spacing: 0) {
                ForEach(0..<2) { _ in
                    Spacer()
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 0.5)
                }
                Spacer()
            }

            VStack {
                HStack {
                    CornerHandle(); Spacer(); CornerHandle()
                }
                Spacer()
                HStack {
                    CornerHandle(); Spacer(); CornerHandle()
                }
            }
            .padding(8)
        }
        .frame(width: size, height: size)
    }
}

struct CornerHandle: View {
    var body: some View {
        Rectangle()
            .fill(Color.white)
            .frame(width: 20, height: 20)
            .cornerRadius(2)
    }
}

#Preview {
    ImageCropView(image: UIImage(systemName: "photo")!, onCrop: { _ in }, onCancel: {})
}
