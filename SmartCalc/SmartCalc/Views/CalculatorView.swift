import SwiftUI
import FirebaseAuth

struct CalculatorView: View {
    @State private var inputSequence: String = "" // Keeps track of all inputs
    @State private var displayResult: String = "0" // Displays the calculated result
    @State private var isTypingNewNumber: Bool = true

    @AppStorage("uid") var userID: String = ""
    @State private var showBMIView = false
    @State private var showConverterView = false

    let buttons = [
        ["AC", "%", "<-", "÷"],
        ["7", "8", "9", "×"],
        ["4", "5", "6", "−"],
        ["1", "2", "3", "+"],
        ["(", ")", "0", "="]
    ]

    let scientificButtons = [
        ["sin", "cos", "tan", "√"],
        ["log", "ln", "π"]
    ]

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Button(action: {
                    let firebaseAuth = Auth.auth()
                    do {
                        try firebaseAuth.signOut()
                        withAnimation {
                            userID = ""
                        }
                    } catch let signOutError {
                        print("Error signing out: \(signOutError)")
                    }
                }) {
                    Text("Sign Out")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color(red: 1.0, green: 0.27, blue: 0.0))
                        .cornerRadius(10)
                }

                Spacer()

                Button(action: {
                    showBMIView = true
                }) {
                    Text("BMI")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                }
                .sheet(isPresented: $showBMIView) {
                    BMIView()
                }

                Spacer()

                Button(action: {
                    showConverterView = true
                }) {
                    Text("Converter")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                }
                .sheet(isPresented: $showConverterView) {
                    ConverterView()
                }
            }
            .padding()

            Spacer()

            // Display input sequence
            Text(inputSequence)
                .font(.title)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding()
                .background(Color.black.opacity(0.1))

            // Display calculated result
            Text("= \(displayResult)")
                .font(.largeTitle)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding()
                .foregroundColor(.orange)

            VStack(spacing: 10) {
                ForEach(scientificButtons, id: \.self) { row in
                    HStack(spacing: 10) {
                        ForEach(row, id: \.self) { button in
                            Button(action: {
                                scientificButtonTapped(button)
                            }) {
                                Text(button)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .frame(width: 70, height: 70)
                                    .background(Color.gray)
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                            }
                        }
                    }
                }

                ForEach(buttons, id: \.self) { row in
                    HStack(spacing: 10) {
                        ForEach(row, id: \.self) { button in
                            Button(action: {
                                buttonTapped(button)
                            }) {
                                Text(button)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .frame(width: 70, height: 70)
                                    .background(Color.black)
                                    .foregroundColor(.white)
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
            inputSequence = ""
            displayResult = "0"
            isTypingNewNumber = true

        case "<-":
            if !inputSequence.isEmpty {
                inputSequence.removeLast()
            }

        case "%":
            if let value = Double(inputSequence) {
                displayResult = formatResult(value / 100)
                inputSequence = displayResult
            }

        case "÷", "×", "−", "+":
            if inputSequence.isEmpty || (inputSequence.last?.isWhitespace ?? true) {
                return // Prevent consecutive operators
            }
            inputSequence += " \(button) "

        case "=":
            calculateResult()

        case "(", ")":
            inputSequence += button

        case ".":
            if !inputSequence.contains(".") {
                inputSequence += button
            }

        default:
            inputSequence += button
        }
    }

    func scientificButtonTapped(_ button: String) {
        if button == "π" {
            inputSequence += "\(Double.pi)"
            displayResult = formatResult(Double.pi)
            return
        }

        inputSequence += "\(button)("
    }

    func calculateResult() {
        var formattedEquation = inputSequence
            .replacingOccurrences(of: "÷", with: "/")
            .replacingOccurrences(of: "×", with: "*")
            .replacingOccurrences(of: "−", with: "-")
            .replacingOccurrences(of: "π", with: "\(Double.pi)")
        
        // Check for unbalanced parentheses
        if !isBalancedParentheses(formattedEquation) {
            displayResult = "Error: Unbalanced parentheses"
            return
        }
        
        formattedEquation = evaluateScientificFunctions(in: formattedEquation)

        let expression = NSExpression(format: formattedEquation)

        if let result = expression.expressionValue(with: nil, context: nil) as? Double {
            displayResult = formatResult(result)
        } else {
            displayResult = "Error"
        }
    }

    func isBalancedParentheses(_ expression: String) -> Bool {
        var stack: [Character] = []
        
        for char in expression {
            if char == "(" {
                stack.append(char)
            } else if char == ")" {
                if stack.isEmpty || stack.last != "(" {
                    return false
                }
                stack.removeLast()
            }
        }
        
        return stack.isEmpty
    }

    func evaluateScientificFunctions(in expression: String) -> String {
        var result = expression

        let functions = ["sin", "cos", "tan", "√", "log", "ln"]
        for function in functions {
            while let range = result.range(of: "\(function)\\([0-9\\.]+\\)", options: .regularExpression) {
                let match = String(result[range])
                if let number = Double(match.replacingOccurrences(of: "\(function)(", with: "").replacingOccurrences(of: ")", with: "")) {
                    let value: Double
                    switch function {
                    case "sin": value = sin(number * .pi / 180)
                    case "cos": value = cos(number * .pi / 180)
                    case "tan": value = tan(number * .pi / 180)
                    case "√": value = sqrt(number)
                    case "log": value = log10(number)
                    case "ln": value = log(number)
                    default: value = 0
                    }
                    result = result.replacingOccurrences(of: match, with: "\(value)")
                } else {
                    displayResult = "Error: Invalid function"
                    return "Error"
                }
            }
        }
        return result
    }

    func formatResult(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(value))
        }
        return String(value)
    }
}
