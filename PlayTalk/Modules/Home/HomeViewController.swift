import UIKit

/// 首页 - 对应 Android GameMic 的 HomeFragment
/// 顶部游戏分类筛选 + 语音房卡片列表
/// 分类：Popular / PUBG / Minecraft / Fortnite / TheSims
class HomeViewController: UIViewController {

    // MARK: - 数据

    /// 游戏分类列表
    private let categories = MockDataManager.shared.gameCategories
    /// 当前选中分类索引（默认 Popular）
    private var selectedCategoryIndex = 0
    /// 当前显示的语音房列表
    private var rooms: [VoiceRoom] = []

    // MARK: - UI 组件

    private let createRoomButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        btn.tintColor = Theme.Colors.primaryYellow
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let backRoomButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "arrow.uturn.backward.circle.fill"), for: .normal)
        btn.tintColor = Theme.Colors.primaryYellow
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let roomFloatView: UIView = {
        let v = UIView()
        v.backgroundColor = Theme.Colors.cardBackground
        v.layer.cornerRadius = 24
        v.layer.borderWidth = 1
        v.layer.borderColor = Theme.Colors.primaryYellow.withAlphaComponent(0.4).cgColor
        v.isHidden = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let roomFloatImageView: UIImageView = {
        let iv = UIImageView()
        iv.layer.cornerRadius = 18
        iv.layer.masksToBounds = true
        iv.contentMode = .scaleAspectFill
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let roomFloatTitleLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.medium(13)
        label.textColor = Theme.Colors.textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let roomFloatIdLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.regular(11)
        label.textColor = Theme.Colors.textSecondary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let roomFloatCloseButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        btn.tintColor = Theme.Colors.textSecondary
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private func makeHeaderButtonStack() -> UIStackView {
        let stack = UIStackView(arrangedSubviews: [backRoomButton, createRoomButton])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }


    /// 顶部分类水平滚动列表（对应 Android 的 HorizontalScrollView）
    private lazy var categoryCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.delegate = self
        cv.dataSource = self
        cv.register(CategoryCell.self, forCellWithReuseIdentifier: CategoryCell.reuseId)
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()

    /// 语音房列表（对应 Android 的 RecyclerView）
    private lazy var roomTableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.delegate = self
        tv.dataSource = self
        tv.register(RoomCell.self, forCellReuseIdentifier: RoomCell.reuseId)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 16, right: 0)
        return tv
    }()

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Voice Game"    // 对应 Android 的 "Voice Game" 标题
        view.backgroundColor = Theme.Colors.darkBackground
        setupUI()
        setupActions()
        loadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
        updateMinimizedRoomFloat()
    }

    // MARK: - 界面搭建

    private func setupUI() {
        let headerButtons = makeHeaderButtonStack()
        view.addSubview(headerButtons)
        view.addSubview(categoryCollectionView)
        view.addSubview(roomTableView)
        view.addSubview(roomFloatView)
        roomFloatView.addSubview(roomFloatImageView)
        roomFloatView.addSubview(roomFloatTitleLabel)
        roomFloatView.addSubview(roomFloatIdLabel)
        roomFloatView.addSubview(roomFloatCloseButton)

        NSLayoutConstraint.activate([
            headerButtons.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            headerButtons.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            createRoomButton.widthAnchor.constraint(equalToConstant: 32),
            createRoomButton.heightAnchor.constraint(equalToConstant: 32),
            backRoomButton.widthAnchor.constraint(equalToConstant: 32),
            backRoomButton.heightAnchor.constraint(equalToConstant: 32),

            // 分类筛选栏（高 36dp，对应 Android）
            categoryCollectionView.topAnchor.constraint(equalTo: headerButtons.bottomAnchor, constant: 8),
            categoryCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            categoryCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            categoryCollectionView.heightAnchor.constraint(equalToConstant: 36),

            // 房间列表
            roomTableView.topAnchor.constraint(equalTo: categoryCollectionView.bottomAnchor, constant: 8),
            roomTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            roomTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            roomTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            roomFloatView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            roomFloatView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            roomFloatView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            roomFloatView.heightAnchor.constraint(equalToConstant: 56),

            roomFloatImageView.leadingAnchor.constraint(equalTo: roomFloatView.leadingAnchor, constant: 12),
            roomFloatImageView.centerYAnchor.constraint(equalTo: roomFloatView.centerYAnchor),
            roomFloatImageView.widthAnchor.constraint(equalToConstant: 36),
            roomFloatImageView.heightAnchor.constraint(equalToConstant: 36),

            roomFloatTitleLabel.leadingAnchor.constraint(equalTo: roomFloatImageView.trailingAnchor, constant: 10),
            roomFloatTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: roomFloatCloseButton.leadingAnchor, constant: -8),
            roomFloatTitleLabel.topAnchor.constraint(equalTo: roomFloatView.topAnchor, constant: 10),

            roomFloatIdLabel.leadingAnchor.constraint(equalTo: roomFloatTitleLabel.leadingAnchor),
            roomFloatIdLabel.topAnchor.constraint(equalTo: roomFloatTitleLabel.bottomAnchor, constant: 2),

            roomFloatCloseButton.trailingAnchor.constraint(equalTo: roomFloatView.trailingAnchor, constant: -12),
            roomFloatCloseButton.centerYAnchor.constraint(equalTo: roomFloatView.centerYAnchor),
            roomFloatCloseButton.widthAnchor.constraint(equalToConstant: 28),
            roomFloatCloseButton.heightAnchor.constraint(equalToConstant: 28)
        ])
    }

    private func setupActions() {
        createRoomButton.addTarget(self, action: #selector(createRoomTapped), for: .touchUpInside)
        backRoomButton.addTarget(self, action: #selector(backRoomTapped), for: .touchUpInside)
        roomFloatCloseButton.addTarget(self, action: #selector(closeFloatTapped), for: .touchUpInside)
        roomFloatView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(roomFloatTapped)))
    }

    // MARK: - 数据加载

    /// 根据当前选中的分类加载语音房数据
    private func loadData() {
        let category = categories[selectedCategoryIndex]
        rooms = MockDataManager.shared.getRooms(for: category)
        roomTableView.reloadData()
    }

    private func updateMinimizedRoomFloat() {
        guard let minimized = MockDataManager.shared.getMinimizedRoom() else {
            roomFloatView.isHidden = true
            return
        }
        roomFloatView.isHidden = false
        roomFloatImageView.image = UIImage(named: minimized.room.coverImage)
        roomFloatTitleLabel.text = minimized.room.roomName
        roomFloatIdLabel.text = "ID: \(minimized.room.roomId)"
    }

    @objc private func createRoomTapped() {
        navigationController?.pushViewController(CreateRoomViewController(), animated: true)
    }

    @objc private func backRoomTapped() {
        guard let minimized = MockDataManager.shared.getMinimizedRoom() else {
            showToast("Currently not in any room")
            return
        }
        openRoom(minimized.room, isOwner: minimized.isOwner)
    }

    @objc private func roomFloatTapped() {
        guard let minimized = MockDataManager.shared.getMinimizedRoom() else { return }
        openRoom(minimized.room, isOwner: minimized.isOwner)
    }

    @objc private func closeFloatTapped() {
        MockDataManager.shared.clearMinimizedRoom()
        updateMinimizedRoomFloat()
    }

    private func openRoom(_ room: VoiceRoom, isOwner: Bool) {
        // 记录浏览历史，对应 Android BrowseHistoryManager.addBrowseHistory
        MockDataManager.shared.addBrowseHistory(room)
        let vc = VoiceRoomViewController()
        vc.room = room
        vc.isOwner = isOwner
        navigationController?.pushViewController(vc, animated: true)
    }

    private func showToast(_ message: String) {
        let toast = UILabel()
        toast.text = message
        toast.font = Theme.Fonts.regular(14)
        toast.textColor = .white
        toast.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        toast.textAlignment = .center
        toast.layer.cornerRadius = 8
        toast.layer.masksToBounds = true
        toast.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toast)
        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80),
            toast.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),
            toast.heightAnchor.constraint(equalToConstant: 36)
        ])
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            toast.removeFromSuperview()
        }
    }
}

// MARK: - 分类 CollectionView 数据源和代理
extension HomeViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categories.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryCell.reuseId, for: indexPath) as! CategoryCell
        cell.configure(
            title: categories[indexPath.item],
            isSelected: indexPath.item == selectedCategoryIndex
        )
        return cell
    }

    /// 点击分类切换 - 刷新列表
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedCategoryIndex = indexPath.item
        collectionView.reloadData()
        loadData()
    }
}

// MARK: - 房间列表 TableView 数据源和代理
extension HomeViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rooms.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RoomCell.reuseId, for: indexPath) as! RoomCell
        cell.configure(with: rooms[indexPath.row])
        return cell
    }

    /// 房间卡片高度 100dp（对应 Android item_game_discussion 高度）
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 108
    }

    /// 点击进入语音房（对应 Android 的 VoiceRoomActivity 跳转）
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        openRoom(rooms[indexPath.row], isOwner: false)
    }
}
