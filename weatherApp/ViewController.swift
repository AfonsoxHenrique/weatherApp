import UIKit
import CoreLocation

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate, UICollectionViewDelegate,
                      UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {


@IBOutlet weak var tableView: UITableView!
@IBOutlet weak var searchBar: UISearchBar!
@IBOutlet weak var cityLabel: UILabel!
@IBOutlet weak var temperatureLabel: UILabel!
@IBOutlet weak var weatherIcon: UIImageView!
@IBOutlet weak var hourlyCollectionView: UICollectionView!
    
var hourlyForecast: [ForecastItem] = []
var dailyForecast: [ForecastItem] = []

let locationManager = CLLocationManager()

override func viewDidLoad() {
    super.viewDidLoad()

    tableView.delegate = self
    tableView.dataSource = self

    locationManager.delegate = self
    locationManager.requestWhenInUseAuthorization()
    
    if locationManager.authorizationStatus == .authorizedWhenInUse ||
       locationManager.authorizationStatus == .authorizedAlways {
        locationManager.requestLocation()
    }
    
    tableView.rowHeight = 70
    
    hourlyCollectionView.delegate = self
    hourlyCollectionView.dataSource = self
    
    NotificationCenter.default.addObserver(self, selector: #selector(refreshUnits), name: NSNotification.Name("unitsChanged"), object: nil)
}
    
    @objc func refreshUnits() {
        tableView.reloadData()
        hourlyCollectionView.reloadData()
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        return CGSize(width: 70, height: 100)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                    numberOfItemsInSection section: Int) -> Int {

    return hourlyForecast.count
}
    
func formatHour(_ dateString: String) -> String {

    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

    if let date = formatter.date(from: dateString) {

        formatter.dateFormat = "ha"
        return formatter.string(from: date)
    }

    return ""
}
    
func collectionView(_ collectionView: UICollectionView,
                    cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HourlyCell",
                                                   for: indexPath) as! HourlyCollectionViewCell

    let forecast = hourlyForecast[indexPath.row]

    let temp = Int(forecast.main.temp)
    let iconCode = forecast.weather.first?.icon ?? ""
    let time = formatHour(forecast.dt_txt)

    cell.tempLabel.text = SettingsManager.formatTemperature(forecast.main.temp)
    cell.timeLabel.text = time

    let iconURL = "https://openweathermap.org/img/wn/\(iconCode)@2x.png"

    if let url = URL(string: iconURL) {
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { return }

            DispatchQueue.main.async {
                cell.iconImageView.image = UIImage(data: data)
            }
        }.resume()
    }

    return cell
}

// MARK: - Search Button

@IBAction func searchButtonTapped(_ sender: UIButton) {

    guard let city = searchBar.text, !city.isEmpty else { return }

    searchBar.resignFirstResponder()

    tableView.reloadData()

    fetchWeather(for: city)
}

// MARK: - TableView

func tableView(_ tableView: UITableView,
               numberOfRowsInSection section: Int) -> Int {
    return dailyForecast.count
}

func tableView(_ tableView: UITableView,
               cellForRowAt indexPath: IndexPath) -> UITableViewCell {

    let cell = tableView.dequeueReusableCell(withIdentifier: "ForecastCell", for: indexPath) as! ForecastTableViewCell

    let forecast = dailyForecast[indexPath.row]

    let day = formatDate(forecast.dt_txt)
    let temp = Int(forecast.main.temp)
    let desc = forecast.weather.first?.description ?? ""
    let iconCode = forecast.weather.first?.icon ?? ""

    cell.dateLabel.text = day
    cell.tempLabel.text = SettingsManager.formatTemperature(forecast.main.temp)
    cell.descLabel.text = desc.capitalized
    
    cell.iconImageView.layer.cornerRadius = 6
    cell.iconImageView.clipsToBounds = true
    cell.selectionStyle = .none

    let iconURL = "https://openweathermap.org/img/wn/\(iconCode)@2x.png"

    if let url = URL(string: iconURL) {
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { return }

            DispatchQueue.main.async {
                cell.iconImageView.image = UIImage(data: data)
            }
        }.resume()
    }

    return cell
}

// MARK: - Fetch Weather by City

func fetchWeather(for city: String) {

    let apiKey = "8011da736900b241b6c870400cbf23d3"
    let cityFormatted = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

    let urlString = "https://api.openweathermap.org/data/2.5/weather?q=\(cityFormatted)&appid=\(apiKey)&units=metric"

    guard let url = URL(string: urlString) else { return }

    URLSession.shared.dataTask(with: url) { data, _, error in

        if let error = error {
            print(error)
            return
        }

        guard let data = data else { return }

        do {
            let decodedData = try JSONDecoder().decode(WeatherResponse.self, from: data)

            DispatchQueue.main.async {
                let lat = decodedData.coord.lat
                let lon = decodedData.coord.lon
                self.fetchForecast(lat: lat, lon: lon)
            }

        } catch {
            print("Decoding error:", error)
        }

    }.resume()
}

// MARK: - Weather Icon Loader 

func loadIcon(urlString: String) {
    guard let url = URL(string: urlString) else { return }

    URLSession.shared.dataTask(with: url) { data, _, _ in
        guard let data = data else { return }

        DispatchQueue.main.async {
            self.weatherIcon.image = UIImage(data: data)
        }
    }.resume()
}

// MARK: - Location

func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {

    switch manager.authorizationStatus {

    case .authorizedWhenInUse, .authorizedAlways:
        locationManager.requestLocation()

    case .denied:
        print("Location access denied")

    default:
        break
    }
}

func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

    guard let location = locations.first else { return }

    let lat = location.coordinate.latitude
    let lon = location.coordinate.longitude

    fetchWeatherByCoordinates(lat: lat, lon: lon)
    fetchForecast(lat: lat, lon: lon)
}

func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    print("Location error:", error)
}

// MARK: - fetchForecast

func fetchForecast(lat: Double, lon: Double) {

    let apiKey = "8011da736900b241b6c870400cbf23d3"

    let urlString =
    "https://api.openweathermap.org/data/2.5/forecast?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=metric"

    guard let url = URL(string: urlString) else { return }

    URLSession.shared.dataTask(with: url) { data, _, _ in

        guard let data = data else { return }

        do {
            let decoded = try JSONDecoder().decode(ForecastResponse.self, from: data)
            
            DispatchQueue.main.async {
                self.hourlyForecast = decoded.list
                self.dailyForecast = stride(from: 0, to: decoded.list.count, by: 8).map { decoded.list[$0] }
                self.tableView.reloadData()
                self.hourlyCollectionView.reloadData()
            }

        } catch {
            print(error)
        }

    }.resume()
}

// MARK: - Weather by Coordinates

func fetchWeatherByCoordinates(lat: Double, lon: Double) {

    let apiKey = "8011da736900b241b6c870400cbf23d3"

    let urlString =
    "https://api.openweathermap.org/data/2.5/weather?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=metric"

    guard let url = URL(string: urlString) else { return }

    URLSession.shared.dataTask(with: url) { data, _, _ in

        guard let data = data else { return }

        do {
            let decodedData = try JSONDecoder().decode(WeatherResponse.self, from: data)

            DispatchQueue.main.async {
                self.cityLabel.text = decodedData.name
                self.temperatureLabel.text = SettingsManager.formatTemperature(decodedData.main.temp)

                let iconCode = decodedData.weather.first?.icon ?? ""
                let iconURL = "https://openweathermap.org/img/wn/\(iconCode)@2x.png"
                self.loadIcon(urlString: iconURL)
            }

        } catch {
            print("Decoding error:", error)
        }

    }.resume()
}

// MARK: - Date Format

func formatDate(_ dateString: String) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    
    if let date = formatter.date(from: dateString) {
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    return dateString
}

}
