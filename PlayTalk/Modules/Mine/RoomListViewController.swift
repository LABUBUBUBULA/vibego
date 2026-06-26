import UIKit

/// 我的收藏/浏览记录通用列表页 - 对应 Android CollectionActivity / BrowseHistoryActivity
class RoomListViewController: UIViewController {

    enum ListType {
        case collection
        case browseHistory

        var title: String {
            switch self {
            case .collection: return "My Collection"
            case .browseHistory: return "Browse History"
            }
        }

        var emptyText: String {
            switch self {
            case .collection: return "No collected rooms yet"
            case .browseHistory: return "No browse history yet"
            }
        }
    }

    var listType: ListType = .collection
    private var rooms: [VoiceRoom] = []

    private lazy var tableView: UITableView = {
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

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.regular(15)
        label.textColor = Theme.Colors.textSecondary
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = listType.title
        view.backgroundColor = Theme.Colors.darkBackground
        setupUI()
        loadData()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(moderationDidChange),
            name: ModerationManager.moderationDidChange,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }

    private func setupUI() {
        view.addSubview(tableView)
        view.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            emptyLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
        ])
    }

    private func loadData() {
        switch listType {
        case .collection:
            rooms = MockDataManager.shared.getCollectedRooms()
        case .browseHistory:
            rooms = MockDataManager.shared.getBrowseHistoryRooms()
        }
        emptyLabel.text = listType.emptyText
        emptyLabel.isHidden = !rooms.isEmpty
        tableView.reloadData()
    }

    @objc private func moderationDidChange() {
        loadData()
    }

    private func openRoom(_ room: VoiceRoom) {
        guard ModerationManager.shared.shouldShow(room: room) else {
            showToast("This room is unavailable")
            loadData()
            return
        }
        // 与 Android 一致：列表项点击进入语音房；iOS mock 数据中已删除房间不会返回。
        MockDataManager.shared.addBrowseHistory(room)
        let vc = VoiceRoomViewController()
        vc.room = room
        vc.isOwner = false
        pushAppViewController(vc, animated: true)
    }
}

extension RoomListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rooms.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RoomCell.reuseId, for: indexPath) as! RoomCell
        cell.configure(with: rooms[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        108
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        openRoom(rooms[indexPath.row])
    }
}
