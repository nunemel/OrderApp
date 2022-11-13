//
//  CategoryTableViewController.swift
//  OrderApp
//
//  Created by Nune Melikyan on 20.10.22.
//

import UIKit

@MainActor
final class CategoryTableViewController: UITableViewController {

    private var categories = [String]()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        MenuController.shared.updateUserActivity(with: .categories)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        Task.init {
            do {
                let categories =
                try await MenuController.shared.fetchCategories()
                updateUI(with: categories)
            }
            catch {
                Helper.displayError(error: error, title: "Failed to Fetch Categories", viewController: self)
            }
        }
    }

    private func updateUI(with categories: [String]) {
        self.categories = categories
        self.tableView.reloadData()
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        return categories.count
    }

    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "Category",
            for: indexPath
        )
        configureCell(cell, forCategoryAt: indexPath)

        return cell
    }

    private func configureCell(
        _ cell: UITableViewCell,
        forCategoryAt indexPath: IndexPath
    ) {
        let category = categories[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = category.capitalized
        cell.contentConfiguration = content
    }

    @IBSegueAction func showMenu(
        _ coder: NSCoder,
        sender: Any?
    ) -> MenuTableViewController? {
        guard
            let cell = sender as? UITableViewCell,
            let indexPath = tableView.indexPath(for: cell)
        else { return nil }
        let category = categories[indexPath.row]

        return MenuTableViewController(
            coder: coder,
            category: category
        )
    }
}
