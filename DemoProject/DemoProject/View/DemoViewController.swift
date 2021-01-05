//
//  DemoViewController.swift
//  DemoProject
//
//  Created by Tai Ma on 5/19/20.
//  Copyright © 2020 Tai Ma. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SocketIO
import Toast
import CoreBluetooth

class DemoViewController: UIViewController {
    @IBOutlet weak var drawView: DrawCanvasView!
    @IBOutlet weak var btnClear: UIButton!
    @IBOutlet weak var btnUndo: UIButton!
    @IBOutlet weak var btnShare: UIButton!
    @IBOutlet weak var vWidthStoke: UISlider!
    
    let manager = SocketManager(socketURL: URL(string: "http://192.168.1.6:3000/")!, config: [.log(false), .compress])
    var socket: SocketIOClient!
    
    private let uuidDevice = UIDevice.current.identifierForVendor!.uuidString
    
    override func viewDidLoad() {
        super.viewDidLoad()
        drawView.delegate = self
        btnShare.setTitle("Deleted", for: .normal)
        eventHandle()
        configSocket()
    }
    
    private func configSocket() {
        socket = manager.defaultSocket
        socket.on(clientEvent: .connect) {data, ack in
            print("socket connected")
        }
        
        socket.on("post_data_mobile") { (data, ack) in
            guard let json = data[0] as? Dictionary<String, [Dictionary<String, Any>]> else { return }
            guard let uuid = data[1] as? String else { return }
            
            if self.uuidDevice == uuid {
                return
            }
            
            let jsonDecoder = JSONDecoder()
            let jsonData  = json["Data"]?.bv_jsonString().data(using: .utf8)
            
            let lines = try? jsonDecoder.decode([LineModel].self, from: jsonData!)
            
            if let lines = lines {
                self.drawView.hanldeSocketLines(lines)
            }
        }
        
        socket.on("clear_data_mobile", callback: { data, ack in
            guard let uuid = data[0] as? String else { return }
            if self.uuidDevice == uuid {
                return
            }
            
            self.drawView.clear()
        })
        socket.connect()
    }
    
    private func eventHandle() {
        btnClear.addTarget(self, action: #selector(btnClearTouched), for: .touchUpInside)
        btnUndo.addTarget(self, action: #selector(btnUndoTouched), for: .touchUpInside)
        vWidthStoke.addTarget(self, action: #selector(vWidthStokeChange), for: .valueChanged)
        btnShare.addTarget(self, action: #selector(btnShareTouched), for: .touchUpInside)
    }
    
    @objc private func btnUndoTouched() {
        drawView.undo()
    }
    
    @objc private func btnClearTouched() {
        socket.emit("clear_data_mobile", with: [self.uuidDevice])
        drawView.clear()
    }
    
    @objc private func vWidthStokeChange() {
        drawView.width = CGFloat(vWidthStoke.value)
    }
    
    @objc private func btnShareTouched() {
        drawView.isDeleted = !drawView.isDeleted
        if drawView.isDeleted {
            btnShare.setTitle("Draw", for: .normal)
        } else {
            btnShare.setTitle("Deleted", for: .normal)
        }
    }
}

extension DemoViewController: DrawCanvasViewDelegate {
    func handleEndDraw() {
        let dic : Dictionary<String, [LineModel]> = [ "Data" : self.drawView.lines]
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted

            let data = try encoder.encode(dic)
            let json = String(data: data, encoding: .utf8)!
            socket.emit("send_data_mobile", with: [json, self.uuidDevice])
        } catch {
            print(error)
        }
    }
}

extension Array {
    public func bv_jsonString(prettyPrint : Bool = true) -> String {
        do {
            let jsonData : Data = try JSONSerialization.data(withJSONObject: self, options: (prettyPrint ? JSONSerialization.WritingOptions.prettyPrinted : JSONSerialization.WritingOptions.init(rawValue: 0)))
            let string : String = String(data: jsonData, encoding: String.Encoding.utf8) ?? ""
            return string
        } catch {
            return ""
        }
    }
}
