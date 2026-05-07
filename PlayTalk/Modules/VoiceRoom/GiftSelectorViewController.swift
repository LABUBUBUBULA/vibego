import UIKit

/// 礼物选择器 - 对应 Android GameMic 的 GiftSelectorDialog（BottomSheet）
/// 布局：标题 → 礼物网格(4列) → 底部（余额+数量选择+发送按钮）
/// 选择礼物后扣除金币，回调通知房间页面添加礼物消息
class GiftSelectorViewController: UIViewController {

    // MARK: - 回调

    /// 礼物发送回调（礼物+数量）
    var onGiftSend: ((Gift, Int) -> Void)?

    // MARK: - 状态

    /// 礼物数据（20个）
    private var gifts = allGifts
    /// 当前选中的礼物索引（默认第一个）
    private var selectedIndex: Int = 0
    /// 发送数量（1-99，默认1）
    private var giftCount: Int = 1

    // MARK: - UI 组件

    /// 标题
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Gift"
        label.font = Theme.Fonts.bold(18)
        label.textColor = Theme.Colors.textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 黄色下划线（对应 Android title 下方的黄色线条）
    private let underlineView: UIView = {
        let v = UIView()
        v.backgroundColor = Theme.Colors.primaryYellow
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    /// 礼物网格（4列，对应 Android rvGifts GridLayoutManager(4)）
    private lazy var giftCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.delegate = self
        cv.dataSource = self
        cv.register(GiftCell.self, forCellWithReuseIdentifier: GiftCell.reuseId)
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()

    /// 余额显示（对应 Android coin balance）
    private let balanceLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.regular(13)
        label.textColor = Theme.Colors.primaryYellow
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 数量输入框
    private let countLabel: UILabel = {
        let label = UILabel()
        label.text = "1"
        label.font = Theme.Fonts.bold(16)
        label.textColor = Theme.Colors.textPrimary
        label.textAlignment = .center
        label.backgroundColor = Theme.Colors.cardBackground
        label.layer.cornerRadius = 8
        label.layer.masksToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 增加按钮
    private let increaseButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("▲", for: .normal)
        btn.setTitleColor(Theme.Colors.textPrimary, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 10)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    /// 减少按钮
    private let decreaseButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("▼", for: .normal)
        btn.setTitleColor(Theme.Colors.textPrimary, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 10)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    /// 发送按钮（对应 Android "Send" 黄色按钮）
    private let sendButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Send", for: .normal)
        btn.setTitleColor(Theme.Colors.darkerBackground, for: .normal)
        btn.titleLabel?.font = Theme.Fonts.bold(14)
        btn.backgroundColor = Theme.Colors.primaryYellow
        btn.layer.cornerRadius = 16
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.Colors.darkBackground
        setupUI()
        setupActions()
        updateBalance()
    }

    // MARK: - 界面搭建

    private func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(underlineView)
        view.addSubview(giftCollectionView)

        // 底部栏
        let bottomView = UIView()
        bottomView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomView)
        bottomView.addSubview(balanceLabel)
        bottomView.addSubview(decreaseButton)
        bottomView.addSubview(countLabel)
        bottomView.addSubview(increaseButton)
        bottomView.addSubview(sendButton)

        NSLayoutConstraint.activate([
            // 标题
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // 黄色下划线
            underlineView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            underlineView.centerXAnchor.constraint(equalTo: titleLabel.centerXAnchor),
            underlineView.widthAnchor.constraint(equalToConstant: 30),
            underlineView.heightAnchor.constraint(equalToConstant: 3),

            // 礼物网格（280dp 高度，对应 Android）
            giftCollectionView.topAnchor.constraint(equalTo: underlineView.bottomAnchor, constant: 12),
            giftCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            giftCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            giftCollectionView.heightAnchor.constraint(equalToConstant: 240),

            // 底部栏
            bottomView.topAnchor.constraint(equalTo: giftCollectionView.bottomAnchor, constant: 8),
            bottomView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            bottomView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            bottomView.heightAnchor.constraint(equalToConstant: 44),

            // 余额（左侧）
            balanceLabel.leadingAnchor.constraint(equalTo: bottomView.leadingAnchor),
            balanceLabel.centerYAnchor.constraint(equalTo: bottomView.centerYAnchor),

            // 发送按钮（右侧）
            sendButton.trailingAnchor.constraint(equalTo: bottomView.trailingAnchor),
            sendButton.centerYAnchor.constraint(equalTo: bottomView.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 72),
            sendButton.heightAnchor.constraint(equalToConstant: 32),

            // 数量选择（发送按钮左侧）
            countLabel.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -12),
            countLabel.centerYAnchor.constraint(equalTo: bottomView.centerYAnchor),
            countLabel.widthAnchor.constraint(equalToConstant: 40),
            countLabel.heightAnchor.constraint(equalToConstant: 28),

            increaseButton.bottomAnchor.constraint(equalTo: countLabel.topAnchor),
            increaseButton.centerXAnchor.constraint(equalTo: countLabel.centerXAnchor),

            decreaseButton.topAnchor.constraint(equalTo: countLabel.bottomAnchor),
            decreaseButton.centerXAnchor.constraint(equalTo: countLabel.centerXAnchor),
        ])
    }

    // MARK: - 事件

    private func setupActions() {
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        increaseButton.addTarget(self, action: #selector(increaseTapped), for: .touchUpInside)
        decreaseButton.addTarget(self, action: #selector(decreaseTapped), for: .touchUpInside)
    }

    /// 增加数量（最多99）
    @objc private func increaseTapped() {
        if giftCount < 99 {
            giftCount += 1
            countLabel.text = "\(giftCount)"
        }
    }

    /// 减少数量（最少1）
    @objc private func decreaseTapped() {
        if giftCount > 1 {
            giftCount -= 1
            countLabel.text = "\(giftCount)"
        }
    }

    /// 发送礼物（对应 Android GiftSelectorDialog 的 Send 逻辑）
    @objc private func sendTapped() {
        let gift = gifts[selectedIndex]
        let totalCost = gift.price * giftCount

        // 检查余额（对应 Android CoinManager.consumeCoins）
        if MockDataManager.shared.coinBalance < totalCost {
            // 余额不足
            let toast = UILabel()
            toast.text = "Insufficient coins"
            toast.font = Theme.Fonts.regular(14)
            toast.textColor = .white
            toast.backgroundColor = UIColor.black.withAlphaComponent(0.7)
            toast.textAlignment = .center
            toast.layer.cornerRadius = 8
            toast.layer.masksToBounds = true
            toast.frame = CGRect(x: 60, y: view.bounds.height - 100, width: view.bounds.width - 120, height: 36)
            view.addSubview(toast)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { toast.removeFromSuperview() }
            return
        }

        // 扣除金币
        MockDataManager.shared.coinBalance -= totalCost
        updateBalance()

        // 回调通知房间
        onGiftSend?(gift, giftCount)
        dismiss(animated: true)
    }

    /// 更新余额显示
    private func updateBalance() {
        balanceLabel.text = "💰 \(MockDataManager.shared.coinBalance)"
    }
}

// MARK: - 礼物网格 CollectionView
extension GiftSelectorViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return gifts.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GiftCell.reuseId, for: indexPath) as! GiftCell
        cell.configure(with: gifts[indexPath.item], isSelected: indexPath.item == selectedIndex)
        return cell
    }

    /// 点击选择礼物
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedIndex = indexPath.item
        collectionView.reloadData()
    }

    /// 每个礼物 cell 大小（4列，对应 Android GridLayoutManager(4)）
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 16 * 2 - 8 * 3) / 4
        return CGSize(width: width, height: width + 36) // 图片 + 名称 + 价格
    }
}

// MARK: - 礼物 Cell

/// 单个礼物 Cell（对应 Android item_gift.xml）
/// 布局：80x80 礼物图片 + 名称 + ��价格
class GiftCell: UICollectionViewCell {
    static let reuseId = "GiftCell"

    /// 礼物图片
    private let giftImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    /// 礼物名称（12sp，单行）
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.regular(11)
        label.textColor = Theme.Colors.textSecondary
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 价格（11sp，黄色）
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.regular(10)
        label.textColor = Theme.Colors.primaryYellow
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 8
        contentView.layer.borderWidth = 1.5
        contentView.layer.borderColor = UIColor.clear.cgColor

        contentView.addSubview(giftImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(priceLabel)

        NSLayoutConstraint.activate([
            giftImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            giftImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            giftImageView.widthAnchor.constraint(equalToConstant: 48),
            giftImageView.heightAnchor.constraint(equalToConstant: 48),

            nameLabel.topAnchor.constraint(equalTo: giftImageView.bottomAnchor, constant: 4),
            nameLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            priceLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            priceLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 配置礼物 Cell
    func configure(with gift: Gift, isSelected: Bool) {
        giftImageView.image = UIImage(named: gift.imageName)
        nameLabel.text = gift.name
        priceLabel.text = "�� \(gift.price)"

        // 选中状态边框（对应 Android bg_gift_selected / bg_gift_unselected）
        contentView.layer.borderColor = isSelected
            ? Theme.Colors.primaryYellow.cgColor
            : UIColor.clear.cgColor
        contentView.backgroundColor = isSelected
            ? Theme.Colors.primaryYellow.withAlphaComponent(0.1)
            : Theme.Colors.cardBackground
    }
}
