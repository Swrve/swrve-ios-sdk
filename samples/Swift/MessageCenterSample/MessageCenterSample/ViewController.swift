import UIKit
import SwrveSDK

class ViewController: UITableViewController {

    var campaigns : NSArray!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshDataSource()
        self.tableView.reloadData()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.newSwrveCampaigns(_:)), name:"SwrveUserResourcesUpdated", object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return campaigns.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MessageCenterCell", forIndexPath: indexPath)
        let baseCampaign = campaigns[indexPath.row] as? SwrveBaseCampaign
        cell.textLabel?.text = baseCampaign?.subject
        
        let dformat : NSDateFormatter = NSDateFormatter()
        dformat.dateFormat = "MMMM dd, yyyy (EEEE) HH:mm:ss z Z"
        cell.detailTextLabel?.text = dformat.stringFromDate((baseCampaign?.dateStart)!)
        
        return cell
    }
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        Swrve.sharedInstance().talk.showMessageCenterCampaign(campaigns[indexPath.row] as? SwrveBaseCampaign)
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.Delete
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            tableView.beginUpdates()
            Swrve.sharedInstance().talk.removeMessageCenterCampaign(campaigns[indexPath.row] as? SwrveBaseCampaign)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Left)
            tableView.endUpdates()
        }
    }
    
    func refreshDataSource() {
        let unsortedCampaigns: NSArray = Swrve.sharedInstance().talk.messageCenterCampaigns()
        let descriptor: NSSortDescriptor = NSSortDescriptor(key: "dateStart", ascending: true)
        campaigns = unsortedCampaigns.sortedArrayUsingDescriptors([descriptor])
    }
    
    func newSwrveCampaigns(notification: NSNotification){
        refreshDataSource()
        self.tableView.reloadData()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
