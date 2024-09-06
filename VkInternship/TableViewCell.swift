//
//  TableViewCell.swift
//  VkInternship
//
//  Created by Arman  Urstem on 06.09.2024.
//

import UIKit

class TableViewCell: UITableViewCell {
    
    var icon: String? {
        didSet {
            updateWeatherIcon()
        }
    }
    
    let weatherIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let infoLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.layer.masksToBounds = true
        
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        layer.cornerRadius = 16
        backgroundColor = UIColor(hex: "#0077FF")
        
        contentView.addSubview(weatherIconImageView)
        contentView.addSubview(infoLabel)
        
        NSLayoutConstraint.activate([
            weatherIconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            weatherIconImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            weatherIconImageView.widthAnchor.constraint(equalToConstant: 50),
            weatherIconImageView.heightAnchor.constraint(equalToConstant: 50),
    

        
            infoLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            infoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            infoLabel.trailingAnchor.constraint(lessThanOrEqualTo: weatherIconImageView.leadingAnchor, constant: -10)
        ])
    }
    
    private func updateWeatherIcon() {
        if let icon = icon, let url = URL(string: "https://openweathermap.org/img/wn/\(icon).png") {
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: url),
                   let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.weatherIconImageView.image = image
                    }
                }
            }
        }
    }
}
