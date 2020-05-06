//
//  ArisenSwiftSoftkeySignatureProvider.swift
//  ArisenSwiftSoftkeySignatureProvider
//
//  Created by Farid Rahmani on 3/14/19.
// Copyright (c) 2017-2019 block.one and its contributors. All rights reserved.
//

import Foundation
import ArisenSwift
import ArisenSwiftEcc

/// Example signature provider for Arisen SDK for Swift for signing transactions using in-memory K1 private keys. This
/// signature provider implementation stores keys in memory and is therefore not secure. Use only for development purposes.
public final class ArisenSoftkeySignatureProvider: ArisenSignatureProviderProtocol {
    private struct Key {
        let arisenPublicKey: String
        let uncompressedPublicKey: Data
        let compressedPublicKey: Data
        let privateKey: Data
    }
    private var keyPairs = [Data: Key]()
    private let lock = String()

    /// Initializes the signature provider using the private keys in the given array.
    ///
    /// - Parameter privateKeys: Array of private keys in `String` format.
    /// - Throws: Throws an error if any of the keys in the given `privateKeys` array is not valid.
    public init(privateKeys: [String]) throws {
        for privateKey in privateKeys {
            let (_, version, _) = try privateKey.arisenComponents()
            if version != "K1" {
                throw ArisenError(ArisenErrorCode.keyManagementError, reason: "Unsupported key type. Only K1 key types are supported in this version of the library. Key: \(privateKey) Type: \(version)")
            }
            let privateKeyData = try Data(ArisenPrivateKey: privateKey)
            let publicKeyData = try EccRecoverKey.recoverPublicKey(privateKey: privateKeyData, curve: .k1)
            guard let compressedPublicKey = publicKeyData.toCompressedPublicKey else {
                throw ArisenError(ArisenErrorCode.keyManagementError, reason: "Cannot compress key \(publicKeyData.hex)")
            }
            let arisenPublicKey = compressedPublicKey.toArisenK1PublicKey
            let key = Key(arisenPublicKey: arisenPublicKey, uncompressedPublicKey: publicKeyData, compressedPublicKey: compressedPublicKey, privateKey: privateKeyData)
            keyPairs[compressedPublicKey] = key
        }

    }

    /// Asynchronous method signing a transaction request. Invoked by an `ArisenTransaction` during the signing process.
    ///
    /// - Parameters:
    ///   - request: An `ArisenTransactionSignatureRequest` struct (as defined in the `ArisenSwift` library).
    ///   - completion: Calls the completion with an `ArisenTransactionSignatureResponse` struct (as defined in the `ArisenSwift` library).
    public func signTransaction(request: ArisenTransactionSignatureRequest, completion: @escaping (ArisenTransactionSignatureResponse) -> Void) {
        var response = ArisenTransactionSignatureResponse()
        do {
            var signatures = [String]()

            for arisenPublicKey in request.publicKeys {
                let compressedPublicKey = try Data(arisenPublicKey: arisenPublicKey)
                objc_sync_enter(lock)
                guard let key = keyPairs[compressedPublicKey] else {
                    response.error = ArisenError(.keyManagementError, reason: "No private key available for \(arisenPublicKey)")
                    return completion(response)
                }
                objc_sync_exit(lock)
                let chainIdData = try Data(hex: request.chainId)
                let zeros = Data(repeating: 0, count: 32)
                let data = try ArisenEccSign.signWithK1(publicKey: key.uncompressedPublicKey, privateKey: key.privateKey, data: chainIdData + request.serializedTransaction + zeros)
                signatures.append(data.toArisenK1Signature)
            }
            var signedTransaction = ArisenTransactionSignatureResponse.SignedTransaction()
            signedTransaction.signatures = signatures
            signedTransaction.serializedTransaction = request.serializedTransaction
            response.signedTransaction = signedTransaction
            completion(response)
        } catch {
            response.error = error as? ArisenError
            completion(response)
        }

    }

    /// Asynchronous method that provides available public keys to the `ArisenTransaction` during the signing preparation process.
    ///
    /// - Parameter completion: Calls the completion with an `ArisenAvailableKeysResponse` stuct containing an optional array of available public keys in `String` format.
    public func getAvailableKeys(completion: @escaping (ArisenAvailableKeysResponse) -> Void) {
        var response = ArisenAvailableKeysResponse()
        objc_sync_enter(lock)
        response.keys = Array(keyPairs.values).compactMap({ (key) -> String? in
            return key.arisenPublicKey
        })
        objc_sync_exit(lock)
        completion(response)
    }
}
