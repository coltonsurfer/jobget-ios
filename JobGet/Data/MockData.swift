import SwiftUI

enum MockData {
    static let profile = UserProfile(
        name: "Jordan Rivera",
        headline: "Barista · Server · Retail associate",
        city: "Austin, TX",
        availability: ["Mon–Fri evenings", "Weekends", "Open to overnight"],
        skills: ["Espresso", "POS systems", "Food handler cert", "Customer service", "Spanish (conversational)"],
        documents: ["Resume · Updated Oct 2026", "Texas Food Handler Certificate", "TABC Certification"],
        profileStrength: 0.85,
        currentEmployer: "Pinewood Coffee Roasters",
        currentLocation: "South Congress"
    )

    static let jobs: [Job] = [
        Job(title: "Barista", company: "Pinewood Coffee Roasters", logoSymbol: "cup.and.saucer.fill", logoColor: Color(hex: 0x8B5A2B),
            payMin: 17, payMax: 19, distanceMiles: 0.8, address: "1412 S Congress Ave", type: .partTime,
            tags: ["Tips", "Flexible hours"], urgentlyHiring: true, postedHoursAgo: 2, applicants: 14,
            about: "Pinewood is a neighborhood roaster with three Austin cafés. We're adding two baristas to our South Congress team ahead of the fall rush. You'll pull shots, steam milk, and keep the bar moving during our busy morning window.",
            responsibilities: ["Prepare espresso and pour-over drinks to spec", "Run the register and mobile order pickup", "Keep the bar stocked, clean, and on time"],
            requirements: ["Texas Food Handler card (we'll reimburse)", "Weekend availability", "Friendly under pressure"],
            schedule: ["Mornings 6a–2p", "Weekends", "20–30 hrs/week"], hiringManager: "Maya Chen"),
        Job(title: "Server", company: "Sunrise Diner", logoSymbol: "fork.knife", logoColor: Color(hex: 0xE2553B),
            payMin: 12, payMax: 25, distanceMiles: 1.4, address: "2300 E Cesar Chavez St", type: .partTime,
            tags: ["Tips", "Same-day pay"], urgentlyHiring: true, noExperience: true, postedHoursAgo: 5, applicants: 31,
            about: "Family-owned diner open 6am–3pm. We're hiring weekend servers. No experience needed—we'll train you on our menu and POS in two shifts.",
            responsibilities: ["Greet guests and take orders", "Run food and refill drinks", "Close out tables and tips"],
            requirements: ["Must be 18+", "Saturday or Sunday availability"],
            schedule: ["Weekends 6a–3p", "Same-day pay available"], hiringManager: "Luis Ortega"),
        Job(title: "Warehouse Associate", company: "QuickShip Fulfillment", logoSymbol: "shippingbox.fill", logoColor: Color(hex: 0x2F6FED),
            payMin: 21, payMax: 23, distanceMiles: 6.2, address: "9800 Metric Blvd", type: .fullTime,
            tags: ["Benefits", "Overtime"], postedHoursAgo: 9, applicants: 58,
            about: "Pick, pack, and ship orders in a climate-controlled facility. Health benefits after 60 days and paid overtime during peak season.",
            responsibilities: ["Pick orders with an RF scanner", "Pack and label shipments", "Load outbound trucks"],
            requirements: ["Lift up to 50 lbs", "Steel-toe shoes (provided)"],
            schedule: ["Mon–Fri 7a–3:30p", "Overtime in Nov–Dec"], hiringManager: "Dana Whitfield"),
        Job(title: "Retail Sales Associate", company: "Blue Oak Outfitters", logoSymbol: "bag.fill", logoColor: Color(hex: 0x1F8A70),
            payMin: 16, payMax: 18, distanceMiles: 2.1, address: "Barton Creek Square Mall", type: .partTime,
            tags: ["Employee discount"], noExperience: true, postedHoursAgo: 14, applicants: 22,
            about: "Outdoor apparel shop looking for weekend sales associates. You'll help customers find gear, keep the floor fresh, and ring up sales.",
            responsibilities: ["Help customers on the floor", "Restock and fold", "Process returns and exchanges"],
            requirements: ["Weekend availability", "Love of the outdoors is a plus"],
            schedule: ["Weekends 10a–8p", "15–25 hrs/week"], hiringManager: "Priya Natarajan"),
        Job(title: "Line Cook", company: "Bella's Pizzeria", logoSymbol: "flame.fill", logoColor: Color(hex: 0xC8102E),
            payMin: 18, payMax: 20, distanceMiles: 3.3, address: "5011 Burnet Rd", type: .fullTime,
            tags: ["Free meals", "Tips"], urgentlyHiring: true, postedHoursAgo: 1, applicants: 9,
            about: "Wood-fired pizzeria on Burnet. We need a line cook for dinner service starting this week. Pizza experience preferred but we'll train the right person.",
            responsibilities: ["Prep dough and toppings", "Work the oven during service", "Keep the line clean and stocked"],
            requirements: ["Food Handler card", "Evening availability"],
            schedule: ["Tue–Sat 3p–11p", "Dinner service"], hiringManager: "Marco Bellini"),
        Job(title: "Front Desk Agent", company: "Lakeside Hotel & Suites", logoSymbol: "bed.double.fill", logoColor: Color(hex: 0x3B4FA3),
            payMin: 17, payMax: 17, distanceMiles: 4.5, address: "208 Barton Springs Rd", type: .fullTime,
            tags: ["Benefits", "Hotel discounts"], postedHoursAgo: 26, applicants: 40,
            about: "Welcome guests at our 180-room lakeside property. Full-time with rotating shifts and paid training.",
            responsibilities: ["Check guests in and out", "Answer calls and requests", "Coordinate with housekeeping"],
            requirements: ["Customer service experience", "Comfortable with computers"],
            schedule: ["Rotating 7a–3p / 3p–11p", "Every other weekend"], hiringManager: "Tom Alvarez"),
        Job(title: "Delivery Driver", company: "GreenLeaf Pharmacy", logoSymbol: "car.fill", logoColor: Color(hex: 0x3C9D3C),
            payMin: 19, payMax: 22, distanceMiles: 2.8, address: "1100 W 6th St", type: .gig,
            tags: ["Mileage paid", "Flexible"], postedHoursAgo: 32, applicants: 17,
            about: "Deliver prescriptions to customers across central Austin using your own vehicle. Pick your blocks each week.",
            responsibilities: ["Pick up and deliver orders", "Verify ID on controlled deliveries", "Log deliveries in the app"],
            requirements: ["Valid driver's license", "Reliable vehicle and insurance"],
            schedule: ["Choose 4-hour blocks", "Daily 10a–8p"], hiringManager: "Aisha Bello"),
        Job(title: "Fitness Front Desk", company: "Metro Fitness", logoSymbol: "dumbbell.fill", logoColor: Color(hex: 0xFF8C1A),
            payMin: 15, payMax: 16, distanceMiles: 1.9, address: "600 W 5th St", type: .partTime,
            tags: ["Free membership"], noExperience: true, postedHoursAgo: 50, applicants: 27,
            about: "Early-morning front desk opener for a downtown gym. Greet members, scan badges, and keep the lobby stocked.",
            responsibilities: ["Open the club at 5am", "Check members in", "Light cleaning and towel service"],
            requirements: ["Early riser", "Reliable transportation"],
            schedule: ["Mon/Wed/Fri 4:45a–10a"], hiringManager: "Kevin Park"),
    ]

    static func conversations(now: Date = .now) -> [Conversation] {
        [
            Conversation(
                counterpartName: "Maya Chen", counterpartRole: "Store Manager", company: "Pinewood Coffee Roasters",
                logoSymbol: "cup.and.saucer.fill", logoColor: Color(hex: 0x8B5A2B),
                messages: [
                    ChatMessage(text: "Hey Jordan, you crushed the Saturday rush. Thanks for staying late!", isFromMe: false, date: now.addingTimeInterval(-3600 * 20)),
                    ChatMessage(text: "Anytime! Happy to help.", isFromMe: true, date: now.addingTimeInterval(-3600 * 19.5)),
                    ChatMessage(text: "Next week's schedule is posted. Let me know if anything doesn't work.", isFromMe: false, date: now.addingTimeInterval(-60 * 42)),
                ],
                unreadCount: 1,
                quickReplies: ["Looks good!", "Can I pick up a shift?", "I have a conflict Friday"],
                pendingReplies: ["Great—see you Thursday!", "I'll take a look and get back to you.", "Sounds good, thanks Jordan."]
            ),
            Conversation(
                counterpartName: "Luis Ortega", counterpartRole: "Owner", company: "Sunrise Diner",
                logoSymbol: "fork.knife", logoColor: Color(hex: 0xE2553B),
                messages: [
                    ChatMessage(text: "You applied to Server at Sunrise Diner", isFromMe: true, date: now.addingTimeInterval(-86400 * 2), kind: .system),
                    ChatMessage(text: "Hi Jordan! Thanks for applying. Could you stop by for a quick chat this week?", isFromMe: false, date: now.addingTimeInterval(-86400 * 2 + 1800)),
                    ChatMessage(text: "Yes! I'm free Thursday afternoon.", isFromMe: true, date: now.addingTimeInterval(-86400 * 2 + 3600)),
                    ChatMessage(text: "Interview confirmed", isFromMe: false, date: now.addingTimeInterval(-86400 * 2 + 4000), kind: .interview(day: "Thu, Oct 29", time: "2:00 PM")),
                ],
                unreadCount: 0,
                quickReplies: ["See you then!", "Can we move it to 3pm?", "What should I bring?"],
                pendingReplies: ["Perfect, see you Thursday at 2.", "Just bring your ID and a smile.", "Great, thanks Jordan!"]
            ),
            Conversation(
                counterpartName: "Dana Whitfield", counterpartRole: "Hiring Lead", company: "QuickShip Fulfillment",
                logoSymbol: "shippingbox.fill", logoColor: Color(hex: 0x2F6FED),
                messages: [
                    ChatMessage(text: "You applied to Warehouse Associate at QuickShip Fulfillment", isFromMe: true, date: now.addingTimeInterval(-86400 * 4), kind: .system),
                    ChatMessage(text: "Thanks for your application! We're reviewing candidates this week and will be in touch.", isFromMe: false, date: now.addingTimeInterval(-86400 * 4 + 7200)),
                ],
                unreadCount: 0,
                quickReplies: ["Thank you!", "What are the next steps?"],
                pendingReplies: ["We'll reach out by Friday with next steps.", "Appreciate your patience!"]
            ),
        ]
    }

    static func applications(now: Date = .now) -> [JobApplication] {
        [
            JobApplication(job: jobs[1], date: now.addingTimeInterval(-86400 * 2), status: .interview),
            JobApplication(job: jobs[2], date: now.addingTimeInterval(-86400 * 4), status: .viewed),
        ]
    }

    static let teammates: [Teammate] = [
        Teammate(name: "Maya Chen", role: "Store Manager", color: Color(hex: 0x8B5A2B), isManager: true),
        Teammate(name: "Sam Okafor", role: "Shift Lead", color: Color(hex: 0x2F6FED), isManager: false),
        Teammate(name: "Elena Vargas", role: "Barista", color: Color(hex: 0xE2553B), isManager: false),
        Teammate(name: "Tyler Brooks", role: "Barista", color: Color(hex: 0x1F8A70), isManager: false),
        Teammate(name: "Nia Thompson", role: "Barista", color: Color(hex: 0xFF8C1A), isManager: false),
    ]

    static func shifts(now: Date = .now) -> [Shift] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        func day(_ offset: Int) -> Date { cal.date(byAdding: .day, value: offset, to: today) ?? today }
        let location = "Pinewood Coffee · South Congress"
        return [
            Shift(date: day(0), start: .init(hour: 14), end: .init(hour: 20), role: "Barista", location: location, manager: "Maya Chen", coworkers: ["Sam Okafor", "Elena Vargas"]),
            Shift(date: day(1), start: .init(hour: 6), end: .init(hour: 12, minute: 30), role: "Barista · Opener", location: location, manager: "Maya Chen", coworkers: ["Tyler Brooks"]),
            Shift(date: day(3), start: .init(hour: 15), end: .init(hour: 21), role: "Barista", location: location, manager: "Maya Chen", coworkers: ["Nia Thompson", "Sam Okafor"]),
            Shift(date: day(4), start: .init(hour: 17), end: .init(hour: 22), role: "Barista · Closer", location: location, manager: "Maya Chen", coworkers: ["Elena Vargas"]),
            Shift(date: day(6), start: .init(hour: 7), end: .init(hour: 13), role: "Barista", location: location, manager: "Maya Chen", coworkers: ["Tyler Brooks", "Nia Thompson"]),
        ]
    }
}
