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
        segmentedControl.selectedSegmentIndex == 0 ? dailyForecast.count : hourlyForecast.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "ForecastDetailCell", for: indexPath) as! ForecastTableViewCell

        let forecast: ForecastItem

        if segmentedControl.selectedSegmentIndex == 0 {
            forecast = dailyForecast[indexPath.row]
            cell.dateLabel.text = formatDay(forecast.dt_txt)
        } else {
            forecast = hourlyForecast[indexPath.row]
            cell.dateLabel.text = formatHour(forecast.dt_txt)
        }

        let desc = forecast.weather.first?.description ?? ""
        let iconCode = forecast.weather.first?.icon ?? ""

        cell.tempLabel.text = SettingsManager.formatTemperature(forecast.main.temp)
        cell.descLabel.text = desc.capitalized
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
                    self.hourlyForecast = Array(decoded.list.prefix(12))
                    self.dailyForecast = stride(from: 0, to: decoded.list.count, by: 8).map {
                        decoded.list[$0]
                    }

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
            points = dailyForecast.map {
                ForecastChartPoint(
                    label: formatShortDay($0.dt_txt),
                    temperature: $0.main.temp
                )
            }
        } else {
            points = hourlyForecast.map {
                ForecastChartPoint(
                    label: formatHour($0.dt_txt),
                    temperature: $0.main.temp
                )
            }
        }

        let chartView = ForecastChartView(points: points)
        let hostingController = UIHostingController(rootView: chartView)

        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear

        chartContainerView.subviews.forEach { $0.removeFromSuperview() }
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
            return formatter.string(from: date).uppercased()
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

        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "ha"
            return formatter.string(from: date)
        }

        return dateString
    }
}
