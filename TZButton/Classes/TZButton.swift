//
//  TZButton.swift
//  wanbiao
//
//  Created by Leery TT on 2025/12/11.
//

import UIKit



// MARK: - 枚举定义（抽离到顶部，语义优化）
/// 图片位置枚举
public enum ImagePosition: CaseIterable {
    /// 仅文字（隐藏图片）
    case onlyText
    /// 仅图片
    case onlyImage
    /// 图片在左
    case left
    /// 图片在右
    case right
    /// 图片在上
    case top
    /// 图片在下
    case bottom
}

/// 按钮状态枚举
public enum ButtonState {
    /// 普通状态
    case normal
    /// 选中状态
    case selected
}

// MARK: - 常量定义（消除魔法值）
private extension CGFloat {
    /// 默认图片尺寸
    static let defaultImageSize: CGFloat = 24
    /// 默认图文间距
    static let defaultSpacing: CGFloat = 5
    /// 默认内边距
    static let defaultInset: CGFloat = 4
}

// MARK: - 自定义按钮核心类
public class TZButton: UIControl {
    // MARK: - 常量属性（不可变）
    /// 回调闭包：点击事件（参数：按钮实例、当前选中状态）
    public var clicked: ((TZButton, Bool) -> Void)?
    
    // MARK: - 可配置UI属性（统一默认值，语义清晰）
    /// 普通状态图片
    private var normalImage: UIImage? {
        didSet { updateButtonUI() }
    }
    /// 选中状态图片（默认复用普通图片）
    private var selectedImage: UIImage? {
        didSet { updateButtonUI() }
    }
    /// 普通状态文字
    private var normalTitle: String? {
        didSet { updateButtonUI() }
    }
    /// 选中状态文字（默认复用普通文字）
    private var selectedTitle: String? {
        didSet { updateButtonUI() }
    }
    /// 普通状态文字颜色
    private var normalTitleColor: UIColor = .black {
        didSet { updateButtonUI() }
    }
    /// 选中状态文字颜色（默认复用普通颜色）
    private var selectedTitleColor: UIColor? {
        didSet { updateButtonUI() }
    }
    /// 文字字体
    private var font: UIFont = .systemFont(ofSize: 14) {
        didSet {
            titleLabel.font = font
            updateButtonLayout()
        }
    }
    /// 图片位置（默认仅文字）
    private var imagePosition: ImagePosition = .onlyText {
        didSet { updateButtonLayout() }
    }
    /// 图文间距（默认5pt）
    private var spacing: CGFloat = .defaultSpacing {
        didSet { updateButtonLayout() }
    }
    /// 内边距（默认4pt）
    private var insets: UIEdgeInsets = UIEdgeInsets(
        top: .defaultInset,
        left: .defaultInset,
        bottom: .defaultInset,
        right: .defaultInset
    ) {
        didSet { updateButtonLayout() }
    }
    /// 图片尺寸（默认24x24）
    private var imageSize: CGSize = CGSize(width: .defaultImageSize, height: .defaultImageSize) {
        didSet { updateButtonLayout() }
    }
    /// 普通状态背景色
    private var normalBgColor: UIColor? {
        didSet { updateButtonUI() }
    }
    /// 选中状态背景色（默认复用普通背景色）
    private var selectedBgColor: UIColor? {
        didSet { updateButtonUI() }
    }
    
    // MARK: - 状态属性（重写选中状态，完善逻辑）
    public override var isSelected: Bool {
        didSet {
            guard isSelected != oldValue else { return }
            updateButtonUI()
        }
    }
    
    // MARK: - 私有子视图（统一配置）
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit // 优化图片显示（替代center）
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - 布局相关（防递归+约束集合）
    /// 防递归标记：避免updateConstraints无限调用
    private var isUpdatingConstraints: Bool = false
    /// 图片约束集合
    private var imageConstraints: [NSLayoutConstraint] = []
    /// 文字约束集合
    private var titleConstraints: [NSLayoutConstraint] = []
    
    // MARK: - 初始化（完善所有初始化方法）
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupBaseUI()
        setupEvent()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupBaseUI()
        setupEvent()
    }
    
    /// 便利初始化：指定图片位置
    /// - Parameter position: 图片位置
    public convenience init(imagePosition: ImagePosition) {
        self.init(frame: .zero)
        self.imagePosition = imagePosition
    }
    
    // MARK: - 布局更新（核心：防递归+统一约束）
    public override func updateConstraints() {
        guard !isUpdatingConstraints else {
            super.updateConstraints()
            return
        }
        
        isUpdatingConstraints = true
        defer { isUpdatingConstraints = false } // 方法结束必重置
        
        super.updateConstraints()
        
        // 移除旧约束
        NSLayoutConstraint.deactivate(imageConstraints + titleConstraints)
        imageConstraints.removeAll()
        titleConstraints.removeAll()
        
        // 根据图片位置配置约束
        configureConstraints(for: imagePosition)
        
        // 激活新约束
        NSLayoutConstraint.activate(imageConstraints + titleConstraints)
    }
    
    // MARK: - 触摸反馈（优化体验）
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        UIView.animate(withDuration: 0.1) {
            self.alpha = 0.8
        }
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        UIView.animate(withDuration: 0.1) {
            self.alpha = 1.0
        }
        // 仅点击按钮内部时触发事件
//        guard let touch = touches.first, bounds.contains(touch.location(in: self)) else { return }
//        sendActions(for: .touchUpInside)
    }
    
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        UIView.animate(withDuration: 0.1) {
            self.alpha = 1.0
        }
    }
    
    public override var intrinsicContentSize: CGSize {
        let imageSize = imageView.isHidden ? .zero : self.imageSize
        let titleSize = titleLabel.intrinsicContentSize
        
        switch imagePosition {
        case .onlyText:
            return CGSize(
                width: titleSize.width + insets.left + insets.right,
                height: titleSize.height + insets.top + insets.bottom
            )
        case .onlyImage:
            return CGSize(
                width: imageSize.width + insets.left + insets.right,
                height: imageSize.height + insets.top + insets.bottom
            )
        case .left, .right:
            let totalWidth = imageSize.width + titleSize.width + spacing + insets.left + insets.right
            let totalHeight = max(imageSize.height, titleSize.height) + insets.top + insets.bottom
            return CGSize(width: totalWidth, height: totalHeight)
        case .top, .bottom:
            let totalWidth = max(imageSize.width, titleSize.width) + insets.left + insets.right
            let totalHeight = imageSize.height + titleSize.height + spacing + insets.top + insets.bottom
            return CGSize(width: totalWidth, height: totalHeight)
        }
    }
}

// MARK: - 公开方法（状态设置）
public extension TZButton {
    /// 设置图片
    /// - Parameters:
    ///   - image: 图片
    ///   - state: 按钮状态
    func setImage(_ image: UIImage?, for state: ButtonState) {
        switch state {
        case .normal: normalImage = image
        case .selected: selectedImage = image
        }
    }
    
    /// 设置标题
    /// - Parameters:
    ///   - title: 标题文字
    ///   - state: 按钮状态
    func setTitle(_ title: String?, for state: ButtonState) {
        switch state {
        case .normal: normalTitle = title
        case .selected: selectedTitle = title
        }
    }
    
    /// 设置标题颜色
    /// - Parameters:
    ///   - color: 文字颜色
    ///   - state: 按钮状态
    func setTitleColor(_ color: UIColor, for state: ButtonState) {
        switch state {
        case .normal: normalTitleColor = color
        case .selected: selectedTitleColor = color
        }
    }
    
    /// 设置背景颜色
    /// - Parameters:
    ///   - color: 背景颜色
    ///   - state: 按钮状态
    func setBackgroundColor(_ color: UIColor?, for state: ButtonState) {
        switch state {
        case .normal: normalBgColor = color
        case .selected: selectedBgColor = color
        }
    }
    /// 设置图片尺寸
    /// - Parameter size: 尺寸大小
    func setImageSize(_ size:CGSize) {
        self.imageSize = size
    }
    /// 设置内边距
    /// - Parameter inset: 内边距值
    func setInsets(_ inset:UIEdgeInsets) {
        self.insets = inset
    }
    /// 设置字体
    /// - Parameter font: 字体
    func setFont(_ font:UIFont) {
        self.font = font
    }
}

// MARK: - 私有方法（UI配置/布局/事件）
private extension TZButton {
    /// 基础UI配置
    func setupBaseUI() {
        isUserInteractionEnabled = true
        
        // 添加子视图
        addSubview(imageView)
        addSubview(titleLabel)
        
        // 设置布局优先级（避免约束冲突）
        imageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        imageView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    
    /// 绑定点击事件
    func setupEvent() {
        addTarget(self, action: #selector(clickHandler), for: .touchUpInside)
    }
    
    /// 点击事件处理
    @objc func clickHandler() {
        clicked?(self, isSelected)
    }
    
    /// 更新按钮UI（状态切换时调用）
    func updateButtonUI() {
        // 根据选中状态设置UI
        if isSelected {
            titleLabel.text = selectedTitle ?? normalTitle
            titleLabel.textColor = selectedTitleColor ?? normalTitleColor
            imageView.image = selectedImage ?? normalImage
            super.backgroundColor = selectedBgColor ?? normalBgColor
        } else {
            titleLabel.text = normalTitle
            titleLabel.textColor = normalTitleColor
            imageView.image = normalImage
            super.backgroundColor = normalBgColor
        }
        // 刷新布局
        updateButtonLayout()
    }
    
    /// 触发布局更新（统一入口）
    func updateButtonLayout() {
        guard !isUpdatingConstraints else { return }
        setNeedsUpdateConstraints()
        layoutIfNeeded()
    }
    
    /// 根据图片位置配置约束
    /// - Parameter position: 图片位置
    func configureConstraints(for position: ImagePosition) {
        // 控制图片显示/隐藏
        imageView.isHidden = position == .onlyText
        
        switch position {
        case .onlyText: configureOnlyTextConstraints()
        case .onlyImage: configureOnlyImageConstraints()
        case .left: configureImageLeftConstraints()
        case .right: configureImageRightConstraints()
        case .top: configureImageTopConstraints()
        case .bottom: configureImageBottomConstraints()
        }
    }
    
    // MARK: - 约束配置（分方向）
    /// 仅图片约束
    func configureOnlyImageConstraints(){
        imageConstraints = [
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.right),
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom),
            imageView.widthAnchor.constraint(equalToConstant: imageSize.width),
            imageView.heightAnchor.constraint(equalToConstant: imageSize.height)
        ]
    }
    /// 仅文字约束
    func configureOnlyTextConstraints() {
        titleConstraints = [
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.right),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom)
        ]
    }
    
    /// 图片在左约束
    func configureImageLeftConstraints() {
        imageConstraints = [
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left),
            imageView.widthAnchor.constraint(equalToConstant: imageSize.width),
            imageView.heightAnchor.constraint(equalToConstant: imageSize.height)
        ]
        
        titleConstraints = [
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: spacing),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.right)
        ]
    }
    
    /// 图片在右约束
    func configureImageRightConstraints() {
        imageConstraints = [
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.right),
            imageView.widthAnchor.constraint(equalToConstant: imageSize.width),
            imageView.heightAnchor.constraint(equalToConstant: imageSize.height)
        ]
        
        titleConstraints = [
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: -spacing),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left)
        ]
    }
    
    /// 图片在上约束（优化逻辑，减少重复）
    func configureImageTopConstraints() {
        // 计算文字宽度
        let currentTitle = isSelected ? (selectedTitle ?? normalTitle) : normalTitle
        let titleWidth = currentTitle?.width(withFont: font) ?? 0
        
        // 图片约束（统一基础约束）
        imageConstraints = [
            imageView.widthAnchor.constraint(equalToConstant: imageSize.width),
            imageView.heightAnchor.constraint(equalToConstant: imageSize.height),
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
            imageView.bottomAnchor.constraint(equalTo: titleLabel.topAnchor, constant: -spacing)
        ]
        
        // 文字宽度 > 图片宽度 → 文字撑满左右，图片居中；反之 → 图片撑满左右，文字居中
        if titleWidth > imageSize.width {
            imageConstraints.append(imageView.centerXAnchor.constraint(equalTo: centerXAnchor))
            titleConstraints = [
                titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left),
                titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.right),
                titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom)
            ]
        } else {
            imageConstraints.append(contentsOf: [
                imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left),
                imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.right)
            ])
            titleConstraints = [
                titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
                titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom)
            ]
        }
    }
    
    /// 图片在下约束（补全insets和imageSize）
    func configureImageBottomConstraints() {
        imageConstraints = [
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom),
            imageView.widthAnchor.constraint(equalToConstant: imageSize.width),
            imageView.heightAnchor.constraint(equalToConstant: imageSize.height)
        ]
        
        titleConstraints = [
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
            titleLabel.bottomAnchor.constraint(equalTo: imageView.topAnchor, constant: -spacing)
        ]
    }
}

extension String {
    /// 获取字符串长度
    /// - Parameter font: 字体
    /// - Returns: width
    func width(withFont font: UIFont) -> CGFloat {
        let attributes = [NSAttributedString.Key.font: font]
        let size = (self as NSString).size(withAttributes: attributes)
        return ceil(size.width)
    }
}
