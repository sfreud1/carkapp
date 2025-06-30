import SwiftUI
import AuthenticationServices
import FirebaseAuth
import FirebaseCore
import GoogleSignIn

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @State private var userName: String = ""
    @State private var profileImageURL: URL? = nil

    var body: some View {
        if isLoggedIn {
            WheelSpinView(userName: userName, profileImageURL: profileImageURL)
        } else {
            VStack(spacing: 24) {
                Spacer()
                Text("Hoş Geldin!")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)

                // Apple ile giriş
                SignInWithAppleButton(.signIn, onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                }, onCompletion: { result in
                    // Giriş sonucu burada işlenir
                })
                .frame(height: 45)
                .signInWithAppleButtonStyle(.whiteOutline)

                // Google ile giriş
                Button(action: {
                    guard let clientID = FirebaseApp.app()?.options.clientID else { return }

                    let config = GIDConfiguration(clientID: clientID)
                    GIDSignIn.sharedInstance.configuration = config

                    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                          let rootViewController = windowScene.windows.first?.rootViewController else {
                        print("Google Sign-In error: No root view controller.")
                        return
                    }

                    GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
                        if let error = error {
                            print("Google Sign-In failed: \(error.localizedDescription)")
                            return
                        }

                        guard let user = result?.user,
                              let idToken = user.idToken?.tokenString else {
                            print("Google Sign-In: Missing tokens.")
                            return
                        }
                        let accessToken = user.accessToken.tokenString

                        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

                        Auth.auth().signIn(with: credential) { authResult, error in
                            if let error = error {
                                print("Firebase Sign-In failed: \(error.localizedDescription)")
                            } else {
                                self.userName = user.profile?.name ?? "Bilinmeyen"
                                self.profileImageURL = user.profile?.imageURL(withDimension: 200)
                                print("Kullanıcı başarıyla giriş yaptı: \(authResult?.user.uid ?? "No UID")")
                                isLoggedIn = true
                            }
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "globe")
                        Text("Google ile Giriş Yap")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(8)
                }


                Spacer()
            }
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, Color.gray]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
        }
    }
}

#Preview {
    LoginView(isLoggedIn: .constant(false))
}
