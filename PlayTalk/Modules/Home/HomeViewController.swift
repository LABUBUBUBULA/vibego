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
        loadData()
    }

    // MARK: - 界面搭建

    private func setupUI() {
        view.addSubview(categoryCollectionView)
        view.addSubview(roomTableView)

        NSLayoutConstraint.activate([
            // 分类筛选栏（高 36dp，对应 Android）
            categoryCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            categoryCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            categoryCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            categoryCollectionView.heightAnchor.constraint(equalToConstant: 36),

            // 房间列表
            roomTableView.topAnchor.constraint(equalTo: categoryCollectionView.bottomAnchor, constant: 8),
            roomTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            roomTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            roomTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - 数据加载

    /// 根据当前选中的分类加载语音房数据
    private func loadData() {
        let category = categories[selectedCategoryIndex]
        rooms = MockDataManager.shared.getRooms(for: category)
        roomTableView.reloadData()
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
        let vc = VoiceRoomViewController()
        vc.room = rooms[indexPath.row]
        vc.isOwner = false
        navigationController?.pushViewController(vc, animated: true)
    }
}
