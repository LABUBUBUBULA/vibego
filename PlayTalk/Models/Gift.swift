import UIKit

/// 礼物模型 - 对应 Android GameMic 的 Gift.java
/// 用于语音房内的礼物赠送功能
struct Gift {
    let id: Int             // 礼物 ID（1-20）
    let name: String        // 礼物名称（如 "Flower", "Diamond"）
    let price: Int          // 价格（88-5888 金币）
    let imageName: String   // 图片资源名（gift_1 ~ gift_20）
    var isSelected: Bool    // 当前是否被选中

    /// 价格显示文本
    var priceText: String {
        return "\(price)"
    }
}

/// 20个礼物数据（对应 Android GiftSelectorDialog 的礼物列表）
let allGifts: [Gift] = [
    Gift(id: 1, name: "Flower", price: 88, imageName: "gift_1", isSelected: false),
    Gift(id: 2, name: "Violetoy", price: 999, imageName: "gift_2", isSelected: false),
    Gift(id: 3, name: "Oraowe", price: 1999, imageName: "gift_3", isSelected: false),
    Gift(id: 4, name: "Diamond", price: 2888, imageName: "gift_4", isSelected: false),
    Gift(id: 5, name: "Crown", price: 3888, imageName: "gift_5", isSelected: false),
    Gift(id: 6, name: "Rocket", price: 5888, imageName: "gift_6", isSelected: false),
    Gift(id: 7, name: "Heart", price: 88, imageName: "gift_7", isSelected: false),
    Gift(id: 8, name: "Star", price: 188, imageName: "gift_8", isSelected: false),
    Gift(id: 9, name: "Ring", price: 888, imageName: "gift_9", isSelected: false),
    Gift(id: 10, name: "Car", price: 4888, imageName: "gift_10", isSelected: false),
    Gift(id: 11, name: "Yacht", price: 5888, imageName: "gift_11", isSelected: false),
    Gift(id: 12, name: "Castle", price: 3888, imageName: "gift_12", isSelected: false),
    Gift(id: 13, name: "Plane", price: 2888, imageName: "gift_13", isSelected: false),
    Gift(id: 14, name: "Teddy", price: 999, imageName: "gift_14", isSelected: false),
    Gift(id: 15, name: "Rose", price: 188, imageName: "gift_15", isSelected: false),
    Gift(id: 16, name: "Cake", price: 388, imageName: "gift_16", isSelected: false),
    Gift(id: 17, name: "Firework", price: 1888, imageName: "gift_17", isSelected: false),
    Gift(id: 18, name: "Trophy", price: 2888, imageName: "gift_18", isSelected: false),
    Gift(id: 19, name: "Balloon", price: 88, imageName: "gift_19", isSelected: false),
    Gift(id: 20, name: "Lollipop", price: 188, imageName: "gift_20", isSelected: false),
]
