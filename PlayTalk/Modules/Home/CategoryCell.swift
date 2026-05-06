import UIKit

/// 分类筛选标签 Cell - 对应 Android HomeFragment 的分类按钮
/// 选中：黄底深色文字 | 未选中：深色底灰色文字
class CategoryCell: UICollectionViewCell {
    static let reuseId = "CategoryCell"

    // MARK: - UI 组件

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.medium(14) // 对应 Android 14sp
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - 初始化

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(titleLabel)
        contentView.layer.cornerRadius = 18  // 圆角胶囊形状
        contentView.layer.masksToBounds = true

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20), // 对应 Android 20dp padding
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
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
            // 选中状态：黄色背景 + 深色文字（对应 Android bg_tab_selected + #FFD500）
            contentView.backgroundColor = Theme.Colors.primaryYellow
            titleLabel.textColor = Theme.Colors.darkerBackground
        } else {
            // 未选中状态：深色背景 + 灰色文字（对应 Android bg_tab_normal + #999999）
            contentView.backgroundColor = Theme.Colors.cardBackground
            titleLabel.textColor = Theme.Colors.textSecondary
        }
    }
}
