import Foundation
import NotificationCenter

@Observable class FinanceController {
    var salary: Double = 0
    var hourlyRate: Double = 0
    var freelanceMonthly: Double = 0
    
    var workSchedule: WorkSchedule = .fullTime
    
    private var monthsPerYear: Double { 12 }
    private var weeksPerYear: Double { 52 }
    private var daysPerYear: Double { 364 }
    
    func monthlyExpenses(from bills: [Transaction]) -> Double {
        bills.reduce(0) { partial, bill in
            partial + bill.amount * bill.frequency.toMonthly
        }
    }
    
    func neededAnnual(from bills: [Transaction]) -> Double {
        monthlyExpenses(from: bills) * monthsPerYear
    }
    
    func neededMonthly(from bills: [Transaction]) -> Double {
        monthlyExpenses(from: bills)
    }
    
    func neededWeekly(from bills: [Transaction]) -> Double {
        neededAnnual(from: bills) / weeksPerYear
    }
    
    func neededDaily(from bills: [Transaction]) -> Double {
        neededAnnual(from: bills) / daysPerYear
    }
    
    func neededHourly(from bills: [Transaction]) -> Double {
        neededAnnual(from: bills) / workSchedule.hoursPerYear
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleNotification(for bill: Transaction) {
        guard let dueDate = bill.dueDate, bill.remindMe else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Upcoming Bill: \(bill.name)"
        content.body = "Don't forget to pay \(bill.name)"
        content.sound = .default
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day], from: dueDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: bill.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelNotification(for bill: Transaction) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [bill.id.uuidString])
    }
}
