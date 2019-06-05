//
//  wallet.swift
//  wallet
//
//  Created by HoIck on 2019. 6. 5..
//  Copyright © CoinUs. All rights reserved.
//

class wallet {
    private init() {}
    
    func sample() {
        if let mnemonic = Utils.shared.createMnemonic(),
            mnemonic.count == 12 {
            // mnemonic is created.
        } else {
            // error
        }
    }
}
