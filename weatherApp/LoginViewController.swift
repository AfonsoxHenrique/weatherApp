import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    @IBAction func goToSignUp(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let signVC = storyboard.instantiateViewController(withIdentifier: "SignUpViewController")
        signVC.modalPresentationStyle = .fullScreen
        navigationController?.pushViewController(signVC, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        passwordField.isSecureTextEntry = true
    }

    @IBAction func loginTapped(_ sender: UIButton) {
        guard let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              let password = passwordField.text,
              !email.isEmpty,
              !password.isEmpty else {
            showError(message: "Please enter your email and password.")
            return
        }

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }

            if let error = error {
                self.showError(message: error.localizedDescription)
                return
            }

            print("User logged in:", result?.user.email ?? "No email")

            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let tabBar = storyboard.instantiateViewController(withIdentifier: "MainTabBar")
            tabBar.modalPresentationStyle = .fullScreen
            self.present(tabBar, animated: true)
        }
    }

    func showError(message: String) {
        let alert = UIAlertController(title: "Error",
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
