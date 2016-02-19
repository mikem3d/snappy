//
//  ViewController.swift
//  snappy
//
//  Created by Michael Martinez on 2/19/16.
//  Copyright © 2016 lonewolf. All rights reserved.
//

import UIKit
import AVFoundation
import Alamofire
import SwiftyJSON

class ViewController: UIViewController {
    
    var captureSession: AVCaptureSession?
    var stillImageOutput: AVCaptureStillImageOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        previewLayer!.frame = self.view.bounds
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        // we do this on another thread so that we don't hang the UI
        captureSession = AVCaptureSession()
        captureSession!.sessionPreset = AVCaptureSessionPresetPhoto
        
        let backCamera = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        var error: NSError?
        var input: AVCaptureDeviceInput!
        do {
            input = try AVCaptureDeviceInput(device: backCamera)
        } catch let error1 as NSError {
            error = error1
            input = nil
        }
        
        if error == nil && captureSession!.canAddInput(input) {
            captureSession!.addInput(input)
            
            stillImageOutput = AVCaptureStillImageOutput()
            stillImageOutput!.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
            if captureSession!.canAddOutput(stillImageOutput) {
                captureSession!.addOutput(stillImageOutput)
                
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                previewLayer!.videoGravity = AVLayerVideoGravityResizeAspect
                previewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.Portrait
                self.view.layer.addSublayer(previewLayer!)
                
                captureSession!.startRunning()
                
                takePhoto()
            }
        }
    }
    
    func takePhoto(){
        if let videoConnection = stillImageOutput!.connectionWithMediaType(AVMediaTypeVideo) {
//            videoConnection.videoOrientation = AVCaptureVideoOrientation.Portrait
            stillImageOutput?.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler: {(sampleBuffer, error) in
                if (sampleBuffer != nil) {
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                    let dataProvider = CGDataProviderCreateWithCFData(imageData)
                    let cgImageRef = CGImageCreateWithJPEGDataProvider(dataProvider, nil, true, CGColorRenderingIntent.RenderingIntentDefault)
                    
                    let image = UIImage(CGImage: cgImageRef!)
                    let imageView = UIImageView(image: image)
                    imageView.frame = CGRectMake(0, 0, self.view.frame.width, self.view.frame.height)
                    self.view.addSubview(imageView)
                    
                    let imageData64 = UIImageJPEGRepresentation(image,1)
                    let encodedImage = imageData64!.base64EncodedStringWithOptions([])
                    
                    let params:[String:AnyObject] = [
                        "image": encodedImage
                    ]
                    
                    //print(encodedImage)
                    
                    self.requestWrapper(.POST, url: "http://104.131.13.135/snappy/", params: params, callback: { (data:JSON)->Void in
                    })
                }
            })
        }

        delay(10){
            self.captureSession!.startRunning()
            self.takePhoto()
        }
    }
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
    
    /*
    * HTTP request wrapper, expects JSON response
    */
    func requestWrapper(method: Alamofire.Method, url:String, params:[String:AnyObject]?, callback:(data:JSON)->Void){
            
            Alamofire.request(method, url, parameters: params, headers: nil)
                .responseJSON { response in
                    print(response.response)
                    //print("response",response.data)
            }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

