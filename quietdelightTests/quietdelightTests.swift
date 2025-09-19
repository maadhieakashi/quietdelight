//
//  quietdelightcafeTests.swift
//  quietdelightcafeTests
//
//  Created by SAHimeshi 002 on 2025-08-18.
//

import Testing
@testable import quietdelight

struct quietdelightTests {
    @Test func testSignIn() async throws {
        let auth = FirebaseAuthManager.shared
        let testEmail = "testuser@example.com"
        let testPassword = "testpassword"
        let resultMessage: String? = await withCheckedContinuation { continuation in
            auth.signIn(email: testEmail, password: testPassword) { result in
                switch result {
                case .success(let message):
                    continuation.resume(returning: message)
                case .failure(let error):
                    continuation.resume(returning: error)
                }
            }
        }
        #expect(resultMessage != nil)
    }

    

}
