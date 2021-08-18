//
//  ExposedViewController.swift
//  traceph-ios-app
//
//  Created by Angelique Rafael on 7/27/21.
//  Copyright © 2021 traceph. All rights reserved.
//

import UIKit

class ExposedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    // Information of references, outsources, and contact details
    let refLabel = ["Endcov.ph",
                    "Department of Health",
                    "COVID-19 Dashboard",
                    "World Health Organization (WHO)",
                    "Centers for Disease Control and Prevention (CDC)"]
    let refDesc = ["- COVID-19 Tracker: https://endcov.ph",
                   "- COVID-19 Tracker: https://doh.gov.ph/covid19tracker \n- FAQ: https://doh.gov.ph/COVID-19/FAQs \n- Updates: https://doh.gov.ph/2019-nCoV \n- Contact-tracing guidelines: https://doh.gov.ph/node/21752 \n",
                   "- What is COVID-19: https://www.covid19.gov.ph/health/what-is-covid-19 \n- Home Quaratine: https://www.covid19.gov.ph/health/home-quarantine \n- FAQ: https://www.covid19.gov.ph/frequently-asked-questions \n",
                   "- What is COVID-19: https://www.who.int/health-topics/coronavirus#tab=tab_1 \n- COVID-19 Guidelines: https://www.who.int/emergencies/diseases/novel-coronavirus-2019/advice-for-public \n- FAQ: https://www.who.int/emergencies/diseases/novel-coronavirus-2019/question-and-answers-hub \n- Contact-tracing guidelines: https://www.who.int/publications/i/item/contact-tracing-in-the-context-of-covid-19 \n",
                   "- COVID-19 Guidelines: https://www.cdc.gov/coronavirus/2019-ncov/prevent-getting-sick/prevention.html \n - FAQ: https://www.cdc.gov/coronavirus/2019-ncov/faq.html \n- Contract-tracing guidelines: https://www.cdc.gov/coronavirus/2019-ncov/php/contact-tracing/contact-tracing-plan/contact-tracing.html \n"]
    let hospitalLabel = ["Yani the Endcovbot",
                         "University Health Service (UHS)",
                         "Philippine General Hospital (PGH)",
                         "Other hospital contacts"]
    let hospitalDesc = ["If you have questions about Health and COVID-19, vaccines, and more, talk to Yani, the Endcovbot: : https://m.me/YaniEndCovBot \n\nYani, the COVID-19 Messenger chatbot developed by the University of the Philippines Resilience Institute, can help users find vaccination sites, hospitals with vacant beds and available ventilators, COVID-19 statistics, topics on the current pandemic situation, and more. For more info, visit Yani's page: https://www.facebook.com/YaniEndCovBot \n\n",
                        "For all UP-mandated clientele and residents: \n- Facebook: https://www.facebook.com/UPDHealthService/ \n- Number: 8981-8500 local 2702 \n- Email: uphs@upd.edu.ph \n- For appointment: uphs.appointlet.com",
                        "Free consultation: https://www.facebook.com/pghgabay \n",
                        "You may find hospital contacts through this link: https://endcov.ph/hospitals/ \n"]
    
    
    @IBOutlet weak var closeContacts: UIScrollView!
    @IBOutlet weak var referenceTableView: UITableView?
    @IBOutlet weak var hospitalTableView: UITableView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let nib = UINib(nibName: "CardTableViewCell", bundle: nil)
        referenceTableView?.register(nib, forCellReuseIdentifier: "CardTableViewCell")
        referenceTableView?.delegate = self
        referenceTableView?.dataSource = self
        referenceTableView?.tableFooterView = UIView()
        hospitalTableView?.register(nib, forCellReuseIdentifier: "CardTableViewCell")
        hospitalTableView?.delegate = self
        hospitalTableView?.dataSource = self
        hospitalTableView?.tableFooterView = UIView()
    }
    
    // Notification Table functions
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == referenceTableView {
            return refLabel.count;
        } else {
            return hospitalLabel.count;
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == referenceTableView {
            let refCell = referenceTableView?.dequeueReusableCell(withIdentifier: "CardTableViewCell", for: indexPath) as! CardTableViewCell
            
            
            refCell.cardLabel?.text = refLabel[indexPath.row]
            refCell.cardDesc?.text = refDesc[indexPath.row]
            
            return refCell
        } else {
            let hospitalCell = hospitalTableView?.dequeueReusableCell(withIdentifier: "CardTableViewCell", for: indexPath) as! CardTableViewCell
            
            
            hospitalCell.cardLabel?.text = hospitalLabel[indexPath.row]
            hospitalCell.cardDesc?.text = hospitalDesc[indexPath.row]
            
            return hospitalCell
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.contentView.layer.masksToBounds = true
    }
}
