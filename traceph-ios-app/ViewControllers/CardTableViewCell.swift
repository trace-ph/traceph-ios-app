//
//  CardTableViewCell.swift
//  traceph-ios-app
//
//  Created by Angelique Rafael on 8/17/21.
//  Copyright © 2021 traceph. All rights reserved.
//

import UIKit

class CardTableViewCell: UITableViewCell {
    
    @IBOutlet weak var cardLabel: UILabel?
    @IBOutlet weak var cardDesc: UITextView?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialization code
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 8
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5))
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
