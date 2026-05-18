import UIKit

/// 完善资料页 - 对应 Android GameMic 的 CompleteProfileActivity
/// 注册成功后填写：头像、昵称、国家、性别
/// 完成后跳转 SelectInterestsViewController 选择兴趣
class CompleteProfileViewController: UIViewController {

    // MARK: - 传入数据（从注册页传来）

    var userId: String = ""
    var email: String = ""

    // MARK: - 表单状态

    /// 选中的性别（默认 male，对应 Android selectedGender）
    private var selectedGender: String = "male"

    // MARK: - UI 组件

    /// 头像容器（对应 Android iv_avatar + iv_camera）
    private let avatarView: UIView = {
        let v = UIView()
        v.backgroundColor = Theme.Colors.primaryYellow.withAlphaComponent(0.2)
        v.layer.cornerRadius = 50
        v.layer.borderWidth = 2
        v.layer.borderColor = Theme.Colors.primaryYellow.cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    /// 头像占位图标
    private let avatarPlaceholder: UILabel = {
        let label = UILabel()
        label.text = "📷"
        label.font = UIFont.systemFont(ofSize: 36)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 昵称输入框（对应 Android et_nickname）
    private let nicknameField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Nickname"
        tf.textColor = Theme.Colors.textPrimary
        tf.font = Theme.Fonts.regular(16)
        tf.backgroundColor = Theme.Colors.cardBackground
        tf.layer.cornerRadius = 12
        tf.layer.borderWidth = 1
        tf.layer.borderColor = Theme.Colors.separator.cgColor
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        tf.leftViewMode = .always
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    /// 性别选择区域标题
    private let genderLabel: UILabel = {
        let label = UILabel()
        label.text = "Gender"
        label.font = Theme.Fonts.medium(14)
        label.textColor = Theme.Colors.textSecondary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 男性选择按钮（对应 Android iv_male）
    private let maleButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("♂ Male", for: .normal)
        btn.titleLabel?.font = Theme.Fonts.medium(14)
        btn.layer.cornerRadius = 20
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    /// 女性选择按钮（对应 Android iv_female）
    private let femaleButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("♀ Female", for: .normal)
        btn.titleLabel?.font = Theme.Fonts.medium(14)
        btn.layer.cornerRadius = 20
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    /// 下一步按钮（对应 Android btn_next）
    private let nextButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Next", for: .normal)
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
        title = "Complete Profile"
        view.backgroundColor = Theme.Colors.darkBackground
        setupUI()
        setupActions()
        updateGenderUI()
    }

    // MARK: - 界面搭建

    private func setupUI() {
        navigationItem.leftBarButtonItem = makeAppBackButton(action: #selector(backTapped))

        view.addSubview(avatarView)
        avatarView.addSubview(avatarPlaceholder)
        view.addSubview(nicknameField)
        view.addSubview(genderLabel)
        view.addSubview(maleButton)
        view.addSubview(femaleButton)
        view.addSubview(nextButton)

        NSLayoutConstraint.activate([
            // 头像（100x100，居中）
            avatarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            avatarView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 100),
            avatarView.heightAnchor.constraint(equalToConstant: 100),

            avatarPlaceholder.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarPlaceholder.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),

            // 昵称
            nicknameField.topAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: 32),
            nicknameField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            nicknameField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            nicknameField.heightAnchor.constraint(equalToConstant: 50),

            // 性别标题
            genderLabel.topAnchor.constraint(equalTo: nicknameField.bottomAnchor, constant: 24),
            genderLabel.leadingAnchor.constraint(equalTo: nicknameField.leadingAnchor),

            // 男女按钮（并排）
            maleButton.topAnchor.constraint(equalTo: genderLabel.bottomAnchor, constant: 12),
            maleButton.leadingAnchor.constraint(equalTo: nicknameField.leadingAnchor),
            maleButton.widthAnchor.constraint(equalToConstant: 120),
            maleButton.heightAnchor.constraint(equalToConstant: 40),

            femaleButton.topAnchor.constraint(equalTo: maleButton.topAnchor),
            femaleButton.leadingAnchor.constraint(equalTo: maleButton.trailingAnchor, constant: 16),
            femaleButton.widthAnchor.constraint(equalToConstant: 120),
            femaleButton.heightAnchor.constraint(equalToConstant: 40),

            // 下一步按钮
            nextButton.topAnchor.constraint(equalTo: maleButton.bottomAnchor, constant: 48),
            nextButton.leadingAnchor.constraint(equalTo: nicknameField.leadingAnchor),
            nextButton.trailingAnchor.constraint(equalTo: nicknameField.trailingAnchor),
            nextButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    // MARK: - 事件

    private func setupActions() {
        maleButton.addTarget(self, action: #selector(maleTapped), for: .touchUpInside)
        femaleButton.addTarget(self, action: #selector(femaleTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    /// 选择男性
    @objc private func maleTapped() {
        selectedGender = "male"
        updateGenderUI()
    }

    /// 选择女性
    @objc private func femaleTapped() {
        selectedGender = "female"
        updateGenderUI()
    }

    /// 更新性别按钮样式（对应 Android checkbox checked/unchecked 状态切换）
    private func updateGenderUI() {
        if selectedGender == "male" {
            maleButton.backgroundColor = Theme.Colors.primaryYellow
            maleButton.setTitleColor(Theme.Colors.darkerBackground, for: .normal)
            femaleButton.backgroundColor = Theme.Colors.cardBackground
            femaleButton.setTitleColor(Theme.Colors.textSecondary, for: .normal)
        } else {
            femaleButton.backgroundColor = Theme.Colors.primaryYellow
            femaleButton.setTitleColor(Theme.Colors.darkerBackground, for: .normal)
            maleButton.backgroundColor = Theme.Colors.cardBackground
            maleButton.setTitleColor(Theme.Colors.textSecondary, for: .normal)
        }
    }

    /// 下一步点击 → 验证 → 跳转兴趣选择页
    @objc private func nextTapped() {
        let nickname = nicknameField.text?.trimmingCharacters(in: .whitespaces) ?? ""

        // 昵称不能为空（对应 Android "Please enter your nickname"）
        guard !nickname.isEmpty else {
            showToast("Please enter your nickname")
            return
        }

        // 跳转兴趣选择页（传递资料数据，对应 Android → SelectInterestsActivity）
        let vc = SelectInterestsViewController()
        vc.nickname = nickname
        vc.gender = selectedGender
        navigationController?.pushViewController(vc, animated: true)
    }

}
