//
//  UIImage+Extension.swift
//  CustomCameraView
//
//  Created by Anirudha on 15/03/18.
//  Copyright © 2018 Anirudha Mahale. All rights reserved.
//

import UIKit

extension UIImage {
    func imageByCropToRect(rect:CGRect, scale:Bool) -> UIImage {
        
        var rect = rect
        var scaleFactor: CGFloat = 1.0
        if scale  {
            scaleFactor = self.scale
            rect.origin.x *= scaleFactor
            rect.origin.y *= scaleFactor
            rect.size.width *= scaleFactor
            rect.size.height *= scaleFactor
        }
        
        var image: UIImage? = nil;
        if rect.size.width > 0 && rect.size.height > 0 {
            let imageRef = self.cgImage!.cropping(to: rect)
            image = UIImage(cgImage: imageRef!, scale: scaleFactor, orientation: self.imageOrientation)
        }
        
        return image!
    }
    
    func cropImage(cropRect: CGRect, size: CGSize) -> UIImage {
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        let subImage = self.cgImage!.cropping(to: cropRect)
        
        let myRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        context?.scaleBy(x: 1, y: -1)
        context?.translateBy(x: 0, y: -size.height)
        context?.draw(subImage!, in: myRect)
        let croppedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return croppedImage!
    }
}
