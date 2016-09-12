import UIKit
import SwrveSDK

class ViewController: UITableViewController {

    var campaigns : NSArray!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshDataSource()
        self.tableView.reloadData()
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.newSwrveCampaigns(_:)), name:NSNotification.Name(rawValue: "SwrveUserResourcesUpdated"), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return campaigns.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCenterCell", for: indexPath)
        let baseCampaign = campaigns[(indexPath as NSIndexPath).row] as? SwrveBaseCampaign
        cell.textLabel?.text = baseCampaign?.subject
        
        let dformat : DateFormatter = DateFormatter()
        dformat.dateFormat = "MMMM dd, yyyy (EEEE) HH:mm:ss z Z"
        cell.detailTextLabel?.text = dformat.string(from: (baseCampaign?.dateStart)!)
        
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        Swrve.sharedInstance().talk.showMessageCenter(campaigns[(indexPath as NSIndexPath).row] as? SwrveBaseCampaign)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.delete
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
            tableView.beginUpdates()
            Swrve.sharedInstance().talk.removeMessageCenter(campaigns[(indexPath as NSIndexPath).row] as? SwrveBaseCampaign)
            tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.left)
            tableView.endUpdates()
        }
    }
    
    func refreshDataSource() {
        let unsortedCampaigns: NSArray = Swrve.sharedInstance().talk.messageCenterCampaigns() as NSArray
        let descriptor: NSSortDescriptor = NSSortDescriptor(key: "dateStart", ascending: true)
        campaigns = unsortedCampaigns.sortedArray(using: [descriptor]) as NSArray
    }
    
    func newSwrveCampaigns(_ notification: Notification){
        refreshDataSource()
        self.tableView.reloadData()
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
}
