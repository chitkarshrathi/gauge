import SwiftUI
import SwiftData

struct FamilySettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var households: [Household]
    
    @State private var showAddMember = false
    @State private var editBudget = false
    @State private var budgetInput: Double = 0.0
    
    var household: Household? {
        households.first
    }
    
    var body: some View {
        Form {
            if let home = household {
                // MARK: - Household Profile
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(home.name)
                                .font(.title2.weight(.bold))
                            Text("Subscription: \(home.subscriptionTier.capitalized.replacingOccurrences(of: "_", with: " "))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "house.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.blue)
                            .padding(12)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .padding(.vertical, 8)
                }
                
                // MARK: - Monthly Budget Management
                Section(header: Text("Financials"), footer: Text("This budget powers the progress bar on your Household Dashboard.")) {
                    HStack {
                        Text("Monthly Fuel Budget")
                        Spacer()
                        if editBudget {
                            TextField("Amount", value: $budgetInput, format: .currency(code: "CAD"))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(.blue)
                                .onSubmit {
                                    home.monthlyBudget = budgetInput
                                    withAnimation { editBudget = false }
                                }
                        } else {
                            Text(home.monthlyBudget, format: .currency(code: "CAD"))
                                .foregroundColor(.secondary)
                        }
                    }
                    .onTapGesture {
                        budgetInput = home.monthlyBudget
                        withAnimation { editBudget.toggle() }
                    }
                }
                
                // MARK: - Family Members
                Section(header: Text("Members")) {
                    // Sort members so Admins show up first
                    let sortedMembers = home.members.sorted { 
                        if $0.role == "admin" && $1.role != "admin" { return true }
                        if $0.role != "admin" && $1.role == "admin" { return false }
                        return $0.name < $1.name
                    }
                    
                    ForEach(sortedMembers) { member in
                        HStack(spacing: 12) {
                            Image(systemName: member.avatarSymbol)
                                .font(.title2)
                                .foregroundColor(member.role == "admin" ? .blue : .secondary)
                                .frame(width: 32)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(member.name)
                                    .font(.body.weight(.medium))
                                Text(member.email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            
                            Text(member.role.capitalized)
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(member.role == "admin" ? Color.blue.opacity(0.15) : Color(UIColor.tertiarySystemFill))
                                .foregroundColor(member.role == "admin" ? .blue : .secondary)
                                .clipShape(Capsule())
                        }
                        .padding(.vertical, 4)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            // Failsafe: Don't let Chitkarsh delete himself if he's the only admin
                            if member.role != "admin" || sortedMembers.filter({ $0.role == "admin" }).count > 1 {
                                Button(role: .destructive) {
                                    modelContext.delete(member)
                                } label: {
                                    Label("Remove", systemImage: "person.fill.xmark")
                                }
                            }
                        }
                    }
                    
                    Button(action: { showAddMember = true }) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                            Text("Add Family Member")
                        }
                        .foregroundColor(.blue)
                    }
                }
            } else {
                // Fallback if no household exists yet
                ContentUnavailableView("No Household Found", systemImage: "house.slash.fill", description: Text("Set up a family garage to share vehicles and budgets."))
            }
        }
        .navigationTitle("Family Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddMember) {
            AddFamilyMemberView(household: household)
        }
    }
}

// MARK: - Add Member Sheet
struct AddFamilyMemberView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var household: Household?
    
    @State private var name = ""
    @State private var email = ""
    @State private var role = "member"
    @State private var selectedAvatar = "person.crop.circle.fill"
    
    // Curated native Apple avatars
    let avatars = [
        "person.crop.circle.fill", "person.crop.square.fill", 
        "person.crop.artframe", "person.bust.fill", 
        "figure.walk.circle.fill", "star.circle.fill", 
        "leaf.circle.fill", "bolt.circle.fill"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Profile Icon")) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 16) {
                        ForEach(avatars, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.system(size: 28))
                                .foregroundColor(selectedAvatar == icon ? .white : .blue)
                                .frame(width: 50, height: 50)
                                .background(selectedAvatar == icon ? Color.blue : Color(UIColor.secondarySystemFill))
                                .clipShape(Circle())
                                .onTapGesture {
                                    withAnimation { selectedAvatar = icon }
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Details")) {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                    
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textContentType(.emailAddress)
                }
                
                Section(header: Text("Permissions"), footer: Text("Admins can edit the household budget and remove other members.")) {
                    Picker("Role", selection: $role) {
                        Text("Member").tag("member")
                        Text("Admin").tag("admin")
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("New Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { saveMember() }
                        .disabled(name.isEmpty || email.isEmpty)
                }
            }
        }
    }
    
    private func saveMember() {
        guard let home = household else { return }
        
        let newMember = FamilyMember(
            name: name,
            email: email,
            role: role,
            avatarSymbol: selectedAvatar
        )
        
        newMember.household = home
        modelContext.insert(newMember)
        dismiss()
    }
}
