import UIKit
import FirebaseFirestore

class AddCityViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    let db = Firestore.firestore()
    var cities: [City] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 70
        
        loadCities()
        
        // ✅ Listen for unit changes
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refreshUnits),
                                               name: NSNotification.Name("unitsChanged"),
                                               object: nil)
    }
    
    // ✅ Refresh temperatures when unit changes
    @objc func refreshUnits() {
        tableView.reloadData()
    }
    
    // MARK: - Add city button
    @IBAction func addCityTapped(_ sender: UIButton) {
        showAddCityPopup()
    }
    
    // MARK: - TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cities.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "CityCell", for: indexPath) as! CityTableViewCell
        
        let city = cities[indexPath.row]
        cell.cityNameLabel.text = city.name
        cell.weatherLabel.text = "Loading..."
        
        // Delete button
        cell.deleteButton.tag = indexPath.row
        cell.deleteButton.addTarget(self, action: #selector(deleteCityButtonTapped(_:)), for: .touchUpInside)
        
        fetchWeather(for: city, cell: cell)
        
        return cell
    }
    
    // MARK: - Fetch weather
    func fetchWeather(for city: City, cell: CityTableViewCell) {
        let apiKey = "8011da736900b241b6c870400cbf23d3"
        let cityEncoded = city.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://api.openweathermap.org/data/2.5/weather?q=\(cityEncoded)&appid=\(apiKey)&units=metric"
        
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print(error)
                return
            }
            
            guard let data = data else { return }
            
            do {
                let decoded = try JSONDecoder().decode(WeatherResponse.self, from: data)
                let desc = decoded.weather.first?.description ?? ""
                let iconCode = decoded.weather.first?.icon ?? ""
                let iconURL = "https://openweathermap.org/img/wn/\(iconCode)@2x.png"
                
                DispatchQueue.main.async {
                    
                    // ✅ Use global temperature setting
                    cell.weatherLabel.text = "\(SettingsManager.formatTemperature(decoded.main.temp)) - \(desc.capitalized)"
                    
                    if let url = URL(string: iconURL) {
                        URLSession.shared.dataTask(with: url) { iconData, _, _ in
                            guard let iconData = iconData else { return }
                            DispatchQueue.main.async {
                                cell.weatherIconImageView.image = UIImage(data: iconData)
                            }
                        }.resume()
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    cell.weatherLabel.text = "Error"
                    cell.weatherIconImageView.image = nil
                }
            }
        }.resume()
    }
    
    // MARK: - Save city to Firestore
    func saveCity(name: String, lat: Double, lon: Double) {
        let cityData: [String: Any] = [
            "name": name,
            "lat": lat,
            "lon": lon
        ]
        
        db.collection("cities").addDocument(data: cityData) { error in
            if let error = error {
                print("Error saving city:", error)
            } else {
                print("City saved!")
                self.loadCities()
            }
        }
    }
    
    // MARK: - Load cities from Firestore
    func loadCities() {
        db.collection("cities").getDocuments { snapshot, error in
            if let error = error {
                print("Error loading cities:", error)
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            self.cities = documents.map { doc in
                let data = doc.data()
                let name = data["name"] as? String ?? ""
                let lat = data["lat"] as? Double ?? 0
                let lon = data["lon"] as? Double ?? 0
                return City(id: doc.documentID, name: name, lat: lat, lon: lon)
            }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: - Delete city
    @objc func deleteCityButtonTapped(_ sender: UIButton) {
        let city = cities[sender.tag]
        
        db.collection("cities").document(city.id).delete { error in
            if let error = error {
                print("Error deleting city:", error)
            } else {
                print("City deleted:", city.name)
                self.loadCities()
            }
        }
    }
    
    // MARK: - Show popup to add city
    func showAddCityPopup() {
        let alert = UIAlertController(title: "Add City",
                                      message: "Enter the name of the city",
                                      preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "City name"
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let addAction = UIAlertAction(title: "Add", style: .default) { _ in
            if let cityName = alert.textFields?.first?.text, !cityName.isEmpty {
                self.fetchCoordinatesAndSave(cityName)
            }
        }
        
        alert.addAction(cancelAction)
        alert.addAction(addAction)
        present(alert, animated: true)
    }
    
    // MARK: - Fetch coordinates via API and save
    func fetchCoordinatesAndSave(_ city: String) {
        let apiKey = "8011da736900b241b6c870400cbf23d3"
        let cityEncoded = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://api.openweathermap.org/data/2.5/weather?q=\(cityEncoded)&appid=\(apiKey)&units=metric"
        
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print(error)
                return
            }
            
            guard let data = data else { return }
            
            do {
                let decoded = try JSONDecoder().decode(WeatherResponse.self, from: data)
                let lat = decoded.coord.lat
                let lon = decoded.coord.lon
                let name = decoded.name
                
                DispatchQueue.main.async {
                    self.saveCity(name: name, lat: lat, lon: lon)
                }
                
            } catch {
                print("City not found")
            }
        }.resume()
    }
}
