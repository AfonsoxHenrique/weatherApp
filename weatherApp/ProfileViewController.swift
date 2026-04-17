import UIKit
import FirebaseAuth
import FirebaseFirestore

class ProfileViewController: UIViewController {

    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var statusLabel: UILabel!

    let db = Firestore.firestore()

    override func viewDidLoad() {
        super.viewDidLoad()
        loadProfile()
    }

    func loadProfile() {
        guard let user = Auth.auth().currentUser else {
            emailLabel.text = "Not logged in"
            nameField.text = ""
            statusLabel.text = "Please log in or sign up."
            return
        }

        emailLabel.text = user.email
        statusLabel.text = ""

        db.collection("users").document(user.uid).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }

            if let data = snapshot?.data() {
                self.nameField.text = data["name"] as? String ?? ""
            } else {
                self.nameField.text = ""
            }

            if let error = error {
                self.statusLabel.text = error.localizedDescription
            }
        }
    }

    @IBAction func saveTapped(_ sender: UIButton) {
        guard let user = Auth.auth().currentUser else {
            showAlert(title: "Error", message: "No user is logged in.")
            return
        }

        let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let data: [String: Any] = [
            "name": name,
            "email": user.email ?? ""
        ]

        db.collection("users").document(user.uid).setData(data, merge: true) { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                self.showAlert(title: "Save Error", message: error.localizedDescription)
            } else {
                self.showAlert(title: "Saved", message: "Profile updated.")
            }
        }
    }

    @IBAction func logoutTapped(_ sender: UIButton) {
        do {
            try Auth.auth().signOut()

            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let nav = storyboard.instantiateViewController(withIdentifier: "LoginNavigationController")

            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else { return }

            window.rootViewController = nav
            window.makeKeyAndVisible()

        } catch {
            showAlert(title: "Logout Error", message: error.localizedDescription)
        }
    }

    @IBAction func deleteAccountTapped(_ sender: UIButton) {
        let alert = UIAlertController(
            title: "Delete Account",
            message: "This will permanently delete your account.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.performDeleteAccount()
        })

        present(alert, animated: true)
    }

    func performDeleteAccount() {
        guard let user = Auth.auth().currentUser else {
            showAlert(title: "Error", message: "No user is logged in.")
            return
        }

        let uid = user.uid

        db.collection("users").document(uid).delete { [weak self] _ in
            user.delete { error in
                guard let self = self else { return }

                if let error = error {
                    self.showAlert(
                        title: "Delete Error",
                        message: error.localizedDescription + "\nYou may need to log in again before deleting."
                    )
                } else {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
                    loginVC.modalPresentationStyle = .fullScreen
                    self.present(loginVC, animated: true)
                }
            }
        }
    }

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
