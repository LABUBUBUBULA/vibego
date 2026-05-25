import UIKit
import StoreKit

/// 充值页面 - 对应 Android GameMic 的 RechargeActivity
/// 展示金币套餐列表，选择后模拟购买（Apple IAP 后续接入）
/// 布局：余额展示 → 套餐网格(2列) → 购买按钮
class RechargeViewController: UIViewController {

    // MARK: - 数据

    /// 充值套餐（对应 Android 的 5 个金币内购套餐）
    private let packages: [(coins: Int, price: String, productId: String)] = [
        (100, "$0.99", "com.playtalklive.coins100"),
        (500, "$4.99", "com.playtalklive.coins500"),
        (1000, "$9.99", "com.playtalklive.coins1000"),
        (5000, "$49.99", "com.playtalklive.coins5000"),
        (10000, "$99.99", "com.playtalklive.coins10000"),
    ]

    /// 当前选中套餐索引
    private var selectedIndex: Int = 0

    // MARK: - UI 组件

    /// 余额标签
    private let balanceLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.bold(28)
        label.textColor = Theme.Colors.primaryYellow
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 余额描述
    private let balanceTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Current Balance"
        label.font = Theme.Fonts.regular(14)
        label.textColor = Theme.Colors.textSecondary
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 套餐网格
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.delegate = self
        cv.dataSource = self
        cv.register(RechargeCell.self, forCellWithReuseIdentifier: RechargeCell.reuseId)
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()

    /// 购买按钮
    private let buyButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Purchase", for: .normal)
        btn.setTitleColor(Theme.Colors.darkerBackground, for: .normal)
        btn.titleLabel?.font = Theme.Fonts.bold(16)
        btn.backgroundColor = Theme.Colors.primaryYellow
        btn.layer.cornerRadius = 25
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Recharge"
        view.backgroundColor = Theme.Colors.darkBackground
        setupUI()
        updateBalance()
        buyButton.addTarget(self, action: #selector(buyTapped), for: .touchUpInside)
    }

    // MARK: - 界面搭建

    private func setupUI() {
        view.addSubview(balanceTitleLabel)
        view.addSubview(balanceLabel)
        view.addSubview(collectionView)
        view.addSubview(buyButton)

        NSLayoutConstraint.activate([
            balanceTitleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            balanceTitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            balanceLabel.topAnchor.constraint(equalTo: balanceTitleLabel.bottomAnchor, constant: 8),
            balanceLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            collectionView.topAnchor.constraint(equalTo: balanceLabel.bottomAnchor, constant: 32),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: 280),

            buyButton.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 32),
            buyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            buyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            buyButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    /// 更新余额显示
    private func updateBalance() {
        balanceLabel.text = "💰 \(MockDataManager.shared.coinBalance)"
    }

    /// 购买按钮点击 → StoreKit 2 发起真实内购
    @objc private func buyTapped() {
        let package = packages[selectedIndex]
        buyButton.isEnabled = false
        buyButton.setTitle("Processing...", for: .normal)

        Task {
            do {
                let products = try await Product.products(for: [package.productId])
                guard let product = products.first else {
                    await showPurchaseResult(success: false, message: "Product not found", coins: 0)
                    return
                }

                let result = try await product.purchase()
                switch result {
                case .success(let verification):
                    switch verification {
                    case .verified(let transaction):
                        await transaction.finish()
                        // 购买成功，加金币
                        await MainActor.run {
                            MockDataManager.shared.coinBalance += package.coins
                            updateBalance()
                        }
                        await showPurchaseResult(success: true, message: "You received \(package.coins) coins!", coins: package.coins)
                    case .unverified(_, let error):
                        await showPurchaseResult(success: false, message: error.localizedDescription, coins: 0)
                    }
                case .pending:
                    await showPurchaseResult(success: false, message: "Purchase pending approval", coins: 0)
                case .userCancelled:
                    await resetBuyButton()
                @unknown default:
                    await resetBuyButton()
                }
            } catch {
                await showPurchaseResult(success: false, message: error.localizedDescription, coins: 0)
            }
        }
    }

    @MainActor
    private func showPurchaseResult(success: Bool, message: String, coins: Int) {
        resetBuyButton()
        let alert = UIAlertController(
            title: success ? "Purchase Successful" : "Purchase Failed",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @MainActor
    private func resetBuyButton() {
        buyButton.isEnabled = true
        buyButton.setTitle("Purchase", for: .normal)
    }
}

// MARK: - CollectionView 数据源
extension RechargeViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return packages.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RechargeCell.reuseId, for: indexPath) as! RechargeCell
        let pkg = packages[indexPath.item]
        cell.configure(coins: pkg.coins, price: pkg.price, isSelected: indexPath.item == selectedIndex)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedIndex = indexPath.item
        collectionView.reloadData()
    }

    /// 每个套餐 cell 大小（2列）
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 24 * 2 - 12) / 2
        return CGSize(width: width, height: 80)
    }
}

// MARK: - 充值套餐 Cell

/// 单个套餐卡片 - 金币数量 + 价格
class RechargeCell: UICollectionViewCell {
    static let reuseId = "RechargeCell"

    /// 金币数量
    private let coinsLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.bold(20)
        label.textColor = Theme.Colors.primaryYellow
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 价格
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.regular(14)
        label.textColor = Theme.Colors.textSecondary
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 12
        contentView.addSubview(coinsLabel)
        contentView.addSubview(priceLabel)

        NSLayoutConstraint.activate([
            coinsLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            coinsLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),

            priceLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            priceLabel.topAnchor.constraint(equalTo: coinsLabel.bottomAnchor, constant: 4)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(coins: Int, price: String, isSelected: Bool) {
        coinsLabel.text = "💰 \(coins)"
        priceLabel.text = price
        contentView.backgroundColor = isSelected ? Theme.Colors.primaryYellow.withAlphaComponent(0.15) : Theme.Colors.cardBackground
        contentView.layer.borderWidth = isSelected ? 2 : 0
        contentView.layer.borderColor = isSelected ? Theme.Colors.primaryYellow.cgColor : UIColor.clear.cgColor
    }
}
