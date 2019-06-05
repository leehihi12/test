//
//  Utils.swift
//  CoinUs
//
//  Created by HoIck on 2017. 11. 25..
//  Copyright © CoinUs. All rights reserved.
//

import BigInt
import CryptoSwift

class Utils {
    static let shared = Utils();
    
    func createMnemonic() -> [String]? {
        if let mnemonic = BTCMnemonic(entropy: BTCRandomDataWithLength(16) as Data,
                                      password: nil,
                                      wordListType: .english) {
            return (mnemonic.words as? [String])
        }
        
        return nil;
    }
    
    func getSeedKey(_ mnemonic: [String]) -> String {
        
        let seedString = BTCMnemonic(words: mnemonic,
                                     password: nil,
                                     wordListType: .english).seed.toHexString()
        let sha = self.getSha256Password(seedString)
        
        return sha
    }
    
    func getSha256Password(_ pass: String) -> String {
        return pass.sha256()
    }
    
    func getKeystoreDic(_ key: Data,
                        passphrase: String) -> [String: Any]? {
        let privateKeyBytes: [UInt8] = Array(key)
        
        do {
            let passphraseBytes: [UInt8] = Array(passphrase.utf8)
            // reduce this number for higher speed. This is the default value, though.
            let numberOfIterations = 2214
            
            // derive key
            let salt: [UInt8] = AES.randomIV(32)
            
            let derivedKey = try PKCS5.PBKDF2(password: passphraseBytes,
                                              salt: salt,
                                              iterations: numberOfIterations,
                                              variant: .sha256).calculate()
            
            // encrypt
            let iv: [UInt8] = AES.randomIV(AES.blockSize)
            let aes = try AES(key: Array(derivedKey[..<16]),
                              blockMode: CTR.init(iv: iv),
                              padding: .noPadding)
            let ciphertext = try aes.encrypt(privateKeyBytes)
            
            // calculate the mac
            let macData = Array(derivedKey[16...]) + ciphertext
            let mac = SHA3(variant: .keccak256).calculate(for: macData)
            
            /* convert to JSONv3 */
            
            // KDF params
            let kdfParams: [String: Any] = [
                "prf": "hmac-sha256",
                "c": numberOfIterations,
                "salt": salt.toHexString(),
                "dklen": 32,
                ]
            
            // cipher params
            let cipherParams: [String: String] = [
                "iv": iv.toHexString(),
                ]
            
            // crypto struct (combines KDF and cipher params
            var cryptoStruct = [String: Any]()
            cryptoStruct["cipher"] = "aes-128-ctr"
            cryptoStruct["ciphertext"] = ciphertext.toHexString()
            cryptoStruct["cipherparams"] = cipherParams
            cryptoStruct["kdf"] = "pbkdf2"
            cryptoStruct["kdfparams"] = kdfParams
            cryptoStruct["mac"] = mac.toHexString()
            
            // encrypted key json v3
            let encryptedKeyJSONV3: [String: Any] = [
                "crypto": cryptoStruct,
                "version": 3,
                "id": "",
                ]
            
            return encryptedKeyJSONV3
        } catch PKCS5.PBKDF2.Error.invalidInput{
            NSLog("invalidInput")
        } catch PKCS5.PBKDF2.Error.derivedKeyTooLong{
            NSLog("derivedKeyTooLong")
        }catch{
            NSLog("error")
        }
        
        return nil;
    }
    
    func getBigInt(from hex: String)-> BigInt?{
        return BigInt(hex.replacingOccurrences(of: "0x", with: ""), radix: 16)
    }
    func getInt64(from hex: String)-> Int64?{
        return Int64(hex.replacingOccurrences(of: "0x", with: ""), radix: 16)
    }
    
    func getHexString(_ num: Int) -> String{
        return "0x\(String(num, radix: 16, uppercase: false))"
    }
    
    func getHexString(_ num: BigInt) -> String{
        return "0x\(String(num, radix: 16, uppercase: false))"
    }
    
    func getAmountInt64(amount: String, decimal: Int) -> Int64 {
        var amountBigInt:BigInt = BigInt("0")
        let amountArr = amount.components(separatedBy: ".")
        if (amountArr.count > 1) {
            var tempValue:Array = Array(amountArr[1])
            
            var loopCnt:Int = decimal - amountArr[1].count
            if (loopCnt < 0) {
                loopCnt = 0
            }
            
            for i in 0..<loopCnt{
                if i < tempValue.count{
                    tempValue.append("0")
                }
            }
            
            if let bigInt = BigInt(String(amountArr[0]) + String(tempValue)) {
                amountBigInt = bigInt
            } else {
                amountBigInt = 0
            }
        } else {
            var tempValue:Array = Array("")
            
            for _ in 0..<decimal{
                tempValue.append("0")
            }
            
            if let bigInt = BigInt(String(amountArr[0]) + String(tempValue)) {
                amountBigInt = bigInt
            } else {
                amountBigInt = 0
            }
        }
        return Int64(amountBigInt)
    }
    
    func isDecimalString(_ number: String)->Bool{
        if Double(number) == nil {
            return false;
        }
        
        let numberOnly = NSCharacterSet.init(charactersIn: "0123456789.")
        let stringFromTextField = NSCharacterSet.init(charactersIn: number)
        if !numberOnly.isSuperset(of: stringFromTextField as CharacterSet) {
            return false;
        }
        return true;
    }
    
    func calcAmountData(amount: String,
                        value: String,
                        isPlus:Bool) -> String{
        
        var result:String = ""
        var amountBigInt:BigInt = BigInt("0")
        var valueBigInt:BigInt = BigInt("0")
        
        let amountArr = amount.components(separatedBy: ".")
        if (amountArr.count > 1) {
            var tempValue:Array = Array(amountArr[1])
            
            var loopCnt:Int = 18 - amountArr[1].count
            if (loopCnt < 0) {
                loopCnt = 0
            }
            
            for i in 0..<loopCnt{
                if i < tempValue.count{
                    tempValue.append("0")
                }
            }
            
            if let bigInt = BigInt(String(amountArr[0]) + String(tempValue)) {
                amountBigInt = bigInt
            } else {
                amountBigInt = 0
            }
        } else {
            var tempValue:Array = Array("")
            
            for _ in 0..<18{
                tempValue.append("0")
            }
            
            if let bigInt = BigInt(String(amountArr[0]) + String(tempValue)) {
                amountBigInt = bigInt
            } else {
                amountBigInt = 0
            }
        }
        
        let valueArr = value.components(separatedBy: ".")
        
        if (valueArr.count > 1) {
            var tempValue:Array = Array(valueArr[1])
            
            var loopCnt:Int = 18 - valueArr[1].count
            if (loopCnt < 0) {
                loopCnt = 0
            }
            
            for _ in 0..<loopCnt{
                tempValue.append("0")
            }
            
            valueBigInt = BigInt(String(valueArr[0]) + String(tempValue))!
        } else {
            var tempValue:Array = Array("")
            
            for _ in 0..<18{
                tempValue.append("0")
            }
            
            valueBigInt = BigInt(String(valueArr[0]) + String(tempValue))!
        }
        
        var resultValue:String = ""
        
        if (isPlus) {
            resultValue = String(amountBigInt + valueBigInt)
            resultValue = resultValue.leftPad(toWidth: 18)
        } else {
            let calcValue:BigInt = amountBigInt - valueBigInt
            
            if (calcValue >= BigInt("0")) {
                resultValue = String(calcValue)
                resultValue = resultValue.leftPad(toWidth: 18)
            } else {
                resultValue = String(calcValue)
                resultValue = resultValue.replacingOccurrences(of: "-", with: "")
                resultValue = resultValue.leftPad(toWidth: 18)
                resultValue = "-\(resultValue)"
            }
        }
        
        var newValue:Array = Array("")
        var tempValue:Array = Array(resultValue)
        
        if (tempValue.count == 18) {
            newValue = tempValue
            newValue.insert(".", at: 0)
            newValue.insert("0", at: 0)
        } else if (tempValue.count == 19 && tempValue[0] == "-") {
            for i in 0..<18{
                newValue.append(tempValue[i+1])
            }
            
            newValue.insert(".", at: 0)
            newValue.insert("0", at: 0)
            newValue.insert("-", at: 0)
        } else {
            for i in 0..<resultValue.count{
                
                if (i == 18) {
                    newValue.insert(".", at: 0)
                }
                
                newValue.insert(tempValue[tempValue.count-i-1], at: 0)
            }
        }
        
        result = String(newValue)
        
        var resultArr:Array = Array(result)
        for _ in 0..<19{
            if (resultArr.count < 1) {
                break;
            }
            
            if  (resultArr[resultArr.count-1] == "0") {
                resultArr.remove(at: resultArr.count-1)
            } else if (resultArr[resultArr.count-1] == ".") {
                resultArr.remove(at: resultArr.count-1)
                break
            } else {
                break
            }
        }
        
        result = String(resultArr)
        
        return result
    }
    
    func doubleToPriceString(rawValue: Double) -> String {
        let newValue:Double = rawValue
        var tempValue:String = ""
        let price = newValue as NSNumber
        
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .currency
        formatter.currencyCode = ""
        formatter.currencySymbol = ""
        formatter.roundingMode = .floor
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 5
        
        tempValue = String(format: "%@", formatter.string(from: price)!)
        
        if (newValue > 0.0 && tempValue == "0") {
            var findStr:String = ""
            let findPrice = newValue as NSNumber
            
            for i in (6..<18+1) {
                let formatter = NumberFormatter()
                formatter.locale = Locale(identifier: "en_US")
                formatter.numberStyle = .currency
                formatter.currencyCode = ""
                formatter.currencySymbol = ""
                formatter.roundingMode = .floor
                formatter.minimumFractionDigits = 0
                formatter.maximumFractionDigits = i
                
                findStr = String(format: "%@", formatter.string(from: findPrice)!)
                
                if (findStr != "0") {
                    break
                }
            }
            
            if (findStr != "") {
                tempValue = findStr
            }
        }
        
        return tempValue
    }
    
    func rawToPriceString(rawValue: String, decimals: Int, symbol:String, maximumDecimal: Int) -> String {
        var result:String = ""
        var rawBalance:String = rawValue
        var tempBalance:Array = Array("")
        var displayDecimal:Int = maximumDecimal
        
        if (rawValue.range(of: "-") != nil || rawValue.range(of: "+") != nil || rawValue.range(of: ".") != nil) {
            return rawValue
        }
        
        if (displayDecimal < 0 || displayDecimal > decimals) {
            displayDecimal = decimals
        }
        
        if (rawBalance.count > decimals) {
            if (decimals == 0) {
                tempBalance = Array(String(format: "%@", rawBalance))
            } else {
                let part2:String = String(rawBalance[rawBalance.index(rawBalance.endIndex, offsetBy: -decimals)...])
                let part1:String = String(rawBalance[..<rawBalance.index(rawBalance.startIndex, offsetBy: rawBalance.count - decimals)])
                
                tempBalance = Array(String(format: "%@.%@", part1, part2))
            }
        } else if (rawBalance.count == decimals) {
            if (decimals == 0) {
                tempBalance = Array(String(format: "%@", rawBalance))
            } else {
                tempBalance = Array(String(format: "0.%@", rawBalance))
            }
        } else {
            rawBalance = rawBalance.leftPad(toWidth: decimals)
            tempBalance = Array(String(format: "0.%@", rawBalance))
        }
        
        var loopCnt:Int = tempBalance.count
        if (loopCnt < 0) {
            loopCnt = 0
        }
        
        for _ in 0..<loopCnt{
            if  (tempBalance[tempBalance.count-1] == "0") {
                tempBalance.remove(at: tempBalance.count-1)
            } else {
                break
            }
        }
        
        if (tempBalance[tempBalance.count-1] == ".") {
            tempBalance.remove(at: tempBalance.count-1)
        }
        
        let valueStr:String = String(tempBalance)
        
        var resultArr:Array = Array("")
        var tempValue:Array = Array(valueStr)
        var isDot:Bool = false
        var numCnt:Int = 0
        
        if (valueStr.range(of: ".") == nil) {
            isDot = true
            numCnt = 1
        }
        
        if (tempValue.count > 1) {
            for i in 0..<tempValue.count{
                if (tempValue[tempValue.count-i-1] == ".") {
                    isDot = true
                }
                
                if (numCnt > 3) {
                    resultArr.insert(",", at: 0)
                    numCnt = 1
                }
                
                if (isDot) {
                    numCnt = numCnt + 1
                }
                
                resultArr.insert(tempValue[tempValue.count-i-1], at: 0)
            }
            
            result = String(resultArr)
        } else {
            result = String(tempValue)
        }
        
        resultArr = Array("")
        tempValue = Array(result)
        
        if (tempValue.count > 1) {
            var isDot:Bool = false
            var numCnt:Int = 0
            
            for i in 0..<tempValue.count{
                if (tempValue[i] == "." && isDot == false) {
                    isDot = true
                    
                    resultArr.append(tempValue[i])
                    continue
                }
                
                if (isDot) {
                    numCnt = numCnt + 1
                }
                
                if (numCnt > displayDecimal) {
                    break
                }
                
                resultArr.append(tempValue[i])
            }
            
            result = String(resultArr)
        } else {
            result = String(tempValue)
        }
        
        if (symbol != "") {
            result = String(format: "%@ %@", result, symbol);
        } else {
            result = String(format: "%@", result);
        }
        
        return result
    }
    
    func getOverflowDecimalStr(amount:String, decimals:Int, symbol:String) -> String {
        var result:String = amount
        let rawValue:String = amount
        var newValue:Array = Array("")
        var tempValue:Array = Array(rawValue)
        
        if (tempValue.count > decimals) {
            var isDot:Bool = false
            var numCnt:Int = 0
            
            for i in 0..<tempValue.count{
                if (tempValue[i] == ".") {
                    isDot = true
                }
                
                if (numCnt > decimals) {
                    break
                }
                
                if (isDot) {
                    numCnt = numCnt + 1
                }
                
                newValue.append(tempValue[i])
            }
            
            if (symbol != "") {
                result = String(format: "%@ %@", String(newValue), symbol);
            } else {
                result = String(format: "%@", String(newValue));
            }
        }
        
        return result
    }
    
    func getDecimalSize(value:String) -> Int {
        let tempVal:String = self.trimZeroDecimal(value: value, tailStr: "")
        var result:Int = 0
        
        if (tempVal.range(of: ".") != nil) {
            let rawValue:String = tempVal
            var tempValue:Array = Array(rawValue)
            
            if (tempValue.count > 1) {
                var decimalCnt:Int = 0
                
                for _ in 0..<tempValue.count{
                    if (tempValue[tempValue.count-1] == ".") {
                        break
                    } else {
                        tempValue.remove(at: tempValue.count-1)
                        decimalCnt = decimalCnt + 1
                    }
                }
                
                result = decimalCnt
            } else {
                result = 0;
            }
        } else {
            result = 0
        }
        
        return result
    }
    
    func trimZeroDecimal(value:String, tailStr:String) -> String {
        var result:String = value
        
        result = result.replacingOccurrences(of: tailStr, with: "");
        result = result.replacingOccurrences(of: " ", with: "");
        
        if (result.range(of: ".") != nil) {
            let rawValue:String = result
            var tempValue:Array = Array(rawValue)
            
            if (tempValue.count > 1) {
                for _ in 0..<tempValue.count{
                    if (tempValue.count < 1) {
                        break;
                    }
                    
                    if  (tempValue[tempValue.count-1] == "0") {
                        tempValue.remove(at: tempValue.count-1)
                    } else if (tempValue[tempValue.count-1] == ".") {
                        tempValue.remove(at: tempValue.count-1)
                        break
                    } else {
                        break
                    }
                }
                
                if (tailStr != "") {
                    result = String(format: "%@ %@", String(tempValue), tailStr);
                } else {
                    result = String(tempValue);
                }
            } else {
                result = value;
            }
        } else {
            if (tailStr != "") {
                result = String(format: "%@ %@", result, tailStr);
            } else {
                result = value;
            }
        }
        
        return result
    }
    
    func priceToDisplayFormat(valueStr:String,
                              decimals:Int,
                              symbol:String) -> String {
        var result:String = valueStr
        
        let valueStr:String = result
        
        if (valueStr.range(of: "-") == nil && valueStr.range(of: "+") == nil) {
            if (symbol != "") {
                result = String(format: "%@ %@", valueStr, symbol);
            } else {
                result = String(format: "%@", valueStr);
            }
        } else {
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .decimal
            let finalNumber = numberFormatter.number(from: "\(valueStr)")
            
            if (symbol != "") {
                result = String(format: "%@ %@", (finalNumber?.decimalValue)! as CVarArg, symbol);
            } else {
                result = String(format: "%@", (finalNumber?.decimalValue)! as CVarArg);
            }
            
            result = Utils.shared.getOverflowDecimalStr(amount: result, decimals: decimals, symbol: symbol)
        }
        
        let rawValue:String = result
        var newValue:Array = Array("")
        var tempValue:Array = Array(rawValue)
        
        if (tempValue.count > 1) {
            var isDot:Bool = false
            var numCnt:Int = 0
            
            for i in 0..<tempValue.count{
                if (tempValue[tempValue.count-i-1] == ".") {
                    isDot = true
                }
                
                if (numCnt > 3) {
                    newValue.insert(",", at: 0)
                    numCnt = 1
                }
                
                if (isDot) {
                    numCnt = numCnt + 1
                }
                
                newValue.insert(tempValue[tempValue.count-i-1], at: 0)
            }
            
            result = String(newValue)
        } else {
            result = String(tempValue)
        }
        
        return result
    }
    
    func decimalnumberToString(_ number: NSDecimalNumber)->String {
        var result = "0"
        
        let n = number.stringValue
        var list = n.components(separatedBy: ".")
        
        switch list.count{
            case 1:
                var l = Array(list[0])
                l.reverse()
                
                var temp: [Character] = []
                
                for i in 0..<l.count {
                    temp.append(l[i])
                    if (i + 1) % 3 == 0 ,
                        i != 0 ,
                        i != (l.count - 1){
                        temp.append(",")
                    }
                }
                temp.reverse()
                result = String(temp)
                
                break;
            
            case 2:
                var l = Array(list[0])
                l.reverse()
                
                var temp: [Character] = []
                
                for i in 0..<l.count {
                    temp.append(l[i])
                    if (i + 1) % 3 == 0 ,
                        i != 0 ,
                        i != (l.count - 1){
                        temp.append(",")
                    }
                }
                temp.reverse()
                result = String(temp) + "." + list[1]
                break;
            
            default:
                break;
        }
        
        return result
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        
        return paths[0]
    }
    
    func GetImagePath(filename:String) -> String {
        let path = getDocumentsDirectory().appendingPathComponent(filename)
        
        return path.absoluteString
    }
    
    func SaveImage(filename:String, imageData:UIImage){
        if let data = UIImageJPEGRepresentation(imageData, 0.5) {
            let path = getDocumentsDirectory().appendingPathComponent(filename)
            try? data.write(to: path)
        }
    }
    
    func LoadImage(filename:String) -> UIImage {
        var result:UIImage
        let path = getDocumentsDirectory().appendingPathComponent(filename)
        
        do {
            let imageData = try Data(contentsOf: path)
            result = UIImage(data: imageData)!
        } catch {
            result = UIImage()
        }
        
        return result
    }
    
    func LoadImageResize(filename:String) -> UIImage {
        var result:UIImage
        let path = getDocumentsDirectory().appendingPathComponent(filename)
        
        do {
            let imageData = try Data(contentsOf: path)
            result = UIImage(data: imageData)!
        } catch {
            result = UIImage()
        }
        
        if result.size.height > 2048 || result.size.width > 2048 {
            result = UIImage.scale(image: result, by: 0.5)!
        }
        
        return result
    }
    
    func getUTCToLocal(UTCDateString: String) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"//Input Format
        dateFormatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
        let UTCDate = dateFormatter.date(from: UTCDateString)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS" // Output Format
        dateFormatter.timeZone = TimeZone.current
        
        if let date = UTCDate{
            let UTCToCurrentFormat = dateFormatter.string(from: date)
            return UTCToCurrentFormat
        }
        
        return nil
    }
    
    func timeAgoSinceDate(date: NSDate,
                          numericDates:Bool) -> String {
        let calendar = NSCalendar.current
        let unitFlags: Set<Calendar.Component> = [.minute, .hour, .day, .weekOfYear, .month, .year, .second]
        let now = NSDate()
        let earliest = now.earlierDate(date as Date)
        let latest = (earliest == now as Date) ? date : now
        let components = calendar.dateComponents(unitFlags, from: earliest as Date,  to: latest as Date)
        
        if (components.year! >= 2) {
            return "\(components.year!) years ago"
        } else if (components.year! >= 1){
            if (numericDates){
                return "1 year ago"
            } else {
                return "Last year"
            }
        } else if (components.month! >= 2) {
            return "\(components.month!) months ago"
        } else if (components.month! >= 1){
            if (numericDates){
                return "1 month ago"
            } else {
                return "Last month"
            }
        } else if (components.weekOfYear! >= 2) {
            return "\(components.weekOfYear!) weeks ago"
        } else if (components.weekOfYear! >= 1){
            if (numericDates){
                return "1 week ago"
            } else {
                return "Last week"
            }
        } else if (components.day! >= 2) {
            return "\(components.day!) days ago"
        } else if (components.day! >= 1){
            if (numericDates){
                return "1 day ago"
            } else {
                return "Yesterday"
            }
        } else if (components.hour! >= 2) {
            return "\(components.hour!) hours ago"
        } else if (components.hour! >= 1){
            if (numericDates){
                return "1 hour ago"
            } else {
                return "An hour ago"
            }
        } else if (components.minute! >= 2) {
            return "\(components.minute!) minutes ago"
        } else if (components.minute! >= 1){
            if (numericDates){
                return "1 minute ago"
            } else {
                return "A minute ago"
            }
        } else if (components.second! >= 3) {
            return "\(components.second!) seconds ago"
        } else {
            return "Just now"
        }
    }
    
    func getDecimalStringZeroCut(_ strAmount: String,
                                 decimals: Int) -> Bool{
        if Double(strAmount) != nil {
            var result = false;
            let list = strAmount.components(separatedBy: ".")
            
            switch list.count {
                case 1:
                    result = true;
                    break;
                case 2:
                    var decimalArray = Array(list[1])
                    let max = decimalArray.count
                    for i in 0..<max{
                        let index = (max - 1 - i)
                        let value = decimalArray[index]
                        
                        if value == "0"{
                            decimalArray.remove(at: index)
                        }else{
                            break;
                        }
                    }
                    
                    if decimalArray.count <= decimals {
                        result = true;
                    } else {
                        result = false;
                    }
                    break;
                default:
                    result = false;
                    break;
            }
            return result;
        } else {
            return false;
        }
    }
    
    func nsdecimalToString(_ number: NSDecimalNumber,
                           scale: Int16 = 2)->String{
        var result = "0"
        
        if number.doubleValue >= 0 {
            let round = NSDecimalNumberHandler(roundingMode: .down, scale: scale, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
            result = number.rounding(accordingToBehavior: round).stringValue
            
        } else {
            let round = NSDecimalNumberHandler(roundingMode: .up, scale: scale, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
            result = number.rounding(accordingToBehavior: round).stringValue
        }
        
        return result
    }
    
    func getCurrencyString(_ price: String) -> String{
        var result = price
        
        if !result.contains(",") {
            if let temp = Double(result) {
                let temp2 = NSNumber(value: temp)
                
                let formatter = NumberFormatter()
                formatter.locale = Locale(identifier: "en_US")
                formatter.numberStyle = .currency
                formatter.currencyCode = ""
                formatter.currencySymbol = ""
                formatter.roundingMode = .down
                formatter.minimumFractionDigits = 0
                formatter.maximumFractionDigits = 3
                
                if let value = formatter.string(from: temp2) {
                    result = value
                }
            }
        }
        
        return result;
    }
}

struct EtherealCerealRegex {
    static var hexadecimalDataRegex: NSRegularExpression = {
        return try! NSRegularExpression(pattern: "^(?:0x)?([a-fA-F0-9]*)$", options: .caseInsensitive)
    }()
}

extension String {
    public var hexadecimalData: Data? {
        guard let match = EtherealCerealRegex.hexadecimalDataRegex.matches(in: self, range: NSMakeRange(0, self.count)).first
            else { return nil }
        
        let hexadecimalString = (self as NSString).substring(with: match.range(at: 1))
        let utf16View: UTF16View
        if hexadecimalString.count % 2 == 1 {
            utf16View = "0\(hexadecimalString)".utf16
        } else {
            utf16View = hexadecimalString.utf16
        }
        guard let data = NSMutableData(capacity: utf16View.count/2) else { return nil }
        
        var byteChars: [CChar] = [0, 0, 0]
        var wholeByte: CUnsignedLong = 0
        var i = utf16View.startIndex
        
        while i < utf16View.index(before: utf16View.endIndex) {
            byteChars[0] = CChar(truncatingIfNeeded: utf16View[i])
            byteChars[1] = CChar(truncatingIfNeeded: utf16View[utf16View.index(after: i)])
            wholeByte = strtoul(byteChars, nil, 16)
            data.append(&wholeByte, length: 1)
            i = utf16View.index(i, offsetBy: 2)
        }
        
        return data as Data
    }
    
    func fromBase64() -> String? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    func toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }
    
    
    func getSplitArray(_ separatedBy: String) -> [String] {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).components(separatedBy: separatedBy)
    }
    
    public var etherABIMethod: String {
        let method = self.data(using: .ascii)!.sha3(.keccak256)[0...3]
        return "0x" + method.toHexString()
    }
    
    public func leftPad(toWidth width: Int) -> String {
        return leftPad(toWidth: width, withString: "0")
    }
    
    public func leftPad(toWidth width: Int, withString string: String?) -> String {
        let paddingString = string ?? "0"
        
        if self.count >= width {
            return self
        }
        
        let remainingLength: Int = width - self.count
        var padString = String()
        for _ in 0 ..< remainingLength {
            padString += paddingString
        }
        
        return [padString, self].joined(separator: "")
    }
}

extension NSMutableAttributedString {
    @discardableResult func bold(_ text: String, withLabel label: UILabel) -> NSMutableAttributedString {
        
        //generate the bold font
        var font: UIFont = UIFont(name: label.font.fontName , size: label.font.pointSize)!
        font = UIFont(descriptor: font.fontDescriptor.withSymbolicTraits(.traitBold) ?? font.fontDescriptor, size: font.pointSize)
        
        //generate attributes
        let attrs: [NSAttributedStringKey: Any] = [NSAttributedStringKey.font: font]
        let boldString = NSMutableAttributedString(string:text, attributes: attrs)
        
        //append the attributed text
        append(boldString)
        
        return self
    }
    
    @discardableResult func normal(_ text: String) -> NSMutableAttributedString {
        let normal = NSAttributedString(string: text)
        append(normal)
        
        return self
    }
}

extension Double {
    /// Rounds the double to decimal places value
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded()
    }
}

extension UIImage {
    class func resize(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / image.size.width
        let heightRatio = targetSize.height / image.size.height
        
        var newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    class func scale(image: UIImage, by scale: CGFloat) -> UIImage? {
        let size = image.size
        let scaledSize = CGSize(width: size.width * scale, height: size.height * scale)
        return UIImage.resize(image: image, targetSize: scaledSize)
    }
}

extension Data {
    var hex: String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
    
    var hexEncoded: String {
        return "0x" + self.hex
    }
    
    init?(fromHexEncodedString string: String) {
        // Convert 0 ... 9, a ... f, A ...F to their decimal value,
        // return nil for all other input characters
        func decodeNibble(u: UInt16) -> UInt8? {
            switch u {
            case 0x30 ... 0x39:
                return UInt8(u - 0x30)
            case 0x41 ... 0x46:
                return UInt8(u - 0x41 + 10)
            case 0x61 ... 0x66:
                return UInt8(u - 0x61 + 10)
            default:
                return nil
            }
        }
        
        self.init(capacity: string.utf16.count/2)
        var even = true
        var byte: UInt8 = 0
        for c in string.utf16 {
            guard let val = decodeNibble(u: c) else { return nil }
            if even {
                byte = val << 4
            } else {
                byte += val
                self.append(byte)
            }
            even = !even
        }
        guard even else { return nil }
    }
}

extension Dictionary where Key: ExpressibleByStringLiteral, Value: Any {
    var jsonString: String? {
        if let dict = (self as AnyObject) as? [String: AnyObject] {
            do {
                let data = try JSONSerialization.data(withJSONObject: dict, options: JSONSerialization.WritingOptions(rawValue: 0))
                if let string = String(data: data, encoding: String.Encoding.utf8) {
                    return string
                }
            } catch {
                print(error)
            }
        }
        return nil
    }
}

public protocol EnumCollection: Hashable {
    static func cases() -> AnySequence<Self>
    static var allValues: [Self] { get }
}

public extension EnumCollection {
    static func cases() -> AnySequence<Self> {
        return AnySequence { () -> AnyIterator<Self> in
            var raw = 0
            return AnyIterator {
                let current: Self = withUnsafePointer(to: &raw) { $0.withMemoryRebound(to: self, capacity: 1) { $0.pointee } }
                guard current.hashValue == raw else {
                    return nil
                }
                raw += 1
                return current
            }
        }
    }
    
    static var allValues: [Self] {
        return Array(self.cases())
    }
}
