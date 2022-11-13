//
//  MenuItemDetailViewController.swift
//  OrderApp
//
//  Created by Nune Melikyan on 21.10.22.
//

import UIKit

@MainActor
final class MenuItemDetailViewController: UIViewController {
    private let menuItem: MenuItem

    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var priceLabel: UILabel!
    @IBOutlet var detailTextLabel: UILabel!
    @IBOutlet var addToOrderButton: UIButton!

    //  MARK: -- Init
    init?(
        coder: NSCoder,
        menuItem: MenuItem
    ) {
        self.menuItem = menuItem
        super.init(coder: coder)
    }

    required init?(
        coder: NSCoder
    ) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: -- Lifecycle
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        MenuController.shared.updateUserActivity(
            with: .menuItemDetail(menuItem)
        )
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        updateUI()
    }

    private func updateUI() {
        nameLabel.text = menuItem.name
        priceLabel.text = Helper.formatUSDPrice(price: menuItem.price)

        detailTextLabel.text = menuItem.detailText

        Task.init {
            if let image = try? await MenuController.shared
                .fetchImage(from: menuItem.imageURL) {
                imageView.image = image
            }
        }
    }

    // MARK: -- Actions
    @IBAction func orderButtonTapped(_ sender: UIButton) {
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.1,
            options: [],
            animations: {
                self.addToOrderButton.transform =
                    CGAffineTransform(scaleX: 2.0, y: 2.0)
                self.addToOrderButton.transform =
                    CGAffineTransform(scaleX: 1.0, y: 1.0)
            },
            completion: nil
        )

        MenuController.shared.order.menuItems.append(menuItem)
    }
}
