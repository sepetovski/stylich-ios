import SwiftUI

struct ArenaView: View {
    @StateObject private var battleService = BattleService()
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker = false
    @State private var selectedCategory = "casual"
    @State private var showResult = false
    @State private var showCrop = false
    @State private var rawImage: UIImage? = nil

    let categories = ["casual", "streetwear", "formal", "vintage", "athletic", "business", "avant_garde"]

    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Title
                VStack(spacing: 6) {
                    Text("Arena")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                    Text("drop a fit. enter the battle.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 48)

                // Photo picker
                Button {
                    showImagePicker = true
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 260, height: 320)

                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 260, height: 320)
                                .clipped()
                                .cornerRadius(24)
                        } else {
                            VStack(spacing: 16) {
                                Image(systemName: "tshirt.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(Color("AccentColor"))
                                Text("Tap to pick your fit")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                // Category picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.self) { cat in
                            Button {
                                selectedCategory = cat
                            } label: {
                                Text(cat.replacingOccurrences(of: "_", with: " "))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(selectedCategory == cat ? Color("AccentColor") : Color.gray.opacity(0.15))
                                    .foregroundColor(selectedCategory == cat ? .black : .primary)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }

                // Error message
                if !battleService.errorMessage.isEmpty {
                    Text(battleService.errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal, 32)
                }

                // Submit button
                Button {
                    guard let image = selectedImage else { return }
                    Task {
                        await battleService.submitFit(image: image, category: selectedCategory)
                        if battleService.battleResult != nil {
                            showResult = true
                            // Reset the arena after success
                            selectedImage = nil
                            rawImage = nil
                        }
                    }
                } label: {
                    if battleService.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("AccentColor"))
                            .cornerRadius(14)
                    } else {
                        Text("Enter the arena ⚔️")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedImage == nil ? Color.gray.opacity(0.3) : Color("AccentColor"))
                            .foregroundColor(selectedImage == nil ? .secondary : .black)
                            .cornerRadius(14)
                    }
                }
                .disabled(selectedImage == nil || battleService.isLoading)
                .padding(.horizontal, 32)

                Spacer()
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $rawImage)
        }
        .fullScreenCover(isPresented: $showCrop) {
            if let raw = rawImage {
                ImageCropView(image: raw) { cropped in
                    selectedImage = cropped
                    showCrop = false
                } onCancel: {
                    showCrop = false
                    rawImage = nil
                }
            }
        }
        .onChange(of: rawImage) { newImage in
            if newImage != nil {
                showImagePicker = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showCrop = true
                }
            }
        }
        .sheet(isPresented: $showResult) {
            BattleResultView(result: battleService.battleResult!)
        }
    }
}

#Preview {
    ArenaView()
}
