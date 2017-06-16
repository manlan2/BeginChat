//
//  YKHotUserViewController.swift
//  BeginChat
//
//  Created by bestkai on 2017/4/25.
//  Copyright © 2017年 YunKai Wang. All rights reserved.
//

import UIKit
import AVOSCloud

class YKHotUserViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {

    private var dataSources = [AVUser]()
    
    
    lazy var tableView: UITableView = {
        let tableView = UITableView.init(frame: CGRect.zero, style: UITableViewStyle.plain)
        tableView.register(YKHotUserTableViewCell.classForCoder(), forCellReuseIdentifier: "YKHotUserTableViewCell")
        tableView.rowHeight = 60
        tableView.tableFooterView = UIView.init()
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "发现"
        self.view.backgroundColor = UIColor.white

        self.initSubViews()
        self.getDataSources()
    }

    func initSubViews() {
        self.view.addSubview(self.tableView)

        self.tableView.snp.makeConstraints { (make) in
            make.edges.equalTo(UIEdgeInsetsMake(0, 0, 0, 0))
        }
    }
    
    
    func getDataSources() {
        let query = AVQuery.init(className: "_User")
        
        query.whereKey("objectId", notEqualTo: (AVUser.current()?.objectId)!)
        
        query.findObjectsInBackground { (objects, error) in
            
            self.dataSources = objects as! [AVUser]
            
            self.tableView.reloadData()
        }
    }
    
    
    //MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSources.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "YKHotUserTableViewCell", for: indexPath) as! YKHotUserTableViewCell
        cell.setUser(user: dataSources[indexPath.row])
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let userDetailVC = YKUserDetailViewController.init()
        userDetailVC.hidesBottomBarWhenPushed = true
        userDetailVC.currentUser = dataSources[indexPath.row]
        self.navigationController?.pushViewController(userDetailVC, animated: true)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}