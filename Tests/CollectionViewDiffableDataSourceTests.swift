#if os(iOS) || os(tvOS)

import XCTest
import UIKit
@testable import DiffableDataSources

final class CollectionViewDiffableDataSourceTests: XCTestCase {
    func testInit() {
        let collectionView = MockCollectionView()
        let dataSource = CollectionViewDiffableDataSource<Int, Int>(collectionView: collectionView) { _, _, _ in
            UICollectionViewCell()
        }

        XCTAssertTrue(collectionView.dataSource === dataSource)
    }

    func testApply() {
        let collectionView = MockCollectionView()
        let dataSource = CollectionViewDiffableDataSource<Int, Int>(collectionView: collectionView) { _, _, _ in
            UICollectionViewCell()
        }

        var snapshot = DiffableDataSourceSnapshot<Int, Int>()

        let e1 = expectation(description: "testApply() e1")
        dataSource.apply(snapshot, completion: e1.fulfill)
        wait(for: [e1], timeout: 1)
        XCTAssertEqual(collectionView.isPerformBatchUpdatesCalledCount, 0)

        snapshot.appendSections([0])
        snapshot.appendItems([0])

        let e2 = expectation(description: "testApply() e2")
        dataSource.apply(snapshot, completion: e2.fulfill)
        wait(for: [e2], timeout: 1)
        XCTAssertEqual(collectionView.isPerformBatchUpdatesCalledCount, 1)

        let e3 = expectation(description: "testApply() e3")
        dataSource.apply(snapshot, completion: e3.fulfill)
        wait(for: [e3], timeout: 1)
        XCTAssertEqual(collectionView.isPerformBatchUpdatesCalledCount, 1)

        snapshot.appendItems([1])

        let e4 = expectation(description: "testApply() e4")
        dataSource.apply(snapshot, completion: e4.fulfill)
        wait(for: [e4], timeout: 1)
        XCTAssertEqual(collectionView.isPerformBatchUpdatesCalledCount, 2)
    }

    func testSnapshot() {
        let collectionView = MockCollectionView()
        let dataSource = CollectionViewDiffableDataSource<Int, Int>(collectionView: collectionView) { _, _, _ in
            UICollectionViewCell()
        }

        let snapshot1 = dataSource.snapshot()
        XCTAssertEqual(snapshot1.sectionIdentifiers, [])
        XCTAssertEqual(snapshot1.itemIdentifiers, [])

        var snapshot2 = dataSource.snapshot()
        snapshot2.appendSections([0, 1, 2])

        let snapshot3 = dataSource.snapshot()
        XCTAssertEqual(snapshot3.sectionIdentifiers, [])
        XCTAssertEqual(snapshot3.itemIdentifiers, [])

        var snapshotToApply = DiffableDataSourceSnapshot<Int, Int>()
        snapshotToApply.appendSections([0, 1, 2])
        snapshotToApply.appendItems([0, 1, 2])
        dataSource.apply(snapshotToApply)

        let snapshot4 = dataSource.snapshot()
        XCTAssertEqual(snapshot4.sectionIdentifiers, [0, 1, 2])
        XCTAssertEqual(snapshot4.itemIdentifiers, [0, 1, 2])

        var snapshot5 = dataSource.snapshot()
        snapshot5.appendSections([3, 4, 5])

        var snapshot6 = dataSource.snapshot()
        XCTAssertEqual(snapshot6.sectionIdentifiers, [0, 1, 2])
        XCTAssertEqual(snapshot6.itemIdentifiers, [0, 1, 2])

        snapshot6.appendSections([3, 4, 5])
        snapshot6.appendItems([3, 4, 5])
        dataSource.apply(snapshot6)

        let snapshot7 = dataSource.snapshot()
        XCTAssertEqual(snapshot7.sectionIdentifiers, [0, 1, 2, 3, 4, 5])
        XCTAssertEqual(snapshot7.itemIdentifiers, [0, 1, 2, 3, 4, 5])
    }

    func testSectionIdentifier() {
        let collectionView = MockCollectionView()
        let dataSource = CollectionViewDiffableDataSource<Int, Int>(collectionView: collectionView) { _, _, _ in
            UICollectionViewCell()
        }

        var snapshot = DiffableDataSourceSnapshot<Int, Int>()
        snapshot.appendSections([10, 20, 30])
        dataSource.apply(snapshot)

        XCTAssertEqual(dataSource.sectionIdentifier(for: 1), 20)
        XCTAssertEqual(dataSource.sectionIdentifier(for: 100), nil)
    }

    func testItemIdentifier() {
        let collectionView = MockCollectionView()
        let dataSource = CollectionViewDiffableDataSource<Int, Int>(collectionView: collectionView) { _, _, _ in
            UICollectionViewCell()
        }

        var snapshot = DiffableDataSourceSnapshot<Int, Int>()
        snapshot.appendSections([0, 1, 2])
        snapshot.appendItems([0, 1, 2], toSection: 0)
        dataSource.apply(snapshot)

        XCTAssertEqual(dataSource.itemIdentifier(for: IndexPath(item: 1, section: 0)), 1)
        XCTAssertEqual(dataSource.itemIdentifier(for: IndexPath(item: 100, section: 100)), nil)
    }

    func testIndexPath() {
        let collectionView = MockCollectionView()
        let dataSource = CollectionViewDiffableDataSource<Int, Int>(collectionView: collectionView) { _, _, _ in
            UICollectionViewCell()
        }

        var snapshot = DiffableDataSourceSnapshot<Int, Int>()
        snapshot.appendSections([0, 1, 2])
        snapshot.appendItems([0, 1, 2], toSection: 0)
        dataSource.apply(snapshot)

        XCTAssertEqual(dataSource.indexPath(for: 2), IndexPath(item: 2, section: 0))
        XCTAssertEqual(dataSource.indexPath(for: 100), nil)
    }

    func testNumberOfSections() {
        let collectionView = MockCollectionView()
        let dataSource = CollectionViewDiffableDataSource<Int, Int>(collectionView: collectionView) { _, _, _ in
            UICollectionViewCell()
        }

        XCTAssertEqual(dataSource.numberOfSections(in: collectionView), 0)

        var snapshot = DiffableDataSourceSnapshot<Int, Int>()
        snapshot.appendSections([0, 1, 2])
        snapshot.appendItems([0, 1, 2], toSection: 0)
        dataSource.apply(snapshot)

        XCTAssertEqual(dataSource.numberOfSections(in: collectionView), 3)
    }

    func testNumberOfRowsInSection() {
        let collectionView = MockCollectionView()
        let dataSource = CollectionViewDiffableDataSource<Int, Int>(collectionView: collectionView) { _, _, _ in
            UICollectionViewCell()
        }

        var snapshot = DiffableDataSourceSnapshot<Int, Int>()
        snapshot.appendSections([0, 1, 2])
        snapshot.appendItems([0, 1, 2], toSection: 0)
        dataSource.apply(snapshot)

        XCTAssertEqual(dataSource.collectionView(collectionView, numberOfItemsInSection: 0), 3)
    }

    func testCellForRowAt() {
        let collectionView = MockCollectionView()
        let cell = UICollectionViewCell()
        let dataSource = CollectionViewDiffableDataSource<Int, Int>(collectionView: collectionView) { _, _, _ in
            cell
        }

        var snapshot = DiffableDataSourceSnapshot<Int, Int>()
        snapshot.appendSections([0, 1, 2])
        snapshot.appendItems([0, 1, 2], toSection: 0)
        dataSource.apply(snapshot)

        XCTAssertEqual(
            dataSource.collectionView(collectionView, cellForItemAt: IndexPath(item: 1, section: 0)),
            cell
        )
    }

    func testCanMoveRowAt() {
        let collectionView = MockCollectionView()
        let cell = UICollectionViewCell()
        let dataSource = CollectionViewDiffableDataSource<Int, Int>(collectionView: collectionView) { _, _, _ in
            cell
        }

        var snapshot = DiffableDataSourceSnapshot<Int, Int>()
        snapshot.appendSections([0, 1, 2])
        snapshot.appendItems([0, 1, 2], toSection: 0)
        dataSource.apply(snapshot)

        XCTAssertEqual(
            dataSource.collectionView(collectionView, canMoveItemAt: IndexPath(item: 1, section: 0)),
            false
        )
    }
}

final class MockCollectionView: UICollectionView {
    var isPerformBatchUpdatesCalledCount = 0

    init() {
        super.init(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())

        let window = UIWindow()
        window.addSubview(self)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func performBatchUpdates(_ updates: (() -> Void)?, completion: ((Bool) -> Void)? = nil) {
        isPerformBatchUpdatesCalledCount += 1
        updates?()
        completion?(true)
    }

    override func insertSections(_ sections: IndexSet) {}
    override func insertItems(at indexPaths: [IndexPath]) {}
}

#endif
