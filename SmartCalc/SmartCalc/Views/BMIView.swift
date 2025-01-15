import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct BMIView: View {
    @State private var height: String = ""
    @State private var weight: String = ""
    @State private var age: String = ""  // New state for age
    @State private var bmiResult: String = ""
    @State private var bmiCategory: String = ""  // BMI category (Underweight, Normal, Overweight, Obese)
    @State private var bmiRecords: [BMRecord] = []
    @State private var showAlert = false
    @State private var comparisonMessage: String = ""
    @State private var tips: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("BMI Calculator")
                .font(.largeTitle)
                .fontWeight(.bold)

            TextField("Enter Height (m)", text: $height)
                .keyboardType(.decimalPad)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)

            TextField("Enter Weight (kg)", text: $weight)
                .keyboardType(.decimalPad)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)

            TextField("Enter Age", text: $age)
                .keyboardType(.decimalPad)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)

            Button(action: calculateBMI) {
                Text("Calculate")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(10)
            }

            if !bmiResult.isEmpty {
                Text("Your BMI: \(bmiResult) - \(bmiCategory)")
                    .font(.title2)
                    .padding(.top, 10)
            }

            Text(comparisonMessage)
                .padding(.top, 10)
                .foregroundColor(comparisonMessage.contains("better") ? .green : .red)
                .font(.headline)

            Text(tips)
                .padding(.top, 10)
                .font(.subheadline)

            List(bmiRecords) { record in
                VStack(alignment: .leading) {
                    Text("BMI: \(String(format: "%.2f", record.bmi))")
                    Text("Category: \(record.bmiCategory)")
                    Text("Date: \(record.timestamp.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Spacer()
        }
        .padding()
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Saved"), message: Text("Information Updated"), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            fetchBMIData() // Automatically fetch data when BMIView appears
        }
    }

    func calculateBMI() {
        guard let height = Double(height), let weight = Double(weight), let age = Int(age) else {
            bmiResult = "Invalid input"
            bmiCategory = ""
            return
        }

        // BMI calculation
        let bmi = weight / (height * height)
        bmiResult = String(format: "%.2f", bmi)

        // Determine BMI category based on BMI value
        bmiCategory = getBMICategory(bmi)

        // Update the data in Firestore
        saveBMIToFirestore(age: age, height: height, weight: weight, bmi: bmi)

        // Compare new BMI with previous
        compareBMIs(newBmi: bmi)
    }

    func getBMICategory(_ bmi: Double) -> String {
        switch bmi {
        case ..<18.5:
            return "Underweight"
        case 18.5..<24.9:
            return "Normal"
        case 25..<29.9:
            return "Overweight"
        default:
            return "Obese"
        }
    }

    func saveBMIToFirestore(age: Int, height: Double, weight: Double, bmi: Double) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user is signed in")
            return
        }

        let db = Firestore.firestore()

        // Check if the user already has a BMI record
        db.collection("users").document(userID).collection("bmiRecords").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching BMI records: \(error.localizedDescription)")
                return
            }

            if let document = snapshot?.documents.first {
                // If a BMI record exists, update it
                db.collection("users").document(userID).collection("bmiRecords").document(document.documentID).updateData([
                    "age": age,
                    "height": height,
                    "weight": weight,
                    "bmi": bmi,
                    "bmiCategory": getBMICategory(bmi),
                    "timestamp": Date()
                ]) { error in
                    if let error = error {
                        print("Error updating BMI data: \(error.localizedDescription)")
                    } else {
                        print("BMI data updated successfully!")
                        showAlert = true
                    }
                }
            } else {
                // If no BMI record exists, create a new one
                let bmiData: [String: Any] = [
                    "age": age,
                    "height": height,
                    "weight": weight,
                    "bmi": bmi,
                    "bmiCategory": getBMICategory(bmi),
                    "timestamp": Date()
                ]
                db.collection("users").document(userID).collection("bmiRecords").addDocument(data: bmiData) { error in
                    if let error = error {
                        print("Error saving BMI data: \(error.localizedDescription)")
                    } else {
                        print("BMI data saved successfully!")
                        showAlert = true
                    }
                }
            }
        }
    }

    func fetchBMIData() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user is signed in")
            return
        }

        let db = Firestore.firestore()
        db.collection("users").document(userID).collection("bmiRecords").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching BMI records: \(error.localizedDescription)")
            } else {
                // Map the documents to BMRecord
                self.bmiRecords = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    if let bmi = data["bmi"] as? Double,
                       let bmiCategory = data["bmiCategory"] as? String,
                       let timestamp = data["timestamp"] as? Timestamp {
                        return BMRecord(id: doc.documentID, bmi: bmi, bmiCategory: bmiCategory, timestamp: timestamp.dateValue())
                    }
                    return nil
                } ?? []
            }
        }
    }

    func compareBMIs(newBmi: Double) {
        if let lastBmiRecord = bmiRecords.last {
            let previousBmi = lastBmiRecord.bmi
            let previousCategory = lastBmiRecord.bmiCategory
            if previousCategory != getBMICategory(newBmi) {
                comparisonMessage = "Your BMI category has changed from \(previousCategory) to \(getBMICategory(newBmi))."
                tips = "Consider making adjustments to your lifestyle based on your new BMI category."
            } else {
                if newBmi < previousBmi {
                    comparisonMessage = "Your BMI has improved within the \(previousCategory) category compared to your previous record."
                    tips = "Keep up the good work by maintaining a balanced diet and regular exercise."
                } else if newBmi > previousBmi {
                    comparisonMessage = "Your BMI has worsened within the \(previousCategory) category compared to your previous record."
                    tips = "Consider reviewing your diet and increasing physical activity to improve your BMI."
                } else {
                    comparisonMessage = "Your BMI is the same as your previous record within the \(previousCategory) category."
                    tips = "Great! You are maintaining a healthy lifestyle. Continue to monitor your BMI regularly."
                }
            }
        } else {
            comparisonMessage = "No previous BMI records found."
            tips = "Start tracking your BMI to monitor your health over time."
        }
    }
}

// Define a custom struct to represent a BMI record
struct BMRecord: Identifiable, Hashable {
    var id: String
    var bmi: Double
    var bmiCategory: String
    var timestamp: Date
}
