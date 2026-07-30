//
//  EventsView.swift
//  buzzbuddy
//
//  Created by Max DeWeese on 7/10/26.
//

import SwiftUI
import MapKit

// MARK: - Event Model

struct Event: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var location: EventLocation?
    var contact: Contact?

    init(id: UUID = UUID(), name: String, location: EventLocation?, contact: Contact?) {
        self.id = id
        self.name = name
        self.location = location
        self.contact = contact
    }
}

// MARK: - Event Store

@MainActor
final class EventStore: ObservableObject {
    static let shared = EventStore()

    @Published private(set) var events: [Event] = []

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("events.json")
    }()

    init() {
        load()
    }

    func add(_ event: Event) {
        events.append(event)
        save()
    }

    func remove(_ event: Event) {
        events.removeAll { $0.id == event.id }
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        guard let decoded = try? JSONDecoder().decode([Event].self, from: data) else { return }
        events = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(events) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}

// MARK: - Events View

struct EventsView: View {
    @Environment(\.tabBarHeight) private var tabBarHeight
    @StateObject private var eventStore = EventStore.shared
    @State private var showingAddEvent = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                    SectionHeader(title: "Events")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, BuzzBuddyTheme.Spacing.lg)
                        .padding(.bottom, BuzzBuddyTheme.Spacing.md)
                        .padding(.horizontal, BuzzBuddyTheme.Spacing.md)

                    ScrollView {
                        content
                            .padding(.horizontal, BuzzBuddyTheme.Spacing.md)
                            .padding(.top, BuzzBuddyTheme.Spacing.sm)
                    }
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        Color.clear.frame(height: tabBarHeight)
                    }
                }

                if !eventStore.events.isEmpty {
                    fab
                }
            }
            .background(BuzzBuddyTheme.Colors.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showingAddEvent) {
                AddEventView(eventStore: eventStore)
            }
        }
    }

    private var fab: some View {
        Button {
            showingAddEvent = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.black)
                .frame(width: 60, height: 60)
                .background(Circle().fill(BuzzBuddyTheme.Colors.accentYellow))
                .shadow(color: BuzzBuddyTheme.Shadow.soft.color, radius: BuzzBuddyTheme.Shadow.soft.radius, y: BuzzBuddyTheme.Shadow.soft.y)
        }
        .accessibilityLabel("Create Event")
        .padding(.trailing, BuzzBuddyTheme.Spacing.lg)
        .padding(.bottom, tabBarHeight + BuzzBuddyTheme.Spacing.lg)
    }

    @ViewBuilder
    private var content: some View {
        if eventStore.events.isEmpty {
            emptyState
        } else {
            VStack(spacing: BuzzBuddyTheme.Spacing.md) {
                ForEach(eventStore.events) { event in
                    EventCard(event: event) {
                        withAnimation(.easeOut(duration: 0.25)) {
                            eventStore.remove(event)
                        }
                    }
                    .transition(.opacity)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: BuzzBuddyTheme.Spacing.md) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 36))
                .foregroundStyle(BuzzBuddyTheme.Colors.textSecondary)
                .accessibilityHidden(true)
            Text("No events yet")
                .font(BuzzBuddyTheme.Typography.headline)
                .foregroundStyle(BuzzBuddyTheme.Colors.textPrimary)
            Text("Add a night out to keep a location and a trusted contact on hand.")
                .font(.subheadline)
                .foregroundStyle(BuzzBuddyTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            BuzzBuddyButton(title: "Create Event", systemImage: "plus", kind: .primary, fullWidth: false) {
                showingAddEvent = true
            }
            .padding(.top, BuzzBuddyTheme.Spacing.sm)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, BuzzBuddyTheme.Spacing.xxl)
        .padding(.horizontal, BuzzBuddyTheme.Spacing.lg)
    }
}

// MARK: - Event Card

private struct EventCard: View {
    let event: Event
    let onDelete: () -> Void

    var body: some View {
        BuzzBuddyCard {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top, spacing: 12) {
                    Text(event.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(BuzzBuddyTheme.Colors.textPrimary)

                    Spacer()

                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 24))
                            .foregroundStyle(BuzzBuddyTheme.Colors.accentYellow)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Mark \(event.name) as done")
                }

                if let location = event.location {
                    Text(location.name)
                        .font(.system(size: 14))
                        .foregroundStyle(BuzzBuddyTheme.Colors.textSecondary)

                    Map(initialPosition: .region(
                        MKCoordinateRegion(
                            center: location.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                    )) {
                        Marker(location.name, coordinate: location.coordinate)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: BuzzBuddyTheme.Radius.sm, style: .continuous))
                    .allowsHitTesting(false)
                    .overlay(
                        RoundedRectangle(cornerRadius: BuzzBuddyTheme.Radius.sm, style: .continuous)
                            .stroke(BuzzBuddyTheme.Colors.border, lineWidth: 1)
                    )
                    .padding(.top, 6)
                }

                if let contact = event.contact {
                    Divider()
                        .overlay(BuzzBuddyTheme.Colors.border)
                        .padding(.top, 10)

                    VStack(alignment: .leading, spacing: 6) {
                        SectionHeader(title: "Contact", style: .section)

                        HStack(spacing: 10) {
                            avatar(for: contact)
                            Text(contact.name)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(BuzzBuddyTheme.Colors.textPrimary)
                        }
                    }
                    .padding(.top, 10)
                }
            }
        }
    }

    @ViewBuilder
    private func avatar(for contact: Contact) -> some View {
        if let data = contact.imageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 32, height: 32)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(BuzzBuddyTheme.Colors.accentYellow.opacity(0.18))
                .frame(width: 32, height: 32)
                .overlay(
                    Text(initials(for: contact.name))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(BuzzBuddyTheme.Colors.accentYellow)
                )
        }
    }

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }
}

#Preview {
    EventsView()
}
