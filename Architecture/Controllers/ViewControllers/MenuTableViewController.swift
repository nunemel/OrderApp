//
//  MenuTableViewController.swift
//  OrderApp
//
//  Created by Nune Melikyan on 20.10.22.
//

import UIKit

final class MenuTableViewController: UITableViewController {

    private let category: String
    private var menuItems = [MenuItem]()
    private var imageLoadTasks: [IndexPath: Task<Void, Never>] = [:]

    // MARK: -- Init
    init?(
        coder: NSCoder,
        category: String
    ) {
        self.category = category
        super.init(coder: coder)
    }

    required init?(
        coder: NSCoder
    ) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: -- Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        title = category.capitalized

        Task.init {
            do {
                let menuItems = try await MenuController.shared
                    .fetchMenuItems(forCategory: category)
                updateUI(with: menuItems)
            }
            catch {
                Helper.displayError(
                    error: error,
                    title:
                        "Failed to Fetch Menu Items for \(self.category)",
                    viewController: self
                )
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        MenuController.shared.updateUserActivity(with: .menu(category: category))
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        imageLoadTasks.forEach { key, value in value.cancel() }
    }

    private func updateUI(with menuItems: [MenuItem]) {
        self.menuItems = menuItems
        tableView.reloadData()
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        return menuItems.count
    }

    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "MenuItem",
            for: indexPath
        )
        configure(cell, forItemAt: indexPath)

        return cell
    }

    @IBSegueAction func showMenuItem(
        _ coder: NSCoder,
        sender: Any?
    ) -> MenuItemDetailViewController? {

        guard let cell = sender as? UITableViewCell,
            let indexPath = tableView.indexPath(for: cell)
        else { return nil }

        let menuItem = menuItems[indexPath.row]

        return MenuItemDetailViewController(
            coder: coder,
            menuItem: menuItem
        )
    }
    
    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        imageLoadTasks[indexPath]?.cancel()
    }
    
    private func configure(_ cell: UITableViewCell, forItemAt indexPath:
       IndexPath) {
        guard let cell = cell as? MenuItemCell else { return }
    
        let menuItem = menuItems[indexPath.row]
       
        cell.itemName = menuItem.name
        cell.price = menuItem.price
        cell.image = nil
    
        imageLoadTasks[indexPath] = Task.init {
            if let image = try? await
                MenuController.shared.fetchImage(from: menuItem.imageURL) {
                if let currentIndexPath = self.tableView.indexPath(for:
                   cell),
                      currentIndexPath == indexPath {
                    cell.image = image
                }
            }
            imageLoadTasks[indexPath] = nil
        }
    }
}
