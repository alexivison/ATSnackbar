//
//  ATSnackbar.swift
//  ATSnackbar
//
//  Created by Aleksi Tuominen on 2019/05/17.
//  Copyright © 2019 Aleksi Tuominen. All rights reserved.
//

import Foundation
import UIKit

/**
 Main class
 */
open class ATSnackbar: UIView {
    
    private var timer: Timer?
    private var isActive: Bool = false
    
    // MARK: - Constraints
    private var leftMarginConstraint: NSLayoutConstraint?
    private var rightMarginConstraint: NSLayoutConstraint?
    private var topMarginConstraint: NSLayoutConstraint?
    private var bottomMarginConstraint: NSLayoutConstraint?
    private var centerXConstraint: NSLayoutConstraint?
    private var minHeightConstraint: NSLayoutConstraint?
    
    // MARK: - Defaults
    private let defaultFrame: CGRect = CGRect(x: 0, y: 0, width: 320, height: 46)
    private let defaultHeight: CGFloat = 46
    
    // MARK: - Components
    public var messageLabel = UILabel()
    public var actionButton = UIButton()
    
    // MARK: - Margins
    public var leftMargin: CGFloat = 0
    public var rightMargin: CGFloat = 0
    public var topMargin: CGFloat = 0
    public var bottomMargin: CGFloat = 0
    
    // MARK: - Dismiss
    public var autoDismiss: Bool = true
    public var duration: Double = 2.0
    
    // MARK: Animations
    public var animation: ATSnackbarAnimationType = .spring
    public var animationDuration: Double = 0.6
    public var animationDirection: ATSnackbarAnimationDirection = .top
    public var animationDelay: Double = 0.0
    public var animationDamping: CGFloat = 0.8
    public var animationSpringVelocity: CGFloat = 1.0
    public var presentAnimationOptions: AnimationOptions = []
    public var dismissAnimationOptions: AnimationOptions = [.curveEaseIn]
    
    override init(frame: CGRect) {
        super.init(frame: defaultFrame)
        configure()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }
}

extension ATSnackbar {
    private func configure() {
        // Snackbar
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .darkGray
        alpha = 0.0

        // button
        addSubview(actionButton)
        actionButton.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -16).isActive = true
        actionButton.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.setTitleColor(.green, for: .normal)
        actionButton.setTitleColor(.white, for: .focused)
        actionButton.setTitle("OK", for: .normal)
        actionButton.addTarget(self, action: #selector(closeAction), for: .allTouchEvents)

        // Label
        addSubview(messageLabel)
        messageLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 16).isActive = true
        messageLabel.rightAnchor.constraint(equalTo: actionButton.leftAnchor, constant: -8).isActive = true
        messageLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.numberOfLines = 2
        messageLabel.textColor = .white
        messageLabel.minimumScaleFactor = 0.7
        messageLabel.adjustsFontSizeToFitWidth = true
        messageLabel.adjustsFontForContentSizeCategory = true
        messageLabel.text = "Message"
        
        // TODO: Swipe gesture
        [UISwipeGestureRecognizer.Direction.up, .down, .left, .right].forEach { (direction) in
            let gesture = UISwipeGestureRecognizer(target: self, action: #selector(swipeAction))
            gesture.direction = direction
            self.addGestureRecognizer(gesture)
        }
    }
}

// MARK: - Present extension
/**
 Present the snackbar
 */
extension ATSnackbar {
    
    /**
     Set up the initial present layout
     */
    open func present() {
        guard let window = UIApplication.shared.delegate?.window ?? UIApplication.shared.keyWindow else {
            fatalError()
        }
        // Return if a snackbar is already active
        if isActive {
            return
        }
        // Start the dismiss timer
        if autoDismiss {
            timer = Timer.init(timeInterval: (TimeInterval)(duration), target: self, selector: #selector(closeAction), userInfo: nil, repeats: false)
            RunLoop.main.add(timer!, forMode: .common)
        }
        
        // Set the constraint target based on OS version
        var target: Any
        if #available(iOS 11.0, *) {
            target = window.safeAreaLayoutGuide
        } else {
            target = window
        }

        // Add snackbar to window
        window.addSubview(self)
        
        // Left constraints
        leftMarginConstraint = NSLayoutConstraint(
            item: self, attribute: .left, relatedBy: .equal,
            toItem: target, attribute: .left, multiplier: 1, constant: leftMargin)
        window.addConstraint(leftMarginConstraint!)

        // Right margin constraint
        rightMarginConstraint = NSLayoutConstraint(
            item: self, attribute: .right, relatedBy: .equal,
            toItem: target, attribute: .right, multiplier: 1, constant: -rightMargin)
        window.addConstraint(rightMarginConstraint!)

        // Bottom margin constraint
        bottomMarginConstraint = NSLayoutConstraint(
            item: self, attribute: .bottom, relatedBy: .equal,
            toItem: target, attribute: .bottom, multiplier: 1, constant: -defaultHeight)
        window.addConstraint(bottomMarginConstraint!)

        // Top margin constraint
        topMarginConstraint = NSLayoutConstraint(
            item: self, attribute: .top, relatedBy: .equal,
            toItem: target, attribute: .top, multiplier: 1, constant: topMargin)
        window.addConstraint(topMarginConstraint!)

        // Center X constraint
        centerXConstraint = NSLayoutConstraint(
            item: self, attribute: .centerX, relatedBy: .equal,
            toItem: window, attribute: .centerX, multiplier: 1, constant: 0)
        window.addConstraint(centerXConstraint!)

        // Minheight
        minHeightConstraint = NSLayoutConstraint(
            item: self, attribute: .height, relatedBy: .greaterThanOrEqual,
            toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: defaultHeight)
        window.addConstraint(minHeightConstraint!)
        
        animatePresent()
    }
    
    /**
     Animate the presentation
     */
    private func animatePresent() {
        // Set active
        isActive = true
        
        // Set animation position
        switch animationDirection {
        case .top:
            bottomMarginConstraint?.isActive = false
            topMarginConstraint?.isActive = true
            if animation == .fade {
                topMarginConstraint?.constant = topMargin
            } else {
                topMarginConstraint?.constant = -defaultHeight
            }
        case .bottom:
            topMarginConstraint?.isActive = false
            bottomMarginConstraint?.isActive = true
            if animation == .fade {
                bottomMarginConstraint?.constant = bottomMargin
            } else {
                bottomMarginConstraint?.constant = defaultHeight
            }
        }
        
        self.window?.layoutIfNeeded()
        
        // Final layout
        switch animation {
        case .spring:
            bottomMarginConstraint?.constant = -bottomMargin
            topMarginConstraint?.constant = topMargin
            leftMarginConstraint?.constant = leftMargin
            rightMarginConstraint?.constant = -rightMargin
            centerXConstraint?.constant = 0
        default:
            break
        }
        
        // Animate
        UIView.animate(
            withDuration: animationDuration,
            delay: animationDelay,
            usingSpringWithDamping: animationDamping,
            initialSpringVelocity: animationSpringVelocity,
            options: presentAnimationOptions,
            animations: { [weak self] in
                self?.alpha = 1.0
                self?.window?.layoutIfNeeded()
        })
    }
}

// MARK: - Dismiss extension
/**
 Dismiss the snackbar
 */
extension ATSnackbar {

    /**
     Dismiss the snackbar
     */
    open func dismiss() {
        DispatchQueue.main.async {
            self.animateDismiss()
        }
    }
    
    private func animateDismiss() {
        // if timer is already stopped, return
        if timer == nil {
            return
        }
        
        var target = UIEdgeInsets.zero
        if #available(iOS 11.0, *) {
            target = self.superview?.safeAreaInsets ?? UIEdgeInsets.zero;
        }
        // stop the timer
        stopTimer()
        
        // Set animation position
        switch animationDirection {
        case .top:
            if animation == .fade {
                topMarginConstraint?.constant = topMargin
            } else {
                topMarginConstraint?.constant = -frame.size.height - target.top
            }
        case .bottom:
            if animation == .fade {
                bottomMarginConstraint?.constant = bottomMargin
            } else {
                bottomMarginConstraint?.constant = frame.size.height + target.bottom
            }
        }
        
        setNeedsLayout()
        
        // Animate
        UIView.animate(
            withDuration: animationDuration,
            delay: animationDelay,
            usingSpringWithDamping: animationDamping,
            initialSpringVelocity: animationSpringVelocity,
            options: dismissAnimationOptions,
            animations: { [weak self] in
                self?.alpha = 0.0
                self?.window?.layoutIfNeeded()
            }) { [weak self] _ in
                self?.isActive = false
                self?.removeFromSuperview()
            }
    }
}

// MARK: Action extension
/**
 Actions
 */
private extension ATSnackbar {
    @objc private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    @objc private func closeAction() {
        dismiss()
    }
    
    @objc private func swipeAction() {
        // TODO
    }
}
