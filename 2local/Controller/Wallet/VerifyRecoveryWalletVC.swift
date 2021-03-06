//
//  VerifyRecoveryWalletVC.swift
//  2local
//
//  Created by Ebrahim Hosseini on 4/9/21.
//  Copyright © 2021 2local Inc. All rights reserved.
//

import UIKit
import KVNProgress

class VerifyRecoveryWalletVC: BaseVC {

  // MARK: - Outlets
  @IBOutlet weak var continueButton: UIButton!
  @IBOutlet weak var mnemonicLabel: UILabel!
  @IBOutlet weak var dividerView: UIView!
  @IBOutlet weak var collectionView: UICollectionView!
  @IBOutlet weak var errorLabel: UILabel!
  @IBOutlet weak var clearButton: UIButton!

  // MARK: - Properties
  private var walletName: Coins?
  private var items: [String] = []
  private var itemCount = 0
  private let removeCount = 4
  private var startRandomItem = 0
  private var firstSectionItems: [String] = []
  private var secondSectionItems: [String] = []
  private var mnemonics: String?

  func initWith(walletName: Coins, items: [String], mnemonics: String) {
    self.walletName = walletName
    self.items = items
    self.mnemonics = mnemonics

    itemCount = items.count
    startRandomItem = itemCount - removeCount
    self.firstSectionItems = items.dropLast(removeCount)
    self.secondSectionItems = items[startRandomItem..<itemCount].shuffled()
  }

  // MARK: - View cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    setupView()
    setupCollection()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }

  // MARK: - Functions
  fileprivate func setupView() {
    if let walletName = walletName?.rawValue {
      setNavigation(title: "Create \(walletName) wallet")
    }
    continueButton.setCornerRadius(8)

    setupMnemonics()

    dividerView.backgroundColor = .e0e0eb

    errorLabel.isHidden = true
  }

  fileprivate func setupMnemonics() {
    var mnemonic = ""
    for index in 0..<(firstSectionItems.count) {
      mnemonic += firstSectionItems[index] + "   "
    }
    mnemonicLabel.text = mnemonic
    checkMnemonics()
  }

  fileprivate func checkMnemonics() {
    DispatchQueue.main.async {
      if self.secondSectionItems.count == 0 {
        self.collectionView.isHidden = true
        if self.firstSectionItems.elementsEqual(self.items) {
          self.continueButton.backgroundColor = .EF8749
          self.continueButton.isEnabled = true
        } else {
          self.errorLabel.isHidden = false
          self.clearButton.isHidden = false
        }
      } else {
        self.collectionView.isHidden = false

        self.errorLabel.isHidden = true

        self.clearButton.isHidden = true

        self.continueButton.backgroundColor = UIColor.EF8749.withAlphaComponent(0.5)
        self.continueButton.isEnabled = false
      }
    }
  }

  fileprivate func saveWallet() {
    guard let mnemonics = self.mnemonics else { return }
    userDefaults.setValue(mnemonics, forKey: UserDefaultsKey.ETHWallet.rawValue)

    let ethWallet = Wallets(name: .ethereum,
                            balance: "0",
                            address: Web3Service.currentAddress ?? "",
                            mnemonic: mnemonics,
                            displayName: Coins.ethereum.rawValue)

    DataProvider.shared.wallets.append(ethWallet)
    NotificationCenter.default.post(name: Notification.Name.wallet, object: nil)
    userDefaults.setValue(Coins.ethereum.rawValue, forKey: Coins.ethereum.rawValue)

    let vc = UIStoryboard.wallet.instantiate(viewController: SuccessfulCreateWalletVC.self)
    if let navigation = self.navigationController {
      navigation.pushViewController(vc, animated: true)
    }
    continueButton.isEnabled = true
  }

  // MARK: - Actions
  @IBAction func continueTapped(_ sender: UIButton) {
    continueButton.isEnabled = false
    self.saveWallet()
  }

  @IBAction func clearTapped(_ sender: UIButton) {
    self.secondSectionItems = items[startRandomItem..<itemCount].shuffled()
    self.firstSectionItems = items.dropLast(removeCount)

    collectionView.reloadData()
    setupMnemonics()
  }
}

// MARK: - collection view
extension VerifyRecoveryWalletVC: UICollectionViewDelegate, UICollectionViewDataSource {
  fileprivate func setupCollection() {

    collectionView.register(SeedPhraseCollectionViewCell.self)

    collectionView.isScrollEnabled = false
    collectionView.dataSource = self
    collectionView.delegate = self
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return secondSectionItems.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeue(SeedPhraseCollectionViewCell.self, indexPath: indexPath)
    cell.fill(secondSectionItems[indexPath.row])
    return cell
  }

  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    firstSectionItems.append(secondSectionItems[indexPath.row])
    secondSectionItems.remove(at: indexPath.row)
    collectionView.reloadData()
    setupMnemonics()

  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
  }

}

extension VerifyRecoveryWalletVC: UICollectionViewDelegateFlowLayout {

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

    let label = UILabel()
    label.font = .TLFont(weight: .regular, size: 16, style: .body)
    label.text = firstSectionItems[indexPath.row]
    let cell = SeedPhraseCollectionViewCell.fromNib()
    cell.layoutIfNeeded()

    var size = cell.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    size.height = 0
    size.width = label.intrinsicContentSize.width + 0

    return size
  }

}
