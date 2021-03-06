//
//  ImageViewController.swift
//  Experiences
//
//  Created by Michael on 3/13/20.
//  Copyright © 2020 Michael. All rights reserved.
//

import UIKit
import Photos
import CoreImage
import CoreImage.CIFilterBuiltins
import MapKit

class ImageViewController: UIViewController {
    
    weak var delegate: ExperienceMediaDelegate?
    
    var experience: Experience? {
        didSet {
            
        }
    }
    
    let context = CIContext(options: nil)
    
    var imageData: Data?
    
    var image: UIImage? {
        didSet {
            
        }
    }
    
    var scaledImage: UIImage? {
        didSet {
            
        }
    }
    
    var originalImage: UIImage? {
        didSet {
            imageView.image = originalImage?.flattened
            
            guard let originalImage = originalImage else { return }
            
            var scaledSize = imageView.bounds.size
            let scale = UIScreen.main.scale
            
            scaledSize = CGSize(width: scaledSize.width * scale,
                                height: scaledSize.height * scale)
            
            scaledImage = originalImage.imageByScaling(toSize: scaledSize)
        }
    }
    
    @IBOutlet weak var addPhotoButton: UIButton!
    @IBOutlet weak var filterSlider: UISlider!
    @IBOutlet weak var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        checkAuthorizationStatus()
        
        updateViews()
    }
    
    @IBAction func sliderChanged(_ sender: Any) {
        updateImage()   
    }
    
    @IBAction func saveTapped(_ sender: Any) {
        view.endEditing(true)
        
        let image = imageView.image
        
        self.experience?.image = image
        
        let experienceDictionary = [mediaAdded : experience] as! [String : Experience]
        NotificationCenter.default.post(name: .mediaAdded, object: nil, userInfo: experienceDictionary)
        
        navigationController?.popViewController(animated: true)

    }
    
    @IBAction func addPhotoTapped(_ sender: Any) {
        let authorizationStatus = PHPhotoLibrary.authorizationStatus()
          
          switch authorizationStatus {
          case .authorized:
              presentImagePickerController()
          case .notDetermined:
              
              PHPhotoLibrary.requestAuthorization { (status) in
                  
                  guard status == .authorized else {
                      NSLog("User did not authorize access to the photo library")
                      self.presentInformationalAlertController(title: "Error", message: "In order to access the photo library, you must allow this application access to it.")
                      return
                  }
                  
                self.presentImagePickerController()
              }
              
          case .denied:
              self.presentInformationalAlertController(title: "Error", message: "In order to access the photo library, you must allow this application access to it.")
          case .restricted:
              self.presentInformationalAlertController(title: "Error", message: "Unable to access the photo library. Your device's restrictions do not allow access.")
              
          @unknown default:
            self.presentInformationalAlertController(title: "Error", message: "Future Unknown Authorization Status")
            }
            presentImagePickerController()
        }
    
    func checkAuthorizationStatus() {
        let authorizationStatus = PHPhotoLibrary.authorizationStatus()
        
        switch authorizationStatus {
        case .authorized:
            presentImagePickerController()
        case .notDetermined:
            
            PHPhotoLibrary.requestAuthorization { (status) in
                
                guard status == .authorized else {
                    NSLog("User did not authorize access to the photo library")
                    self.presentInformationalAlertController(title: "Error", message: "In order to access the photo library, you must allow this application access to it.")
                    return
                }
                
              self.presentImagePickerController()
            }
            
        case .denied:
            self.presentInformationalAlertController(title: "Error", message: "In order to access the photo library, you must allow this application access to it.")
        case .restricted:
            self.presentInformationalAlertController(title: "Error", message: "Unable to access the photo library. Your device's restrictions do not allow access.")
            
        @unknown default:
          self.presentInformationalAlertController(title: "Error", message: "Future Unknown Authorization Status")
          }
          presentImagePickerController()
    }
    
    func updateViews() {
        guard let imageData = imageData,
            let image = UIImage(data: imageData) else {
                return
        }

        imageView.image = image
    }
    
    func updateImage() {
        if let scaledImage = scaledImage {
            imageView.image = filterImage(scaledImage)
        } else {
            imageView.image = nil
        }
    }
    
    func filterImage(_ image: UIImage) -> UIImage? {
        
        // UIImage > CGImage > CIImage
        guard let cgImage = image.cgImage else { return nil }
        let ciImage = CIImage(cgImage: cgImage)
        let filter = CIFilter.colorPosterize()
        filter.inputImage = ciImage
        filter.levels = filterSlider.value
        
        guard let outputCIImage = filter.outputImage else { return nil }
            
        // Render the image (apply the filter to the image) i.e. baking the cookies in the over
        guard let outputCGImage = context.createCGImage(outputCIImage, from: CGRect(origin: CGPoint.zero, size: image.size)) else { return nil }
            // CIImage > CGImage > UIImage
        return UIImage(cgImage: outputCGImage)
    }
    
    private func presentImagePickerController() {
        
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            presentInformationalAlertController(title: "Error", message: "The photo library is unavailable")
            return
        }
        
        let imagePicker = UIImagePickerController()
        
        imagePicker.delegate = self
        
        imagePicker.sourceType = .photoLibrary

        present(imagePicker, animated: true, completion: nil)
    }
    
    // MARK: - Navigation
}

extension ImageViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true, completion: nil)
        
        guard let image = info[.originalImage] as? UIImage else { return }
        
        imageView.image = image
        originalImage = image
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
