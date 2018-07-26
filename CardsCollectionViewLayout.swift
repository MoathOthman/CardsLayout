//
//  CardsCollectionViewLayout.swift
//  CardsExample
//
//  Created by Filipp Fediakov on 18.08.17.
//  Copyright © 2017 filletofish. All rights reserved.
//

import UIKit

open class CardsCollectionViewLayout: UICollectionViewFlowLayout {
    
    // MARK: - Layout configuration
    
    public var cellSize: CGSize = CGSize(width: 280, height: 450) {
        didSet{
            invalidateLayout()
        }
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
    
    var lastCellPeekValue: CGFloat = 40
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
    
    override open func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let totalItemsCount = collectionView.numberOfItems(inSection: 0)
        
        let currentMinVisibleIndex = max(Int(collectionView.contentOffset.x) / Int(collectionView.bounds.width), 0)
        let minVisibleIndex = currentMinVisibleIndex == 0 ? currentMinVisibleIndex : currentMinVisibleIndex
        let maxVisibleIndex = min(minVisibleIndex + maximumVisibleItems, totalItemsCount)
        
        let contentCenterX = collectionView.contentOffset.x + (collectionView.bounds.width / 2.0)
        
        let deltaOffset = Int(collectionView.contentOffset.x) % Int(collectionView.bounds.width)
        
        let percentageDeltaOffset = CGFloat(deltaOffset) / collectionView.bounds.width
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
    
    override open func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    /// maintain a cache for all disappearing cells
    var movedOutCard: [Int: UICollectionViewLayoutAttributes?] = [:]
    var celllimit: CGFloat {
        return 315//collectionView.bounds.width - 35
    }

}


// MARK: - Layout computations

fileprivate extension CardsCollectionViewLayout {
    
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
        }
        
        if visibleIndex == 0 {
            rawScale -= delta
        }
        return CGAffineTransform(scaleX: rawScale, y: rawScale)
    }
    
    fileprivate func computeLayoutAttributesForItem(indexPath: IndexPath,
                                                    minVisibleIndex: Int,
                                                    contentCenterX: CGFloat,
                                                    deltaOffset: CGFloat,
                                                    percentageDeltaOffset: CGFloat) -> UICollectionViewLayoutAttributes {
        
        let attributes = UICollectionViewLayoutAttributes(forCellWith:indexPath)
        let visibleIndex = indexPath.row - minVisibleIndex
        attributes.size = itemSize
        let midY = self.collectionView.bounds.midY
        attributes.center = CGPoint(x: contentCenterX + spacingX * CGFloat(visibleIndex),
                                    y: midY + spacingY * CGFloat(visibleIndex))
        attributes.zIndex = maximumVisibleItems - visibleIndex
        
        attributes.transform = transform(atCurrentVisibleIndex: visibleIndex,
                                         percentageOffset: percentageDeltaOffset)
        switch visibleIndex {
        case 0:
            if deltaOffset >= celllimit {
                let translate = CGAffineTransform(translationX: -celllimit, y: 0)
                attributes.transform = attributes.transform.concatenating(translate)
                movedOutCard[indexPath.row] = attributes
                break
            }
            let translate = CGAffineTransform(translationX: -deltaOffset, y: 0)
            attributes.transform = attributes.transform.concatenating(translate)
        case 1..<maximumVisibleItems:
            attributes.center.x -= spacingX * percentageDeltaOffset
            attributes.center.y -= spacingY * percentageDeltaOffset
            
            if visibleIndex == maximumVisibleItems - 1 {
                attributes.alpha = percentageDeltaOffset
            }
        default:
            attributes.alpha = 0
        }
        
        return attributes
    }
}
