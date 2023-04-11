#if os(iOS) || os(tvOS)

import UIKit
import DifferenceKit

/// A class for backporting `UICollectionViewDiffableDataSource` introduced in iOS 13.0+, tvOS 13.0+.
/// Represents the data model object for `UICollectionView` that can be applies the
/// changes with automatic diffing.
open class CollectionViewDiffableDataSource<SectionIdentifierType: Hashable, ItemIdentifierType: Hashable>: NSObject, UICollectionViewDataSource {
    /// The type of closure providing the cell.
    public typealias CellProvider = (UICollectionView, IndexPath, ItemIdentifierType) -> UICollectionViewCell?

    /// The type of closure providing the supplementary view for element of kind.
    public typealias SupplementaryViewProvider = (UICollectionView, String, IndexPath) -> UICollectionReusableView?

    /// A closure to dequeue the views for element of kind.
    public var supplementaryViewProvider: SupplementaryViewProvider?

    private weak var collectionView: UICollectionView?
    private let cellProvider: CellProvider
    private let core = DiffableDataSourceCore<SectionIdentifierType, ItemIdentifierType>()
    private let forceFallback: Bool
    private var _nativeDataSource: Any?
    @available(iOS 13.0, *)
    private var nativeDataSource: UICollectionViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType> {
        get {
            guard let nativeDataSource = _nativeDataSource as? UICollectionViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType> else {
                fatalError()
            }
            return nativeDataSource
        }
        set {
            _nativeDataSource = newValue
        }
    }

    @available(iOS 13.0, *)
    private func createNativeDataSource(for collectionView: UICollectionView, cellProvider: @escaping CellProvider) {
        _nativeDataSource = UICollectionViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType>(collectionView: collectionView, cellProvider: cellProvider)
    }

    /// Creates a new data source.
    ///
    /// - Parameters:
    ///   - collectionView: A collection view instance to be managed.
    ///   - cellProvider: A closure to dequeue the cell for items.
    public convenience init(collectionView: UICollectionView, cellProvider: @escaping CellProvider) {
        self.init(collectionView: collectionView, forceFallback: false, cellProvider: cellProvider)
    }

    internal init(collectionView: UICollectionView, forceFallback: Bool, cellProvider: @escaping CellProvider) {
        self.collectionView = collectionView
        self.cellProvider = cellProvider
        self.forceFallback = forceFallback
        super.init()

        if #available(iOS 13, *), !forceFallback {
            createNativeDataSource(for: collectionView, cellProvider: cellProvider)
            return
        }
        collectionView.dataSource = self
    }

    /// Applies given snapshot to perform automatic diffing update.
    ///
    /// - Parameters:
    ///   - snapshot: A snapshot object to be applied to data model.
    ///   - animatingDifferences: A Boolean value indicating whether to update with
    ///                           diffing animation.
    ///   - completion: An optional completion block which is called when the complete
    ///                 performing updates.
    public func apply(_ snapshot: DiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>, animatingDifferences: Bool = true, completion: (() -> Void)? = nil) {
        if #available(iOS 13, *), !forceFallback {
            nativeDataSource.apply(snapshot.nativeSnapshot, animatingDifferences: animatingDifferences, completion: completion)
            return
        }
        core.apply(
            snapshot,
            view: collectionView,
            animatingDifferences: animatingDifferences,
            performUpdates: { collectionView, changeset, setSections in
                collectionView.reload(using: changeset, setData: setSections)
            },
            completion: completion
        )
    }

    /// Returns a new snapshot object of current state.
    ///
    /// - Returns: A new snapshot object of current state.
    public func snapshot() -> DiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType> {
        if #available(iOS 13, *), !forceFallback {
            return .from(nativeSnapshot: nativeDataSource.snapshot())
        }
        return core.snapshot(forceFallback: forceFallback)
    }

    /// Returns an item identifier for given index path.
    ///
    /// - Parameters:
    ///   - indexPath: An index path for the item identifier.
    ///
    /// - Returns: An item identifier for given index path.
    public func itemIdentifier(for indexPath: IndexPath) -> ItemIdentifierType? {
        if #available(iOS 13, *), !forceFallback {
            return nativeDataSource.itemIdentifier(for: indexPath)
        }
        return core.itemIdentifier(for: indexPath)
    }

    /// Returns an index path for given item identifier.
    ///
    /// - Parameters:
    ///   - itemIdentifier: An identifier of item.
    ///
    /// - Returns: An index path for given item identifier.
    public func indexPath(for itemIdentifier: ItemIdentifierType) -> IndexPath? {
        if #available(iOS 13, *), !forceFallback {
            return nativeDataSource.indexPath(for: itemIdentifier)
        }
        return core.indexPath(for: itemIdentifier)
    }

    /// Returns the number of sections in the data source.
    ///
    /// - Parameters:
    ///   - collectionView: A collection view instance managed by `self`.
    ///
    /// - Returns: The number of sections in the data source.
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        if #available(iOS 13, *), !forceFallback {
            return nativeDataSource.numberOfSections(in: collectionView)
        }
        return core.numberOfSections()
    }

    /// Returns the number of items in the specified section.
    ///
    /// - Parameters:
    ///   - collectionView: A collection view instance managed by `self`.
    ///   - section: An index of section.
    ///
    /// - Returns: The number of items in the specified section.
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if #available(iOS 13, *), !forceFallback {
            return nativeDataSource.collectionView(collectionView, numberOfItemsInSection: section)
        }
        return core.numberOfItems(inSection: section)
    }

    /// Returns a cell for item at specified index path.
    ///
    /// - Parameters:
    ///   - collectionView: A collection view instance managed by `self`.
    ///   - indexPath: An index path for cell.
    ///
    /// - Returns: A cell for row at specified index path.
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if #available(iOS 13, *), !forceFallback {
            return nativeDataSource.collectionView(collectionView, cellForItemAt: indexPath)
        }
        let itemIdentifier = core.unsafeItemIdentifier(for: indexPath)
        guard let cell = cellProvider(collectionView, indexPath, itemIdentifier) else {
            universalError("UICollectionView dataSource returned a nil cell for item at index path: \(indexPath), collectionView: \(collectionView), itemIdentifier: \(itemIdentifier)")
        }

        return cell
    }

    /// Returns a supplementary view for element of kind at specified index path.
    ///
    /// - Parameters:
    ///   - collectionView: A collection view instance managed by `self`.
    ///   - kind: The kind of element to be display.
    ///   - indexPath: An index path for supplementary view.
    ///
    /// - Returns: A supplementary view for element of kind at specified index path.
    open func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if #available(iOS 13, *), !forceFallback {
            return nativeDataSource.collectionView(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath)
        }
        guard let view = supplementaryViewProvider?(collectionView, kind, indexPath) else {
            return UICollectionReusableView()
        }

        return view
    }

    /// Returns whether it is possible to edit a row at given index path.
    ///
    /// - Parameters:
    ///   - collectionView: A collection view instance managed by `self`.
    ///   - section: An index of section.
    ///
    /// - Returns: A boolean for row at specified index path.
    open func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    /// Moves a row at given index path.
    ///
    /// - Parameters:
    ///   - collectionView: A collection view instance managed by `self`.
    ///   - sourceIndexPath: An index path for given cell position.
    ///   - destinationIndexPath: An index path for target cell position.
    ///
    /// - Returns: Void.
    public func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        // Empty implementation.
    }
}

#endif
