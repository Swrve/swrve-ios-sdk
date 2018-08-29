import UIKit
import SwrveSDK

class ViewController: UITableViewController {

    var campaigns : NSArray!

    override func viewDidLoad() {
        super.viewDidLoad()
        refreshDataSource()
        self.tableView.reloadData()

        // Observe for the new campaigns
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.newSwrveCampaigns(_:)), name:NSNotification.Name(rawValue: "SwrveUserResourcesUpdated"), object: nil)

        // The Swrve SDK creates new UIWindows to display content to avoid
        // creating issues for games etc. However, this means that the controllers
        // do not get their callbacks called.
        // We set this class as the delegate to listen to these events.
        SwrveSDK.messaging().showMessageDelegate = self;
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    func refreshDataSource() {
        let unsortedCampaigns: NSArray = SwrveSDK.messaging().messageCenterCampaigns() as NSArray
        let descriptor: NSSortDescriptor = NSSortDescriptor(key: "dateStart", ascending: false)
        campaigns = unsortedCampaigns.sortedArray(using: [descriptor]) as NSArray
    }

    func newSwrveCampaigns(_ notification: Notification) {
        refreshDataSource()
        self.tableView.reloadData()
    }
}

//MARK: SwrveMessageDelegate Delegate

extension ViewController: SwrveMessageDelegate {

    func messageWillBeHidden(_ viewController: UIViewController)  {
        // An in-app message or conversation will be hidden.
        // Notify the table view that the state of a campaign might have changed.
        self.tableView.reloadData()
    }
}

//MARK: UITableViewDelegate and UITableViewDataSource extension
extension ViewController {

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        SwrveSDK.messaging().showMessageCenter(campaigns[indexPath.row] as? SwrveCampaign)
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.delete
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
            guard let campaign = campaigns[indexPath.row] as? SwrveCampaign else { return }
            tableView.beginUpdates()
            SwrveSDK.messaging().removeMessageCenter(campaign)
            tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.left)
            tableView.endUpdates()
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCenterCell", for: indexPath)
        let baseCampaign = campaigns[indexPath.row] as? SwrveCampaign
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

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return campaigns.count
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
}
