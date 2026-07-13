import SwiftUI
import FirebaseDatabase
import PhotosUI

struct CreatePostPage: View {

    @Environment(\.dismiss) private var dismiss

    @State private var isUploading = false
    @State private var caption = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?

    var body: some View {

        ZStack {

            LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 0.08, green: 0.08, blue: 0.14)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {

                VStack(spacing: 30) {

                    VStack(spacing: 15) {

                        if let selectedImage {

                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 300, height: 300)
                                .clipShape(
                                    RoundedRectangle(cornerRadius: 28)
                                )
                                .shadow(
                                    color: .purple.opacity(0.35),
                                    radius: 15
                                )

                        } else {

                            RoundedRectangle(cornerRadius: 28)
                                .fill(Color.white.opacity(0.06))
                                .frame(width: 300, height: 300)
                                .overlay {

                                    VStack(spacing: 12) {

                                        Image(systemName: "photo.on.rectangle.angled")
                                            .font(.system(size: 60))
                                            .foregroundColor(.gray)

                                        Text("Select a Photo")
                                            .foregroundColor(.gray)
                                    }
                                }
                        }

                        PhotosPicker(
                            selection: $selectedItem,
                            matching: .images
                        ) {

                            HStack {

                                Image(systemName: "photo.fill.on.rectangle.fill")

                                Text("Choose Image")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {

                        Text("Caption")
                            .foregroundColor(.white)
                            .font(.headline)

                        TextField(
                            "Write something...",
                            text: $caption,
                            axis: .vertical
                        )
                        .foregroundColor(.white)
                        .padding()
                        .frame(minHeight: 120,
                               alignment: .topLeading)
                        .background(
                            Color.white.opacity(0.08)
                        )
                        .cornerRadius(20)
                    }

                    Button {

                        uploadPost()

                    } label: {

                        HStack {

                            if isUploading {

                                ProgressView()
                                    .tint(.white)

                            } else {

                                Image(systemName: "paperplane.fill")
                            }

                            Text(
                                isUploading
                                ? "Uploading..."
                                : "Share Post"
                            )
                            .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(

                            LinearGradient(
                                colors: [
                                    .pink,
                                    .purple,
                                    .blue
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(18)
                    }
                    .disabled(
                        selectedImage == nil || isUploading
                    )

                    Spacer(minLength: 40)
                }
                .padding()
            }
        }
        .navigationTitle("Create Post")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onChange(of: selectedItem) { item in

            Task {

                if let data = try? await item?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {

                    selectedImage = image
                }
            }
        }
    }

    func uploadPost() {

        guard let image = selectedImage else {

            print("No image selected")
            return
        }

        // Compress the image so the Base64 string isn't huge
        guard let imageData =
                image.jpegData(compressionQuality: 0.3)
        else {

            print("Image conversion failed")
            return
        }

        isUploading = true

        // Convert image data directly to a Base64 string
        let base64String =
        imageData.base64EncodedString()

        let currentUserId =
        UserDefaults.standard.string(
            forKey: "currentUserId"
        ) ?? ""

        let currentUsername =
        UserDefaults.standard.string(
            forKey: "currentUsername"
        ) ?? ""

        let postRef =
        Database.database()
            .reference()
            .child("posts")
            .childByAutoId()

        let data: [String: Any] = [

            "userId": currentUserId,
            "username": currentUsername,
            "imageURL": base64String,   // storing Base64 directly, no Storage involved
            "caption": caption,
            "timestamp":
                Date()
                .timeIntervalSince1970
        ]

        postRef.setValue(data) { error, _ in

            isUploading = false

            if let error = error {

                print(
                    "❌ Database Error:",
                    error.localizedDescription
                )

            } else {

                print("✅ Post Uploaded Successfully")

                caption = ""
                selectedImage = nil

                dismiss()
            }
        }
    }
}

#Preview {
    CreatePostPage()
}
