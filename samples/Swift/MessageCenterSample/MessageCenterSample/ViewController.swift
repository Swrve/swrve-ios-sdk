import UIKit
import SwrveSDK

class ViewController: UITableViewController, SwrveMessageDelegate {

    var campaigns : NSArray!

    override func viewDidLoad() {
        super.viewDidLoad()
        refreshDataSource()
        self.tableView.reloadData()
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.newSwrveCampaigns(_:)), name:NSNotification.Name(rawValue: "SwrveUserResourcesUpdated"), object: nil)

        SwrveSDK.messaging().showMessageDelegate = self;
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
        let baseCampaign = campaigns[(indexPath as NSIndexPath).row] as? SwrveCampaign
        cell.textLabel?.text = baseCampaign?.subject

        let dformat : DateFormatter = DateFormatter()
        dformat.dateFormat = "MMMM dd, yyyy (EEEE) HH:mm:ss z Z"
        cell.detailTextLabel?.text = dformat.string(from: (baseCampaign?.dateStart)!)

        // Campaign cell background colour based on seen / unseen status
        if let state = baseCampaign?.state.status {
            switch(state) {
            case SWRVE_CAMPAIGN_STATUS_UNSEEN:
                cell.backgroundColor = UIColor.init(red:1, green:0, blue:0, alpha:0.4);
                break;
            case SWRVE_CAMPAIGN_STATUS_SEEN:
                cell.backgroundColor = UIColor.init(red:0, green:1, blue:0, alpha:0.4);
                break;
            default:
                break;
            }
        }

        return cell
    }


    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        SwrveSDK.messaging().showMessageCenter(campaigns[(indexPath as NSIndexPath).row] as? SwrveCampaign)
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
            SwrveSDK.messaging().removeMessageCenter(campaigns[(indexPath as NSIndexPath).row] as? SwrveCampaign)
            tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.left)
            tableView.endUpdates()
        }
    }

    func refreshDataSource() {
        let unsortedCampaigns: NSArray = SwrveSDK.messaging().messageCenterCampaigns() as NSArray
        let descriptor: NSSortDescriptor = NSSortDescriptor(key: "dateStart", ascending: true)
        campaigns = unsortedCampaigns.sortedArray(using: [descriptor]) as NSArray
    }

    func newSwrveCampaigns(_ notification: Notification) {
        refreshDataSource()
        self.tableView.reloadData()
    }

    override var prefersStatusBarHidden : Bool {
        return true
    }

    func messageWillBeHidden(_ viewController: UIViewController)  {
        // An in-app message or conversation will be hidden.
        // Notify the table view that the state of a campaign might have changed.
        self.tableView.reloadData()
    }
}
