import SwiftUI

/// Landing tab: the disclaimer, the room label for the report, and the order to run the tools in.
struct HomeView: View {
    @EnvironmentObject private var session: TriageSession

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("A pocket first-aid kit for home resiliency")
                        .font(.title.bold())
                        .foregroundStyle(Theme.ink)

                    Text("After a storm, water hides inside walls for days before anything shows. StructSense uses the sensors already in your phone to find the wet spots first, so you know where to open up, what to photograph for insurance, and when to call a professional.")
                        .font(.body)
                        .foregroundStyle(Theme.muted)

                    DisclaimerBanner()

                    ToolCard(title: "Where are you checking?") {
                        TextField("Room or wall, for example: Garage north wall", text: $session.report.roomLabel)
                            .textFieldStyle(.roundedBorder)
                        Text("This label goes at the top of your shared report.")
                            .font(.footnote)
                            .foregroundStyle(Theme.muted)
                    }

                    ToolCard(title: "Run the three checks in order") {
                        VStack(alignment: .leading, spacing: 12) {
                            StepRow(icon: "dot.radiowaves.left.and.right", title: "Magnetic sweep", text: "Slide the phone across the wall to map studs, pipes and nail plates. Metal tells you where the framing is, and where water travels.")
                            StepRow(icon: "waveform", title: "Acoustic check", text: "Press the phone flat on a dry reference spot, then on the suspect spot. The app plays a low tone and compares how much each spot absorbs.")
                            StepRow(icon: "humidity.fill", title: "Humidity puck", text: "Leave a Bluetooth sensor in the crawlspace or closet and watch for readings above 60 percent, the EPA alert line.")
                        }
                    }

                    ToolCard(title: "What the phone cannot do") {
                        Text("It cannot see copper or PVC, cannot measure moisture content, and cannot judge whether a wall is structurally sound. Treat every result as a reason to look closer, not as a diagnosis.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.muted)
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("StructSense")
        }
    }
}

private struct StepRow: View {
    let icon: String
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Theme.clinical)
                .frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.ink)
                Text(text).font(.subheadline).foregroundStyle(Theme.muted)
            }
        }
    }
}
