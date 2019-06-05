//
//  ETHClient.swift
//  CoinUs
//
//  Created by HoIck on 2017. 12. 3..
//  Copyright © CoinUs. All rights reserved.
//

import UIKit
import SwiftyJSON
import Geth
import BigInt

enum EthereumUnit: Int64 {
    case wei = 1
    case kwei = 1_000
    case gwei = 1_000_000_000
    case ether = 1_000_000_000_000_000_000
}

class ETHClient {
    static let shared = ETHClient()
    private init() {}
    
    func getETHAddress(_ words: String,
                       path: Int) -> String?{
        
        return self.getETHAddress(words.components(separatedBy: " "), path: path);
    }
    
    func getETHAddress(_ words: [String],
                       path: Int) -> String?{
        let passphrase = "";
        
        if let mnemonic = BTCMnemonic(words: words,
                                      password: "",
                                      wordListType: .english){
            
            let seed = mnemonic.seed
            let datadir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let keydir = datadir + "/keystore"
            let gethKeyStorage = GethNewKeyStore(keydir, GethLightScryptN, GethLightScryptP)
            let chain = BTCKeychain(seed: seed).derivedKeychain(withPath: "m/44'/60'/0'/0/\(path)")
            let key = chain?.key
            
            if let privateKey = (key?.privateKey as Data?),
                let dic = Utils.shared.getKeystoreDic(privateKey, passphrase: passphrase){
                let value = dic.jsonString
                
                if let v = value {
                    let data = v.data(using: .utf8)
                    
                    do {
                        let gethAccount = try gethKeyStorage?.importKey(data,
                                                                        passphrase: passphrase,
                                                                        newPassphrase: passphrase)
                        
                        let address = gethAccount?.getAddress().getHex()
                        
                        try gethKeyStorage?.delete(gethAccount,
                                                   passphrase: passphrase)
                        
                        return address
                    } catch {
                    }
                }
            }
        }
        
        return nil;
    }
    
    func getEthKey(_ words: String,
                   path: Int)  -> BTCKey?{
        if let mnemonic = BTCMnemonic(words: words.components(separatedBy: " "),
                                      password: "",
                                      wordListType: .english){
            let seed = mnemonic.seed
            let path = "m/44'/60'/0'/0/\(path)"
            let chain = BTCKeychain(seed: seed).derivedKeychain(withPath: path)
            
            return chain?.key
        }
        
        return nil;
    }
    
    func getGethAccount(_ words: [String],
                        path: Int) -> GethAccount?{
        let passphrase = "";
        
        if let mnemonic = BTCMnemonic(words: words,
                                      password: "",
                                      wordListType: .english){
            let seed = mnemonic.seed
            let chain = BTCKeychain(seed: seed).derivedKeychain(withPath: "m/44'/60'/0'/0/\(path)")
            let key = chain?.key
            
            if let privateKey = (key?.privateKey as Data?){
                if let value = Utils.shared.getKeystoreDic(privateKey, passphrase: passphrase)?.jsonString{
                    if let data = value.data(using: .utf8){
                        let keydir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/keystore"
                        let gethKeyStorage: GethKeyStore = GethNewKeyStore(keydir, GethLightScryptN, GethLightScryptP)
                        
                        do {
                            let gethAccount = try gethKeyStorage.importKey(data,
                                                                           passphrase: passphrase,
                                                                           newPassphrase: passphrase)
                            
                            return gethAccount;
                        } catch {
                        }
                    }
                }}}
        return nil;
    }
    
    func getGethAccount(_ privateKey: String,
                        password: String) -> GethAccount?{
        let keydir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/keystore"
        let gethKeyStorage: GethKeyStore = GethNewKeyStore(keydir, GethLightScryptN, GethLightScryptP)
        
        if let d = Data(fromHexEncodedString: privateKey),
            let value = Utils.shared.getKeystoreDic(d, passphrase: password)?.jsonString,
            let data = value.data(using: .utf8) {
                do {
                    let gethAccount = try gethKeyStorage.importKey(data,
                                                                   passphrase: password,
                                                                   newPassphrase: password)
                    
                    return gethAccount;
                    
                } catch {
                }
        }
        
        return nil;
    }
    
    func checkEthAddress(_ address: String) -> Bool{
        if address.count == 42 &&
            address.hasPrefix("0x") &&
            BigInt(address.replacingOccurrences(of: "0x", with: ""), radix: 16) != nil{
            return true
        }
        
        return false
    }
    
    var baseURL: String {
        get{
            return "https://mainnet.infura.io/v3/0e1ee5338163439aba2f97f5d8afd72e"
        }
    }
    
    func getHeader(url: String,
                   method: String,
                   isNoLogin: Bool = false,
                   parameters: Any?) -> NSMutableURLRequest{
        let request: NSMutableURLRequest = AFJSONRequestSerializer().request(withMethod: method,
                                                                             urlString: url,
                                                                             parameters: parameters,
                                                                             error: nil);
        request.setValue("application/json", forHTTPHeaderField: "Content-Type");

        return request;
    }
    
    func getGasPrice(block:@escaping (JSON,Error?) -> Void){
        var param = [String: Any]()
        param.updateValue("2.0", forKey: "jsonrpc")
        param.updateValue("eth_gasPrice", forKey: "method")
        param.updateValue(1, forKey:"id")
        
        let task: URLSessionDataTask = AFURLSessionManager().dataTask(with: (self.getHeader(url: baseURL,
                                                                                            method: "POST",
                                                                                            parameters: param) as URLRequest),
                                                                      uploadProgress: nil,
                                                                      downloadProgress: nil,
                                                                      completionHandler: {
                                                                        (response: URLResponse, result: Any?, error: Error?) -> Void in
                                                                        if let r = result {
                                                                            block(JSON(r),error);
                                                                        }else{
                                                                            block(JSON([]),error);
                                                                        }
        });
        
        task.resume();
    }
    
    func getGasEstimateLimit(_ from :String,
                             _ address: String,
                             block:@escaping (JSON,Error?) -> Void){
        var param = [String: Any]()
        param.updateValue("2.0", forKey: "jsonrpc")
        param.updateValue("eth_estimateGas", forKey: "method")
        param.updateValue(1, forKey:"id")
        
        let temp: [String: String] = ["from" : from,
                                      "to" : address]
        param.updateValue([temp],
                          forKey: "params")
        
        let task: URLSessionDataTask = AFURLSessionManager().dataTask(with: (self.getHeader(url: baseURL,
                                                                                            method: "POST",
                                                                                            parameters: param) as URLRequest),
                                                                      uploadProgress: nil,
                                                                      downloadProgress: nil,
                                                                      completionHandler: {
                                                                        (response: URLResponse, result: Any?, error: Error?) -> Void in
                                                                        if let r = result {
                                                                            block(JSON(r),error);
                                                                        }else{
                                                                            block(JSON([]),error);
                                                                        }
        })
        
        task.resume();
    }
    
    func getGasEstimateLimit(from: String,
                             contract: String,
                             data: String,
                             block:@escaping (JSON,Error?) -> Void){
        var param = [String: Any]()
        
        param.updateValue("2.0", forKey: "jsonrpc")
        param.updateValue("eth_estimateGas", forKey: "method")
        param.updateValue(1, forKey:"id")
        
        let temp: [String: String] = ["from" : from,
                                      "to" : contract,
                                      "data" : data]
        param.updateValue([temp],
                          forKey: "params")
        
        let task: URLSessionDataTask = AFURLSessionManager().dataTask(with: (self.getHeader(url: self.baseURL,
                                                                                            method: "POST",
                                                                                            parameters: param) as URLRequest),
                                                                      uploadProgress: nil,
                                                                      downloadProgress: nil,
                                                                      completionHandler: {
                                                                        (response: URLResponse, result: Any?, error: Error?) -> Void in
                                                                        if let r = result {
                                                                            block(JSON(r),error);
                                                                        }else{
                                                                            block(JSON([]),error);
                                                                        }
        });
        
        task.resume();
    }
    
    func getEthCall(_ from :String,
                    _ address: String,
                    _ data: String,
                    id: String = "1",
                    block:@escaping (JSON,Error?) -> Void){
        var param = [String: Any]()
        param.updateValue("2.0", forKey: "jsonrpc")
        param.updateValue("eth_call", forKey: "method")
        param.updateValue(id, forKey:"id")
        let temp: [String: String] = ["from" : from,
                                      "to" : address,
                                      "data": data]
        param.updateValue([temp, "latest"],
                          forKey: "params")
        let task: URLSessionDataTask = AFURLSessionManager().dataTask(with: (self.getHeader(url: baseURL,
                                                                                            method: "POST",
                                                                                            parameters: param) as URLRequest),
                                                                      uploadProgress: nil,
                                                                      downloadProgress: nil,
                                                                      completionHandler: {
                                                                        (response: URLResponse, result: Any?, error: Error?) -> Void in
                                                                        if let r = result {
                                                                            block(JSON(r),error);
                                                                        }else{
                                                                            block(JSON([]),error);
                                                                        }
        })
        
        task.resume();
    }
    
    func getTransactionCount(_ address: String,
                             block:@escaping (JSON,Error?) -> Void){
        var param = [String: Any]()
        
        param.updateValue("2.0", forKey: "jsonrpc")
        param.updateValue("eth_getTransactionCount", forKey: "method")
        param.updateValue(1, forKey:"id")
        param.updateValue([address , "latest"], forKey: "params")
        
        let task: URLSessionDataTask = AFURLSessionManager().dataTask(with: (self.getHeader(url: baseURL,
                                                                                            method: "POST",
                                                                                            parameters: param) as URLRequest),
                                                                      uploadProgress: nil,
                                                                      downloadProgress: nil,
                                                                      completionHandler: {
                                                                        (response: URLResponse, result: Any?, error: Error?) -> Void in
                                                                        if let r = result {
                                                                            block(JSON(r),error);
                                                                        }else{
                                                                            block(JSON([]),error);
                                                                        }
        });
        
        task.resume();
    }
    
    func sendRawTransaction(_ transaction: String,
                            block:@escaping (JSON,Error?) -> Void){
        var param = [String: Any]()
        
        param.updateValue("2.0", forKey: "jsonrpc")
        param.updateValue("eth_sendRawTransaction", forKey: "method")
        param.updateValue(1, forKey:"id");
        param.updateValue([transaction], forKey: "params")
        
        let task: URLSessionDataTask = AFURLSessionManager().dataTask(with: (self.getHeader(url: baseURL,
                                                                                            method: "POST",
                                                                                            parameters: param) as URLRequest),
                                                                      uploadProgress: nil,
                                                                      downloadProgress: nil,
                                                                      completionHandler: {
                                                                        (response: URLResponse, result: Any?, error: Error?) -> Void in
                                                                        if let r = result {
                                                                            block(JSON(r),error);
                                                                        }else{
                                                                            block(JSON([]),error);
                                                                        }
        });
        
        task.resume();
    }
}
