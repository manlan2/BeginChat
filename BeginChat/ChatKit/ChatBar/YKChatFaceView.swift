//
//  YKChatFaceView.swift
//  BeginChat
//
//  Created by bestkai on 2017/5/5.
//  Copyright © 2017年 YunKai Wang. All rights reserved.
//

import UIKit

class YKChatFaceView: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.red
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
