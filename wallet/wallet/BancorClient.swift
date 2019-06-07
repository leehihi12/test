//
//  BancorClient.swift
//  CoinUs
//
//  Created by HoIck on 30/01/2019.
//  Copyright © 2019 CoinUs. All rights reserved.
//

import UIKit
import Geth
import web3swift
import UInt256
import BigInt

enum BNUSMarketStatus{
    case open
    case close
    case pending
}

class BancorClient{
    
    static let shared = BancorClient()
    private init() {}
    
    let signer = "Write proper key value";
    let bnusConverterAddress = "0x13bccb947052935cc5a96d8bd761984918ccb667"
    let bnusTokenAddress = "0xbcf8969f0f5c5075f0b925809fed62eb04e58ecf"
    let cnusTokenAddress = "0x722F2f3EaC7e9597C73a593f7CF3de33Fbfc3308"
    let tokenPoolAddress = "0x5ebd231ca190623fbf829f97938ac2c127582ea0"
    let cnusStakingAddress = "0x70d93c969ab23468b6305f0180b6f05e8afe046f"
    
    var bnusStatus: BNUSMarketStatus = .close;
    var messageNoBNUS: String = "";
    var sellFees: String = "";
    var buyFees: String = "";
    
    let maxSendLimit: Double = 200000
    let maxApproveLimit: Double = 80000
    
    func getEnableBNUS(_ handler: @escaping (()->Void) ){
        NetworkManager.shared.getBnusMarketConfig{
            result, error in
            
            BancorClient.shared.bnusStatus = BNUSMarketStatus.close;
            if result["status"]["code"].intValue == 200,
                result["data"]["items"].count > 0{
                if result["data"]["items"][0]["activeYn"].stringValue.lowercased() == "y"{
                    BancorClient.shared.bnusStatus = BNUSMarketStatus.open;
                }else if result["data"]["items"][0]["activeYn"].stringValue.lowercased() == "p"{
                    BancorClient.shared.bnusStatus = BNUSMarketStatus.pending;
                }else{
                    BancorClient.shared.bnusStatus = BNUSMarketStatus.close;
                }
                
                if let noti = result["data"]["items"][0]["notiTitle"].string{
                    BancorClient.shared.messageNoBNUS = noti
                }
                BancorClient.shared.buyFees = result["data"]["items"][0]["buyFees"].stringValue
                BancorClient.shared.sellFees = result["data"]["items"][0]["sellFees"].stringValue
 
            }
            handler()
        }
    }
    
    func getApproveABI(address: String,
                       amount: String)->String?{
        if let a = BigUInt(amount, radix: 0){
            do {
                
                let function = try SolidityFunction(function: "approve(address,uint256)");
                let result = function.encode([web3swift.Address(address), a])
                
                return "0x"+result.hex
            } catch(let error) {
            }
        }
        return nil;
    }
    
    func getAllowanceABI(owner: String,
                         spender: String)->String?{
        do {
            let function = try SolidityFunction(function: "allowance(address,address)");
            let result = function.encode([web3swift.Address(owner), web3swift.Address(spender)])
            
            return "0x"+result.hex
        } catch(let error) {
        }
        
        return nil;
    }
    
    func getStakeABI(amount: String,
                     expiration: Int,
                     signature: Data )->String? {
        if let a = BigUInt(amount, decimals: 0) {
            let e = BigUInt(BigInt(expiration))
            
            do {
                let function = try SolidityFunction(function: "stake(uint256,uint256,bytes)");
                let result = function.encode([a, e, signature])
                
                return "0x"+result.hex
            } catch(let error) {
            }
        }
        
        return nil;
    }
    
    func getBuyBnusABI(amount: String,
                       min: String,
                       expiration: Int,
                       signature: Data )->String? {
        if let a = BigUInt(amount, decimals: 0),
            let m = BigUInt(min, decimals: 0) {
            let e = BigUInt(BigInt(expiration))
            
            do {
                let function = try SolidityFunction(function: "buyBnus(uint256,uint256, uint256,bytes)");
                let result = function.encode([a, m, e, signature])
                
                return "0x"+result.hex
            } catch(let error) {
            }
        } else {
        }
        
        return nil;
    }
    
    func getSellBnusABI(amount: String,
                        min: String,
                        expiration: Int,
                        signature: Data )->String? {
        if let a = BigUInt(amount, decimals: 0),
            let m = BigUInt(min, decimals: 0) {
            let e = BigUInt(BigInt(expiration))
            
            do {
                let function = try SolidityFunction(function: "sellBnus(uint256,uint256,uint256,bytes)");
                let result = function.encode([a, m, e, signature])
                
                return "0x"+result.hex
            } catch(let error) {
            }
        }
        
        return nil;
    }
    
    func getExpectedCnusABI(cnus: String)->String? {
        if let c = BigUInt(cnus, decimals: 0){
            do {
                let function = try SolidityFunction(function: "getExpectedCnus(uint256)");
                let result = function.encode([c])

                return "0x"+result.hex
            } catch(let error) {
            }
        }
        
        return nil;
    }
    
    func getExpectedBnusABI(cnus: String)->String? {
        if let c = BigUInt(cnus, decimals: 0) {
            do {
                let function = try SolidityFunction(function: "getExpectedBnus(uint256)");
                let result = function.encode([c])

                return "0x"+result.hex
            } catch(let error) {
            }
        }
        
        return nil;
    }
 
    func getStakeSha3Hex(amount: String,
                         expiration: Int)->String?{
        
        if let a = UInt256(amount) {
            let e = UInt256(expiration)
            let temp = "0x\(a)\(e)"
            let result =
                Data(hex: temp).sha3(.keccak256).hex
            
            return result
        }
        
        return nil
    }
    
    func getTransferBnusSha3Hex(amount: String,
                                min: String,
                                expiration: Int)->String?{
        if let a = UInt256(amount),
            let m = UInt256(min) {
            let e = UInt256(expiration)
            let temp = "0x\(a)\(m)\(e)"
            
            let result =
                Data(hex: temp).sha3(.keccak256).hex

            return result
        }
        return nil
    }

    func personalSign(hex: String) -> Data?{
        do {
            let key = PrivateKey(Data(hex: self.signer))
            
            if let message = self.getPersonalMessage(hex) {
                let signed = try key.sign(hash: message)
                
                var list = Array<UInt8>(hex: signed.data.hex)
                
                if list.count > 64 {
                    list[64] = list[64] + 27
                }
                
                let result = Data(fromArray: list)

                return result
            }
        }catch (let error){
        }
        
        return nil;
    }
    
    func getPersonalMessage(_ hexString: String) -> Data? {
        let prefix = "\u{19}Ethereum Signed Message:\n"
        
        var hex = hexString
        if hex.hasPrefix("0x") {
            hex = hex.replacingOccurrences(of: "0x", with: "")
        }
        
        let messageData = Data(hex: hex)
        if let prefixData = (prefix + String(messageData.count)).data(using: .ascii){
            
            return (prefixData + messageData).sha3(.keccak256)
        }
        
        return nil;
    }

    func getExpiration() -> Int{
        return Int(Date().timeIntervalSince1970 + 3000);
    }
    
    //MARK: - makeRawTx
    func getBancorRawTx(account: GethAccount,
                        nonce: Int64,
                        price: Int64,
                        limit: Int64,
                        address: String,
                        path: Int,
                        abi: String,
                        amount: Int64 = 0) -> String?{
        let password = "";
        
        do {
            let keydir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/keystore"
            let gethKeyStorage: GethKeyStore = GethNewKeyStore(keydir, GethLightScryptN, GethLightScryptP)
            
            try gethKeyStorage.unlock(account,
                                      passphrase: password)
            var transaction: GethTransaction!
            
            if let d = abi.hexadecimalData{
                transaction = GethNewTransaction(nonce,
                                                 GethNewAddressFromHex(address, nil),
                                                 GethNewBigInt(amount),//Amount
                    limit,//Limit
                    GethNewBigInt(price),//Price
                    d)
                
                var gethNewBigInt: GethBigInt
                gethNewBigInt = GethNewBigInt(1)

                let signedTransaction = try gethKeyStorage.signTx(account,
                                                                  tx: transaction,
                                                                  chainID: gethNewBigInt)
                let rlp = try signedTransaction.encodeRLP()

                return rlp.hexEncoded
            } else {
            }
        } catch (let error){
        }
        
        return nil
    }
}
