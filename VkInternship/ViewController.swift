//
//  ViewController.swift
//  VkInternship
//
//  Created by Arman  Urstem on 06.09.2024.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    struct DailyWeather {
        let date: String
        let temperature: Double
        let icon: String
    }
    
    let openWeatherAPIKey = "5cdb428ad0660ba0deefb77bd67cddd9"
    
    var dailyWeatherData: [DailyWeather] = []
    
    var cityName: String = ""
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    
    let locationManager = CLLocationManager()
    
    func fetchWeather(forCity city: String) {
        let formattedCity = city.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? city
        let urlString = "https://api.openweathermap.org/data/2.5/weather?q=\(formattedCity)&appid=\(openWeatherAPIKey)&units=metric"
        
        guard let url = URL(string: urlString) else {
            print("Неверный URL.")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                print("Ошибка запроса погоды: \(error)")
                return
            }
            
            guard let data = data else {
                print("Данные не получены.")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let main = json["main"] as? [String: Any],
                   let sys = json["sys"] as? [String: Any],
                   let wind = json["wind"] as? [String: Any],
                   let temp = main["temp"] as? Double,
                   let speed = wind["speed"] as? Double,
                   let pressure = main["pressure"] as? Double,
                   let sunrise = sys["sunrise"] as? Double,
                   let sunset = sys["sunset"] as? Double,
                   let feelsLike = main["feels_like"] as? Double,
                   let tempmax = main["temp_max"] as? Double,
                   let tempmin = main["temp_min"] as? Double,
                   let humidity = main["humidity"] as? Double,
                   let weatherArray = json["weather"] as? [[String: Any]],
                   let weather = weatherArray.first,
                   let icon = weather["icon"] as? String {
                    DispatchQueue.main.async {
                        self.degreesLabel.text = "\(Int(temp))°C"
                        self.feelsLikeLabel.text = "Ощущается как: \(Int(feelsLike))°C"
                        self.airSpeedLabel.text = "\(Int(speed)) м/с"
                        self.pressureLabel.text = "\((pressure*100*760/101325).rounded()) мм рт. ст."
                        self.humidityLabel.text = "\(humidity) %"
                        self.maxMinTempLabel.text = "\(Int(tempmin))°C/\(Int(tempmax))°C"
                        
                        let date = Date(timeIntervalSince1970: sunrise)
                        let dateSunset = Date(timeIntervalSince1970: sunset)
                        let dateFormatter = DateFormatter()
                        dateFormatter.timeZone = TimeZone.current
                        dateFormatter.locale = Locale(identifier: "ru_RU")
                        dateFormatter.dateFormat = "HH:mm"
                        
                        let sunriseTime = dateFormatter.string(from: date)
                        let sunsetTime = dateFormatter.string(from: dateSunset)
                        self.sunriseLabel.text = "\(sunriseTime)"
                        self.sunsetLabel.text = "\(sunsetTime)"
                        
                        if let url = URL(string: "https://openweathermap.org/img/wn/\(icon).png") {
                            DispatchQueue.global().async {
                                if let data = try? Data(contentsOf: url),
                                   let image = UIImage(data: data) {
                                    DispatchQueue.main.async {
                                        self.weatherImageView.image = image
                                    }
                                }
                            }
                        }
                    }
                }
            } catch let jsonError {
                print("Ошибка при разборе JSON: \(jsonError)")
            }
        }
        
        task.resume()
    }
    
    func fetchWeatherForFiveDays(forCity city: String) {
        let formattedCity = city.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? city
        let urlString = "https://api.openweathermap.org/data/2.5/forecast?q=\(formattedCity)&appid=\(openWeatherAPIKey)&units=metric"
        
        guard let url = URL(string: urlString) else {
            print("Неверный URL.")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                print("Ошибка запроса погоды: \(error)")
                return
            }
            
            guard let data = data else {
                print("Данные не получены.")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let list = json["list"] as? [[String: Any]] {
                    self.dailyWeatherData.removeAll()
                    for item in list {
                        if let dtTxt = item["dt_txt"] as? String, dtTxt.contains("12:00:00") {
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                            if let date = dateFormatter.date(from: dtTxt) {
                                dateFormatter.dateFormat = "dd.MM"
                                let dateString = dateFormatter.string(from: date)
                                if let main = item["main"] as? [String: Any],
                                   let temp = main["temp"] as? Double,
                                   let weatherArray = item["weather"] as? [[String: Any]],
                                   let weather = weatherArray.first,
                                   let icon = weather["icon"] as? String {
                                    print(temp)
                                    let weatherData = DailyWeather(date: dateString, temperature: temp, icon: icon)
                                    self.dailyWeatherData.append(weatherData)
                                }
                            }
                        }
                    }
                    DispatchQueue.main.async {
                        self.weatherTableView.reloadData()
                    }
                }
            } catch {
                print("Ошибка при десериализации JSON: \(error)")
            }
        }
        
        task.resume()
    }
    
    private lazy var roundedSquareView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.white
        view.layer.cornerRadius = 40
        view.clipsToBounds = true
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return view
    }()
    
    private lazy var temperatureView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(hex: "#0077FF")
        view.layer.cornerRadius = 40
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var cityLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = .systemFont(ofSize: 25)
        label.textColor = .white
        return label
    }()
    
    private lazy var degreesLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = .systemFont(ofSize: 50)
        label.textColor = .white
        return label
    }()
    
    private lazy var windImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "wind")
        imageView.tintColor = .black
        return imageView
    }()
    
    private lazy var airSpeedLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = .systemFont(ofSize: 15)
        return label
    }()
    
    private lazy var pressureLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = .systemFont(ofSize: 15)
        return label
    }()
    
    private lazy var sunriseImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "sunrise")
        imageView.tintColor = .black
        return imageView
    }()
    
    private lazy var sunriseLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = .systemFont(ofSize: 15)
        return label
    }()
    
    private lazy var sunsetImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "sunset")
        imageView.tintColor = .black
        return imageView
    }()
    
    private lazy var sunsetLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = .systemFont(ofSize: 15)
        return label
    }()
    
    private lazy var feelsLikeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = .systemFont(ofSize: 15)
        label.textColor = .white
        return label
    }()

    private lazy var weatherImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = UIColor(hex: "#0077FF")
        imageView.layer.cornerRadius = 60
        return imageView
    }()
    
    private lazy var dropImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "drop")
        imageView.tintColor = .black
        return imageView
    }()
    
    private lazy var pressureImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "barometer")
        imageView.tintColor = .black
        return imageView
    }()
    
    private lazy var tempImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "thermometer.medium")
        imageView.tintColor = .black
        return imageView
    }()
    
    private lazy var humidityLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = .systemFont(ofSize: 15)
        label.textColor = .black
        return label
    }()
    
    private lazy var maxMinTempLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = .systemFont(ofSize: 15)
        label.textColor = .black
        return label
    }()
    
    private lazy var weatherTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(TableViewCell.self, forCellReuseIdentifier: "WeatherTableViewCell")
        return tableView
    }()
    
    private lazy var searchButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        let image = UIImage(systemName: "magnifyingglass")
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(searchButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var geoButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        let image = UIImage(systemName: "location")
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(geoButtonTapped), for: .touchUpInside)
        return button
    }()
    
    @objc private func searchButtonTapped() {
        let searchViewController = SearchViewController()
        searchViewController.onCitySelected = { [weak self] selectedCity in
            self?.cityName = selectedCity
            self?.updateUIWithSelectedCity()
        }
        present(searchViewController, animated: true, completion: nil)
    }

    @objc private func geoButtonTapped() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func updateUIWithSelectedCity() {
        cityLabel.text = cityName
        fetchWeather(forCity: cityName)
        fetchWeatherForFiveDays(forCity: cityName)
    }
    
    func checkAndSetSelectedCity() {
        if let selectedCity = UserDefaults.standard.string(forKey: "SelectedCity") {
            print("Выбранный город: \(selectedCity)")
            cityName = selectedCity
        } else {
            print("Город не выбран")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkAndSetSelectedCity()
        
        if cityName.isEmpty {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        }
        
        cityLabel.text = cityName
        fetchWeather(forCity: cityName)
        fetchWeatherForFiveDays(forCity: cityName)
        
        weatherTableView.separatorStyle = .none
        let screenHeight = UIScreen.main.bounds.height
        print(screenHeight)
        let smallDeviceHeight: CGFloat = 667.0
        weatherTableView.isScrollEnabled = screenHeight <= smallDeviceHeight
        weatherTableView.allowsSelection = false

        view.backgroundColor = UIColor(hex: "#0077FF")
        
        let guideView = UIView()
        guideView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(guideView)
        view.addSubview(roundedSquareView)
        view.addSubview(cityLabel)
        view.addSubview(geoButton)
        view.addSubview(searchButton)
        roundedSquareView.addSubview(temperatureView)
        roundedSquareView.addSubview(degreesLabel)
        roundedSquareView.addSubview(windImageView)
        roundedSquareView.addSubview(airSpeedLabel)
        roundedSquareView.addSubview(pressureLabel)
        roundedSquareView.addSubview(sunriseImageView)
        roundedSquareView.addSubview(sunriseLabel)
        roundedSquareView.addSubview(sunsetImageView)
        roundedSquareView.addSubview(sunsetLabel)
        roundedSquareView.addSubview(feelsLikeLabel)
        roundedSquareView.addSubview(weatherImageView)
        roundedSquareView.addSubview(dropImageView)
        roundedSquareView.addSubview(humidityLabel)
        roundedSquareView.addSubview(pressureImageView)
        roundedSquareView.addSubview(tempImageView)
        roundedSquareView.addSubview(maxMinTempLabel)
        roundedSquareView.addSubview(weatherTableView)
        
        NSLayoutConstraint.activate([
            guideView.widthAnchor.constraint(equalToConstant: 0),
            guideView.heightAnchor.constraint(equalToConstant: 0),
            guideView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            guideView.centerXAnchor.constraint(equalTo: view.leadingAnchor, constant: 3 * view.bounds.width / 4),
            
            roundedSquareView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            roundedSquareView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            roundedSquareView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            roundedSquareView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            cityLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            cityLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            
            searchButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            searchButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            searchButton.widthAnchor.constraint(equalToConstant: 30),
            searchButton.heightAnchor.constraint(equalToConstant: 30),
            
            geoButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            geoButton.trailingAnchor.constraint(equalTo: searchButton.leadingAnchor, constant: -10),
            geoButton.widthAnchor.constraint(equalToConstant: 30),
            geoButton.heightAnchor.constraint(equalToConstant: 30),
            
            temperatureView.topAnchor.constraint(equalTo: roundedSquareView.topAnchor, constant: 30),
            temperatureView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            temperatureView.heightAnchor.constraint(equalToConstant: 120),
            temperatureView.trailingAnchor.constraint(equalTo: view.centerXAnchor),
            
            degreesLabel.topAnchor.constraint(equalTo: temperatureView.topAnchor, constant: 15),
            degreesLabel.centerXAnchor.constraint(equalTo: temperatureView.centerXAnchor),
            
            feelsLikeLabel.centerXAnchor.constraint(equalTo: temperatureView.centerXAnchor),
            feelsLikeLabel.bottomAnchor.constraint(equalTo: temperatureView.bottomAnchor, constant: -20),
            
            weatherImageView.topAnchor.constraint(equalTo: roundedSquareView.topAnchor, constant: 30),
            weatherImageView.centerXAnchor.constraint(equalTo: guideView.centerXAnchor),
            weatherImageView.heightAnchor.constraint(equalToConstant: 120),
            weatherImageView.widthAnchor.constraint(equalToConstant: 120),
            
            windImageView.topAnchor.constraint(equalTo: temperatureView.bottomAnchor, constant: 30),
            windImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            windImageView.widthAnchor.constraint(equalToConstant: 40),
            windImageView.heightAnchor.constraint(equalToConstant: 40),
            
            sunriseImageView.topAnchor.constraint(equalTo: windImageView.bottomAnchor, constant: 30),
            sunriseImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            sunriseImageView.widthAnchor.constraint(equalToConstant: 40),
            sunriseImageView.heightAnchor.constraint(equalToConstant: 40),
            
            sunsetImageView.topAnchor.constraint(equalTo: sunriseImageView.bottomAnchor, constant: 30),
            sunsetImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            sunsetImageView.widthAnchor.constraint(equalToConstant: 40),
            sunsetImageView.heightAnchor.constraint(equalToConstant: 40),
            
            dropImageView.topAnchor.constraint(equalTo: temperatureView.bottomAnchor, constant: 30),
            dropImageView.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 10),
            dropImageView.widthAnchor.constraint(equalToConstant: 40),
            dropImageView.heightAnchor.constraint(equalToConstant: 40),
            
            pressureImageView.topAnchor.constraint(equalTo: dropImageView.bottomAnchor, constant: 30),
            pressureImageView.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 10),
            pressureImageView.widthAnchor.constraint(equalToConstant: 40),
            pressureImageView.heightAnchor.constraint(equalToConstant: 40),
            
            tempImageView.topAnchor.constraint(equalTo: pressureImageView.bottomAnchor, constant: 30),
            tempImageView.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 10),
            tempImageView.widthAnchor.constraint(equalToConstant: 40),
            tempImageView.heightAnchor.constraint(equalToConstant: 40),
            
            airSpeedLabel.centerYAnchor.constraint(equalTo: windImageView.centerYAnchor),
            airSpeedLabel.leadingAnchor.constraint(equalTo: windImageView.trailingAnchor, constant: 10),
            
            pressureLabel.centerYAnchor.constraint(equalTo: pressureImageView.centerYAnchor),
            pressureLabel.leadingAnchor.constraint(equalTo: pressureImageView.trailingAnchor, constant: 10),
            
            sunriseLabel.centerYAnchor.constraint(equalTo: sunriseImageView.centerYAnchor),
            sunriseLabel.leadingAnchor.constraint(equalTo: sunriseImageView.trailingAnchor, constant: 10),
            
            sunsetLabel.centerYAnchor.constraint(equalTo: sunsetImageView.centerYAnchor),
            sunsetLabel.leadingAnchor.constraint(equalTo: sunsetImageView.trailingAnchor, constant: 10),
            
            maxMinTempLabel.centerYAnchor.constraint(equalTo: tempImageView.centerYAnchor),
            maxMinTempLabel.leadingAnchor.constraint(equalTo: tempImageView.trailingAnchor, constant: 10),
            
            humidityLabel.centerYAnchor.constraint(equalTo: dropImageView.centerYAnchor),
            humidityLabel.leadingAnchor.constraint(equalTo: dropImageView.trailingAnchor, constant: 10),
            
            weatherTableView.topAnchor.constraint(equalTo: tempImageView.bottomAnchor, constant: 10),
            weatherTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            weatherTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            weatherTableView.bottomAnchor.constraint(equalTo: roundedSquareView.bottomAnchor, constant: -10),
        ])
        
        weatherTableView.delegate = self
        weatherTableView.dataSource = self
    }
    
    private func checkLocationAuthorization(_ status: CLAuthorizationStatus) {
        switch status {
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            case .restricted, .denied:
                print("Доступ к геолокации ограничен или отключен.")
            case .authorizedAlways, .authorizedWhenInUse:
                locationManager.startUpdatingLocation()
            @unknown default:
                break
        }
    }
}

extension ViewController {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            locationManager.stopUpdatingLocation()
            let geocoder = CLGeocoder()
            
            self.latitude = location.coordinate.latitude
            self.longitude = location.coordinate.longitude
            
            geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
                if let error = error {
                    print("Ошибка при получении адреса: \(error)")
                    return
                }
                
                if let placemark = placemarks?.first, let city = placemark.locality {
                    print("Город пользователя: \(city)")
                    self?.cityName = city
                    self?.cityLabel.text = city
                    self?.fetchWeather(forCity: city)
                    self?.fetchWeatherForFiveDays(forCity: city)
                    UserDefaults.standard.set(city, forKey: "SelectedCity")
                }
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization(manager.authorizationStatus)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Ошибка при получении геопозиции: \(error)")
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dailyWeatherData.count
    }
    
    func getDayOfWeek(from dateString: String) -> String {
        let currentYear = Calendar.current.component(.year, from: Date())
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        dateFormatter.locale = Locale(identifier: "ru_RU")
        
        let dateStringWithYear = "\(dateString)-\(currentYear)"
        
        guard let date = dateFormatter.date(from: dateStringWithYear) else {
            return ""
        }
        
        dateFormatter.dateFormat = "E"
        let dayOfWeek = dateFormatter.string(from: date).capitalized
        return dayOfWeek
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "WeatherTableViewCell", for: indexPath) as? TableViewCell else {
            return UITableViewCell()
        }
        
        let weather = dailyWeatherData[indexPath.row]
        let dayOfWeek = getDayOfWeek(from: weather.date)
        cell.infoLabel.text = "\(dayOfWeek)    \(weather.date)    \(Int(weather.temperature))°C"
        cell.icon = weather.icon
        cell.selectionStyle = .none
        
        cell.layer.borderWidth = 4.0
        cell.layer.borderColor = UIColor.white.cgColor
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
}

extension UIColor {
    convenience init?(hex: String) {
        let r, g, b: CGFloat
        
        let start = hex.hasPrefix("#") ? hex.index(hex.startIndex, offsetBy: 1) : hex.startIndex
        let hexColor = String(hex[start...])
        
        if hexColor.count == 6 {
            let scanner = Scanner(string: hexColor)
            var hexNumber: UInt64 = 0
            
            if scanner.scanHexInt64(&hexNumber) {
                r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
                g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
                b = CGFloat(hexNumber & 0x0000ff) / 255
                
                self.init(red: r, green: g, blue: b, alpha: 1.0)
                return
            }
        }
        
        return nil
    }
}
