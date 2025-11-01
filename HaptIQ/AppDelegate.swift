import UIKit
import FirebaseCore
import FirebaseFirestore

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        print("✅ Firebase configured successfully")

        // Test connection
        let db = Firestore.firestore()
        let testData: [String: Any] = [
            "timestamp": Date().timeIntervalSince1970,
            "message": "Connected to Firestore 🚀"
        ]
        db.collection("connectionTest").addDocument(data: testData) { error in
            if let error = error {
                print("❌ Firestore write failed: \(error.localizedDescription)")
            } else {
                print("✅ Firestore test data written successfully!")
            }
        }

        return true
    }
}
