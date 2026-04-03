import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject var projectsVM: ProjectsViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel

    var upcomingTasks: [BuildTask] {
        projectsVM.tasks
            .filter { !$0.isCompleted }
            .sorted { $0.dueDate < $1.dueDate }
    }

    var overdueTasks: [BuildTask] {
        upcomingTasks.filter { $0.dueDate < Date() }
    }

    var dueSoonTasks: [BuildTask] {
        let soon = Date().addingTimeInterval(7 * 86400)
        return upcomingTasks.filter { $0.dueDate >= Date() && $0.dueDate <= soon }
    }

    var body: some View {
        ZStack {
            Color.surfaceLight.ignoresSafeArea()

            if projectsVM.tasks.filter({ !$0.isCompleted }).isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bell.slash")
                        .font(.system(size: 52, weight: .light))
                        .foregroundColor(.textMuted)
                    Text("No Notifications")
                        .font(SBCFont.headline(20))
                    Text("Pending tasks will appear here")
                        .font(SBCFont.body(14))
                        .foregroundColor(.textSecondary)
                }
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        if !overdueTasks.isEmpty {
                            VStack(spacing: 8) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.brandRed)
                                    Text("Overdue")
                                        .font(SBCFont.headline(16))
                                        .foregroundColor(.brandRed)
                                    Spacer()
                                    Text("\(overdueTasks.count)")
                                        .font(SBCFont.mono(14))
                                        .foregroundColor(.brandRed)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Capsule().fill(Color.brandRed.opacity(0.12)))
                                }
                                ForEach(overdueTasks) { task in
                                    NotificationTaskRow(task: task, style: .overdue)
                                }
                            }
                        }

                        if !dueSoonTasks.isEmpty {
                            VStack(spacing: 8) {
                                HStack {
                                    Image(systemName: "clock.fill")
                                        .foregroundColor(.brandGold)
                                    Text("Due This Week")
                                        .font(SBCFont.headline(16))
                                        .foregroundColor(.brandGold)
                                    Spacer()
                                    Text("\(dueSoonTasks.count)")
                                        .font(SBCFont.mono(14))
                                        .foregroundColor(.brandGold)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Capsule().fill(Color.brandGold.opacity(0.12)))
                                }
                                ForEach(dueSoonTasks) { task in
                                    NotificationTaskRow(task: task, style: .upcoming)
                                }
                            }
                        }

                        if !settingsVM.notificationsEnabled {
                            HStack(spacing: 12) {
                                Image(systemName: "bell.slash.fill")
                                    .foregroundColor(.textSecondary)
                                Text("Enable notifications in Settings to get task reminders")
                                    .font(SBCFont.body(13))
                                    .foregroundColor(.textSecondary)
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.brandGold.opacity(0.08))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.brandGold.opacity(0.2), lineWidth: 1))
                            )
                        }

                        Spacer(minLength: 20)
                    }
                    .padding(16)
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

enum NotificationStyle { case overdue, upcoming }

struct NotificationTaskRow: View {
    var task: BuildTask
    var style: NotificationStyle
    @EnvironmentObject var projectsVM: ProjectsViewModel

    var accent: Color { style == .overdue ? .brandRed : .brandGold }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(accent)
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(SBCFont.headline(14))
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11))
                    Text(task.dueDate, style: .date)
                        .font(SBCFont.caption(12))
                }
                .foregroundColor(accent)
            }
            Spacer()
            Circle()
                .fill(task.priority.color)
                .frame(width: 8, height: 8)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(accent.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(accent.opacity(0.2), lineWidth: 1))
        )
    }
}
