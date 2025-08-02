import SwiftUI
import SwiftData
import Charts

// MARK: - Models

@Model
final class Book {
    var title: String
    var author: String
    var isPartOfSeries: Bool
    var seriesName: String?
    var seriesNumber: Int?
    var reads: [Read]
    
    init(title: String,
         author: String,
         isPartOfSeries: Bool = false,
         seriesName: String? = nil,
         seriesNumber: Int? = nil,
         reads: [Read] = []) {
        self.title = title
        self.author = author
        self.isPartOfSeries = isPartOfSeries
        self.seriesName = seriesName
        self.seriesNumber = seriesNumber
        self.reads = reads
    }
    
    var currentRead: Read? {
        reads.sorted { $0.startDate > $1.startDate }.first { $0.endDate == nil }
    }
    
    var isCurrentlyReading: Bool {
        currentRead != nil
    }
    
    var rereadCount: Int {
        reads.count
    }
}

@Model
final class Read {
    var startDate: Date
    var endDate: Date?
    var rating: Int?
    var notes: String
    var readingLog: [Date]
    
    init(startDate: Date = .now,
         endDate: Date? = nil,
         rating: Int? = nil,
         notes: String = "",
         readingLog: [Date] = []) {
        self.startDate = startDate
        self.endDate = endDate
        self.rating = rating
        self.notes = notes
        self.readingLog = readingLog
    }
}

// MARK: - Views

struct ContentView: View {
    var body: some View {
        TabView {
            BookListView()
                .tabItem {
                    Label("List", systemImage: "books.vertical")
                }
            
            ChartsView()
                .tabItem {
                    Label("Charts", systemImage: "chart.bar.xaxis")
                }
        }
    }
}

#Preview {
    ContentView()
}

// MARK: - Book List View

struct BookListView: View {
    @Environment(\.modelContext) private var context
    @Query private var books: [Book]
    
    enum Filter: String, CaseIterable {
        case current = "Currently Reading"
        case past = "Read Books"
        case tbr = "TBR"
    }
    
    @State private var selectedFilter: Filter = .current
    @State private var showingAddBook = false
    
    var filteredBooks: [Book] {
        books.filter { book in
            switch selectedFilter {
            case .current:
                return book.isCurrentlyReading
            case .past:
                return !book.isCurrentlyReading && !book.reads.isEmpty
            case .tbr:
                return book.reads.isEmpty
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(Filter.allCases, id: \.self) {
                        Text($0.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                List(filteredBooks) { book in
                    NavigationLink(value: book) {
                        VStack(alignment: .leading) {
                            Text(book.title).font(.headline)
                            Text("by \(book.author)").font(.subheadline)
                        }
                    }
                }
            }
            .navigationTitle("Books")
            .navigationDestination(for: Book.self) { book in
                BookDetailView(book: book)
            }
            .toolbar {
                Button("Add Book") {
                    showingAddBook = true
                }
            }
            .sheet(isPresented: $showingAddBook) {
                AddBookView()
            }
        }
    }
}

// MARK: - Add Book View

struct AddBookView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var title = ""
    @State private var author = ""
    @State private var isSeries = false
    @State private var seriesName = ""
    @State private var seriesNumber: Int?
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                TextField("Author", text: $author)
                Toggle("Part of a Series", isOn: $isSeries)
                if isSeries {
                    TextField("Series Name", text: $seriesName)
                    TextField("Series Number", value: $seriesNumber, formatter: NumberFormatter())
                }
            }
            .navigationTitle("New Book")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newBook = Book(title: title, author: author, isPartOfSeries: isSeries, seriesName: seriesName.isEmpty ? nil : seriesName, seriesNumber: seriesNumber)
                        context.insert(newBook)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Book Detail View

struct BookDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var book: Book
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(book.title).font(.title).bold()
                        Text("by \(book.author)").font(.headline)
                        if book.isPartOfSeries, let name = book.seriesName, let number = book.seriesNumber {
                            Text("Series: \(name) #\(number)").font(.subheadline).foregroundColor(.secondary)
                        }
                        Text("Read \(book.rereadCount) time\(book.rereadCount > 1 ? "s" : "")")
                            .font(.subheadline)
                    }
                    Spacer()
                    ShareLink(item: "I'm reading \(book.title) by \(book.author)!") {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .labelStyle(.iconOnly)
                            .font(.title2)
                            .padding(8)
                    }
                }
                
                if let currentRead = book.currentRead {
                    Button("Mark Today as Read") {
                        if !currentRead.readingLog.contains(where: { Calendar.current.isDateInToday($0) }) {
                            currentRead.readingLog.append(Date())
                        }
                    }
                    Button("Mark as Complete") {
                        currentRead.endDate = Date()
                    }
                } else {
                    Button("Start Reread") {
                        book.reads.append(Read())
                    }
                }
                
                ChartView(reads: book.reads)
                
                Divider()
                
                ForEach(book.reads.sorted(by: { $0.startDate > $1.startDate })) { read in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Started: \(read.startDate.formatted(date: .abbreviated, time: .omitted))")
                        if let end = read.endDate {
                            Text("Finished: \(end.formatted(date: .abbreviated, time: .omitted))")
                        }
                        if let rating = read.rating {
                            Text("Rating: \(rating)/5")
                        }
                        if !read.notes.isEmpty {
                            Text("Notes: \(read.notes)")
                        }
                        if !read.readingLog.isEmpty {
                            Text("Reading Days: \(read.readingLog.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Divider()
                }
            }
            .padding()
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Chart View

struct ReadingActivity: Identifiable {
    let date: Date
    let count: Int
    var id: Date { date }
}

struct ChartView: View {
    let reads: [Read]
    
    var body: some View {
        let activities = readingData(from: reads)
        let grid = Calendar.current.generateFullHeatmapGrid(start: activities.first?.date, end: activities.last?.date)
        
        VStack(alignment: .leading, spacing: 4) {
            ForEach(grid, id: \.self) { week in
                HStack(spacing: 4) {
                    ForEach(week, id: \.self) { date in
                        let count = activities.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) })?.count ?? 0
                        RoundedRectangle(cornerRadius: 2)
                            .fill(count > 0 ? Color.blue : Color(.systemGray5))
                            .frame(width: 12, height: 12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(Color(.systemGray3), lineWidth: 0.5)
                            )
                            .accessibilityLabel(Text("\(date.formatted(date: .abbreviated, time: .omitted)): \(count) reads"))
                    }
                }
            }
        }
        .padding()
    }
    
    func readingData(from reads: [Read]) -> [ReadingActivity] {
        let allDates = reads.flatMap { $0.readingLog }
        let grouped = Dictionary(grouping: allDates) { Calendar.current.startOfDay(for: $0) }
        return grouped.map { ReadingActivity(date: $0.key, count: $0.value.count) }
            .sorted { $0.date < $1.date }
    }
}

// MARK: - Charts View

struct ChartsView: View {
    @Query private var books: [Book]
    @State private var selectedSeries: String = "All"
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("Filter by Series", selection: $selectedSeries) {
                    Text("All").tag("All")
                    ForEach(seriesList(), id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.menu)
                .padding()
                
                let reads = filteredReads()
                if reads.isEmpty {
                    ContentUnavailableView("No Reading Data", systemImage: "book")
                } else {
                    ChartView(reads: reads)
                }
            }
            .navigationTitle("Reading Charts")
        }
    }
    
    func filteredReads() -> [Read] {
        if selectedSeries == "All" {
            return books.flatMap { $0.reads }
        } else {
            return books.filter { $0.seriesName == selectedSeries }.flatMap { $0.reads }
        }
    }
    
    func seriesList() -> [String] {
        Array(Set(books.compactMap { $0.seriesName })).sorted()
    }
}

// MARK: - Calendar Utility

extension Calendar {
    func generateFullHeatmapGrid(start: Date?, end: Date?) -> [[Date]] {
        guard let start = start, let end = end else {
            // Default grid: past 8 weeks
            let today = startOfDay(for: Date())
            let earliest = date(byAdding: .day, value: -56, to: today)!
            return generateWeeks(from: earliest, to: today)
        }
        
        let paddedStart = startOfDay(for: start)
        let paddedEnd = startOfDay(for: end)
        return generateWeeks(from: paddedStart, to: paddedEnd)
    }
    
    private func generateWeeks(from start: Date, to end: Date) -> [[Date]] {
        var allDates: [Date] = []
        var date = start
        
        while date <= end {
            allDates.append(date)
            date = date.addingTimeInterval(86400) // add one day
        }
        
        return stride(from: 0, to: allDates.count, by: 7).map {
            Array(allDates[$0..<min($0 + 7, allDates.count)])
        }
    }
}
