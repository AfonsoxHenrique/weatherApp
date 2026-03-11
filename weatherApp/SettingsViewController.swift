import UIKit

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    let settingsOptions = [
        "Units",
        "Notifications",
        "Appearance",
        "About"
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        applyAppearance()
    }

    // MARK: - Appearance
    func applyAppearance() {
        guard let window = UIApplication.shared.windows.first else { return }
        
        switch SettingsManager.appearance {
        case 1:
            window.overrideUserInterfaceStyle = .light
        case 2:
            window.overrideUserInterfaceStyle = .dark
        default:
            window.overrideUserInterfaceStyle = .unspecified
        }
    }

    // MARK: - TableView
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingsOptions.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "cell")
        cell.textLabel?.text = settingsOptions[indexPath.row]
        cell.selectionStyle = .none
        
        // UNITS SEGMENT
        if indexPath.row == 0 {
            let segment = UISegmentedControl(items: ["°C", "°F"])
            segment.selectedSegmentIndex = SettingsManager.isCelsius ? 0 : 1
            segment.addTarget(self, action: #selector(tempChanged(_:)), for: .valueChanged)
            cell.accessoryView = segment
        }
        
        // APPEARANCE SEGMENT
        else if indexPath.row == 2 {
            let segment = UISegmentedControl(items: ["System", "Light", "Dark"])
            segment.selectedSegmentIndex = SettingsManager.appearance
            segment.addTarget(self, action: #selector(appearanceChanged(_:)), for: .valueChanged)
            cell.accessoryView = segment
        }
        
        // NORMAL CELLS
        else {
            cell.accessoryType = .disclosureIndicator
        }
        
        return cell
    }

    // MARK: - Celsius / Fahrenheit
    
    @objc func tempChanged(_ sender: UISegmentedControl) {
        SettingsManager.isCelsius = sender.selectedSegmentIndex == 0
        NotificationCenter.default.post(name: NSNotification.Name("unitsChanged"), object: nil)
    }
    
    // MARK: - Appearance
    
    @objc func appearanceChanged(_ sender: UISegmentedControl) {
        SettingsManager.appearance = sender.selectedSegmentIndex
        applyAppearance()
    }
    
}
