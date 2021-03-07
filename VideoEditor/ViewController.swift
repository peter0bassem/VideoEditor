//
//  ViewController.swift
//  VideoEditor
//
//  Created by Peter Bassem on 07/03/2021.
//

import UIKit
import Photos
import MobileCoreServices

class ViewController: UIViewController {
    
    private lazy var picker: UIImagePickerController = {
        var picker = UIImagePickerController()
        picker.delegate = self
        picker.mediaTypes = [kUTTypeMovie as String]
        return picker
    }()
    private lazy var alert: UIAlertController = {
        var alert = UIAlertController(title: "Choose Source", message: nil, preferredStyle: .actionSheet)
        let gallaryAction = UIAlertAction(title: "Gallary", style: .default) { _ in
            self.openGallery()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        // Add the actions
        alert.addAction(gallaryAction)
        alert.addAction(cancelAction)
//        alert.popoverPresentationController?.sourceView = self.view
        return alert
    }()
    
    var showPicker: Bool = true
    
    var videoPath: String?
    private lazy var videoEditor: UIVideoEditorController = {
        let videoEditor = UIVideoEditorController()
        videoEditor.videoPath = self.videoPath ?? ""
        videoEditor.videoMaximumDuration = 15
        videoEditor.delegate = self
        return videoEditor
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = .red
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if showPicker {
            self.present(alert, animated: true)
        }
    }
    
    func openGallery() {
        alert.dismiss(animated: true, completion: nil)
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let asset = info[.phAsset] as? PHAsset {
            getUrl(fromPHAsset: asset) { [weak self] (url) in
                guard let self = self else { return }
                print(1)
                self.checkURLLength(inPickecView: picker, url: url)
            }
        } else if let url = info[.mediaURL] as? URL {
            print(2)
            checkURLLength(inPickecView: picker, url: url)
        } else if let referenceURL = info[.referenceURL] as? URL {
            let assets = PHAsset.fetchAssets(withALAssetURLs: [referenceURL], options: nil)
            if let asset = assets.firstObject {
                getUrl(fromPHAsset: asset) { [weak self] (url) in
                    guard let self = self else { return }
                    print(3)
                    self.checkURLLength(inPickecView: picker, url: url)
                }
            }
        }
    }
    
    private func getUrl(fromPHAsset asset: PHAsset, callBack: @escaping (_ url: URL?) -> Void) {
        asset.requestContentEditingInput(with: PHContentEditingInputRequestOptions()) { (contentEditingInput, dictInfo) in
            if let strURL = (contentEditingInput!.audiovisualAsset as? AVURLAsset)?.url.absoluteString {
                callBack(URL.init(string: strURL))
            }
        }
    }
    
    private func checkURLLength(inPickecView picker: UIImagePickerController, url: URL?) {
        guard let url = url else { return }
        self.showPicker = false
        self.videoPath = url.absoluteString
        picker.dismiss(animated: true, completion: nil)
        let asset = AVAsset(url: url)
        let duration = asset.duration
        let durationTime = CMTimeGetSeconds(duration)
        if durationTime > 15 {
            if UIVideoEditorController.canEditVideo(atPath: url.absoluteString) {
                present(videoEditor, animated: true, completion: nil)
            }
        } else {
            print(url)
        }
    }
}

extension ViewController: UIVideoEditorControllerDelegate {
    
    func videoEditorController(_ editor: UIVideoEditorController, didSaveEditedVideoToPath editedVideoPath: String) {
        
//        editor.dismiss(animated: true, completion: nil)
        //Do whatever you wish with the trimmed video here
        videoEditor.delegate = nil
        print(editedVideoPath)
    }
    
    func videoEditorController(_ editor: UIVideoEditorController, didFailWithError error: Error) {
        print("Failed to save trimmed video:", error)
    }
    
    func videoEditorControllerDidCancel(_ editor: UIVideoEditorController) {
        print("Cancelled")
    }
}
