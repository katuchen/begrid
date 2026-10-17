import Foundation
import Testing
@testable import BeGrid

struct PipelineOptionsTests {
    @Test func everythingIsEnabledByDefault() throws {
        let defaults = try #require(UserDefaults(suiteName: "PipelineOptionsTests.defaults"))
        defaults.removePersistentDomain(forName: "PipelineOptionsTests.defaults")

        #expect(PipelineOptions.overridden(by: defaults) == PipelineOptions())
    }

    @Test func launchArgumentStringDisablesFlag() throws {
        let defaults = try #require(UserDefaults(suiteName: "PipelineOptionsTests.override"))
        defaults.removePersistentDomain(forName: "PipelineOptionsTests.override")
        defaults.set("NO", forKey: "pipeline.downsample")

        #expect(PipelineOptions.overridden(by: defaults) == PipelineOptions(downsampling: false))
    }
}
