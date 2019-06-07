//
//  wallet.swift
//  wallet
//
//  Created by HoIck on 2019. 6. 5..
//  Copyright © CoinUs. All rights reserved.
//

import SwiftyJSON

class wallet {
    private init() {}
    
    func sample() {
        // Create mnemonic
        if let mnemonic = Utils.shared.createMnemonic(),
            mnemonic.count == 12 {
            // mnemonic is created.
        } else {
            // error
        }
        
        // Buy Bnus
        self.buyBnus("1000",
                     mnemonic: [""],
                     path: 1, nonce: 1, handler: {
                        isSuccess, message in
                        
                        if isSuccess{
                            // Succeess
                        } else {
                            // Fail
                        }
        })
        
        // Sell Bnus
        self.sellBnus("1000",
                      mnemonic: [""],
                      path: 1, handler: {
                        isSuccess, message in
                        
                        if isSuccess{
                            // Succeess
                        } else {
                            // Fail
                        }
        })
    }
    
    func buyBnus(_ amount: String,
                 mnemonic: [String],
                 path: Int,
                 nonce: Int64,
                 handler: @escaping ((Bool, String)->Void)) {
        if let address = ETHClient.shared.getETHAddress(mnemonic, path: path){
            
            let expiration = BancorClient.shared.getExpiration()
            let min = "1"
            
            if let hex = BancorClient.shared.getTransferBnusSha3Hex(amount: amount, min: min, expiration: expiration) {
                if let signature = BancorClient.shared.personalSign(hex: hex) {
                    if let abi = BancorClient.shared.getBuyBnusABI(amount: amount,
                                                                   min: min,
                                                                   expiration: expiration,
                                                                   signature: signature) {
                        let bnusConverterAddress = BancorClient.shared.bnusConverterAddress;
                        let price: Int64 = 1000
                        let limit: Int64 = Int64(BancorClient.shared.maxSendLimit)

                        if let account = ETHClient.shared.getGethAccount(mnemonic, path: path),
                            let rawTx = BancorClient.shared.getBancorRawTx(account: account, nonce: nonce, price: price, limit: limit, address: bnusConverterAddress, path: path, abi: abi) {
                            
                            ETHClient.shared.sendRawTransaction(rawTx, block: {
                                [weak self] result, error in
                                
                                if result["error"] != JSON.null{
                                    handler(false, result["error"]["message"].stringValue)
                                }else{
                                    handler(true, result["result"].stringValue)
                                }
                            });
                        }
                    }
                }
            }
        }
    }
    
    func sellBnus(_ amount: String,
                      mnemonic: [String],
                      path: Int,
                      handler: @escaping ((Bool, String)->Void)) {
        if let address = ETHClient.shared.getETHAddress(mnemonic, path: path) {
            let expiration = BancorClient.shared.getExpiration()
            let min = "1"
            
            if let hex = BancorClient.shared.getTransferBnusSha3Hex(amount: amount, min: min, expiration: expiration),
                let signature = BancorClient.shared.personalSign(hex: hex) {
                if let abi = BancorClient.shared.getSellBnusABI(amount: amount,
                                                                min: min,
                                                                expiration: expiration,
                                                                signature: signature){
                    let bnusConverterAddress = BancorClient.shared.bnusConverterAddress;

                    ETHClient.shared.getTransactionCount(address, block: {
                        [weak self] result, error in
                        
                        if let selfWeak = self {
                            if result["error"] != JSON.null{
                                handler(false, result["error"]["message"].stringValue)
                            }else{
                                
                                let price: Int64 = 1000
                                let limit: Int64 = Int64(BancorClient.shared.maxSendLimit)
                                
                                if let nonce = Int64(result["result"].stringValue.replacingOccurrences(of: "0x", with: ""), radix: 16),
                                    let account = ETHClient.shared.getGethAccount(mnemonic, path: path),
                                    let rawTx = BancorClient.shared.getBancorRawTx(account: account, nonce: nonce, price: price, limit: limit, address: bnusConverterAddress, path: path, abi: abi){

                                    ETHClient.shared.sendRawTransaction(rawTx, block: {
                                        result, error in
                                        if result["error"] == JSON.null{
                                            handler(true, result["result"].stringValue)
                                        }else{
                                            handler(false, result["error"]["message"].stringValue)
                                        }
                                    });
                                }
                            }
                        }
                    })
                }
            }
        }
    }
}
