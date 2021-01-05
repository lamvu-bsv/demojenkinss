//
//  CircleMenuViewController.swift
//  DemoProject
//
//  Created by Tai Ma on 9/4/20.
//  Copyright © 2020 Tai Ma. All rights reserved.
//

import UIKit

class CircleMenuViewController: UIViewController {

    @IBOutlet weak var clv: UICollectionView!
    
    private var items: [UIColor] = [.red,.black,.blue,.brown,.cyan,.darkGray,.lightGray,.purple]
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        configDataSource()
    }
    
    private func configDataSource() {
        clv.delegate = self
        clv.dataSource = self
        clv.register(UINib(nibName: String(describing: CollectionViewCell.self), bundle: nil), forCellWithReuseIdentifier: String(describing: CollectionViewCell.self))
//        clv.collectionViewLayout = CircleLayoutCollection()
    }
}

extension CircleMenuViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: CollectionViewCell.self), for: indexPath)
        cell.backgroundColor = items[indexPath.row]
        return cell
    }
}
