import Foundation
import SwiftData

@Model class LifeModel {
    var age: Int
    var goals: [Goal]
    
    init(age: Int = 0, goals: [Goal] = []) {
        self.age = age
        self.goals = goals
    }
    
    var lifeExpectancy = 77
    
    var yearsLeft: Int {
        max(lifeExpectancy - age, 0)
    }
    
    var estimatedDeathDate: Date? {
        Calendar.current.date(byAdding: .year, value: yearsLeft, to: Date())
    }
}
