import UIKit
import SwrveSDK

class ViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        updateTextView()
    }

    @IBAction func startSwrve(_ sender: Any) {

        let title = "Enter custom userId to start swrve with or leave blank to generate one."
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: UIAlertController.Style.alert)
        alertController.addTextField { (textField: UITextField!) -> Void in
            textField.placeholder = ""
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: nil))
        alertController.addAction(UIAlertAction(title: "Start", style: UIAlertAction.Style.default, handler: { alert -> Void in
            if let textField = alertController.textFields?[0] {
                if textField.text!.count > 0 {
                    SwrveSDK.start(withUserId: textField.text!)
                } else {
                    SwrveSDK.start();
                }

                let title = "Swrve SDK Started"
                let alertConfirmation = UIAlertController(title: title, message: nil, preferredStyle: UIAlertController.Style.alert)
                alertConfirmation.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { alert -> Void in
                    self.updateTextView()
                }))
                self.present(alertConfirmation, animated: true, completion: nil)
            }
        }))
        present(alertController, animated: true, completion: nil)

    }

    func updateTextView() {
        if (SwrveSDK.started()) {
            textView.text = "Started with userId:" + SwrveSDK.userID()
        } else {
            textView.text = "Not started."
        }
    }
}

