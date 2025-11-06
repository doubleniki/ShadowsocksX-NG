//
//  ServerProfileTests.swift
//  ShadowsocksX-NG
//
//  Created by Rainux Luo on 07/01/2017.
//  Copyright © 2017 qiuyuzhou. All rights reserved.
//

import XCTest
@testable import ShadowsocksX_NG

class ServerProfileTests: XCTestCase {

    var profile: ServerProfile!

    override func setUp() {
        super.setUp()

        profile = ServerProfile.fromDictionary(["ServerHost": "example.com",
                                                "ServerPort": 8388,
                                                "Method": "aes-256-cfb",
                                                "Password": "password",
                                                "Remark": "Protoss Prism",
                                                "OTA": true])
        XCTAssertNotNil(profile)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testInitWithSelfGeneratedURL() {
        guard let profileURL = profile.URL() else {
            XCTFail("Failed to generate URL from profile")
            return
        }
        let newProfile = ServerProfile.init(url: profileURL)

        XCTAssertEqual(newProfile?.serverHost, profile.serverHost)
        XCTAssertEqual(newProfile?.serverPort, profile.serverPort)
        XCTAssertEqual(newProfile?.method, profile.method)
        XCTAssertEqual(newProfile?.password, profile.password)
        XCTAssertEqual(newProfile?.remark, profile.remark)
    }

    func testInitWithBase64EncodedURL() {
        // "ss://aes-256-cfb:password@example.com:8388"
        guard let url = URL(string: "ss://YWVzLTI1Ni1jZmI6cGFzc3dvcmRAZXhhbXBsZS5jb206ODM4OA") else {
            XCTFail("Failed to create URL")
            return
        }

        let profile = ServerProfile(url: url)

        XCTAssertNotNil(profile)

        XCTAssertEqual(profile?.serverHost, "example.com")
        XCTAssertEqual(profile?.serverPort, 8388)
        XCTAssertEqual(profile?.method, "aes-256-cfb")
        XCTAssertEqual(profile?.password, "password")
        XCTAssertEqual(profile?.remark, "")
    }

    func testInitWithBase64EncodedURLandQuery() {
        // "ss://aes-256-cfb:password@example.com:8388?Remark=Prism&OTA=true"
        guard let url = URL(string: "ss://YWVzLTI1Ni1jZmI6cGFzc3dvcmRAZXhhbXBsZS5jb206ODM4OD9SZW1hcms9UHJpc20mT1RBPXRydWU") else {
            XCTFail("Failed to create URL")
            return
        }

        let profile = ServerProfile(url: url)

        XCTAssertNotNil(profile)

        XCTAssertEqual(profile?.serverHost, "example.com")
        XCTAssertEqual(profile?.serverPort, 8388)
        XCTAssertEqual(profile?.method, "aes-256-cfb")
        XCTAssertEqual(profile?.password, "password")
        XCTAssertEqual(profile?.remark, "Prism")
    }
    
    func testInitWithLegacyBase64EncodedURLWithTag() {
        guard let url = URL(string: "ss://YmYtY2ZiOnRlc3RAMTkyLjE2OC4xMDAuMTo4ODg4Cg#example-server") else {
            XCTFail("Failed to create URL")
            return
        }

        let profile = ServerProfile(url: url)
        
        XCTAssertNotNil(profile)
        XCTAssertEqual(profile?.remark, "example-server")
    }
    
    func testInitWithLegacyBase64EncodedURLWithSymboInPassword() {
        // Note that the legacy URI doesn't follow RFC3986. It means the password here
        // should be plain text, not percent-encoded.
        // Ref: https://shadowsocks.org/en/config/quick-guide.html
        // `ss://bf-cfb:test/!@#:@192.168.100.1:8888`
        guard let url = URL(string: "ss://YmYtY2ZiOnRlc3QvIUAjOkAxOTIuMTY4LjEwMC4xOjg4ODg#example") else {
            XCTFail("Failed to create URL")
            return
        }

        let profile = ServerProfile(url: url)
        
        XCTAssertNotNil(profile)
        XCTAssertEqual(profile?.password, "test/!@#:")
    }
    
    func testInitWithLegacyURLWithEscapedChineseRemark() {
        guard let url = URL(string: "ss://YmYtY2ZiOnRlc3RAMTkyLjE2OC4xMDAuMTo4ODg4#%e4%bd%a0%e5%a5%bd") else {
            XCTFail("Failed to create URL")
            return
        }
        let profile = ServerProfile(url: url)
        XCTAssertNotNil(profile)
        XCTAssertEqual(profile?.remark, "你好")
    }

    func testInitWithEmptyURL() {
        guard let url = URL(string: "ss://") else {
            XCTFail("Failed to create URL")
            return
        }

        let profile = ServerProfile(url: url)

        XCTAssertNil(profile)
    }

    func testInitWithBase64EncodedInvalidURL() {
        // "ss://invalid url"
        guard let url = URL(string: "ss://aW52YWxpZCB1cmw") else {
            XCTFail("Failed to create URL")
            return
        }

        let profile = ServerProfile(url: url)

        XCTAssertNil(profile)
    }

    func testInitWithSIP002URL() {
        // "ss://aes-256-cfb:password@example.com:8388?Remark=Prism&OTA=true"
        guard let url = URL(string: "ss://YWVzLTI1Ni1jZmI6cGFzc3dvcmQ=@example.com:8388/?Remark=Prism&OTA=true") else {
            XCTFail("Failed to create URL")
            return
        }

        let profile = ServerProfile(url: url)

        XCTAssertNotNil(profile)

        XCTAssertEqual(profile?.serverHost, "example.com")
        XCTAssertEqual(profile?.serverPort, 8388)
        XCTAssertEqual(profile?.method, "aes-256-cfb")
        XCTAssertEqual(profile?.password, "password")
        XCTAssertEqual(profile?.remark, "Prism")
    }

    func testInitWithSIP002URLProfileName() {
        guard let url = URL(string: "ss://YWVzLTI1Ni1jZmI6cGFzc3dvcmQ=@example.com:8388/#Name") else {
            XCTFail("Failed to create URL")
            return
        }

        let profile = ServerProfile(url: url)

        XCTAssertNotNil(profile)
        XCTAssertEqual(profile?.remark, "Name")
    }

    func testInitWithSIP002URLProfileNameOverride() {
        guard let url = URL(string: "ss://YWVzLTI1Ni1jZmI6cGFzc3dvcmQ=@example.com:8388/?Remark=Name#Overriden") else {
            XCTFail("Failed to create URL")
            return
        }

        let profile = ServerProfile(url: url)

        XCTAssertNotNil(profile)
        XCTAssertEqual(profile?.remark, "Overriden")
    }
    
    func testInitWithSIP002URLProfileWithSIP003PluginNoPluginOpts() {
        guard let url = URL(string: "ss://YWVzLTI1Ni1jZmI6cGFzc3dvcmQ=@134.209.56.100:8088/?plugin=v2ray-plugin;#moon-v2ray") else {
            XCTFail("Failed to create URL")
            return
        }

        let profile = ServerProfile(url: url)
        
        XCTAssertNotNil(profile)
        XCTAssertEqual(profile?.plugin, "v2ray-plugin")
    }
    
    func testInitWithSIP002URLProfileWithSIP003Plugin() {
        guard let url = URL(string: "ss://YWVzLTI1Ni1jZmI6cGFzc3dvcmQ=@134.209.56.100:8088/?plugin=v2ray-plugin;tls#moon-v2ray") else {
            XCTFail("Failed to create URL")
            return
        }

        let profile = ServerProfile(url: url)
        
        XCTAssertNotNil(profile)
        XCTAssertEqual(profile?.plugin, "v2ray-plugin")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    

}
