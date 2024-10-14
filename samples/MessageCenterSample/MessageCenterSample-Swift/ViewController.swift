import SwrveSDK
import UIKit

class ViewController: UITableViewController {

    var campaigns: NSArray!

    override func viewDidLoad() {
        super.viewDidLoad()
        refreshDataSource()
        self.tableView.reloadData()

        // Observe for the new campaigns
        NotificationCenter.default.addObserver(
            self, selector: #selector(ViewController.reloadData(_:)), name: NSNotification.Name(rawValue: "SwrveUserResourcesUpdated"), object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(ViewController.reloadData(_:)), name: NSNotification.Name(rawValue: "SwrveMessageWillBeHidden"), object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    func refreshDataSource() {
        let unsortedCampaigns: NSArray = SwrveSDK.messageCenterCampaigns() as NSArray
        let descriptor: NSSortDescriptor = NSSortDescriptor(key: "dateStart", ascending: false)
        campaigns = unsortedCampaigns.sortedArray(using: [descriptor]) as NSArray
    }

    @objc func reloadData(_ notification: Notification) {
        refreshDataSource()
        self.tableView.reloadData()
    }
}

// MARK: UITableViewDelegate and UITableViewDataSource extension
extension ViewController {

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let campaign = campaigns[indexPath.row] as? SwrveCampaign

        if let campaign = campaign {
            _ = SwrveSDK.showMessageCenter(campaign)
        }
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        true
    }

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        UITableViewCell.EditingStyle.delete
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCell.EditingStyle.delete {
            guard let campaign = campaigns[indexPath.row] as? SwrveCampaign else { return }
            tableView.beginUpdates()
            SwrveSDK.removeMessageCenter(campaign)
            tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.left)
            tableView.endUpdates()
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCenterCell", for: indexPath)
        let baseCampaign = campaigns[indexPath.row] as? SwrveCampaign
        cell.textLabel?.text = baseCampaign?.messageCenterDetails?.subject ?? ""

        let dformat: DateFormatter = DateFormatter()
        dformat.dateFormat = "MMMM dd, yyyy (EEEE) HH:mm:ss z Z"
        cell.detailTextLabel?.text = dformat.string(from: (baseCampaign?.dateStart)!)

        // Campaign cell background colour based on seen / unseen status
        if let state = baseCampaign?.state.status {
            switch state {
            case .unseen:
                cell.backgroundColor = UIColor.init(red: 1, green: 0, blue: 0, alpha: 0.4)
            case .seen:
                cell.backgroundColor = UIColor.init(red: 0, green: 1, blue: 0, alpha: 0.4)
            default:
                break
            }
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        campaigns.count
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
}
