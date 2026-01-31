//
//  MenuView.swift
//  ForLunch
//
//  Grok-first design: meal type (Lunch > Breakfast) → main items → modifiers → context.
//

import SwiftUI
import UIKit

/// Today = date-scoped feed (Lunch, Breakfast, Events). Calendar = month grid, tap day → sheet.
enum Surface: String, CaseIterable {
    case today
    case calendar
}

enum AddMenuSource: Identifiable {
    case camera(School)
    case photo(School)
    case document(School)
    var id: String {
        switch self {
        case .camera(let s): return "camera-\(s.id)"
        case .photo(let s): return "photo-\(s.id)"
        case .document(let s): return "document-\(s.id)"
        }
    }
    var school: School {
        switch self {
        case .camera(let s), .photo(let s), .document(let s): return s
        }
    }
}

struct MenuView: View {
    let schools: [School]
    let onChangeSchool: () -> Void
    let onRemoveSchool: (School) -> Void

    @State private var viewingDate: Date = Date()
    @State private var selectedSurface: Surface = .today
    @State private var menusBySchoolId: [String: DayMenu] = [:]
    @State private var errorsBySchoolId: [String: String] = [:]
    @State private var isLoading = true
    @State private var eventsForViewingDate: [Event] = []
    @State private var eventCountByDate: [String: Int] = [:]
    @State private var addMenuSource: AddMenuSource?
    @State private var showAddMenuThankYou = false
    @State private var showMenuSheet = false
    @State private var selectedCalendarDate: Date?
    @State private var showDaySheet = false
    @State private var sheetEvents: [Event] = []
    @State private var sheetMenus: [String: DayMenu] = [:]
    @AppStorage("ForLunch.BreakfastExpanded") private var breakfastExpanded: Bool = false
    @State private var eventsSectionExpanded: Bool = false
    private static let surfaceStorageKey = "ForLunch.SelectedSurface"

    private let menuDatabase = MenuDatabaseService()
    private let eventsService = EventsService()
    private let remoteMenuService = RemoteMenuService()
    private let menuService = MenuService()
    private let calendar = Calendar.current

    private static var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f
    }

    private var dateHeroText: String {
        Self.dateFormatter.string(from: viewingDate)
    }

    /// Task id so menu load re-runs when date or school list changes (e.g. after adding a school).
    private var menuTaskId: String {
        let dateKey = viewingDate.timeIntervalSince1970
        let ids = schools.map(\.id).sorted().joined(separator: ",")
        return "\(dateKey)-\(ids)"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DesignTokens.background.ignoresSafeArea()
                VStack(spacing: 0) {
                    appHeader
                    mainContent
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .preferredColorScheme(.dark)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(DesignTokens.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showMenuSheet = true
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .foregroundStyle(DesignTokens.title)
                    }
                }
            }
            .sheet(isPresented: $showMenuSheet) {
                MenuSheetView(
                    onOpenSchools: { onChangeSchool() },
                    onDismiss: { showMenuSheet = false }
                )
            }
            .task(id: menuTaskId) {
                await loadMenusForAllSchools()
                if selectedSurface == .today {
                    let startOfDay = calendar.startOfDay(for: viewingDate)
                    eventsForViewingDate = await eventsService.events(for: startOfDay, schoolIds: schools.map(\.id))
                    eventsSectionExpanded = !eventsForViewingDate.isEmpty
                }
            }
            .sheet(isPresented: $showDaySheet) {
                if let date = selectedCalendarDate {
                    DayDetailSheet(
                        date: date,
                        events: sheetEvents,
                        schools: schools,
                        menusBySchoolId: sheetMenus,
                        onDismiss: { showDaySheet = false }
                    )
                }
            }
            .sheet(item: $addMenuSource) { source in
                addMenuSheet(for: source)
            }
            .alert("Thank you", isPresented: $showAddMenuThankYou) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("We'll use this to add the menu later.")
            }
            .onAppear {
                if let raw = UserDefaults.standard.string(forKey: Self.surfaceStorageKey),
                   let s = Surface(rawValue: raw) {
                    selectedSurface = s
                }
            }
            .onChange(of: selectedSurface) { newValue in
                UserDefaults.standard.set(newValue.rawValue, forKey: Self.surfaceStorageKey)
            }
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        if selectedSurface == .today {
            if isLoading {
                ProgressView("Loading menus…")
                    .foregroundStyle(DesignTokens.date)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                todayScrollContent
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 50)
                            .onEnded { value in
                                let w = value.translation.width
                                let h = value.translation.height
                                if abs(w) > abs(h), abs(w) > 50 {
                                    if w > 0 {
                                        if let prev = calendar.date(byAdding: .day, value: -1, to: viewingDate) {
                                            viewingDate = prev
                                        }
                                    } else {
                                        if let next = calendar.date(byAdding: .day, value: 1, to: viewingDate) {
                                            viewingDate = next
                                        }
                                    }
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                            }
                    )
            }
        } else {
            CalendarView(
                viewingDate: viewingDate,
                surface: $selectedSurface,
                viewingDateBinding: $viewingDate,
                onSelectDate: { date in
                    selectedCalendarDate = date
                    Task {
                        await loadSheetData(for: date)
                        await MainActor.run { showDaySheet = true }
                    }
                },
                eventCountByDate: eventCountByDate
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private var todayScrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(schools) { school in
                    schoolBlock(school: school)
                }
                EventsSectionView(
                    events: eventsForViewingDate,
                    date: viewingDate,
                    isExpanded: eventsSectionExpanded,
                    onToggle: { eventsSectionExpanded.toggle() }
                )
                .padding(.top, 20)
                addAnotherSchoolCTA
                    .padding(.top, 8)
            }
            .padding(.top, DesignTokens.schoolNameTopMargin)
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .scrollContentBackground(.hidden)
    }

    // MARK: - Header (56pt, Figma: primary date 22pt, secondary 13pt, Yesterday/Tomorrow nav)

    private var appHeader: some View {
        VStack(spacing: DesignTokens.headerPrimaryToSecondary) {
            // Primary: "Today" when today, else "Fri, Feb 6"
            Group {
                if calendar.isDateInToday(viewingDate) {
                    Text("Today")
                        .font(.system(size: DesignTokens.headerPrimarySize, weight: .semibold))
                        .foregroundStyle(DesignTokens.title)
                    Text(dateHeroText)
                        .font(.system(size: DesignTokens.headerSecondarySize, weight: .regular))
                        .foregroundStyle(DesignTokens.date)
                } else {
                    Text(dateHeroText)
                        .font(.system(size: DesignTokens.headerPrimarySize, weight: .semibold))
                        .foregroundStyle(DesignTokens.title)
                }
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            Picker("", selection: $selectedSurface) {
                Text("Today").tag(Surface.today)
                Text("Calendar").tag(Surface.calendar)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 24)
            .padding(.top, 4)
            HStack(spacing: 16) {
                Button {
                    if let prev = calendar.date(byAdding: .day, value: -1, to: viewingDate) {
                        viewingDate = prev
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .medium))
                        Text("Yesterday")
                            .font(.system(size: 13, weight: .regular))
                    }
                    .foregroundStyle(DesignTokens.date)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Spacer()
                if !calendar.isDateInToday(viewingDate) {
                    Button {
                        viewingDate = Date()
                    } label: {
                        Text("Today")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(DesignTokens.date)
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                Button {
                    if let next = calendar.date(byAdding: .day, value: 1, to: viewingDate) {
                        viewingDate = next
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("Tomorrow")
                            .font(.system(size: 13, weight: .regular))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(DesignTokens.date)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .frame(minHeight: DesignTokens.headerHeight)
        .background(DesignTokens.background)
    }

    // MARK: - School block (name + Lunch card + Breakfast card)

    @ViewBuilder
    private func schoolBlock(school: School) -> some View {
        let menu = menusBySchoolId[school.id]
        let error = errorsBySchoolId[school.id]

        VStack(alignment: .leading, spacing: 0) {
            Text(school.name)
                .font(.system(size: 15, weight: .medium))
                .lineSpacing(4)
                .foregroundStyle(DesignTokens.schoolName)
                .padding(.bottom, DesignTokens.schoolNameBottomMargin)

            if let msg = error {
                Text(msg)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(DesignTokens.secondaryItem)
                addMenuPrompt(school: school)
                    .padding(.top, 8)
            } else if let dayMenu = menu {
                // Lunch first (primary, always expanded)
                mealCard(
                    title: "Lunch",
                    items: dayMenu.lunchItems,
                    isPrimary: true
                )
                .padding(.bottom, DesignTokens.cardSpacing)
                // Breakfast: collapsed by default; empty = collapsed. Persist expanded state.
                breakfastBlock(items: dayMenu.breakfastItems)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            }
        }
        .padding(.bottom, 20)
    }

    // MARK: - Breakfast (collapsed by default; empty = collapsed; persist expanded)

    @ViewBuilder
    private func breakfastBlock(items: [String]) -> some View {
        let showExpanded = !items.isEmpty && breakfastExpanded
        if showExpanded {
            mealCard(
                title: "Breakfast",
                items: items,
                isPrimary: false,
                showCollapseButton: true,
                onCollapse: { breakfastExpanded = false }
            )
        } else {
            Button {
                if !items.isEmpty {
                    breakfastExpanded = true
                }
            } label: {
                HStack {
                    Text("Breakfast")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(DesignTokens.mealHeaderSecondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(DesignTokens.date)
                }
                .padding(DesignTokens.cardPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DesignTokens.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(items.isEmpty)
        }
    }

    // MARK: - Meal card (shared spec: 16pt radius, 16pt padding, #1C1C1E)

    private func mealCard(
        title: String,
        items: [String],
        isPrimary: Bool,
        showCollapseButton: Bool = false,
        onCollapse: (() -> Void)? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title)
                    .font(.system(size: isPrimary ? 20 : 18, weight: isPrimary ? .semibold : .medium))
                    .foregroundStyle(isPrimary ? DesignTokens.mealHeader : DesignTokens.mealHeaderSecondary)
                Spacer()
                if showCollapseButton, let onCollapse = onCollapse {
                    Button {
                        onCollapse()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(DesignTokens.date)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, DesignTokens.mealHeaderToItems)
            if items.isEmpty {
                Text("No items listed for this date.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(DesignTokens.secondaryItem)
            } else {
                VStack(alignment: .leading, spacing: DesignTokens.itemRowSpacing) {
                    ForEach(Array(items.enumerated()), id: \.offset) { _, raw in
                        menuItemRow(ParsedMenuItem.parse(raw))
                    }
                }
            }
        }
        .padding(DesignTokens.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius, style: .continuous))
    }

    // MARK: - Menu item row (main + optional secondary + optional chip)

    private func menuItemRow(_ item: ParsedMenuItem) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .top, spacing: 6) {
                Text("•")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(DesignTokens.secondaryItem)
                Text(item.main)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(DesignTokens.mainItem)
                if let mod = item.modifier {
                    modifierChip(mod)
                }
            }
            if let sec = item.secondary, !sec.isEmpty {
                Text(sec)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(DesignTokens.secondaryItem)
                    .padding(.leading, 14)
            }
        }
    }

    private func modifierChip(_ mod: MenuItemModifier) -> some View {
        let (textColor, bgColor) = mod == .vegetarian
            ? (DesignTokens.Chip.vegetarianText, DesignTokens.Chip.vegetarianBg)
            : (DesignTokens.Chip.dailyOptionText, DesignTokens.Chip.dailyOptionBg)
        return Text(mod.rawValue)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(textColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(bgColor)
            .clipShape(Capsule())
    }

    // MARK: - Add menu prompt / sheets

    private func addMenuPrompt(school: School) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Add this menu:")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(DesignTokens.schoolName)
            HStack(spacing: 12) {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button {
                        addMenuSource = .camera(school)
                    } label: {
                        Label("Take a picture", systemImage: "camera")
                            .font(.system(size: 14))
                            .foregroundStyle(DesignTokens.mainItem)
                    }
                }
                Button {
                    addMenuSource = .photo(school)
                } label: {
                    Label("Upload photo", systemImage: "photo")
                        .font(.system(size: 14))
                        .foregroundStyle(DesignTokens.mainItem)
                }
                Button {
                    addMenuSource = .document(school)
                } label: {
                    Label("Upload PDF", systemImage: "doc")
                        .font(.system(size: 14))
                        .foregroundStyle(DesignTokens.mainItem)
                }
            }
        }
    }

    @ViewBuilder
    private func addMenuSheet(for source: AddMenuSource) -> some View {
        switch source {
        case .camera:
            ImagePicker(
                source: .camera,
                onPick: { _ in addMenuSource = nil; showAddMenuThankYou = true },
                onCancel: { addMenuSource = nil }
            )
        case .photo:
            ImagePicker(
                source: .photoLibrary,
                onPick: { _ in addMenuSource = nil; showAddMenuThankYou = true },
                onCancel: { addMenuSource = nil }
            )
        case .document:
            DocumentPicker(
                onPick: { _ in addMenuSource = nil; showAddMenuThankYou = true },
                onCancel: { addMenuSource = nil }
            )
        }
    }

    private var addAnotherSchoolCTA: some View {
        Button {
            onChangeSchool()
        } label: {
            Text("Add another school")
                .font(.system(size: 11))
                .foregroundStyle(DesignTokens.date)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    // MARK: - Data loading

    private func loadMenusForAllSchools() async {
        isLoading = true
        menusBySchoolId = [:]
        errorsBySchoolId = [:]
        defer { isLoading = false }
        let startOfDay = calendar.startOfDay(for: viewingDate)

        await withTaskGroup(of: (String, DayMenu?).self) { group in
            for school in schools {
                group.addTask {
                    let menu = await loadMenu(for: school, date: startOfDay)
                    return (school.id, menu)
                }
            }
            for await (schoolId, menu) in group {
                if let menu = menu {
                    menusBySchoolId[schoolId] = menu
                } else {
                    errorsBySchoolId[schoolId] = "No menu for this date."
                }
            }
        }
    }

    private func loadMenu(for school: School, date: Date) async -> DayMenu? {
        let startOfDay = calendar.startOfDay(for: date)
        if let dbMenu = menuDatabase.menu(for: school.id, date: startOfDay) {
            return dbMenu
        }
        if let remoteMenu = try? await remoteMenuService.fetchMenu(schoolId: school.id, date: startOfDay) {
            return remoteMenu
        }
        if let nearest = menuDatabase.nearestMenu(for: school.id, near: startOfDay) {
            return nearest
        }
        if school.hasNutrislice, let menu = try? await menuService.fetchDayMenu(school: school, date: startOfDay) {
            return menu
        }
        return nil
    }

    private func loadSheetData(for date: Date) async {
        let startOfDay = calendar.startOfDay(for: date)
        sheetEvents = await eventsService.events(for: startOfDay, schoolIds: schools.map(\.id))
        var menus: [String: DayMenu] = [:]
        await withTaskGroup(of: (String, DayMenu?).self) { group in
            for school in schools {
                group.addTask {
                    let menu = await loadMenu(for: school, date: startOfDay)
                    return (school.id, menu)
                }
            }
            for await (schoolId, menu) in group {
                if let menu = menu {
                    menus[schoolId] = menu
                }
            }
        }
        sheetMenus = menus
    }
}
