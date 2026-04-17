import UIKit
import FirebaseAuth

class SignUpViewController: UIViewController {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var confirmPasswordField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        passwordField.isSecureTextEntry = true
        confirmPasswordField.isSecureTextEntry = true
    }

    @IBAction func signupTapped(_ sender: UIButton) {
        guard let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              let password = passwordField.text,
              let confirmPassword = confirmPasswordField.text,
              !email.isEmpty,
              !password.isEmpty,
              !confirmPassword.isEmpty else {
            showError(message: "Please fill in all fields.")
            return
        }

        guard password == confirmPassword else {
            showError(message: "Passwords do not match.")
            return
        }

        guard password.count >= 6 else {
            showError(message: "Password must be at least 6 characters long.")
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }

            if let error = error {
                self.showError(message: error.localizedDescription)
                return
            }

            print("User created:", result?.user.email ?? "No email")

            let alert = UIAlertController(
                title: "Success",
                message: "Account created successfully. You can now log in.",
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                self.dismiss(animated: true)
            })

            self.present(alert, animated: true)
        }
    }

    func showError(message: String) {
        let alert = UIAlertController(title: "Register Error",
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
