//
//  OrderConfirmationViewController.swift
//  OrderApp
//
//  Created by Nune Melikyan on 01.11.22.
//

import UIKit

final class OrderConfirmationViewController: UIViewController {

    private var minutesToPrepare: Int
    private lazy var timeInterval = Date().addingTimeInterval(TimeInterval(minutesToPrepareBySeconds))
    
    @IBOutlet var confirmationLabel: UILabel!
    private lazy var confirmationText = "From \(minutesToPrepare) minute(s) your order will be ready."
    
    @IBOutlet weak var progressBar: UIProgressView!
    private var myTimer = Timer()
    private var counter = 0
    private lazy var minutesToPrepareBySeconds: Int = 60 * minutesToPrepare
    private lazy var progressCount = minutesToPrepareBySeconds
    private var delta: Float = 0.0
    
    private let center = UNUserNotificationCenter.current()
    private var notificationIdentifier = UUID().uuidString
    
    // MARK: -- Init
    init?(
        coder: NSCoder,
        minutesToPrepare: Int
    ) {
        self.minutesToPrepare = minutesToPrepare
        super.init(coder: coder)
    }

    required init?(
        coder: NSCoder
    ) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: -- Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
    
        sendNotification(minutesToPrepare: minutesToPrepare)
        
        delta = 1.0 / Float(minutesToPrepareBySeconds)
        progressBar.progress = 0.0
        confirmationLabel.text = confirmationText
        createTimer()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        cancelTimer()
        cancelNotifications()
    }
    
    // MARK: -- Acion
    @IBAction func dismissButton(_ sender: UIButton) {
       cancelTimer()
       cancelNotifications()
    }
    
    // MARK: -- Timer
    private func createTimer() {
        myTimer = Timer.scheduledTimer(timeInterval: 1,
                                       target: self,
                                       selector: #selector(updateProgressView),
                                       userInfo: nil,
                                       repeats: true)
    }
    
    // MARK: -- Progress Bar
    @objc private func updateProgressView() {        
        confirmationLabel.text = "From \(minutesToPrepareBySeconds/60) minute(s) your order will be ready."
       
        counter += 1
        progressBar.progress += delta
        if counter > 60 {
            minutesToPrepareBySeconds -= 1
        }
        
        if counter == progressCount {
            myTimer.invalidate()
            progressBar.progress = 1
            confirmationLabel.text = "Your order is ready."
        }
    }
   
    // MARK: -- Notification
    private func sendNotification(minutesToPrepare: Int) {
        let _ = center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            if !granted {
                print("Permission denied.")
            }
        }
        
        let _ = center.getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                print(settings)
            } else { return }
        }
        
        center.delegate = self
        createNotification(minutesToPrepare)
    }
    
    private func createNotification(_ minutesToPrepare: Int) {
        var secondsBeforeNotification: TimeInterval = 0
        
        if minutesToPrepare < 1 {
            print("Preparation time can not be less than one minute.")
            return
        }
        
        if minutesToPrepare == 1 {
            secondsBeforeNotification = TimeInterval(minutesToPrepareBySeconds - 10)
        } else if minutesToPrepare > 1 && minutesToPrepare <= 10 {
            secondsBeforeNotification = TimeInterval(minutesToPrepareBySeconds - 60)
        } else if minutesToPrepare > 10 {
            secondsBeforeNotification = TimeInterval(minutesToPrepareBySeconds - 600)
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Order Alert"
        content.subtitle = "Remains \((minutesToPrepareBySeconds - Int(secondsBeforeNotification)) / 60) minute(s) for the order to be ready."
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: secondsBeforeNotification, repeats: false)

        let request = UNNotificationRequest(identifier: notificationIdentifier, content: content, trigger: trigger)

        center.add(request) { (error) in }
    }
    
    private func cancelNotifications() {
        center.removeDeliveredNotifications(withIdentifiers: [notificationIdentifier])
        center.removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
    }
    
    private func cancelTimer() {
        myTimer.invalidate()
        progressBar.progress = 0.0
    }
}

// MARK: -- Extension
extension OrderConfirmationViewController: UNUserNotificationCenterDelegate {
    internal func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
        print(#function)
    }
    
    internal func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        print(#function)
    }
}
