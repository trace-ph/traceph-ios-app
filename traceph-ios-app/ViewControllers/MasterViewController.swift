//
//  MasterViewController.swift
//  traceph-ios-app
//
//  Created by Angelique Rafael on 8/3/21.
//  Copyright © 2021 traceph. All rights reserved.
//

import UIKit
import SideMenu

// Controls the menu
class MasterViewController: UIViewController, MenuControllerDelegate {
    
    private var menu: UISideMenuNavigationController?
    
    private let ContactController = ViewController()
    private let ReportController = ReportViewController()
    private let NotificationController = NotificationViewController()
    private let ExposedController = ExposedViewController()
    private let AboutUsController = AboutUsViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Menu code
        let currentMenu = MenuListController(with: menuComponent.allCases)
        currentMenu.delegate = self
        menu = UISideMenuNavigationController(rootViewController: currentMenu)
        menu?.leftSide = true
        menu?.setNavigationBarHidden(true, animated: false)
        
        SideMenuManager.default.menuLeftNavigationController = menu
        SideMenuManager.default.menuAddPanGestureToPresent(toView: self.view)
        
        addChildControllers()
//        ContactController.view.isHidden = false
    }
    
    private func addChildControllers() {
//        addController(controller: self.ContactController)
        addController(controller: self.ReportController)
        addController(controller: self.NotificationController)
        addController(controller: self.ExposedController)
        addController(controller: self.AboutUsController)
    }
    
    private func addController(controller: UIViewController) {
        addChild(controller)
        view.addSubview(controller.view)
        controller.view.frame = view.bounds
        controller.didMove(toParent: self)
        controller.view.isHidden = true
    }
    
    @IBAction func menuButton(_ sender: UIBarButtonItem) {
        present(menu!, animated: true)
    }
    
    func didSelectMenuItem(named: menuComponent) {
        menu?.dismiss(animated: true, completion: nil)
        
        switch(named){
        case .home:
//            ContactController.view.isHidden = false
            ReportController.view.isHidden = true
            NotificationController.view.isHidden = true
            ExposedController.view.isHidden = true
            AboutUsController.view.isHidden = true
        case .report:
//            ContactController.view.isHidden = true
            ReportController.view.isHidden = false
            NotificationController.view.isHidden = true
            ExposedController.view.isHidden = true
            AboutUsController.view.isHidden = true
        case .notif:
//            ContactController.view.isHidden = true
            ReportController.view.isHidden = true
            NotificationController.view.isHidden = false
            ExposedController.view.isHidden = true
            AboutUsController.view.isHidden = true
        case .expose:
//            ContactController.view.isHidden = true
            ReportController.view.isHidden = true
            NotificationController.view.isHidden = true
            ExposedController.view.isHidden = false
            AboutUsController.view.isHidden = true
        case .about:
//            ContactController.view.isHidden = true
            ReportController.view.isHidden = true
            NotificationController.view.isHidden = true
            ExposedController.view.isHidden = true
            AboutUsController.view.isHidden = false
        }
    }
}
