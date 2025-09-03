//
//  SettingsComponents.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import SwiftUI

// MARK: - Settings Group Container

struct SettingsGroup<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

// MARK: - Settings Toggle

struct SettingsToggle: View {
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool
    @FocusState private var isFocused: Bool
    
    init(title: String, subtitle: String? = nil, isOn: Binding<Bool>) {
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
    }
    
    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
                
                Toggle("", isOn: $isOn)
                    #if !os(tvOS)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    #endif
                    .labelsHidden()
                    .allowsHitTesting(false)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isFocused ? Color.white.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isFocused ? Color.green : Color.clear, lineWidth: isFocused ? 1 : 0)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Settings Picker

struct SettingsPicker<T: CaseIterable & Hashable & RawRepresentable>: View where T.RawValue == String, T: CustomStringConvertible {
    let title: String
    @Binding var selection: T
    let options: [T]
    @FocusState private var isFocused: Bool
    @State private var showingPicker = false
    
    var body: some View {
        Button {
            showingPicker = true
        } label: {
            HStack(spacing: 16) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(selection.description)
                    .font(.body)
                    .foregroundColor(.blue)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isFocused ? Color.white.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isFocused ? Color.green : Color.clear, lineWidth: isFocused ? 1 : 0)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .sheet(isPresented: $showingPicker) {
            PickerSheet(title: title, selection: $selection, options: options)
        }
    }
}

// MARK: - Settings Slider

struct SettingsSlider: View {
    let title: String
    let subtitle: String?
    @Binding var value: Double
    let range: ClosedRange<Double>
    let format: SliderFormat
    @FocusState private var isFocused: Bool
    
    enum SliderFormat {
        case percent
        case currency
        case number
        case minutes
        case megabytes
        
        func format(_ value: Double) -> String {
            switch self {
            case .percent:
                return (value).formatted(.percent.precision(.fractionLength(1)))
            case .currency:
                return Decimal(value).formatted(.currency(code: "USD"))
            case .number:
                return value.formatted(.number.precision(.fractionLength(0)))
            case .minutes:
                let minutes = Int(value)
                return minutes == 1 ? "1 minute" : "\(minutes) minutes"
            case .megabytes:
                return "\(Int(value)) MB"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                Text(format.format(value))
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
            
            #if os(tvOS)
            // tvOS doesn't support Slider - use a simple stepper or value display
            HStack {
                Text("Value: \(value, specifier: "%.2f")")
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("-") { 
                    value = max(range.lowerBound, value - 0.1) 
                }
                .foregroundColor(.blue)
                
                Button("+") { 
                    value = min(range.upperBound, value + 0.1) 
                }
                .foregroundColor(.blue)
            }
            .focused($isFocused)
            #else
            Slider(value: $value, in: range)
                .tint(.blue)
                .focused($isFocused)
            #endif
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isFocused ? Color.white.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isFocused ? Color.green : Color.clear, lineWidth: isFocused ? 1 : 0)
        )
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Settings Text Field

struct SettingsTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.body)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.1))
                        .stroke(isFocused ? Color.blue : Color.clear, lineWidth: 1)
                )
                .focused($isFocused)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Settings Numeric Field

struct SettingsNumericField: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Spacer()
            
            TextField("", value: $value, format: .number)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.body)
                .foregroundColor(.blue)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .stroke(isFocused ? Color.blue : Color.clear, lineWidth: 1)
                )
                .focused($isFocused)
                .onChange(of: value) { newValue in
                    value = max(range.lowerBound, min(range.upperBound, newValue))
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Settings Button

struct SettingsButton: View {
    let title: String
    let subtitle: String?
    let systemImage: String?
    let action: () -> Void
    @FocusState private var isFocused: Bool
    
    init(title: String, subtitle: String? = nil, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .font(.body)
                        .foregroundColor(.blue)
                        .frame(width: 20)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isFocused ? Color.white.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isFocused ? Color.green : Color.clear, lineWidth: isFocused ? 1 : 0)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Settings Read-Only Row

struct SettingsReadOnlyRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Picker Sheet

struct PickerSheet<T: CaseIterable & Hashable & RawRepresentable>: View where T.RawValue == String, T: CustomStringConvertible {
    let title: String
    @Binding var selection: T
    let options: [T]
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedOption: T?
    
    var body: some View {
        TVNavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
                .padding(.horizontal, 60)
                .padding(.vertical, 20)
                .background(Color.white.opacity(0.05))
                
                // Options List
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 8) {
                        ForEach(Array(options.enumerated()), id: \.element) { index, option in
                            PickerOptionRow(
                                option: option,
                                isSelected: option == selection,
                                isFocused: focusedOption == option
                            ) {
                                selection = option
                            }
                            .focused($focusedOption, equals: option)
                        }
                    }
                    .padding(.vertical, 30)
                }
                .padding(.horizontal, 60)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedOption = selection
            }
        }
    }
}

struct PickerOptionRow<T: CustomStringConvertible>: View {
    let option: T
    let isSelected: Bool
    let isFocused: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(option.description)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.body)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private var backgroundColor: Color {
        if isFocused {
            return .white.opacity(0.1)
        } else if isSelected {
            return .blue.opacity(0.2)
        } else {
            return Color.clear
        }
    }
    
    private var borderColor: Color {
        if isFocused {
            return .green
        } else if isSelected {
            return .blue
        } else {
            return .clear
        }
    }
    
    private var borderWidth: CGFloat {
        (isFocused || isSelected) ? 1 : 0
    }
}

// MARK: - Extensions for CustomStringConvertible

extension AccountType: CustomStringConvertible {
    var description: String { displayName }
}

extension OrderType: CustomStringConvertible {
    var description: String { displayName }
}

extension TimeInForce: CustomStringConvertible {
    var description: String { displayName }
}

extension RiskProfile: CustomStringConvertible {
    var description: String { displayName }
}

extension AppTheme: CustomStringConvertible {
    var description: String { displayName }
}

extension ColorScheme: CustomStringConvertible {
    var description: String { displayName }
}

extension ChartDisplayType: CustomStringConvertible {
    var description: String { displayName }
}

extension PriceFormat: CustomStringConvertible {
    var description: String { displayName }
}

extension PercentFormat: CustomStringConvertible {
    var description: String { displayName }
}

extension APIEnvironment: CustomStringConvertible {
    var description: String { displayName }
}

extension LogLevel: CustomStringConvertible {
    var description: String { displayName }
}

extension WatchlistSort: CustomStringConvertible {
    var description: String { displayName }
}

extension ChartTimeframe: CustomStringConvertible {
    var description: String { displayName }
}