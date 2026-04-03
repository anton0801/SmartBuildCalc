import SwiftUI

struct ProjectsView: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @State private var showAddProject = false
    @State private var searchText = ""

    var filtered: [Project] {
        searchText.isEmpty ? projectsVM.projects : projectsVM.projects.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.buildingType.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.surfaceLight.ignoresSafeArea()

                if projectsVM.projects.isEmpty {
                    EmptyStateView(
                        icon: "folder",
                        title: "No Projects",
                        message: "Create your first construction project to get started",
                        buttonTitle: "Add Project"
                    ) { showAddProject = true }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filtered) { project in
                                NavigationLink(destination: ProjectDetailView(project: project)) {
                                    ProjectCard(project: project)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Projects")
            .searchable(text: $searchText, prompt: "Search projects...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddProject = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.brandOrange)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddProject) { AddProjectView() }
    }
}

struct ProjectCard: View {
    var project: Project
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var projectsVM: ProjectsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient.brandGradient)
                        .frame(width: 48, height: 48)
                    Image(systemName: project.buildingType.icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(SBCFont.headline(16))
                    Text(project.buildingType.rawValue)
                        .font(SBCFont.caption(13))
                        .foregroundColor(.brandOrange)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.textMuted)
            }
            .padding(16)

            Divider().padding(.horizontal, 16)

            // Stats
            HStack {
                StatBadge(value: "\(project.roomCount)", label: "Rooms")
                Divider().frame(height: 30)
                StatBadge(value: settingsVM.formatArea(project.totalArea), label: "Total Area")
                Divider().frame(height: 30)
                let matCount = projectsVM.materials(for: project.id).count
                StatBadge(value: "\(matCount)", label: "Materials")
            }
            .padding(.vertical, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.07), radius: 10, x: 0, y: 4)
        )
    }
}

struct AddProjectView: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var projectName = ""
    @State private var buildingType = Project.BuildingType.house
    @State private var showError = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.surfaceLight.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 16) {
                            SBCInputField(title: "Project Name", placeholder: "e.g. My New House", text: $projectName)

                            VStack(alignment: .leading, spacing: 8) {
                                if #available(iOS 16.0, *) {
                                    Text("Building Type")
                                        .font(SBCFont.caption(12))
                                        .foregroundColor(.textSecondary)
                                        .textCase(.uppercase)
                                        .tracking(0.5)
                                } else {
                                    Text("Building Type")
                                        .font(SBCFont.caption(12))
                                        .foregroundColor(.textSecondary)
                                        .textCase(.uppercase)
                                }

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(Project.BuildingType.allCases, id: \.self) { type in
                                            Button(action: { buildingType = type }) {
                                                HStack(spacing: 6) {
                                                    Image(systemName: type.icon)
                                                    Text(type.rawValue)
                                                }
                                                .font(SBCFont.caption(13))
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 10)
                                                .background(
                                                    buildingType == type
                                                        ? LinearGradient.brandGradient
                                                        : LinearGradient(colors: [Color.clear], startPoint: .top, endPoint: .bottom)
                                                )
                                                .foregroundColor(buildingType == type ? .white : .textSecondary)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(buildingType == type ? Color.clear : Color.textMuted.opacity(0.4), lineWidth: 1)
                                                )
                                                .cornerRadius(10)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .cardStyle(padding: 0)

                        if showError {
                            Text("Please enter a project name")
                                .font(SBCFont.caption(13))
                                .foregroundColor(.brandRed)
                        }

                        Button("Create Project") {
                            guard !projectName.trimmingCharacters(in: .whitespaces).isEmpty else {
                                showError = true; return
                            }
                            let project = Project(
                                name: projectName,
                                buildingType: buildingType,
                                rooms: [],
                                createdAt: Date(),
                                totalEstimate: 0
                            )
                            projectsVM.addProject(project)
                            presentationMode.wrappedValue.dismiss()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding(16)
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(.brandOrange)
                }
            }
        }
    }
}

struct ProjectDetailView: View {
    var project: Project
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @State private var showAddRoom = false
    @State private var showAddMaterial = false
    @State private var localProject: Project

    init(project: Project) {
        self.project = project
        self._localProject = State(initialValue: project)
    }

    var body: some View {
        ZStack {
            Color.surfaceLight.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    // Project stats
                    HStack(spacing: 0) {
                        StatBadge(value: "\(localProject.roomCount)", label: "Rooms", color: .brandOrange)
                        Divider().frame(height: 40)
                        StatBadge(value: settingsVM.formatArea(localProject.totalArea), label: "Area", color: .brandGold)
                        Divider().frame(height: 40)
                        StatBadge(value: "\(projectsVM.materials(for: localProject.id).count)", label: "Materials", color: .brandGreen)
                    }
                    .cardStyle()

                    // Rooms
                    VStack(spacing: 10) {
                        SBCSectionHeader(title: "Rooms", actionTitle: "+ Add Room") {
                            showAddRoom = true
                        }

                        if localProject.rooms.isEmpty {
                            Text("No rooms yet. Add a room to get started.")
                                .font(SBCFont.body(14))
                                .foregroundColor(.textSecondary)
                                .padding(20)
                                .frame(maxWidth: .infinity)
                                .cardStyle(padding: 0)
                        } else {
                            ForEach(localProject.rooms) { room in
                                RoomRow(room: room)
                            }
                        }
                    }

                    // Materials for this project
                    let projectMaterials = projectsVM.materials(for: localProject.id)
                    if !projectMaterials.isEmpty {
                        VStack(spacing: 10) {
                            SBCSectionHeader(title: "Materials")
                            ForEach(projectMaterials) { material in
                                MaterialRow(material: material)
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle(localProject.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddRoom = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(.brandOrange)
                }
            }
        }
        .sheet(isPresented: $showAddRoom) {
            AddRoomView(project: $localProject)
        }
        .onReceive(projectsVM.$projects) { projects in
            if let updated = projects.first(where: { $0.id == project.id }) {
                localProject = updated
            }
        }
    }
}

struct RoomRow: View {
    var room: Room
    @EnvironmentObject var settingsVM: SettingsViewModel

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.brandOrange.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: room.roomType.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.brandOrange)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(room.name)
                    .font(SBCFont.headline(15))
                Text("\(String(format: "%.1f", room.length))×\(String(format: "%.1f", room.width)) \(settingsVM.lengthUnit) • \(settingsVM.formatArea(room.area))")
                    .font(SBCFont.body(13))
                    .foregroundColor(.textSecondary)
            }
            Spacer()
        }
        .cardStyle()
    }
}

struct AddRoomView: View {
    @Binding var project: Project
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var roomName = ""
    @State private var roomType = Room.RoomType.bedroom
    @State private var length = ""
    @State private var width = ""
    @State private var height = "2.5"
    @State private var showError = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.surfaceLight.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(spacing: 16) {
                            SBCInputField(title: "Room Name", placeholder: "e.g. Master Bedroom", text: $roomName)

                            VStack(alignment: .leading, spacing: 8) {
                                if #available(iOS 16.0, *) {
                                    Text("Room Type")
                                        .font(SBCFont.caption(12))
                                        .foregroundColor(.textSecondary)
                                        .textCase(.uppercase)
                                        .tracking(0.5)
                                } else {
                                    Text("Room Type")
                                        .font(SBCFont.caption(12))
                                        .foregroundColor(.textSecondary)
                                        .textCase(.uppercase)
                                }
                                Picker("Room Type", selection: $roomType) {
                                    ForEach(Room.RoomType.allCases, id: \.self) { type in
                                        Label(type.rawValue, systemImage: type.icon).tag(type)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(height: 120)
                            }

                            HStack(spacing: 12) {
                                SBCInputField(title: "Length (m)", placeholder: "5.0", text: $length, keyboardType: .decimalPad)
                                SBCInputField(title: "Width (m)", placeholder: "4.0", text: $width, keyboardType: .decimalPad)
                            }
                            SBCInputField(title: "Height (m)", placeholder: "2.5", text: $height, keyboardType: .decimalPad)
                        }
                        .padding()
                        .cardStyle(padding: 0)

                        if showError {
                            Text("Please fill all required fields with valid numbers")
                                .font(SBCFont.caption(13))
                                .foregroundColor(.brandRed)
                        }

                        Button("Add Room") {
                            guard !roomName.isEmpty,
                                  let l = Double(length), let w = Double(width), let h = Double(height),
                                  l > 0, w > 0, h > 0 else { showError = true; return }
                            let room = Room(name: roomName, roomType: roomType, length: l, width: w, height: h)
                            projectsVM.addRoom(room, to: &project)
                            presentationMode.wrappedValue.dismiss()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Add Room")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(.brandOrange)
                }
            }
        }
    }
}

struct EmptyStateView: View {
    var icon: String
    var title: String
    var message: String
    var buttonTitle: String
    var action: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 56, weight: .light))
                .foregroundColor(.brandOrange.opacity(0.4))
            VStack(spacing: 8) {
                Text(title)
                    .font(SBCFont.display(22))
                    .foregroundColor(.primary)
                Text(message)
                    .font(SBCFont.body(15))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            Button(buttonTitle, action: action)
                .buttonStyle(PrimaryButtonStyle(isFullWidth: false))
        }
        .padding(40)
    }
}
