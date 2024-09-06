//
//  SearchViewController.swift
//  VkInternship
//
//  Created by Arman  Urstem on 06.09.2024.
//

import Foundation
import MapKit

class SearchViewController: UIViewController, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate {
    
    var onCitySelected: ((String) -> Void)?
    
    private let searchBar = UISearchBar()
    private let tableView = UITableView()
    
    private var searchResults: [String] = []
    
    private let geocoder = CLGeocoder()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    
    private func setupUI() {
        view.backgroundColor = .white
        
        searchBar.delegate = self
        searchBar.placeholder = "Введите название города"
        view.addSubview(searchBar)
        
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        
        
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            tableView.reloadData()
            return
        }
        
        performCitySearch(with: searchText)
    }
    
    private func performCitySearch(with query: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        
        let search = MKLocalSearch(request: request)
        search.start { [weak self] (response, error) in
            guard let self = self else { return }
            
            self.searchResults.removeAll()
            
            if let response = response {
                for item in response.mapItems {
                    if let city = item.placemark.locality {
                        if !self.searchResults.contains(city) {
                            self.searchResults.append(city)
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ?? UITableViewCell(style: .default, reuseIdentifier: "cell")
        cell.textLabel?.text = searchResults[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedCity = searchResults[indexPath.row]
        UserDefaults.standard.set(selectedCity, forKey: "SelectedCity")
        onCitySelected?(selectedCity)
        dismiss(animated: true, completion: nil)
    }
}

extension Sequence where Element: Hashable {
    func unique() -> [Element] {
        var seen: Set<Element> = []
        return filter { seen.insert($0).inserted }
    }
}
