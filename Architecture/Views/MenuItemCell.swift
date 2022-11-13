//
//  MenuItemCell.swift
//  OrderApp
//
//  Created by Nune Melikyan on 01.11.22.
//

import UIKit

class MenuItemCell: UITableViewCell {

    var itemName: String? = nil {
        didSet {
            if oldValue != itemName {
                setNeedsUpdateConfiguration()
            }
        }
    }
    var price: Double? = nil {
        didSet {
            if oldValue != price {
                setNeedsUpdateConfiguration()
            }
        }
    }
    var image: UIImage? = nil {
        didSet {
            if oldValue != image {
                setNeedsUpdateConfiguration()
            }
        }
    }
    
    override func updateConfiguration(using state:
       UICellConfigurationState) {
        
        if itemName == nil {
            return
        }
        
        var content = defaultContentConfiguration().updated(for: state)
        content.text = itemName
        content.secondaryText = Helper.formatUSDPrice(price: price ?? 0.00)
        content.prefersSideBySideTextAndSecondaryText = true
      
        if var image = image {
            image = image.resizeImageWithHeight(newW: CGFloat(55), newH: CGFloat(55)) ?? image
            content.image = image
        } else {
            content.image = UIImage(systemName: "photo.fill.on.rectangle.fill")
        }
        self.contentConfiguration = content
    }
}
