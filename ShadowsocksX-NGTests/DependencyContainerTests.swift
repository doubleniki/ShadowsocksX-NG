//
//  DependencyContainerTests.swift
//  ShadowsocksX-NGTests
//

import XCTest
@testable import ShadowsocksX_NG

final class DependencyContainerTests: XCTestCase {
    func testMockContainerUsesInjectedServices() {
        let container = MockDependencyContainer()

        XCTAssertTrue(container.preferences === container.mockPreferences)
        XCTAssertTrue(container.profileManager === container.mockProfileManager)
        XCTAssertTrue(container.launchAgent === container.mockLaunchAgent)
        XCTAssertTrue(container.fileSystem === container.mockFileSystem)
    }

    func testProxyCoordinatorPersistsModeChangesThroughPreferences() {
        let preferences = MockPreferences()
        let coordinator = ProxyCoordinator(
            preferences: preferences,
            launchAgent: MockLaunchAgent(),
            profileManager: MockProfileManager()
        )

        coordinator.switchMode(to: .global)

        XCTAssertEqual(preferences.string(forKey: "ShadowsocksRunningMode"), "global")
    }
}
