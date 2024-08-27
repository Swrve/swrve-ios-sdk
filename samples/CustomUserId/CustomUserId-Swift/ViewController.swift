import SwrveSDK
import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        updateTextView()
    }

    @IBAction func startSwrve(_ sender: Any) {

        let title = "Enter custom userId to start swrve with or leave blank to generate one."
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: UIAlertController.Style.alert)
        alertController.addTextField { textField in
            textField.placeholder = ""
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: nil))
        alertController.addAction(
            UIAlertAction(
                title: "Start",
                style: UIAlertAction.Style.default,
                handler: { _ in
                    if let text = alertController.textFields?[0].text {
                        if text.isEmpty {
                            SwrveSDK.start()
                        } else {
                            SwrveSDK.start(withUserId: text)
                        }

                        let title = "Swrve SDK Started"
                        let alertConfirmation = UIAlertController(title: title, message: nil, preferredStyle: UIAlertController.Style.alert)
                        alertConfirmation.addAction(
                            UIAlertAction(
                                title: "OK",
                                style: UIAlertAction.Style.default,
                                handler: { _ in
                                    self.updateTextView()
                                }
                            )
                        )
                        self.present(alertConfirmation, animated: true, completion: nil)
                    }
                }
            )
        )
        present(alertController, animated: true, completion: nil)

    }

    func updateTextView() {
        if SwrveSDK.started() {
            textView.text = "Started with userId:" + SwrveSDK.userID()
        } else {
            textView.text = "Not started."
        }
    }
}
