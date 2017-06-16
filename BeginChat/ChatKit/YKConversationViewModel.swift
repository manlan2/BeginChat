//
//  YKConversationViewModel.swift
//  BeginChat
//
//  Created by bestkai on 2017/6/2.
//  Copyright © 2017年 YunKai Wang. All rights reserved.
//

import Foundation
import AVOSCloudIM
protocol YKConversationViewModelDelegate {
    func messageSendStateChanged(message:Any, sendStatus:YKMessageSendStatus,progress:Double) -> Void
    
    func messageReadStateChanged(message:Any, readStatus:YKMessageReadStatus,progress:Double) -> ()
}

class YKConversationViewModel: NSObject {
    
    var parentViewController : YKConversationViewController
    
    var delegate:YKConversationViewModelDelegate?
    
    lazy var currentConversation: AVIMConversation = {
        let currentConversation:AVIMConversation = self.parentViewController.conversation!
        return currentConversation
    }()
    
    lazy var currentConversationId: String = {
        
        let currentConversationId = self.currentConversation.conversationId
        return currentConversationId!
    }()
    
    
    
    init(parentViewController: YKConversationViewController) {
        self.parentViewController = parentViewController
        super.init()
    }
    
    func sendMessage(message:Any) {
        
        self.sendMessage(amessage: message, progressClosure: { (percent) in
            
            print("percnt\(percent)")
            
            self.delegate?.messageSendStateChanged(message: message, sendStatus: .Sending, progress: 1.0)
//            self.delegate?.messageSendStateChanged(message: message, sendStatus: .Sending, progress: Double(percent/100.0))
            
        }, success: { (succeed, error) in
            
            self.delegate?.messageSendStateChanged(message: message, sendStatus: .Sent, progress: 1.0)
            
        },failed: { (succeed, error) in
            
            self.delegate?.messageSendStateChanged(message: message, sendStatus: .Failed, progress: 1.0)
        })
    }
    
    private func sendMessage(amessage:Any,progressClosure:AVProgressClosure?,success: YKBooleanResultClosure?,failed: YKBooleanResultClosure?){
        
        var avimTypedMessage: AVIMTypedMessage
        
        let  message:YKMessage = amessage as! YKMessage
        
        message.conversationId = self.currentConversationId
        message.sendStatus = .Sending
//        message.sender = 
        message.ownerType = .BySelf
        
        avimTypedMessage = AVIMTypedMessage.yk_messageWithYKMessage(message: message)
        
        self.preloadMessageToTableView(aMessage: message) { 
            
            YKConversationService.defaultService().sendMessage(message: avimTypedMessage, conversation: currentConversation, progressClosure: progressClosure!, callBack: { (succeeded, error) in
                if error != nil {
                    if success != nil{
                        success!(succeeded,nil)
                    }
                }else{
                    if failed != nil {
                        failed!(succeeded,error)
                    }
                }
            })
        }
    }
    
    
    private func preloadMessageToTableView(aMessage:Any,callBack:YKVoidClosure){
        
        let message:YKMessage = aMessage as! YKMessage
        
//        let oldLastMessageCount = self.parentViewController.dataSources.count
        
        self.appendingMessagesToTrailing(messages: [message])
        
//        let newLastMessageCount = self.parentViewController.dataSources.count
        
        delegate?.messageSendStateChanged(message: message, sendStatus: .Sending, progress: 0.0)
        
    }
    
    private func appendingMessagesToTrailing(messages:Array<Any>){
        
        let lastObject = self.parentViewController.dataSources.count > 0 ? self.parentViewController.dataSources.last : nil
        
        self.appendMessagesToDataArrayTrailing(messages: self.messageWithSystemMessages(messages: messages, lastMessage: lastObject))
    }
    
    private func appendMessagesToDataArrayTrailing(messages:Array<Any>){
        
        if !messages.isEmpty {
            self.parentViewController.dataSources = self.parentViewController.dataSources + messages
        }
    }
    
    private func messageWithSystemMessages(messages:Array<Any>,lastMessage:Any?) -> Array<Any> {
        
        var messageWithSystemMessages:Array = [Any]()
        
        messageWithSystemMessages = (lastMessage != nil) ? [lastMessage!] : Array()
        
        for (index,messsage) in messages.enumerated() {
            messageWithSystemMessages.append(messsage)
            let tempMsg:YKMessage = messsage as! YKMessage
            
            if index > 0 {
                messageWithSystemMessages.insert(YKMessage.systemMessageWithTimestamp(timeStamp: tempMsg.timestamp!), at: 0)
            }else{
                if tempMsg.shouldDisplayTiemLabel(lastMessage: messageWithSystemMessages[index - 1] as? YKMessage) {
                    messageWithSystemMessages.insert(YKMessage.systemMessageWithTimestamp(timeStamp: tempMsg.timestamp!), at: messageWithSystemMessages.count - 1)
                }
            }
        }
        
        if (lastMessage != nil) {
            messageWithSystemMessages.removeFirst()
        }
        return messageWithSystemMessages
    }
    
    
    func loadMessagesFirstTimeWithCallback(callback:YKBooleanResultClosure) {
        
        
    }
    
    func queryAndCacheMessageWithTimestamp(timestamp:Int,closure:AVIMArrayResultBlock) {
        var tempTimestamp = timestamp
        
        if self.parentViewController.loadingMoreMessage {
            return
        }
        
        if self.parentViewController.dataSources.count == 0 {
            tempTimestamp = 0
        }
        
        self.parentViewController.loadingMoreMessage = true
        
        YKConversationService.defaultService().queryTypedMessagesWithConversation(conversation: self.currentConversation, timestamp: tempTimestamp, limit: YKOnePageSize) { (avimTypedMessages, error) in
            
        }
    }
    
}
