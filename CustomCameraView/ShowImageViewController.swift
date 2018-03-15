//
//  ShowImageViewController.swift
//  CustomCameraView
//
//  Created by Anirudha on 15/03/18.
//  Copyright © 2018 Anirudha Mahale. All rights reserved.
//

import UIKit

class ShowImageViewController: UIViewController {

    var image = UIImage()
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.image = image
    }
}
