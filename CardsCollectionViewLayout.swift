//
//  CardsCollectionViewLayout.swift
//  CardsExample
//
//  Created by Filipp Fediakov on 18.08.17.
//  Copyright © 2017 filletofish. All rights reserved.
//

import UIKit

open class CardsCollectionViewLayout: UICollectionViewFlowLayout {
    
    /// maintain a cache for all disappearing cells
    var movedOutCard: [Int: UICollectionViewLayoutAttributes?] = [:]
    
    public var cellHeight: CGFloat = 400 {
        didSet {
            invalidateLayout()
        }
    }
    
    private var cellSize: CGSize {
        let marging: CGFloat = 40
        return CGSize(width: (self.collectionView.bounds.width - marging) / maximamScale, height: cellHeight)
    }
    
    public var spacingX: CGFloat = 20.0 {
        didSet{
            invalidateLayout()
        }
    }
    
    public var spacingY: CGFloat = 5.0 {
        didSet{
            invalidateLayout()
        }
    }
    
    public var maximumVisibleItems: Int = 4 {
        didSet{
            invalidateLayout()
        }
    }
    
    var lastCellPeekValue: CGFloat = -5
    // MARK: UICollectionViewLayout
    
    override open var collectionView: UICollectionView {
        return super.collectionView!
    }
    
    override open var collectionViewContentSize: CGSize {
        let itemsCount = CGFloat(collectionView.numberOfItems(inSection: 0))
        return CGSize(width: collectionView.bounds.width * itemsCount,
                      height: collectionView.bounds.height)
    }
    
    override open func prepare() {
        super.prepare()
        itemSize = self.cellSize
        assert(collectionView.numberOfSections == 1, "Multiple sections aren't supported!")
        
    }
    private var maxVisibleIndex: Int = 0
    override open func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let totalItemsCount = collectionView.numberOfItems(inSection: 0)
        
        let minVisibleIndex = max(Int(collectionView.contentOffset.x) / Int(collectionView.bounds.width), 0)
        maxVisibleIndex = min(minVisibleIndex + maximumVisibleItems, totalItemsCount)
        
        let contentCenterX = collectionView.contentOffset.x + (collectionView.bounds.width / 2.0)
        
        var deltaOffset = Int(collectionView.contentOffset.x) % Int(collectionView.bounds.width)
        
        var percentageDeltaOffset = CGFloat(deltaOffset) / collectionView.bounds.width
        if percentageDeltaOffset < 0 {
            percentageDeltaOffset *= 0.08
            deltaOffset = Int(percentageDeltaOffset * collectionView.bounds.width)
            
        }
        print(percentageDeltaOffset)
        let visibleIndices = minVisibleIndex..<maxVisibleIndex
        
        var attributes: [UICollectionViewLayoutAttributes] = visibleIndices.map { index in
            let indexPath = IndexPath(item: index, section: 0)
            return computeLayoutAttributesForItem(indexPath: indexPath,
                                                  minVisibleIndex: minVisibleIndex,
                                                  contentCenterX: contentCenterX,
                                                  deltaOffset: CGFloat(deltaOffset),
                                                  percentageDeltaOffset: percentageDeltaOffset)
        }
        
        if minVisibleIndex > 0 ,
            let movedAttribute = movedOutCard[minVisibleIndex - 1],
            let moved = movedAttribute {
            attributes.append(moved)
        }
        
        return attributes
    }
    
    open override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        print("propoed", proposedContentOffset)
        return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
    }
    
    override open func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}


// MARK: - Layout computations

extension CardsCollectionViewLayout {
    
    var maximamScale: CGFloat {
        return 1.1
    }
    
    var minimumScaleForTheLeftCard: CGFloat {
        return 1.09
    }
    
    var stoppingLine: CGFloat {
        return collectionView.bounds.width / maximamScale - lastCellPeekValue
    }
    
    private func scale(at index: Int) -> CGFloat {
        let translatedCoefficient = CGFloat(index) - CGFloat(self.maximumVisibleItems) / 2.0
        return CGFloat(pow(0.95, translatedCoefficient))
    }
    
    private func transform(atCurrentVisibleIndex visibleIndex: Int, percentageOffset: CGFloat) -> CGAffineTransform {
        var rawScale = visibleIndex < maximumVisibleItems ? scale(at: visibleIndex) : 1.0
        let previousScale = scale(at: visibleIndex - 1)
        let delta = (previousScale - rawScale) * percentageOffset
        if visibleIndex != 0 {
            rawScale += delta
        } else {
            rawScale -= delta
            if rawScale < minimumScaleForTheLeftCard {
                rawScale = minimumScaleForTheLeftCard
            }
        }
        return CGAffineTransform(scaleX: rawScale, y: rawScale)
    }
    
    
    fileprivate func computeLayoutAttributesForItem(indexPath: IndexPath,
                                                    minVisibleIndex: Int,
                                                    contentCenterX: CGFloat,
                                                    deltaOffset: CGFloat,
                                                    percentageDeltaOffset: CGFloat) -> UICollectionViewLayoutAttributes {
        
        
        let attributes = UICollectionViewLayoutAttributes(forCellWith:indexPath)
        var visibleIndex = indexPath.row - minVisibleIndex
        func proposedvisibleIndex() -> Int {
            return visibleIndex == maximumVisibleItems - 1 ? visibleIndex - 1 : visibleIndex
        }
      
        attributes.size = itemSize
        let midY = self.collectionView.bounds.midY
        attributes.center = CGPoint(x: contentCenterX + spacingX * CGFloat(proposedvisibleIndex()),
                                    y: midY + spacingY * CGFloat(proposedvisibleIndex()))
        attributes.zIndex = maximumVisibleItems - visibleIndex
        if visibleIndex != maximumVisibleItems - 1 {
            
            attributes.transform = transform(atCurrentVisibleIndex: visibleIndex,
                                             percentageOffset: percentageDeltaOffset)
        }
        switch visibleIndex {
        case 0:
            if deltaOffset >= stoppingLine {
                let translate = CGAffineTransform(translationX: -stoppingLine, y: 0)
                attributes.transform = attributes.transform.concatenating(translate)
                movedOutCard[indexPath.row] = attributes
                break
            }
            let translate = CGAffineTransform(translationX: -deltaOffset, y: 0)
            attributes.transform = attributes.transform.concatenating(translate)
            
        case 1..<maximumVisibleItems:
            if visibleIndex != maximumVisibleItems - 1 {
                attributes.center.x -= spacingX * percentageDeltaOffset
                attributes.center.y -= spacingY * percentageDeltaOffset
            }
        default:
            attributes.alpha = 0
        }
        return attributes
    }
}
