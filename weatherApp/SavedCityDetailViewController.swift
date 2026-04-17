import UIKit
import SwiftUI

class SavedCityDetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var chartContainerView: UIView!

    var selectedCity: City?

    var hourlyForecast: [ForecastItem] = []
    var dailyForecast: [ForecastItem] = []

    private var chartHostingController: UIHostingController<ForecastChartView>?

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 80

        guard let city = selectedCity else { return }

        cityLabel.text = city.name
        fetchForecast(lat: city.lat, lon: city.lon)
    }

    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        tableView.reloadData()
        updateChart()
    }

    // MARK: - TableView

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if segmentedControl.selectedSegmentIndex == 0 {
            return hourlyForecast.count
        } else {
            return dailyForecast.count
        }
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "ForecastDetailCell", for: indexPath) as! ForecastTableViewCell

        let forecast: ForecastItem

        if segmentedControl.selectedSegmentIndex == 0 {
            guard indexPath.row < hourlyForecast.count else { return cell }
            forecast = hourlyForecast[indexPath.row]
            cell.dateLabel.text = formatHour(forecast.dt_txt)
        } else {
            guard indexPath.row < dailyForecast.count else { return cell }
            forecast = dailyForecast[indexPath.row]
            cell.dateLabel.text = formatDay(forecast.dt_txt)
        }

        let desc = forecast.weather.first?.description ?? ""
        let iconCode = forecast.weather.first?.icon ?? ""

        cell.tempLabel.text = SettingsManager.formatTemperature(forecast.main.temp)
        cell.descLabel.text = desc.capitalized
        cell.selectionStyle = .none
        cell.iconImageView.image = nil

        let iconURL = "https://openweathermap.org/img/wn/\(iconCode)@2x.png"

        if let url = URL(string: iconURL) {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                guard let data = data else { return }
                DispatchQueue.main.async {
                    if let updatedCell = tableView.cellForRow(at: indexPath) as? ForecastTableViewCell {
                        updatedCell.iconImageView.image = UIImage(data: data)
                    }
                }
            }.resume()
        }

        return cell
    }

// MARK: - Forecast

func fetchForecast(lat: Double, lon: Double) {
    let apiKey = "8011da736900b241b6c870400cbf23d3"
    let urlString = "https://api.openweathermap.org/data/2.5/forecast?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=metric"

    guard let url = URL(string: urlString) else { return }

    URLSession.shared.dataTask(with: url) { data, _, error in
        if let error = error {
            print("Forecast error:", error)
            return
        }

        guard let data = data else { return }

    do {
        let decoded = try JSONDecoder().decode(ForecastResponse.self, from: data)

        DispatchQueue.main.async {
            let allForecasts = decoded.list

            self.hourlyForecast = Array(allForecasts.prefix(8))

            var groupedDaily: [ForecastItem] = []
            var usedDays: Set<String> = []

            for item in allForecasts {
                let dayKey = String(item.dt_txt.prefix(10))
                if !usedDays.contains(dayKey) {
                    groupedDaily.append(item)
                    usedDays.insert(dayKey)
                }
            }

            self.dailyForecast = groupedDaily

            print("Hourly times:")
            self.hourlyForecast.forEach { print($0.dt_txt, $0.main.temp) }

            self.tableView.reloadData()
            self.updateChart()
        }
    } catch {
        print("Forecast decoding error:", error)
    }
    }.resume()
}

    // MARK: - Chart

func updateChart() {
    let points: [ForecastChartPoint]

    if segmentedControl.selectedSegmentIndex == 0 {
        points = hourlyForecast.map {
            ForecastChartPoint(
                label: formatHour($0.dt_txt),
                temperature: $0.main.temp
            )
        }
    } else {
        points = dailyForecast.map {
            ForecastChartPoint(
                label: formatShortDay($0.dt_txt),
                temperature: $0.main.temp
            )
        }
    }

    chartHostingController?.willMove(toParent: nil)
    chartHostingController?.view.removeFromSuperview()
    chartHostingController?.removeFromParent()

    let hostingController = UIHostingController(rootView: ForecastChartView(points: points))
    chartHostingController = hostingController

    addChild(hostingController)
    hostingController.view.translatesAutoresizingMaskIntoConstraints = false
    hostingController.view.backgroundColor = .clear

    chartContainerView.addSubview(hostingController.view)

    NSLayoutConstraint.activate([
        hostingController.view.topAnchor.constraint(equalTo: chartContainerView.topAnchor),
        hostingController.view.bottomAnchor.constraint(equalTo: chartContainerView.bottomAnchor),
        hostingController.view.leadingAnchor.constraint(equalTo: chartContainerView.leadingAnchor),
        hostingController.view.trailingAnchor.constraint(equalTo: chartContainerView.trailingAnchor)
    ])

    hostingController.didMove(toParent: self)
}

// MARK: - Formatters

func formatDay(_ dateString: String) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

    if let date = formatter.date(from: dateString) {
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    return dateString
}

func formatShortDay(_ dateString: String) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

    if let date = formatter.date(from: dateString) {
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    return dateString
}

func formatHour(_ dateString: String) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    formatter.locale = Locale(identifier: "en_US_POSIX")

    if let date = formatter.date(from: dateString) {
        formatter.dateFormat = "h a"
        return formatter.string(from: date)
    }

    return dateString
}
}
