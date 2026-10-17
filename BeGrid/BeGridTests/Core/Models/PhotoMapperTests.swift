import Testing
@testable import BeGrid

struct PhotoMapperTests {
    struct SummaryCase: Sendable, CustomTestStringConvertible {
        let altDescription: String?
        let description: String?
        let expected: String?

        var testDescription: String {
            "alt: \(altDescription.debugDescription), description: \(description.debugDescription)"
        }
    }

    @Test(arguments: [
        SummaryCase(altDescription: "alt", description: "desc", expected: "alt"),
        SummaryCase(altDescription: nil, description: "desc", expected: "desc"),
        SummaryCase(altDescription: "", description: "desc", expected: "desc"),
        SummaryCase(altDescription: "  \n", description: "desc", expected: "desc"),
        SummaryCase(altDescription: "  alt  ", description: nil, expected: "alt"),
        SummaryCase(altDescription: nil, description: nil, expected: nil),
        SummaryCase(altDescription: " ", description: "\t", expected: nil)
    ])
    func summaryFallsBackInOrder(_ testCase: SummaryCase) {
        let summary = PhotoMapper.summary(altDescription: testCase.altDescription, description: testCase.description)
        #expect(summary == testCase.expected)
    }
}
