//
//  NetworkManager.swift
//  CoinUs
//
//  Created by HoIck on 2017. 11. 25..
//  Copyright © CoinUs. All rights reserved.
//

import UIKit
import SwiftyJSON

class NetworkManager {
    
    private init() {}
    static let shared = NetworkManager()
    
    var baseURL: String {
        get{
            return "https://apis.coinus.io/v2"
        }
    }
    
    let apiKey = "Please contact to biz@coinus.io"
    
    func getHeader(url: String,
                   method: String,
                   isNoLogin: Bool = false,
                   parameters: Any?) -> NSMutableURLRequest{
        let request: NSMutableURLRequest = AFJSONRequestSerializer().request(withMethod: method,
                                                                             urlString: url,
                                                                             parameters: parameters,
                                                                             error: nil);
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type");
        request.setValue(self.apiKey, forHTTPHeaderField: "Api-Key");
        
        return request;
    }
    
    func getCurrencyList(currencyNm: String? = nil,
                         currencySymbol: String? = nil,
                         pageNo: Int = 1,
                         pageSize: Int = 2000,
                         block:@escaping (JSON,Error?) -> Void){
        let str_url = "\(self.baseURL)/commons/currency"
        
        var param = [String: Any]()
        
        if let nm = currencyNm {
            param.updateValue(nm, forKey: "currencyNm")
        }
        if let symbol = currencySymbol {
            param.updateValue(symbol, forKey: "currencySymbol")
        }
        
        param.updateValue(NSNumber(value: pageNo), forKey: "pageNo")
        param.updateValue(NSNumber(value: pageSize), forKey:"pageSize")
        
        
        let task: URLSessionDataTask = AFURLSessionManager().dataTask(with: (NetworkManager.shared.getHeader(url: str_url,
                                                                                                             method: "GET",
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
    
    func getCryptoCurrencyExchange(coinSymbol: String,
                                   block:@escaping (JSON,Error?) -> Void){
        let str_url = "\(self.baseURL)/crypto-currency/exchanges/\(coinSymbol)"
        
        var param = [String: Any]()
        param.updateValue(coinSymbol, forKey: "coinSymbol")
        
        let task: URLSessionDataTask = AFURLSessionManager().dataTask(with: (NetworkManager.shared.getHeader(url: str_url,
                                                                                                             method: "GET",
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
    
    func getEthAddress(address: String,
                       currency: String,
                       block:@escaping (JSON,Error?) -> Void){
        let str_url = "\(self.baseURL)/ethereum/address/\(address)"
        
        var param = [String: Any]()
        
        param.updateValue(address, forKey: "address")
        param.updateValue(currency, forKey: "currency")
        
        let task: URLSessionDataTask = AFURLSessionManager().dataTask(with: (NetworkManager.shared.getHeader(url: str_url,
                                                                                                             method: "GET",
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
    
    func getEthTokenByAddressContract(address: String,
                                      contractAddress: String,
                                      currency: String,
                                      block:@escaping (JSON,Error?) -> Void){
        let str_url = "\(self.baseURL)/ethereum/address/\(address)/tokens/\(contractAddress)"
        
        var param = [String: Any]()
        
        param.updateValue(address, forKey: "address")
        param.updateValue(contractAddress, forKey: "contractAddress")
        param.updateValue(currency, forKey: "currency")
        
        let task: URLSessionDataTask = AFURLSessionManager().dataTask(with: (NetworkManager.shared.getHeader(url: str_url,
                                                                                                             method: "GET",
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
    
    func getEthTxByAddressList(address: String,
                               inOut: String? = nil,
                               failYn: String? = nil,
                               pageNo: Int = 1,
                               pageSize: Int = 20,
                               block:@escaping (JSON,Error?) -> Void){
        let str_url = "\(self.baseURL)/ethereum/address/\(address)/txs"
        
        var param = [String: Any]()
        
        param.updateValue(address, forKey: "address")
        
        if let yn = failYn {
            param.updateValue(yn, forKey: "failYn")
        }
        
        if let io = inOut{
            param.updateValue(io, forKey: "inOut")
        }
        
        param.updateValue(NSNumber(value: pageNo), forKey: "pageNo")
        param.updateValue(NSNumber(value: pageSize), forKey:"pageSize")
        
        let task: URLSessionDataTask = AFURLSessionManager().dataTask(with: (NetworkManager.shared.getHeader(url: str_url,
                                                                                                             method: "GET",
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
    
    func getEthTokenTransferByAddressList(address: String,
                                          contractAddress: String,
                                          inOut: String? = nil,
                                          failYn: String? = nil,
                                          pageNo: Int = 1,
                                          pageSize: Int = 20,
                                          block:@escaping (JSON,Error?) -> Void){
        let str_url = "\(self.baseURL)/ethereum/address/\(address)/tokens/\(contractAddress)/transfers"
        
        var param = [String: Any]()
        
        param.updateValue(address, forKey: "address")
        param.updateValue(contractAddress, forKey: "contractAddress")
        
        if let yn = failYn {
            param.updateValue(yn, forKey: "failYn")
        }
        
        if let io = inOut{
            param.updateValue(io, forKey: "inOut")
        }
        
        param.updateValue(NSNumber(value: pageNo), forKey: "pageNo")
        param.updateValue(NSNumber(value: pageSize), forKey:"pageSize")
        
        let task: URLSessionDataTask = AFURLSessionManager().dataTask(with: (NetworkManager.shared.getHeader(url: str_url,
                                                                                                             method: "GET",
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
    
    func getWalletTokenList(wno: Int,
                            keyword: String? = nil,
                            pageNo: Int = 1,
                            pageSize: Int = 20,
                            block:@escaping (JSON,Error?) -> Void){
        
        let str_url = "\(self.baseURL)/wallets/\(wno)/tokens"
        
        var param = [String: Any]()
        
        param.updateValue(NSNumber(value: wno), forKey: "wno")
        
        if let key = keyword {
            param.updateValue(key, forKey: "keyword")
        }
        param.updateValue(NSNumber(value: pageNo), forKey: "pageNo")
        
        param.updateValue(NSNumber(value: pageSize), forKey:"pageSize")
        
        let task: URLSessionDataTask = AFURLSessionManager().dataTask(with: (NetworkManager.shared.getHeader(url: str_url,
                                                                                                             method: "GET",
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
    
    func updateImage(_ image: UIImage,
                     fileName: String,
                     block:@escaping (JSON,Error?) -> Void){
        
        let str_url = "\(self.baseURL)/kyc/id-picture";
        
        let request = AFHTTPRequestSerializer().multipartFormRequest(withMethod: "POST",
                                                                     urlString: str_url,
                                                                     parameters: nil,
                                                                     constructingBodyWith: {
                                                                        data in
                                                                        
                                                                        if let imageData = UIImageJPEGRepresentation(image, 0.1){
                                                                            
                                                                            data.appendPart(withFileData: imageData ,
                                                                                            name: "uploadFile",
                                                                                            fileName: "\(fileName).jpg",
                                                                                mimeType: "image/jpg");
                                                                        }
                                                                        
        },
                                                                     error: nil);

        request.setValue(self.apiKey, forHTTPHeaderField: "Api-Key");

        let manager: AFURLSessionManager = AFURLSessionManager(sessionConfiguration: URLSessionConfiguration.default);

        let task: URLSessionUploadTask = manager.uploadTask(withStreamedRequest: (request as URLRequest),
                                                            progress: {
                                                                progress in
                                                                
        },
                                                            completionHandler: {
                                                                response, result, error in
                                                                
                                                                if let r = result {
                                                                    block(JSON(r),error);
                                                                }else{
                                                                    block(JSON([]),error);
                                                                }
        });
        
        task.resume();
    }
    
    func getCryptoMarketCapForDashboardList(pageSize: Int = 20, block:@escaping (JSON,Error?) -> Void){
        let str_url = "\(self.baseURL)/crypto-market-caps/top"
        
        var param = [String: Any]()
        param.updateValue(NSNumber(value: pageSize), forKey: "pageSize")
        
        let task: URLSessionDataTask = AFURLSessionManager().dataTask(with: (NetworkManager.shared.getHeader(url: str_url,
                                                                                                             method: "GET",
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
    
    func getEventDashboardList(block:@escaping (JSON,Error?) -> Void){
        let str_url = "\(self.baseURL)/dashboard/events"
        
        let task: URLSessionDataTask = AFURLSessionManager().dataTask(with: (NetworkManager.shared.getHeader(url: str_url,
                                                                                                             method: "GET",
                                                                                                             parameters: nil) as URLRequest),
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
    
    func getAnnouncementNoticeTop(block:@escaping (JSON,Error?) -> Void){
        let str_url = "\(self.baseURL)/announcement-notice/top"
        
        let task: URLSessionDataTask = AFURLSessionManager().dataTask(with: (NetworkManager.shared.getHeader(url: str_url,
                                                                                                             method: "GET",
                                                                                                             parameters: nil) as URLRequest),
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
    
    func getBnusMarketConfig(block:@escaping (JSON,Error?) -> Void){
        
        let str_url = "\(self.baseURL)/bnus/market-configs"
        
        
        let task: URLSessionDataTask = AFURLSessionManager().dataTask(with: (NetworkManager.shared.getHeader(url: str_url,
                                                                                                             method: "GET",
                                                                                                             parameters: nil) as URLRequest),
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
