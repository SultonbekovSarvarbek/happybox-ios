import SwiftUI

extension PurchaseRequest {
    var statusColor: Color {
        if isPaid && isRedeemed { return .secondary }
        if isPaid && isTransferred { return .purple }
        switch (status?.value ?? "").uppercased() {
        case "PAID":      return .green
        case "CANCELLED": return .red
        default:          return .orange
        }
    }
}
