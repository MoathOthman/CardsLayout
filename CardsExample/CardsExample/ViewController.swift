//
//  ViewController.swift
//  CardsExample
//
//  Created by Filipp Fediakov on 03.11.17.
//  Copyright © 2017 filletofish. All rights reserved.
//a
import UIKit

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet var collectionView: UICollectionView!
    let flow = CardsCollectionViewLayout()
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.collectionViewLayout = flow
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
    }
    
    var colors: [UIColor]  = [
        UIColor(red: 237, green: 37, blue: 78),
        UIColor(red: 249, green: 120, blue: 92),
        UIColor(red: 294, green: 204, blue: 189),
        UIColor(red: 249, green: 220, blue: 92),
        UIColor(red: 124, green: 234, blue: 189),
        UIColor(red: 194, green: 134, blue: 109),
        UIColor(red: 114, green: 214, blue: 119),
        UIColor(red: 194, green: 184, blue: 149),

    ]
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCellReuseIdentifier", for: indexPath)
        cell.contentView.layer.cornerRadius = 15.0
        cell.layer.shadowOpacity = 0.1
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOffset = CGSize(width: 4, height: 0)
        cell.contentView.backgroundColor = colors[indexPath.row]
        cell.clipsToBounds = false
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colors.count
    }
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        self.init(red: CGFloat(red)/255 ,
                  green: CGFloat(green)/255,
                  blue: CGFloat(blue)/255,
                  alpha: 1.0)
    }
}

