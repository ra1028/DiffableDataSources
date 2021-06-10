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

    /// Creates a new data source.
    ///
    /// - Parameters:
    ///   - collectionView: A collection view instance to be managed.
    ///   - cellProvider: A closure to dequeue the cell for items.
    public init(collectionView: UICollectionView, cellProvider: @escaping CellProvider) {
        self.collectionView = collectionView
        self.cellProvider = cellProvider
        super.init()

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
        return core.snapshot()
    }

    /// Returns an section identifier for given section index.
    ///
    /// - Parameters:
    ///   - section: An section index for the section identifier.
    ///
    /// - Returns: An section identifier for given section index.
    public func sectionIdentifier(for section: Int) -> SectionIdentifierType? {
        return core.sectionIdentifier(for: section)
    }

    /// Returns an item identifier for given index path.
    ///
    /// - Parameters:
    ///   - indexPath: An index path for the item identifier.
    ///
    /// - Returns: An item identifier for given index path.
    public func itemIdentifier(for indexPath: IndexPath) -> ItemIdentifierType? {
        return core.itemIdentifier(for: indexPath)
    }

    /// Returns an index path for given item identifier.
    ///
    /// - Parameters:
    ///   - itemIdentifier: An identifier of item.
    ///
    /// - Returns: An index path for given item identifier.
    public func indexPath(for itemIdentifier: ItemIdentifierType) -> IndexPath? {
        return core.indexPath(for: itemIdentifier)
    }

    /// Returns the number of sections in the data source.
    ///
    /// - Parameters:
    ///   - collectionView: A collection view instance managed by `self`.
    ///
    /// - Returns: The number of sections in the data source.
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
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
