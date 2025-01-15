import SwiftUI

struct ConverterView: View {
    @State private var inputValue: String = ""
    @State private var fromUnit: String = "pound"
    @State private var toUnit: String = "kilogram"
    @State private var convertedValue: String = "Enter values to see result"
    @State private var selectedType: String = "weight"
    
    let categories = ["weight", "length", "temperature", "volume", "speed", "area"]
    let units = [
        "weight": ["pound", "kilogram", "ounce", "gram"],
        "length": ["meter", "kilometer", "mile", "foot", "inch"],
        "temperature": ["celsius", "fahrenheit", "kelvin"],
        "volume": ["liter", "milliliter", "cubic_meter", "gallon"],
        "speed": ["meter_per_second", "kilometer_per_hour", "mile_per_hour"],
        "area": ["square_meter", "square_kilometer", "acre", "hectare"]
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Unit Converter")
                .font(.largeTitle)
                .bold()
            
            // Dropdown for selecting category
            Picker("Select Type", selection: $selectedType) {
                ForEach(categories, id: \.self) { category in
                    Text(category.capitalized)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding(.horizontal)
            .onChange(of: selectedType) { _ in
                // Reset units when category changes
                fromUnit = units[selectedType]?.first ?? ""
                toUnit = units[selectedType]?.last ?? ""
            }
            
            // Dropdown for selecting from and to units
            HStack {
                Picker("From Unit", selection: $fromUnit) {
                    ForEach(units[selectedType] ?? [], id: \.self) { unit in
                        Text(unit.capitalized)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                Text("to")
                
                Picker("To Unit", selection: $toUnit) {
                    ForEach(units[selectedType] ?? [], id: \.self) { unit in
                        Text(unit.capitalized)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            .padding(.horizontal)
            
            // TextField for input value
            TextField("Enter Value", text: $inputValue)
                .keyboardType(.decimalPad)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .padding(.horizontal)
            
            // Convert button
            Button(action: {
                convert()
            }) {
                Text("Convert")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(10)
            }
            
            // Result display
            Text("Converted Value: \(convertedValue)")
                .font(.headline)
                .padding()
        }
        .padding()
    }
    
    func convert() {
        guard let value = Double(inputValue) else {
            convertedValue = "Invalid input"
            return
        }
        
        UnitConverterAPI.convert(type: selectedType, fromUnit: fromUnit, toUnit: toUnit, fromValue: value) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let result):
                    if let validResult = result {
                        convertedValue = String(format: "%.4f", validResult)
                    } else {
                        convertedValue = "Conversion failed: No result"
                    }
                case .failure(let error):
                    convertedValue = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
}
