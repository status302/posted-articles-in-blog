//: Playground - noun: a place where people can play

import UIKit


extension String {
    var length: Int {
        return unicodeScalars.count
    }
    var sequences: [String] {
        var arr = [String]()
        enumerateSubstrings(in: startIndex..<endIndex, options: .byComposedCharacterSequences) { (substring, _, _, _) in
            if let str = substring { arr += [str] }
        }
        return arr
    }
    /// 截取字符串操作
    ///
    /// - Parameters:
    ///   - toLength: 要截取的字符串的length, 编码为：unicode, 即： `unicodeScalars.count`
    /// - Returns: 返回的截取好的字符串
    func substring(toLength: Int) -> String {
        guard toLength < length else {
                return self
        }
        
        var results = String()
        for index in 0 ..< sequences.count {
            if results.length + sequences[index].length <= toLength {
                results.append(sequences[index])
            }
            else {
                return results
            }
        }
        return self
    }
}

"👨🏿‍🎓".characters.reduce("组成：") {
    "\($0) \($1)"
}

"👨🏿‍🎓".sequences.forEach {
    print("sequences string \($0)")
}
"👨‍👩‍👧‍👦🙆🏻‍♂️🤦🏻‍♂️🙎🏽🙇‍♀️👩‍👩‍👧‍👧👩‍👩‍👧‍👧👨‍👨‍👦👨‍👧👚👘🎒⛑👑👛👜💼🌂☂️🌂👓💼👜🎒🦁🙊🕸🦂🦐🐙🦑🐙🦐🐠🦈🐬🐡🦌🐪🐫🐘🐕🐑🐏🐐🐩🐈🐓🦃🐀🐁🐁🐇🕊🐿🐾🐉🐲🌳🌲🎄🎍🎋🍃🌾🌹🌸🌼🌻🌎🌍🌏💫🌙✨⚡️🔥💥⛅️🌤☀️☄️🌦⛈🌩🌬❄️⛄️☃️💨🌪🌫🌊☔️💦💧💦☔️🥕".substring(toLength: 30)


