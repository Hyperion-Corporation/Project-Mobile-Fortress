import UIKit

/// Minimal `UIApplicationDelegate`, used alongside the SwiftUI `@main` app
/// (`@UIApplicationDelegateAdaptor`) only for the lifecycle hooks SwiftUI's
/// `Scene`/`ScenePhase` API doesn't cover cleanly for SpriteKit — namely,
/// making sure the render/physics loop inside `GameScene` is paused before
/// the app is suspended, matching the pause-on-background contract documented
/// in `.agent/workflows/ios_lifecycle.md` (analogous to `GameView`'s
/// `SurfaceHolder.Callback` teardown on Android).
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        GameManager.shared.pause()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        GameManager.shared.pause()
    }
}
