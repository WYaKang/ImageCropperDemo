//
//  ViewController.swift
//  ImageCropperDemo
//
//  Created by yakang wang on 2018/1/7.
//  Copyright © 2018年 yakang wang. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBAction func selectImageAction(_ sender: Any) {
        //判断设置是否支持图片库
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            //初始化图片控制器
            let picker = UIImagePickerController()
            //设置代理
            picker.delegate = self
            //指定图片控制器类型
            picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
            //弹出控制器，显示界面
            self.present(picker, animated: true, completion: {
                () -> Void in
            })
        }else{
            print("读取相册错误")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

//UIImagePickerControllerDelegate & UINavigationControllerDelegate

extension ViewController: UINavigationControllerDelegate {
    
}

extension ViewController: UIImagePickerControllerDelegate {
    //选择图片成功后代理
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : Any]) {
        // 图片控制器退出
        picker.dismiss(animated: true) {
            let image: UIImage = info[UIImagePickerControllerOriginalImage] as! UIImage
            let atVC = ATImageCropperController(image: image, cropFrame: CGRect(x: 0, y: 100, width: self.view.frame.size.width, height: self.view.frame.size.width), limitScaleRatio: 3.0)
            atVC.delegate = self
            DispatchQueue.main.async {
                self.present(atVC, animated: true, completion: nil)
            }
        }
    }
}

extension ViewController: ATImageCropperDelegate {
    func imageCropper(_ cropperViewController: ATImageCropperController, didFinished editedImage: UIImage) {
        cropperViewController.dismiss(animated: true, completion: nil)
        print(editedImage)
    }
    
    func imageCropperDidCancel(_ cropperViewController: ATImageCropperController) {
        cropperViewController.dismiss(animated: true, completion: nil)
    }
}

