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
@available(iOS 13.0, *)
class MasterViewController: UIViewController, MenuControllerDelegate {
    
    private var menu: UISideMenuNavigationController?
    
    private lazy var ContactController: ViewController = {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        var VC = storyboard.instantiateViewController(identifier: "ContactViewController") as! ViewController
        self.addController(controller: VC)
        return VC
    }()
    private lazy var ReportController: ReportViewController = {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        var VC = storyboard.instantiateViewController(identifier: "ReportViewController") as! ReportViewController
        self.addController(controller: VC)
        return VC
    }()
    private lazy var NotificationController: NotificationViewController = {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        var VC = storyboard.instantiateViewController(identifier: "NotificationViewController") as! NotificationViewController
        self.addController(controller: VC)
        return VC
    }()
    private lazy var ExposedController: ExposedViewController = {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        var VC = storyboard.instantiateViewController(identifier: "ExposedViewController") as! ExposedViewController
        self.addController(controller: VC)
        return VC
    }()
    private lazy var AboutUsController: AboutUsViewController = {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        var VC = storyboard.instantiateViewController(identifier: "AboutUsViewController") as! AboutUsViewController
        self.addController(controller: VC)
        return VC
    }()
    
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
        
        addChildrenController()
        ContactController.view.isHidden = false
    }
    
    private func addChildrenController(){
        addController(controller: ContactController)
        addController(controller: ReportController)
        addController(controller: NotificationController)
        addController(controller: ExposedController)
        addController(controller: AboutUsController)
    }
    
    private func addController(controller: UIViewController) {
        addChild(controller)
        view.addSubview(controller.view)
        controller.view.frame = view.bounds
        controller.didMove(toParent: self)
        controller.view.isHidden = true
    }
    
    private func removeController(controller: UIViewController) {
        controller.willMove(toParent: nil)
        controller.view.removeFromSuperview()
        controller.removeFromParent()
    }
    
    @IBAction func menuButton(_ sender: UIBarButtonItem) {
        present(menu!, animated: true)
    }
    
    func didSelectMenuItem(named: menuComponent) {
        menu?.dismiss(animated: true, completion: nil)
        
        switch(named){
        case .home:
            ContactController.view.isHidden = false
            ReportController.view.isHidden = true
            NotificationController.view.isHidden = true
            ExposedController.view.isHidden = true
            AboutUsController.view.isHidden = true
        case .report:
            ContactController.view.isHidden = true
            ReportController.view.isHidden = false
            NotificationController.view.isHidden = true
            ExposedController.view.isHidden = true
            AboutUsController.view.isHidden = true
        case .notif:
            ContactController.view.isHidden = true
            ReportController.view.isHidden = true
            NotificationController.view.isHidden = false
            ExposedController.view.isHidden = true
            AboutUsController.view.isHidden = true
        case .expose:
            ContactController.view.isHidden = true
            ReportController.view.isHidden = true
            NotificationController.view.isHidden = true
            ExposedController.view.isHidden = false
            AboutUsController.view.isHidden = true
        case .about:
            ContactController.view.isHidden = true
            ReportController.view.isHidden = true
            NotificationController.view.isHidden = true
            ExposedController.view.isHidden = true
            AboutUsController.view.isHidden = false
        }
    }
}
