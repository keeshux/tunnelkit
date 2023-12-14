//
//  CryptoCBCTests.swift
//  TunnelKitOpenVPNTests
//
//  Created by Davide De Rosa on 12/12/23.
//  Copyright (c) 2023 Davide De Rosa. All rights reserved.
//
//  https://github.com/passepartoutvpn
//
//  This file is part of TunnelKit.
//
//  TunnelKit is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  TunnelKit is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with TunnelKit.  If not, see <http://www.gnu.org/licenses/>.
//

import XCTest
@testable import TunnelKitCore
@testable import TunnelKitOpenVPNCore
import CTunnelKitCore
import CTunnelKitOpenVPNProtocol

class CryptoCBCTests: XCTestCase {
    private let cipherKey = ZeroingData(count: 32)

    private let hmacKey = ZeroingData(count: 32)

    private let plainData = Data(hex: "00112233ffddaa")

    private let plainHMACData = Data(hex: "8dd324c81ca32f52e4aa1aa35139deba799a68460e80b0e5ac8bceb043edf6e500112233ffddaa")

    private let encryptedHMACData = Data(hex: "fea3fe87ee68eb21c697e62d3c29f7bea2f5b457d9a7fa66291322fc9c2fe6f700000000000000000000000000000000ebe197e706c3c5dcad026f4e3af1048b")

    private var packetId: [UInt8] = [0x56, 0x34, 0x12, 0x00]

    private var ad: [UInt8] = [0x00, 0x12, 0x34, 0x56]

    private lazy var flags: CryptoFlags = {
        return packetId.withUnsafeBufferPointer { iv in
            ad.withUnsafeBufferPointer { ad in
                CryptoFlags(iv: iv.baseAddress,
                            ivLength: iv.count,
                            ad: ad.baseAddress,
                            adLength: ad.count,
                            forTesting: true)
            }
        }
    }()

    func test_givenDecrypted_whenEncryptWithoutCipher_thenEncodesWithHMAC() {
        let sut = CryptoCBC(cipherName: nil, digestName: "sha256")
        sut.configureEncryption(withCipherKey: nil, hmacKey: hmacKey)

        do {
            let returnedData = try sut.encryptData(plainData, flags: &flags)
            XCTAssertEqual(returnedData, plainHMACData)
        } catch {
            XCTFail("Cannot encrypt: \(error)")
        }
    }

    func test_givenDecrypted_whenEncryptWithCipher_thenEncryptsWithHMAC() {
        let sut = CryptoCBC(cipherName: "aes-128-cbc", digestName: "sha256")
        sut.configureEncryption(withCipherKey: cipherKey, hmacKey: hmacKey)

        do {
            let returnedData = try sut.encryptData(plainData, flags: &flags)
            XCTAssertEqual(returnedData, encryptedHMACData)
        } catch {
            XCTFail("Cannot encrypt: \(error)")
        }
    }

    func test_givenEncodedWithHMAC_thenDecodes() {
        let sut = CryptoCBC(cipherName: nil, digestName: "sha256")
        sut.configureDecryption(withCipherKey: nil, hmacKey: hmacKey)

        do {
            let returnedData = try sut.decryptData(plainHMACData, flags: &flags)
            XCTAssertEqual(returnedData, plainData)
        } catch {
            XCTFail("Cannot decrypt: \(error)")
        }
    }

    func test_givenEncryptedWithHMAC_thenDecrypts() {
        let sut = CryptoCBC(cipherName: "aes-128-cbc", digestName: "sha256")
        sut.configureDecryption(withCipherKey: cipherKey, hmacKey: hmacKey)

        do {
            let returnedData = try sut.decryptData(encryptedHMACData, flags: &flags)
            XCTAssertEqual(returnedData, plainData)
        } catch {
            XCTFail("Cannot decrypt: \(error)")
        }
    }

    func test_givenHMAC_thenVerifies() {
        let sut = CryptoCBC(cipherName: nil, digestName: "sha256")
        sut.configureDecryption(withCipherKey: nil, hmacKey: hmacKey)

        XCTAssertNoThrow(try sut.verifyData(plainHMACData, flags: &flags))
        XCTAssertNoThrow(try sut.verifyData(encryptedHMACData, flags: &flags))
    }
}
