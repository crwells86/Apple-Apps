import SwiftUI
import PDFKit

struct InvoiceExportView: View {
    let job: Job
    let shifts: [WorkShift]
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var startDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var endDate: Date = Date()
    @State private var pdfURL: URL?
    
    var filteredShifts: [WorkShift] {
        shifts
            .filter { $0.job.id == job.id }
            .filter { shift in
                shift.startTime >= startDate && shift.startTime <= endDate
            }
            .sorted { $0.startTime < $1.startTime }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Date Range") {
                    DatePicker("Start", selection: $startDate, displayedComponents: [.date])
                    DatePicker("End", selection: $endDate, displayedComponents: [.date])
                }
                
                Section("Summary") {
                    Text("Shifts: \(filteredShifts.count)")
                    Text("Total Time: \(timeString(from: totalWorked))")
                    Text("Earnings: \(formattedCurrency(totalEarnings))")
                }
                
                if let url = pdfURL {
                    Section {
                        ShareLink(item: url, preview: SharePreview("Invoice for \(job.title)", image: Image(systemName: "doc.richtext"))) {
                            Text("Share PDF")
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("Export Invoice")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Generate PDF") {
                        generatePDF()
                    }
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    var totalWorked: TimeInterval {
        filteredShifts.reduce(0) { $0 + $1.totalWorked }
    }
    
    var totalEarnings: Decimal {
        let hours = totalWorked / 3600
        return Decimal(hours) * job.hourlyRate
    }
    
    func formattedCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(for: value) ?? "$0.00"
    }
    
    func timeString(from interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return String(format: "%dh %02dm", hours, minutes)
    }
    
    func generatePDF() {
        let renderer = InvoicePDFRenderer(job: job, shifts: filteredShifts, startDate: startDate, endDate: endDate)
        if let data = renderer.render() {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("Invoice-\(UUID().uuidString).pdf")
            try? data.write(to: url)
            self.pdfURL = url
        }
    }
}


import Foundation
import UIKit
import PDFKit

struct InvoicePDFRenderer {
    let job: Job
    let shifts: [WorkShift]
    let startDate: Date
    let endDate: Date
    
    func render() -> Data? {
        let format = UIGraphicsPDFRendererFormat()
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        return renderer.pdfData { context in
            context.beginPage()
            let margin: CGFloat = 40
            var y = margin
            
            let titleFont = UIFont.boldSystemFont(ofSize: 24)
            let sectionHeaderFont = UIFont.boldSystemFont(ofSize: 16)
            let bodyFont = UIFont.systemFont(ofSize: 14)
            let monoFont = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            
            // Title
            let title = "Invoice for \(job.title)"
            drawText(title, font: titleFont, at: CGPoint(x: margin, y: y))
            y += 36
            
            // Date Range
            drawText("Date Range: \(dateFormatter.string(from: startDate)) – \(dateFormatter.string(from: endDate))", font: bodyFont, at: CGPoint(x: margin, y: y))
            y += 24
            
            // Job Metadata
            if let company = job.company {
                drawText("Company: \(company)", font: bodyFont, at: CGPoint(x: margin, y: y))
                y += 20
            }
            
            let totalTime = shifts.reduce(0) { $0 + $1.totalWorked }
            let hours = totalTime / 3600
            let totalEarned = Decimal(hours) * job.hourlyRate
            
            drawText("Shifts Worked: \(shifts.count)", font: bodyFont, at: CGPoint(x: margin, y: y))
            y += 18
            
            drawText("Total Time: \(Int(hours))h", font: bodyFont, at: CGPoint(x: margin, y: y))
            y += 18
            
            drawText("Total Earned: \(currencyString(totalEarned))", font: bodyFont, at: CGPoint(x: margin, y: y))
            y += 30
            
            // Section Header
            drawText("Shift Breakdown", font: sectionHeaderFont, at: CGPoint(x: margin, y: y))
            y += 24
            
            // Table Headers
            drawText("Date", font: monoFont, at: CGPoint(x: margin, y: y))
            drawText("Duration", font: monoFont, at: CGPoint(x: margin + 200, y: y))
            drawText("Earnings", font: monoFont, at: CGPoint(x: margin + 300, y: y))
            y += 16
            drawLine(from: CGPoint(x: margin, y: y), to: CGPoint(x: pageRect.width - margin, y: y))
            y += 10
            
            for shift in shifts {
                //                guard y < pageRect.height - 60 else {
                //                    context.beginPage()
                //                    y = margin
                //                }
                guard y < pageRect.height - 40 else {
                    context.beginPage()
                    return y = 40
                }
                
                let date = dateFormatter.string(from: shift.startTime)
                let duration = timeString(from: shift.totalWorked)
                let earnings = currencyString(Decimal(shift.totalWorked / 3600) * job.hourlyRate)
                
                drawText(date, font: monoFont, at: CGPoint(x: margin, y: y))
                drawText(duration, font: monoFont, at: CGPoint(x: margin + 200, y: y))
                drawText(earnings, font: monoFont, at: CGPoint(x: margin + 300, y: y))
                y += 18
            }
        }
    }
    
    private func drawText(_ text: String, font: UIFont, at point: CGPoint) {
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        text.draw(at: point, withAttributes: attrs)
    }
    
    private func drawLine(from start: CGPoint, to end: CGPoint) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()
        context.setStrokeColor(UIColor.lightGray.cgColor)
        context.setLineWidth(1)
        context.move(to: start)
        context.addLine(to: end)
        context.strokePath()
        context.restoreGState()
    }
    
    private func timeString(from interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
    
    private func currencyString(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(for: value) ?? "$0.00"
    }
}
