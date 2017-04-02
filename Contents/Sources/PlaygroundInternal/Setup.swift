import UIKit
import PlaygroundSupport

public func _setup() {
    let viewController = GameViewController()
    viewController.view = Canvas.shared.backingView
    PlaygroundPage.current.liveView = viewController
}
