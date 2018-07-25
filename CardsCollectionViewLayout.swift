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
    
    public var cellSize: CGSize = CGSize(width: 260, height: 500) {
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
        
        if minVisibleIndex > 0 {
            let lastindex = IndexPath(item: minVisibleIndex - 1, section: 0)
            if let leastbyone = self.layoutAttributesForItem(at: lastindex) {
                let lastframe = attributes.first!.frame
                leastbyone.frame = lastframe.offsetBy(dx: -lastframe.width - 20, dy: 0)
                //                leastbyone.transform = possiblemoved.transform
                //                attributes.append(leastbyone)
            }
        }
        return attributes
    }
    
    func endedDisplayingCell(at index: IndexPath) {
        movedOutCard = self.layoutAttributesForItem(at: index)
    }
    
    override open func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    var movedOutCard: UICollectionViewLayoutAttributes? = nil
    
    
    override open func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        
        let pageWidth = itemSize.width
        let approximatePage = self.collectionView.contentOffset.x/pageWidth
        print(proposedContentOffset, approximatePage)
        
        // Determine the current page based on velocity.
        let currentPage = (velocity.x < 0.0) ? floor(approximatePage) : ceil(approximatePage)
        
        // Create custom flickVelocity.
        let flickVelocity = velocity.x
        
        // Check how many pages the user flicked, if <= 1 then flickedPages should return 0.
        let flickedPages = (abs(round(flickVelocity)) <= 1) ? 0 : round(flickVelocity)
        //        print("flicked: ",flickVelocity, self.collectionView.contentInset.left, pageWidth, flickedPages)
        // Calculate newVerticalOffset.
        let newVerticalOffset = ((currentPage - 1 + flickedPages) * pageWidth) - self.collectionView.contentInset.left
        
        print(CGPoint(x: newVerticalOffset, y: proposedContentOffset.y), currentPage, flickedPages)
        return CGPoint(x: newVerticalOffset + 190, y: proposedContentOffset.y)
    }
    
}


// MARK: - Layout computations

fileprivate extension CardsCollectionViewLayout {
    
    private func scale(at index: Int) -> CGFloat {
        let translatedCoefficient = CGFloat(index) - CGFloat(self.maximumVisibleItems) / 2
        return CGFloat(pow(0.95, translatedCoefficient))
    }
    
    private func transform(atCurrentVisibleIndex visibleIndex: Int, percentageOffset: CGFloat) -> CGAffineTransform {
        var rawScale = visibleIndex < maximumVisibleItems ? scale(at: visibleIndex) : 1.0
        
        if visibleIndex != 0 {
            let previousScale = scale(at: visibleIndex - 1)
            let delta = (previousScale - rawScale) * percentageOffset
            rawScale += delta
        }
        
        if visibleIndex == 0 {
            let previousScale = scale(at: visibleIndex - 1)
            let delta = (previousScale - rawScale) * percentageOffset
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
        case -1:
            print("case -1")
        case 0:
            if deltaOffset < cellSize.width  {
                attributes.center.x -= deltaOffset
            } else {
                attributes.center.x -= cellSize.width
            }
            print(attributes.center, deltaOffset)
            break
        case 1..<maximumVisibleItems:
            attributes.center.x -= spacingX * percentageDeltaOffset
            attributes.center.y -= spacingY * percentageDeltaOffset
            
            if visibleIndex == maximumVisibleItems - 1 {
                attributes.alpha = percentageDeltaOffset
            }
            break
        default:
            attributes.alpha = 0
            break
        }
        
        return attributes
    }
}
