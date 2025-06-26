import Foundation
import Speech
import AVFoundation

@Observable class SpeechRecognizer: NSObject, SFSpeechRecognizerDelegate {
    private let recognizer = SFSpeechRecognizer(locale: Locale.current)!
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    var recognizedText: String = ""
    
    func startRecording() throws {
        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request = request else { throw NSError(domain: "No request", code: -1) }
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            if let result = result {
                self.recognizedText = result.bestTranscription.formattedString
            }
            if error != nil || (result?.isFinal ?? false) {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.request = nil
                self.recognitionTask = nil
            }
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        request?.endAudio()
    }
    
    func requestPermissions(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                let micStatus = AVAudioApplication.shared.recordPermission
                let micGranted = micStatus == .granted || micStatus == .undetermined
                completion(authStatus == .authorized && micGranted)
            }
        }
    }
}


// MARK: - Expense Parsing
//func parseAmount(from transcript: String) -> Double? {
//    let pattern = #"(?:(\$)?(\d{1,6})(?:[.,](\d{1,2}))?)"#
//    let regex = try! NSRegularExpression(pattern: pattern)
//    let nsString = transcript as NSString
//    guard let match = regex.firstMatch(in: transcript, range: NSRange(location: 0, length: nsString.length)) else {
//        return nil
//    }
//    
//    let hasDollarSign = match.range(at: 1).location != NSNotFound
//    let dollarsStr = match.range(at: 2).location != NSNotFound ? nsString.substring(with: match.range(at: 2)) : ""
//    let centsStr = match.range(at: 3).location != NSNotFound ? nsString.substring(with: match.range(at: 3)) : ""
//    
//    if hasDollarSign || !centsStr.isEmpty {
//        // Exact amount or has a dollar sign
//        let full = centsStr.isEmpty ? dollarsStr : "\(dollarsStr).\(centsStr)"
//        return Double(full)
//    } else if let intVal = Int(dollarsStr) {
//        // No dollar/decimal → assume cents
//        return Double(intVal) / 100.0
//    }
//    
//    return nil
//}

//func parseVendorOrCategory(from transcript: String) -> String {
//    let knownVendors: [String: [String]] = [
//        // Convenience / Gas
//        "7-Eleven": ["711", "7 11", "seven eleven", "7-eleven", "7:11"],
//        "Circle K": ["circle k", "circlek"],
//        "Wawa": ["wawa"],
//        "Sheetz": ["sheetz"],
//        "Casey's": ["caseys", "casey's"],
//        "Speedway": ["speedway"],
//        "QuikTrip": ["quiktrip", "qt", "quicktrip"],
//        "RaceTrac": ["racetrac", "race trac", "race-track"],
//        "Mobil": ["mobil"],
//        "Exxon": ["exxon", "exxonmobil"],
//        "Shell": ["shell"],
//        "Chevron": ["chevron"],
//        "BP": ["bp", "british petroleum"],
//        "Marathon": ["marathon"],
//        "Sunoco": ["sunoco"],
//        
//        // Grocery / Supermarkets
//        "Walmart": ["walmart", "wal-mart"],
//        "Target": ["target"],
//        "Costco": ["costco"],
//        "Sam's Club": ["sams club", "sam's club"],
//        "Kroger": ["kroger"],
//        "Safeway": ["safeway"],
//        "Publix": ["publix"],
//        "Albertsons": ["albertsons"],
//        "Aldi": ["aldi"],
//        "Whole Foods": ["whole foods", "wholefoods"],
//        "Trader Joe's": ["trader joes", "trader joe's"],
//        "HEB": ["heb"],
//        "Meijer": ["meijer"],
//        "WinCo": ["winco"],
//        "Food Lion": ["food lion"],
//        "Giant": ["giant"],
//        "Harris Teeter": ["harris teeter"],
//        "Fry's": ["frys"],
//        "Piggly Wiggly": ["piggly wiggly"],
//        "Ralphs": ["ralphs"],
//        "Stop & Shop": ["stop and shop", "stop & shop"],
//        "Giant Eagle": ["giant eagle"],
//        "H-E-B": ["h-e-b", "heb"],
//        
//        // Pharmacy / Drug stores
//        "CVS": ["cvs", "cvs pharmacy"],
//        "Walgreens": ["walgreens", "walgreens pharmacy"],
//        "Rite Aid": ["rite aid", "riteaid"],
//        
//        // Big Box / Retail
//        "Best Buy": ["best buy", "bestbuy"],
//        "Home Depot": ["home depot", "the home depot"],
//        "Lowe's": ["lowes", "lowe's"],
//        "IKEA": ["ikea"],
//        "Dick's Sporting Goods": ["dicks sporting goods", "dick's sporting goods"],
//        "Bed Bath & Beyond": ["bed bath beyond", "bed bath & beyond"],
//        "Office Depot": ["office depot"],
//        "Staples": ["staples"],
//        "Macy's": ["macys", "macy's"],
//        "Nordstrom": ["nordstrom"],
//        "TJ Maxx": ["tj maxx"],
//        "Marshalls": ["marshalls"],
//        "Kohl's": ["kohls", "kohl's"],
//        
//        // Restaurants / Fast Food
//        "McDonald's": ["mcdonalds", "macdonalds", "mickey d's", "mickey dees"],
//        "Starbucks": ["starbucks", "star bucks"],
//        "Subway": ["subway"],
//        "Chipotle": ["chipotle"],
//        "Dunkin'": ["dunkin", "dunkin donuts"],
//        "Panera Bread": ["panera", "panera bread"],
//        "Burger King": ["burger king"],
//        "Taco Bell": ["taco bell"],
//        "KFC": ["kfc", "kentucky fried chicken"],
//        "Wendy's": ["wendys", "wendy's"],
//        "Domino's": ["dominos", "domino's"],
//        "Pizza Hut": ["pizza hut"],
//        "Chick-fil-A": ["chick-fil-a", "chickfila", "chick fil a"],
//        "Five Guys": ["five guys"],
//        "Sonic": ["sonic"],
//        "Dairy Queen": ["dairy queen", "dq"],
//        
//        // Online / Tech
//        "Amazon": ["amazon", "amazon.com"],
//        "Apple": ["apple store", "apple"],
//        "eBay": ["ebay"],
//        "Walmart.com": ["walmart.com", "walmart dot com"],
//        "Etsy": ["etsy"],
//        "Newegg": ["newegg"],
//        
//        // Ride sharing / Delivery
//        "Uber": ["uber"],
//        "Lyft": ["lyft"],
//        "DoorDash": ["doordash"],
//        "Grubhub": ["grubhub"],
//        "Postmates": ["postmates"],
//        "Instacart": ["instacart"],
//        
//        // Miscellaneous
//        "REI": ["rei"],
//        "Costco Gas": ["costco gas"],
//        "Sam's Club Gas": ["sams club gas", "sam's club gas"],
//        "Walgreens Pharmacy": ["walgreens pharmacy"],
//        "CVS Pharmacy": ["cvs pharmacy"],
//    ]
//    
//    let categories = [
//        // Food and Drink
//        "coffee", "bagel", "breakfast", "brunch", "lunch", "dinner", "snack", "meal", "fast food",
//        "dessert", "pizza", "burger", "sandwich", "soda", "tea", "juice", "alcohol", "bar",
//        
//        // Retail and Shopping
//        "groceries", "supermarket", "pharmacy", "electronics", "clothing", "apparel", "furniture",
//        "home improvement", "hardware", "office supplies", "beauty", "cosmetics", "books",
//        
//        // Services and Transport
//        "gas", "fuel", "ride", "rideshare", "taxi", "uber", "lyft", "delivery", "shipping",
//        "movie", "entertainment", "tickets",
//        
//        // Financial
//        "payment", "bill", "subscription", "donation", "tip",
//        
//        // General
//        "miscellaneous", "other"
//    ]
//    
//    // Normalize the transcript
//    var lowerTranscript = transcript.lowercased()
//    let normalizationMap: [String: String] = [
//        // Convenience / Gas
//        "7:11": "711",
//        "7 11": "711",
//        "seven eleven": "711",
//        "7-eleven": "711",
//        "sheetz": "sheetz",
//        "circlek": "circle k",
//        "racetrac": "race trac",
//        "quiktrip": "qt",
//        
//        // Grocery
//        "wholefoods": "whole foods",
//        "trader joes": "trader joe's",
//        "sams club": "sam's club",
//        "wal-mart": "walmart",
//        "heb": "h-e-b",
//        "stop and shop": "stop & shop",
//        
//        // Retail
//        "bestbuy": "best buy",
//        "home depot": "the home depot",
//        "lowes": "lowe's",
//        "kohls": "kohl's",
//        "macys": "macy's",
//        
//        // Fast Food / Restaurants
//        "mickey dees": "mcdonalds",
//        "star bucks": "starbucks",
//        "dunkin donuts": "dunkin",
//        "chickfila": "chick-fil-a",
//        "burgerking": "burger king",
//        
//        // Online / Tech
//        "amazon.com": "amazon",
//        "walmart dot com": "walmart.com",
//        
//        // Ride sharing / Delivery
//        "doordash": "doordash",
//        "grub hub": "grubhub",
//    ]
//    
//    for (pattern, replacement) in normalizationMap {
//        lowerTranscript = lowerTranscript.replacingOccurrences(of: pattern, with: replacement)
//    }
//    
//    // Check for known vendor matches
//    for (vendor, keywords) in knownVendors {
//        if keywords.contains(where: { lowerTranscript.contains($0) }) {
//            return vendor
//        }
//    }
//    
//    // Check for general category-based fallback
//    for category in categories {
//        if lowerTranscript.contains(category) {
//            return category.capitalized
//        }
//    }
//    
//    return "Unknown"
//}
func parseVendorOrCategory(from transcript: String) -> String {
    // 1. Vendor lookup
    let knownVendors: [String: [String]] = [
        // Gas & Convenience
        "7-Eleven":      ["711","7 11","seven eleven","7-eleven","7:11"],
        "Circle K":      ["circle k","circlek"],
        "Wawa":          ["wawa"],
        "Sheetz":        ["sheetz"],
        "Casey's":       ["caseys","casey's"],
        "Speedway":      ["speedway"],
        "QuikTrip":      ["quiktrip","qt","quicktrip"],
        "Exxon":         ["exxon","exxonmobil"],
        "Shell":         ["shell"],
        "Chevron":       ["chevron"],
        "BP":            ["bp","british petroleum"],
        "Marathon":      ["marathon"],
        "Sunoco":        ["sunoco"],

        // Grocery / Supermarket
        "Walmart":       ["walmart","wal-mart"],
        "Target":        ["target"],
        "Costco":        ["costco","costco wholesale"],
        "Sam's Club":    ["sams club","sam's club"],
        "Kroger":        ["kroger"],
        "Safeway":       ["safeway"],
        "Publix":        ["publix"],
        "Aldi":          ["aldi"],
        "Whole Foods":   ["whole foods","wholefoods"],
        "Trader Joe's":  ["trader joe's","trader joes"],
        "HEB":           ["heb","h-e-b"],

        // Pharmacy / Drugstore
        "CVS":           ["cvs pharmacy","cvs"],
        "Walgreens":     ["walgreens pharmacy","walgreens"],
        "Rite Aid":      ["rite aid","riteaid"],

        // Big-Box Retail
        "Best Buy":      ["best buy","bestbuy"],
        "Home Depot":    ["home depot","the home depot"],
        "Lowe's":        ["lowes","lowe's"],
        "IKEA":          ["ikea"],
        "Macy's":        ["macy's","macys"],
        "Nordstrom":     ["nordstrom"],
        "TJ Maxx":       ["tj maxx"],
        "Marshalls":     ["marshalls"],
        "Kohl's":        ["kohl's","kohls"],

        // Restaurants & Fast-Food
        "McDonald's":    ["mcdonalds","mickey dees","mickey d's"],
        "Starbucks":     ["starbucks","star bucks"],
        "Subway":        ["subway"],
        "Chipotle":      ["chipotle"],
        "Dunkin'":       ["dunkin donuts","dunkin"],
        "Panera Bread":  ["panera bread","panera"],
        "Burger King":   ["burger king"],
        "Taco Bell":     ["taco bell"],
        "KFC":           ["kfc","kentucky fried chicken"],
        "Wendy's":       ["wendy's","wendys"],
        "Domino's":      ["domino's","dominos"],
        "Pizza Hut":     ["pizza hut"],
        "Chick-fil-A":   ["chick-fil-a","chickfila"],
        "Five Guys":     ["five guys"],
        "Sonic":         ["sonic"],
        "Dairy Queen":   ["dairy queen","dq"],

        // Online / Tech
        "Amazon":        ["amazon.com","amazon"],
        "Apple Store":   ["apple store","apple"],
        "eBay":          ["ebay"],
        "Etsy":          ["etsy"],
        "Newegg":        ["newegg"],

        // Services & Utilities
        "Netflix":       ["netflix"],
        "Spotify":       ["spotify"],
        "Hulu":          ["hulu"],
        "YouTube Premium":["youtube premium"],
        "Comcast":       ["comcast"],
        "Cox":           ["cox"],
        "Verizon":       ["verizon"],
        "AT&T":          ["att","a t & t"],
        "T-Mobile":      ["tmobile","t mobile"],

        // Travel & Transport
        "Uber":          ["uber"],
        "Lyft":          ["lyft"],
        "Amtrak":        ["amtrak"],
        "Delta Airlines":["delta"],
        "Southwest":     ["southwest"],
        "United Airlines":["united"],
        "Airbnb":        ["airbnb"],
        "Marriott":      ["marriott"],

        // Payments & Finance
        "Visa":          ["visa "],
        "Mastercard":    ["mastercard"],
        "PayPal":        ["paypal"],
        "Square":        ["square"],

        // Miscellaneous / Charity
        "REI":           ["rei"],
        "Charity":       ["donation","charity"]
    ]

    let lower = transcript.lowercased()
    // Vendor match
    for (vendor, keywords) in knownVendors {
        if keywords.contains(where: { lower.contains($0) }) {
            return vendor
        }
    }

    // 2. Keyword→Category fallback
    let fallback: [String:String] = [
        // Food & Drink
        "coffee":"Food", "breakfast":"Food", "lunch":"Food", "dinner":"Food",
        "pizza":"Food", "burger":"Food", "restaurant":"Food", "bar":"Food",
        "groceries":"Food", "fast food":"Food",

        // Transportation
        "taxi":"Transportation", "bus":"Transportation", "train":"Transportation",
        "gas":"Transportation", "fuel":"Transportation",

        // Utilities
        "electric":"Utilities", "water":"Utilities", "internet":"Utilities",
        "phone":"Utilities", "trash":"Utilities", "garbage":"Utilities",

        // Entertainment
        "movie":"Entertainment", "concert":"Entertainment", "game":"Entertainment",

        // Healthcare & Personal Care
        "gym":"Healthcare", "doctor":"Healthcare", "hospital":"Healthcare",
        "pharmacy":"Healthcare", "salon":"Personal Care","spa":"Personal Care",

        // Travel
        "hotel":"Travel", "flight":"Travel", "airbnb":"Travel",

        // Subscriptions
        "subscription":"Subscriptions", "membership":"Subscriptions"
    ]
    for (keyword, category) in fallback {
        if lower.contains(keyword) {
            return category
        }
    }

    // 3. Default
    return "Miscellaneous"
}


/// Maps transcript keywords to categories
private let categoryKeywords: [ExpenseCategory: [String]] = [
    .food: ["coffee", "breakfast", "lunch", "dinner", "pizza", "burger", "meal", "snack", "groceries"],
    .transportation: ["uber", "lyft", "taxi", "fuel", "gas", "bus", "train"],
    .subscriptions: ["netflix", "spotify", "subscription", "amazon prime", "hulu"],
    .entertainment: ["movie", "theater", "concert", "game"],
    .utilities: ["electric", "water", "internet", "phone", "utility", "utilities"],
    .housing: ["rent", "mortgage", "lease"],
    .healthcare: ["doctor", "pharmacy", "hospital", "clinic"],
    .personalCare: ["hair", "salon", "spa", "barber"],
    .education: ["tuition", "school", "course", "book"],
    .travel: ["hotel", "flight", "airbnb", "ticket"],
    .gifts: ["gift", "donation"],
    .insurance: ["insurance", "premium"],
    .debt: ["loan", "credit card", "debt"],
    .savings: ["savings", "deposit"]
]

/// Normalize transcript and pick category
func inferCategory(from transcript: String) -> ExpenseCategory {
    let lower = transcript.lowercased()
    for (category, keywords) in categoryKeywords {
        if keywords.contains(where: { lower.contains($0) }) {
            return category
        }
    }
    return .miscellaneous
}

// MARK: - Expense Parsing

func parseAmount(from transcript: String) -> Double? {
    let pattern = #"(?:(\$)?(\d{1,6})(?:[.,](\d{1,2}))?)"#
    let regex = try! NSRegularExpression(pattern: pattern)
    let ns = transcript as NSString
    guard let m = regex.firstMatch(in: transcript, range: NSRange(location: 0, length: ns.length)) else {
        return nil
    }
    let hasDollar = m.range(at: 1).location != NSNotFound
    let dStr = ns.substring(with: m.range(at: 2))
    let cStr = m.range(at: 3).location != NSNotFound ? ns.substring(with: m.range(at: 3)) : ""
    if hasDollar || !cStr.isEmpty {
        let full = cStr.isEmpty ? dStr : "\(dStr).\(cStr)"
        return Double(full)
    } else if let iv = Int(dStr) {
        return Double(iv) / 100
    }
    return nil
}

func parseVendor(from transcript: String) -> String {
    // rudimentary: first non-numeric token after amount
    let tokens = transcript.components(separatedBy: .whitespaces)
    return tokens.last ?? ""
}

func parseExpense(from transcript: String) -> Expense {
    let amountValue = parseAmount(from: transcript)
    let vendorOrCategory = parseVendorOrCategory(from: transcript)

    // Use the parsed string as vendor
    let vendor = vendorOrCategory

    // Map vendorOrCategory to ExpenseCategory
    let category: ExpenseCategory
    switch vendorOrCategory.lowercased() {
    case "7-eleven", "circle k", "wawa", "shell", "exxon":
        category = .transportation
    case "walmart", "target", "costco", "whole foods", "trader joe's":
        category = .food
    case "starbucks", "mcdonalds", "chipotle", "dunkin":
        category = .food
    case "uber", "lyft":
        category = .transportation
    case let text where text.contains("subscription"):
        category = .subscriptions
    default:
        category = .miscellaneous
    }

    let parsedAmount = amountValue ?? 0
    return Expense(
        amount: Decimal(parsedAmount),
        vendor: vendor,
        date: .now,
        category: category
    )
}

func extractAmountDecimal(from text: String) -> Decimal? {
    // Match "X dollars and Y cents"
    let dollarCentsPattern = #"(?:(\w+)[\s-]dollars?)?(?:\s*and\s*)?(\w+)[\s-]cents?"#
    if let match = text.matchGroups(for: dollarCentsPattern),
       match.count == 2 {
        let dollars = wordsToNumber(match[0])
        let cents = wordsToNumber(match[1])
        if let d = dollars, let c = cents {
            return Decimal(d) + Decimal(c) / 100
        }
    }
    
    // Match digit-like patterns: "420789" → 4207.89
    let digitPattern = #"\b\d{3,6}\b"#
    if let raw = text.firstMatch(for: digitPattern),
       let decimal = inferDecimal(from: raw) {
        return decimal
    }
    
    // Match word-based phrases: "twenty five dollars"
    let fallbackPattern = #"((?:\w+\s?)+)(dollars?|bucks?)"#
    if let match = text.matchGroups(for: fallbackPattern)?.first,
       let value = wordsToNumber(match.trimmingCharacters(in: .whitespaces)) {
        return Decimal(value)
    }
    
    return nil
}

func extractVendor(from text: String) -> String? {
    let knownWords = ["spent", "grabbed", "dropped", "paid", "on", "for", "at", "the", "a", "and", "dollars", "bucks", "cents"]
    let tokens = text.components(separatedBy: .whitespacesAndNewlines)
        .filter { !knownWords.contains($0) }
    
    for word in tokens.reversed() {
        if !CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: word)) {
            return word
        }
    }
    
    return nil
}

func wordsToNumber(_ input: String) -> Int? {
    let numberWords: [String: Int] = [
        "zero": 0, "one": 1, "two": 2, "three": 3, "four": 4,
        "five": 5, "six": 6, "seven": 7, "eight": 8, "nine": 9,
        "ten": 10, "eleven": 11, "twelve": 12, "thirteen": 13,
        "fourteen": 14, "fifteen": 15, "sixteen": 16, "seventeen": 17,
        "eighteen": 18, "nineteen": 19, "twenty": 20, "thirty": 30,
        "forty": 40, "fifty": 50, "sixty": 60, "seventy": 70,
        "eighty": 80, "ninety": 90
    ]
    
    var total = 0
    let words = input.lowercased().split(separator: " ")
    
    for word in words {
        if let val = numberWords[String(word)] {
            total += val
        }
    }
    
    return total > 0 ? total : nil
}

func inferDecimal(from raw: String) -> Decimal? {
    guard let number = Int(raw) else { return nil }
    
    switch raw.count {
    case 3: return Decimal(number) / 10
    case 4, 5, 6: return Decimal(number) / 100
    default: return nil
    }
}


//MARK: - Extensions
extension String {
    func matchGroups(for regex: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: regex) else { return nil }
        guard let match = regex.firstMatch(in: self, range: NSRange(startIndex..., in: self)) else { return nil }
        
        return (1..<match.numberOfRanges).compactMap {
            Range(match.range(at: $0), in: self).map { String(self[$0]) }
        }
    }
    
    func firstMatch(for pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        guard let match = regex.firstMatch(in: self, range: NSRange(startIndex..., in: self)) else { return nil }
        if let range = Range(match.range, in: self) {
            return String(self[range])
        }
        return nil
    }
}

extension DateFormatter {
    static let monthAndYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
}
