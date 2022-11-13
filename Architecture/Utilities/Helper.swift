//
//  Helper.swift
//  OrderApp
//
//  Created by Nune Melikyan on 31.10.22.
//

import Foundation
import UIKit

struct Helper {
    static func displayError(
        error: Error,
        title: String,
        viewController: UIViewController
    ) {
        guard let _ = viewController.viewIfLoaded?.window else {
            return
        }

        let alert = UIAlertController(
            title: title,
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        let action = UIAlertAction(title: "Dismiss", style: .default)
        alert.addAction(action)
        viewController.present(alert, animated: true)
    }

    static func formatUSDPrice(price: Double) -> String {
        return price.formatted(.currency(code: "usd"))
    }
}
