import UIKit

/// 分类筛选标签 Cell - 对应 Android HomeFragment 的分类按钮
/// 选中：黄底深色文字 | 未选中：深色底灰色文字
class CategoryCell: UICollectionViewCell {
    static let reuseId = "CategoryCell"

    // MARK: - UI 组件

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.medium(14) // 对应 Android 14sp
        label.textAlignment = .center
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - 初始化

    /// 底部选中指示条
    private let indicator: UIView = {
        let v = UIView()
        v.backgroundColor = Theme.Colors.primaryPurple
        v.layer.cornerRadius = 1.5
        v.isHidden = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(titleLabel)
        contentView.addSubview(indicator)
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            indicator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            indicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            indicator.widthAnchor.constraint(equalToConstant: 24),
            indicator.heightAnchor.constraint(equalToConstant: 3)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 配置

    /// 设置分类标签内容和选中状态
    /// - Parameters:
    ///   - title: 分类名称
    ///   - isSelected: 是否选中（选中为黄色背景）
    func configure(title: String, isSelected: Bool) {
        titleLabel.text = title
        if isSelected {
            contentView.backgroundColor = .clear
            titleLabel.textColor = Theme.Colors.primaryPurple
            titleLabel.font = Theme.Fonts.bold(15)
            indicator.isHidden = false
        } else {
            contentView.backgroundColor = .clear
            titleLabel.textColor = Theme.Colors.textSecondary
            titleLabel.font = Theme.Fonts.medium(14)
            indicator.isHidden = true
        }
    }
}
