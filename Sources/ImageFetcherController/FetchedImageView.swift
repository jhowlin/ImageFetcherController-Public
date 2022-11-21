//
//  File.swift
//  
//
//  Created by Jason Howlin on 9/13/20.
//

import Foundation
import UIKit
import SwiftUI

public class ImageLoader: ObservableObject {
    
    @Published var image: UIImage?
    private let controller = ImageFetcherController.shared
    var token = UUID().uuidString
    var debugTag: String
    var fadeIn: Bool
    
    public init(debugTag:String = "", fadeIn: Bool = true) {
        self.debugTag = debugTag
        self.fadeIn = fadeIn
    }

    func downloadImage(request:ImageFetcherRequest) {
        // This may be an issue on rotation - this image may be invalid. Needs investigating...
        guard self.image == nil else { return }
        controller.fetchImage(imageRequest: request, observationToken: token) { res in
            switch res {
            case let .success(image, req):
                if self.fadeIn && req.performanceMetrics.fulfillmentType == .downloaded {
                    withAnimation {
                        self.image = image
                    }
                } else {
                    self.image = image
                }
            case let .error(error, _):
                print(error)
            }
        }
    }
    
    func cancelDownloadImage(request:ImageFetcherRequest) {
        controller.removeRequestObserver(request: request, token: token)
    }
}

public struct FetchedImage: View {
    public init(url: String, identifier: String, sourceSize: CGSize, cornerRadius: CGFloat = 0, debugTag: String = "", fadeIn:Bool = true, resize: Bool = true, scaleToFill: Bool = true) {
        self.url = url
        self.identifier = identifier
        self.sourceSize = sourceSize
        self.cornerRadius = cornerRadius
        self.debugTag = debugTag
        self.fadeIn = fadeIn
        self.resize = resize
        self.scaleToFill = scaleToFill
    }
    
    
    public let url: String
    public let identifier: String
    public let sourceSize: CGSize
    public var cornerRadius: CGFloat = 0
    @StateObject var imageLoader = ImageLoader()
    public var debugTag = ""
    @State var width: CGFloat = .zero
    public var fadeIn: Bool
    var resize: Bool
    var scaleToFill: Bool

    public var body: some View {
        GeometryReader { proxy in
            if self.imageLoader.image == nil {
                Rectangle().frame(width: proxy.size.width, height: proxy.size.height).foregroundColor(.clear)
                    .onAppear {
                        imageLoader.fadeIn = fadeIn
                        imageLoader.debugTag = debugTag
                        self.downloadImage(proxy: proxy, shouldCancel: false)
                        self.width = proxy.size.width
                    }.onDisappear {
                        self.downloadImage(proxy: proxy, shouldCancel: true)
                    }
            } else {
                Image(uiImage: self.imageLoader.image!)
                    .resizable()
                    .aspectRatio(contentMode: scaleToFill ? .fill : .fit)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .cornerRadius(self.cornerRadius)
            }
        }
    }
    
    func downloadImage(proxy:GeometryProxy, shouldCancel:Bool = false) {
        imageLoader.debugTag = self.debugTag
        
        // Hack for bug in iOS 15 where when cancelling due to on disappear in view, the proxy size.width is 0. That causes our cancel to fail because we can't match the image op request to the request we generate to cancel. We could also save the request as a workaround, or allow to request using just the token, but let's see if they fix this...
        
        var size = proxy.size
        if proxy.size.width == 0 {
            size.width = self.width
        }
        
        let imageFrame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        let targetSize = imageFrame.size.scaled(scaleFactor: UIScreen.main.scale)
        
        var sizeMetrics:ImageFetcherImageSizeMetrics? = sourceSize.greaterThanZero && targetSize.greaterThanZero ? ImageFetcherImageSizeMetrics(targetSize: targetSize, sourceSize: sourceSize) : nil
        
        if !resize {
            sizeMetrics = nil
        }
       
        let req = ImageFetcherRequest(url: url, identifier: identifier, isLowPriority: false, sizeMetrics: sizeMetrics)
        
        if shouldCancel {
            imageLoader.cancelDownloadImage(request: req)
        } else {
            imageLoader.downloadImage(request: req)
        }
    }
}

public struct ScalesToFillImage: View {
    public let name: String
    public var body: some View {
        GeometryReader { geometry in
            Image(name).resizable().scaledToFill().frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}



