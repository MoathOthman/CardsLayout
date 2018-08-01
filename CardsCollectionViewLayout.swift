//
//  CardsCollectionViewLayout.swift
//  CardsExample
//
//  Created by Filipp Fediakov on 18.08.17.
//  Copyright © 2017 filletofish. All rights reserved.
//

import UIKit

struct MovedOutCard {
    let contentOffsetWhenMoved: CGPoint
    let attribute: UICollectionViewLayoutAttributes?
}

open class CardsCollectionViewLayout: UICollectionViewFlowLayout {
    
    /// maintain a cache for all disappearing cells
    var movedOutCard: [Int: MovedOutCard] = [:]
    
    public var cellHeight: CGFloat = 400 {
        didSet {
            invalidateLayout()
        }
    }
    
    fileprivate var cellSize: CGSize {
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
    
    var maximamScale: CGFloat {
        return 1.10803324099723
    }
    
    var minimumScaleForTheLeftCard: CGFloat {
        return 1.09
    }
    
    // the offset from left
    var stoppingLine: CGFloat {
        return 33
    }
    
    private var maxVisibleIndex: Int = 0
    private var offsetWhenOneCardISHidden: CGFloat = 0

}


// MARK: - Layout computations

extension CardsCollectionViewLayout {

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
        collectionView.decelerationRate = 1
        minimumInteritemSpacing = 0
        minimumInteritemSpacing = 0
        minimumLineSpacing = 0
        assert(collectionView.numberOfSections == 1, "Multiple sections aren't supported!")
    }
    
    override open func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let totalItemsCount = collectionView.numberOfItems(inSection: 0)
        
        let minVisibleIndex = max(Int(collectionView.contentOffset.x) / Int(collectionView.bounds.width), 0)
        maxVisibleIndex = min(minVisibleIndex + maximumVisibleItems, totalItemsCount)
        
        let contentCenterX = collectionView.contentOffset.x + (collectionView.bounds.width / 2.0)
        
        var deltaOffset = Int(collectionView.contentOffset.x) % Int(collectionView.bounds.width)
        
        var percentageDeltaOffset = CGFloat(deltaOffset) / collectionView.bounds.width
        /// when swipping to right , make the diff so little
        if percentageDeltaOffset < 0 {
            percentageDeltaOffset *= 0.08
            deltaOffset = Int(percentageDeltaOffset * collectionView.bounds.width)
        }
        
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
            let moved = movedAttribute.attribute {
            let offsetxmin = collectionView.contentOffset.x
            let oldcenter = moved.center
            let rect = CGRect(x: offsetxmin + stoppingLine , y: moved.bounds.origin.y, width: moved.bounds.width, height: moved.bounds.height)
            moved.frame = rect
            moved.center = CGPoint(x: moved.center.x, y: oldcenter.y)
            moved.zIndex = Int.min
            attributes.append(moved)
        }
        return attributes
    }
    
    override open func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
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
            // check and set the scale of the left card
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
        // do not transform the items comming after the last visible item
        if visibleIndex != maximumVisibleItems - 1 {
            attributes.transform = transform(atCurrentVisibleIndex: visibleIndex,
                                             percentageOffset: percentageDeltaOffset)
        }
        switch visibleIndex {
        case 0:
            let cardWidth = collectionView.bounds.width
            let nextCardOffset = cardWidth * CGFloat(attributes.indexPath.row + 1)
            let offsetToNextCardOffset = abs(nextCardOffset - collectionView.contentOffset.x)

            // check if we reached a point passing the stopping point
            // if so pin it
            if offsetToNextCardOffset <= stoppingLine {
                print(cardWidth * CGFloat(attributes.indexPath.row + 1),nextCardOffset, collectionView.contentOffset.x)
                let transition = -(nextCardOffset) / CGFloat(attributes.indexPath.row + 1) + stoppingLine
                let translate = CGAffineTransform(translationX: transition, y: 0)
                let offsetxmin = collectionView.contentOffset.x
                let rect = CGRect(x: offsetxmin + stoppingLine , y: attributes.bounds.origin.y, width: attributes.bounds.width, height: attributes.bounds.height)
                attributes.frame = rect
                attributes.center = CGPoint(x: attributes.center.x,
                                            y: midY)

                attributes.transform = attributes.transform.concatenating(translate)
                
                movedOutCard[indexPath.row] = MovedOutCard(contentOffsetWhenMoved: collectionView.contentOffset,
                                                           attribute: attributes)
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
