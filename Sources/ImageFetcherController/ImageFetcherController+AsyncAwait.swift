//
//  File.swift
//  
//
//  Created by Jason Howlin on 1/25/22.
//

import Foundation
import UIKit

extension ImageFetcherController {
    
    public func fetchImage(imageRequest:ImageFetcherRequest) async -> ImageFetcherResult {
        let observationToken = UUID().uuidString
        return await withTaskCancellationHandler(operation: {
            return await withCheckedContinuation { continuation in
                self.fetchImage(imageRequest: imageRequest, observationToken: observationToken) { result in
                    continuation.resume(returning: result)
                }
            }
        }, onCancel: {
            self.removeRequestObserver(request: imageRequest, token: observationToken)
        })
    }
}
