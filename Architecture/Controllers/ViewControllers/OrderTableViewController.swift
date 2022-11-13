//
//  OrderTableViewController.swift
//  OrderApp
//
//  Created by Nune Melikyan on 20.10.22.
//

import UIKit

final class OrderTableViewController: UITableViewController {

    private var minutesToPrepareOrder = 0
    private var imageLoadTasks: [IndexPath: Task<Void, Never>] = [:]

    // MARK: -- Lifecycle
    override func viewDidDisappear(_ animated: Bool) {
        imageLoadTasks.forEach { key, value in value.cancel() }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
       
        MenuController.shared.updateUserActivity(with: .order)

        if MenuController.shared.order.menuItems.count == 0 {
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        }
        else {
            self.navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    
        navigationItem.leftBarButtonItem = editButtonItem
        NotificationCenter.default.addObserver(
            tableView!,
            selector: #selector(UITableView.reloadData),
            name: MenuController.orderUpdatedNotification,
            object: nil
        )
    }

    // MARK: -- Actions
    @IBSegueAction func confirmOrder(
        _ coder: NSCoder
    ) -> OrderConfirmationViewController? {
        return OrderConfirmationViewController(
            coder: coder,
            minutesToPrepare: minutesToPrepareOrder
        )
    }
    
    @IBAction func unwindToOrderList(segue: UIStoryboardSegue) {
        if segue.identifier == "dismissConfirmation" {
            MenuController.shared.order.menuItems.removeAll()
        }
    }

    @IBAction func submitTapped(_ sender: Any) {
        let orderTotal = MenuController.shared.order.menuItems.reduce(
            0.0
        ) { (result, menuItem) -> Double in
            return result + menuItem.price
        }

        let formattedTotal = Helper.formatUSDPrice(price: orderTotal)

        let alert = UIAlertController(
            title: "Confirm Order",
            message:
                "You are about to submit your order with a total of \(formattedTotal)",
            preferredStyle: .actionSheet
        )

        let actionSubmit = UIAlertAction(
            title: "Submit",
            style: .default,
            handler: { _ in
                self.uploadOrder()
            }
        )

        let actionCancel = UIAlertAction(
            title: "Cancel",
            style: .cancel
        )

        alert.addAction(actionSubmit)
        alert.addAction(actionCancel)

        present(alert, animated: true)
    }

    private func uploadOrder() {
        let menuIds = MenuController.shared.order.menuItems.map {
            $0.id
        }
        Task.init {
            do {
                let minutesToPrepare = try await MenuController.shared
                    .submitOrder(forMenuIDs: menuIds)
                minutesToPrepareOrder = minutesToPrepare
                performSegue(
                    withIdentifier: "confirmOrder",
                    sender: nil
                )
            }
            catch {
                Helper.displayError(
                    error: error,
                    title: "Order Submission Failed",
                    viewController: self
                )
            }
        }
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        return MenuController.shared.order.menuItems.count
    }

    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "Order",
            for: indexPath
        )

        configure(cell, forItemAt: indexPath)

        return cell
    }

    private func configure(
        _ cell: UITableViewCell,
        forItemAt indexPath:
            IndexPath
    ) {
        guard let cell = cell as? MenuItemCell else { return }
    
        let menuItem = MenuController.shared.order.menuItems[
            indexPath.row
        ]

        cell.itemName = menuItem.name
        cell.price = menuItem.price
        cell.image = nil

        imageLoadTasks[indexPath] = Task.init {
            if let image = try? await MenuController.shared
                .fetchImage(from: menuItem.imageURL) {
                if let currentIndexPath = self.tableView.indexPath(
                    for:
                        cell
                ),
                    currentIndexPath == indexPath {
                    cell.image = image
                }
            }
            imageLoadTasks[indexPath] = nil
        }
    }

    override func tableView(
        _ tableView: UITableView,
        canEditRowAt indexPath: IndexPath
    ) -> Bool {
        return true
    }

    // Override to support editing the table view.
    override func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        if editingStyle == .delete {
            MenuController.shared.order.menuItems.remove(
                at: indexPath.row
            )
        }
    }
    
    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        imageLoadTasks[indexPath]?.cancel()
    }
}

extension UIImage {
    func resizeImageWithHeight(
        newW: CGFloat,
        newH: CGFloat
    ) -> UIImage? {
        UIGraphicsBeginImageContext(CGSize(width: newW, height: newH))
        self.draw(in: CGRect(x: 0, y: 0, width: newW, height: newH))

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
}
