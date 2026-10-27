import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let setupVC = SetupViewController()
        setupVC.tabBarItem = UITabBarItem(title: "Setup & Test",
                                          image: UIImage(systemName: "keyboard"),
                                          tag: 0)

        let historyVC = HistoryViewController()
        historyVC.tabBarItem = UITabBarItem(title: "Clipboard",
                                            image: UIImage(systemName: "doc.on.clipboard"),
                                            tag: 1)

        let tabBar = UITabBarController()
        tabBar.viewControllers = [
            UINavigationController(rootViewController: setupVC),
            UINavigationController(rootViewController: historyVC),
        ]

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = tabBar
        window.makeKeyAndVisible()
        self.window = window
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Opportunistically capture the current system clipboard when the host app opens.
        let pb = UIPasteboard.general
        let store = ClipboardStore.shared
        guard pb.changeCount != store.lastSeenChangeCount else { return }
        store.lastSeenChangeCount = pb.changeCount
        if pb.hasStrings, let text = pb.string {
            store.add(text)
            NotificationCenter.default.post(name: .clipboardHistoryDidUpdate, object: nil)
        }
    }
}

extension Notification.Name {
    static let clipboardHistoryDidUpdate = Notification.Name("kbx.clipboardHistoryDidUpdate")
}
