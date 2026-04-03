import SwiftUI

struct TasksView: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showAddTask = false
    @State private var filterPriority: BuildTask.Priority? = nil

    var filteredTasks: [BuildTask] {
        let sorted = projectsVM.tasks.sorted { !$0.isCompleted && $1.isCompleted }
        if let priority = filterPriority {
            return sorted.filter { $0.priority == priority }
        }
        return sorted
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.surfaceLight.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Priority filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(label: "All", isSelected: filterPriority == nil) {
                                filterPriority = nil
                            }
                            ForEach(BuildTask.Priority.allCases, id: \.self) { p in
                                FilterChip(label: p.rawValue, color: p.color, isSelected: filterPriority == p) {
                                    filterPriority = filterPriority == p ? nil : p
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }

                    if filteredTasks.isEmpty {
                        Spacer()
                        EmptyStateView(
                            icon: "checkmark.circle",
                            title: "No Tasks",
                            message: "Add construction tasks to stay organized",
                            buttonTitle: "Add Task"
                        ) { showAddTask = true }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                // Stats
                                HStack(spacing: 12) {
                                    SmallStatChip(value: "\(projectsVM.pendingTaskCount)", label: "Pending", color: .brandOrange)
                                    SmallStatChip(value: "\(projectsVM.completedTaskCount)", label: "Done", color: .brandGreen)
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 4)

                                ForEach(filteredTasks) { task in
                                    TaskRow(task: task)
                                        .padding(.horizontal, 16)
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                settingsVM.cancelNotification(for: task.id)
                                                projectsVM.deleteTask(task)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                                Spacer(minLength: 20)
                            }
                            .padding(.top, 8)
                        }
                    }
                }
            }
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(.brandOrange)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddTask = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.brandOrange)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddTask) { AddTaskView() }
    }
}

struct TaskRow: View {
    var task: BuildTask
    @EnvironmentObject var projectsVM: ProjectsViewModel

    var isOverdue: Bool {
        !task.isCompleted && task.dueDate < Date()
    }

    var body: some View {
        HStack(spacing: 14) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    projectsVM.toggleTaskCompleted(task)
                }
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 26))
                    .foregroundColor(task.isCompleted ? .brandGreen : .textMuted)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(SBCFont.headline(15))
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .textSecondary : .primary)

                if !task.notes.isEmpty {
                    Text(task.notes)
                        .font(SBCFont.body(12))
                        .foregroundColor(.textSecondary)
                        .lineLimit(1)
                }

                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11))
                    Text(task.dueDate, style: .date)
                        .font(SBCFont.caption(12))
                }
                .foregroundColor(isOverdue ? .brandRed : .textSecondary)
            }

            Spacer()

            // Priority indicator
            Circle()
                .fill(task.priority.color)
                .frame(width: 10, height: 10)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(UIColor.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isOverdue ? Color.brandRed.opacity(0.3) : Color.clear, lineWidth: 1.5)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        )
        .opacity(task.isCompleted ? 0.65 : 1.0)
    }
}

struct AddTaskView: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var title = ""
    @State private var notes = ""
    @State private var dueDate = Date().addingTimeInterval(86400)
    @State private var priority = BuildTask.Priority.medium
    @State private var showError = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.surfaceLight.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(spacing: 14) {
                            SBCInputField(title: "Task Title", placeholder: "e.g. Buy concrete mix", text: $title)
                            SBCInputField(title: "Notes (optional)", placeholder: "Details or supplier info...", text: $notes)

                            VStack(alignment: .leading, spacing: 6) {
                                if #available(iOS 16.0, *) {
                                    Text("Due Date")
                                        .font(SBCFont.caption(12))
                                        .foregroundColor(.textSecondary)
                                        .textCase(.uppercase)
                                        .tracking(0.5)
                                } else {
                                    Text("Due Date")
                                        .font(SBCFont.caption(12))
                                        .foregroundColor(.textSecondary)
                                        .textCase(.uppercase)
                                }
                                DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                                    .datePickerStyle(.graphical)
                                    .accentColor(.brandOrange)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                if #available(iOS 16.0, *) {
                                    Text("Priority")
                                        .font(SBCFont.caption(12))
                                        .foregroundColor(.textSecondary)
                                        .textCase(.uppercase)
                                        .tracking(0.5)
                                } else {
                                    Text("Priority")
                                        .font(SBCFont.caption(12))
                                        .foregroundColor(.textSecondary)
                                        .textCase(.uppercase)
                                }
                                HStack(spacing: 10) {
                                    ForEach(BuildTask.Priority.allCases, id: \.self) { p in
                                        Button(action: { priority = p }) {
                                            Text(p.rawValue)
                                                .font(SBCFont.caption(13))
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(
                                                    priority == p
                                                        ? p.color
                                                        : p.color.opacity(0.12)
                                                )
                                                .foregroundColor(priority == p ? .white : p.color)
                                                .cornerRadius(10)
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .cardStyle(padding: 0)

                        if showError {
                            Text("Please enter a task title")
                                .font(SBCFont.caption(13))
                                .foregroundColor(.brandRed)
                        }

                        Button("Add Task") {
                            guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
                                showError = true; return
                            }
                            let task = BuildTask(
                                title: title,
                                notes: notes,
                                dueDate: dueDate,
                                priority: priority
                            )
                            projectsVM.addTask(task)
                            settingsVM.scheduleTaskNotification(for: task)
                            presentationMode.wrappedValue.dismiss()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding(16)
                }
            }
            .navigationTitle("New Task")
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

struct FilterChip: View {
    var label: String
    var color: Color = .brandOrange
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(SBCFont.caption(13))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? color : color.opacity(0.1))
                .foregroundColor(isSelected ? .white : color)
                .cornerRadius(20)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}

struct SmallStatChip: View {
    var value: String
    var label: String
    var color: Color

    var body: some View {
        HStack(spacing: 6) {
            Text(value)
                .font(SBCFont.mono(15))
                .foregroundColor(color)
            Text(label)
                .font(SBCFont.body(13))
                .foregroundColor(.textSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.08))
        )
    }
}
