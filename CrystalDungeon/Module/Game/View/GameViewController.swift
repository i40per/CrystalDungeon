//
//  GameViewController.swift
//  CrystalDungeon
//
//  Created by Евгений Лукин on 18.03.2026.
//

import UIKit

protocol GameViewProtocol: AnyObject {
    func display(output: String)
}

final class GameViewController: UIViewController, GameViewProtocol {

    var presenter: GamePresenterProtocol!

    private let outputLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 24, weight: .medium)
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        presenter.viewDidLoad()
    }

    func display(output: String) {
        outputLabel.text = output
    }

    private func setupUI() {
        view.backgroundColor = .brown
        view.addSubview(outputLabel)

        NSLayoutConstraint.activate([
            outputLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            outputLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            outputLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            outputLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
        ])
    }
}
