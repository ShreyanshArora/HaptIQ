import UIKit
import FirebaseFirestore

class ViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let db = Firestore.firestore()
    db.collection("test").addDocument(data: ["message": "Hello Firebase!"]) { err in
      if let err = err {
        print("❌ Error adding document: \(err)")
      } else {
        print("✅ Test document added successfully!")
      }
    }
  }
}
