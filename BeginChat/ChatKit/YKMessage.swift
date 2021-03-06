//
//  YKMessage.swift
//  BeginChat
//
//  Created by bestkai on 2017/4/26.
//  Copyright © 2017年 YunKai Wang. All rights reserved.
//

import UIKit
import AVOSCloudIM
/*
 消息发送状态,自己发送的消息时有
 */
enum YKMessageSendStatus: Int {
    case None = 0
    case Sending
    case Sent
    case Delivered
    case Failed
    case Read
}

/*
 消息读取状态,自己接收消息时有
 */
enum YKMessageReadStatus: Int {
    case UnRead = 0
    case UnReading
    case Readed
}

/**
 *  消息拥有者类型
 */
enum YKMessageOwnerType: Int {
    case Unknown = 0
    case BySystem
    case BySelf
    case ByOther
}

/**
 *  消息聊天类型
 */
enum YKConversationType: Int {
    case Single = 0 //单聊
    case Group  = 1 //群聊
}

let kAVIMMessageMediaTypeSystem: AVIMMessageMediaType = AVIMMessageMediaType(rawValue: -7)!


class YKUser {
    
    @discardableResult open class func currentUser() -> YKUser? {
        if AVUser.current() == nil {
            return nil
        }
        struct Static {
            //Singleton instance. Initializing keyboard manger.
            static let currentUser = YKUser(user: AVUser.current())
            private init(){}
        }
        /** @return Returns the default singleton instance. */
        return Static.currentUser
    }
    
    init() {
        
    }
    
    init(user:AVUser?) {
        self.userId = user?.objectId
        self.name = user?.username
        self.avatarURL = user?.object(forKey: "avatar") != nil ? URL.init(string: (user?.object(forKey: "avatar") as? String)!) : nil
    }
    
    var userId: String?
    var name: String?
    var avatarURL: URL?
}


class YKBaseMessage {
    var messageId: String?
    var sender: YKUser?
    var sendStatus = YKMessageSendStatus.None
    var conversationId: String?
    var timestamp: TimeInterval?
    var ownerType = YKMessageOwnerType.Unknown
    var hasRead: Bool?
    var receiverHasRead: Bool?
    var ownerName: String?
    var chatType = YKConversationType.Single
    var cellHeight:CGFloat = 0.0
    
}



class YKMessage: YKBaseMessage {
    
    var serverMessageId: String?
    //文本消息
    var text: String?
    
    //图片消息
    var originPhoto:UIImage?
    var thumbnailPhoto:UIImage?
    var photoPath:String?
    var thumbnailUrl:URL?
    var originPhotoUrl:URL?
    var imageWidth:CGFloat = 0.0
    var imageHeight:CGFloat = 0.0
    
    
    var mediaType:AVIMMessageMediaType?
    
    override init() {
        super.init()
    }
    //MARK: - Text Message
    init(text:String, sender:YKUser?, timestamp:TimeInterval, serverMessageId:String?, chatType:YKConversationType) {
        super.init()
        self.text = text
        self.sender = sender
        self.timestamp = timestamp
        self.serverMessageId = serverMessageId
        self.mediaType = AVIMMessageMediaType.text
        self.chatCellHeight()
    }
    
    //MARK: - System Message
    init(systemText:String) {
        super.init()
        
        self.text = systemText
        self.mediaType = kAVIMMessageMediaTypeSystem
        self.ownerType = YKMessageOwnerType.BySystem
        self.chatCellHeight()
    }
    
    class func systemMessageWithTimestamp(timeStamp: TimeInterval) -> YKMessage {
        
        let date: Date = NSDate.init(timeIntervalSince1970: timeStamp/1000) as Date
        
        let dateFormatter = DateFormatter.init()
        dateFormatter.dateFormat = "MM-dd HH:mm"
        
        let text = dateFormatter.string(from: date)
        
        let message = YKMessage.init(systemText: text)
        
        return message
    }
    
    init(originImage:UIImage?,thumbnilImage:UIImage?,thumbnailSize:CGSize?,thumbnailUrl:URL?,originUrl:URL?,sender:YKUser?, timestamp:TimeInterval, serverMessageId:String?, chatType:YKConversationType)
    {
        super.init()
        self.originPhoto = originImage
        self.thumbnailPhoto = thumbnilImage
        self.thumbnailUrl = thumbnailUrl
        self.originPhotoUrl = originUrl
        self.sender = sender
        self.timestamp = timestamp
        self.serverMessageId = serverMessageId
        self.mediaType = AVIMMessageMediaType.image
        
        if (thumbnailSize?.height)! > YK_MSG_CELL_MAXIMAGE_HEIGHT {
            self.imageHeight = YK_MSG_CELL_MAXIMAGE_HEIGHT
//            self.imageWidth = YK_MSG_CELL_MAXIMAGE_HEIGHT*(thumbnailSize?.width/thumbnailSize?.height)
        }else{
            self.imageHeight = (thumbnailSize?.height)!
        }
        
        self.chatCellHeight()
    }
    
    
    class func messageWithAVIMTypedMessage(message:AVIMTypedMessage) -> YKMessage? {
        
        var ykMessage:YKMessage = YKMessage.init()
        let mediaType = message.mediaType
        
        switch mediaType {
        case .text:
            
            let textMsg = message as! AVIMTextMessage
            ykMessage = YKMessage.init(text: textMsg.text!, sender: nil, timestamp: TimeInterval(textMsg.sendTimestamp), serverMessageId: textMsg.messageId, chatType: .Single)
            
        case.image:
            let imageMsg = message as! AVIMImageMessage
            
            let minWidth = min(imageMsg.width, 200)
            
            let minHeight = min(Double(minWidth)*(Double(imageMsg.height)/Double(imageMsg.width) ), 200)
            
            let imageSize = CGSize.init(width: CGFloat(minWidth), height: CGFloat(minHeight))
            
            let thumbnailUrl = imageMsg.file?.url?.appending("?imageView2/2/w/200/h/200")
            
            ykMessage = YKMessage.init(originImage: nil, thumbnilImage: nil,thumbnailSize:imageSize, thumbnailUrl: URL.init(string: thumbnailUrl ?? ""), originUrl: URL.init(string: (imageMsg.file?.url)!), sender: nil, timestamp: TimeInterval(imageMsg.sendTimestamp), serverMessageId: imageMsg.messageId, chatType: .Single)
            
        default: break
            
        }
        
        if YKSessionService.defaultService().clientId == message.clientId {
            ykMessage.ownerType = .BySelf
        }else{
            ykMessage.ownerType = .ByOther
        }
        ykMessage.sendStatus = YKMessageSendStatus.init(rawValue: Int(message.status.rawValue))!
        
        return ykMessage
    }
    
}


extension YKMessage {
    
    func chatCellHeight() {
        
        var textHeight = self.text?.height(fontSize: Float(YK_MSG_CELL_TEXT_FONTSIZE),maxWidth:Float(YK_MSG_CELL_MAX_TEXT_WIDTH))
        
        if textHeight == nil {
            textHeight = 0.0
        }
        
        let showName = self.ownerType == YKMessageOwnerType.ByOther && self.chatType == YKConversationType.Group
        
        switch self.mediaType! {
        case .text:
            
            if showName {
                textHeight! += (YK_MSG_CELL_NAME_FONTSIZE + 4.0)
            }
            
            self.cellHeight = CGFloat(textHeight!) + (YK_MSG_CELL_TEXT_CONTENT_INSET * 2) + CGFloat(YK_MSG_CELL_CONTENT_BOTTOM_MARGIN)
        case .image:
            
            if showName {
                textHeight! += (YK_MSG_CELL_NAME_FONTSIZE + 4.0)
            }
            
            self.cellHeight = CGFloat(textHeight!) + self.imageHeight + CGFloat(YK_MSG_CELL_CONTENT_BOTTOM_MARGIN)
            
        case kAVIMMessageMediaTypeSystem:
            
            self.cellHeight = CGFloat(YK_MSG_CELL_TIME_HEIGHT + YK_MSG_CELL_CONTENT_BOTTOM_MARGIN + YK_MSG_CELL_TIME_TOP_MARGIN)
            
        default:
            self.cellHeight = 0
        }
    }
    
    func shouldDisplayTiemLabel(lastMessage:YKMessage?) -> Bool {
        if lastMessage == nil {
            return true
        }
        
        let interval: Int = Int(self.timestamp! - (lastMessage?.timestamp)!)
            
        let limitInterval = 60*3*1000
        
        if interval > limitInterval {
            return true
        }
        return false
    }
}

