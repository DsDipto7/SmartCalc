import SwiftUI

struct CalculatorView: View {
    @State private var display: String = "0"
    @State private var firstNumber: Double? = nil
    @State private var currentOperation: String? = nil

    let buttons = [
        ["AC", "%", "<-", "÷"],
        ["7", "8", "9", "×"],
        ["4", "5", "6", "−"],
        ["1", "2", "3", "+"],
        ["00", "0", ".", "="]
    ]

    var body: some View {
        VStack(spacing: 10) {
            Spacer()
           
            // Display
            Text(display)
                .font(.largeTitle)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding()
                .background(Color.black.opacity(0.1))

            // Buttons Grid
            VStack(spacing: 10) {
                ForEach(buttons, id: \.self) { row in
                    HStack(spacing: 10) {
                        ForEach(row, id: \.self) { button in
                            Button(action: {
                                self.buttonTapped(button)
                            }) {
                                Text(button)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .frame(width: 70, height: 70) // Fixed width for all buttons
                                    .background(Color.black)
                                    .foregroundColor(Color.white)
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
            }
        }
        .padding()
    }

    func buttonTapped(_ button: String) {
        switch button {
        case "AC":
            display = "0"
            firstNumber = nil
            currentOperation = nil
        case "<-":
            if !display.isEmpty {
                display.removeLast()
                if display.isEmpty { display = "0" }
            }
        case "%":
            if let number = Double(display) {
                display = String(number / 100)
            }
        case "÷", "×", "−", "+":
            firstNumber = Double(display)
            currentOperation = button
            display = "0"
        case "=":
            if let first = firstNumber, let second = Double(display), let operation = currentOperation {
                display = performOperation(first, second, operation)
                firstNumber = nil
                currentOperation = nil
            }
        case ".":
            if !display.contains(".") {
                display += "."
            }
        default:
            if display == "0" {
                display = button
            } else {
                display += button
            }
        }
    }

    func performOperation(_ first: Double, _ second: Double, _ operation: String) -> String {
        switch operation {
        case "÷": return second == 0 ? "Error" : String(first / second)
        case "×": return String(first * second)
        case "−": return String(first - second)
        case "+": return String(first + second)
        default: return "0"
        }
    }
}

#Preview {
    CalculatorView()
}
