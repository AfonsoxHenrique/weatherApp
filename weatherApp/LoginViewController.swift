
import UIKit

class LoginViewController: UIViewController {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    @IBAction func loginTapped(_ sender: UIButton) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let tabBar = storyboard.instantiateViewController(withIdentifier: "MainTabBar")
        tabBar.modalPresentationStyle = .fullScreen
        present(tabBar, animated: true)
        
        if emailField.text == "test@test.com" &&
           passwordField.text == "123456" {
            
            performSegue(withIdentifier: "goToWeather", sender: self)
            
        } else {
            showError()
        }
    }
    
    func showError() {
        let alert = UIAlertController(title: "Error",
                                      message: "Invalid login",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
