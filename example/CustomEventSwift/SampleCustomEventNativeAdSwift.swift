//
// Copyright (C) 2017 Google, Inc.
//
// SampleCustomEventNativeAdSwift.swift
// Mediation Example
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation
import GoogleMobileAds
import SampleAdSDK

/// Constant for Sample Ad Network custom event error domain.
private let customEventErrorDomain: String = "com.google.CustomEvent"

class SampleCustomEventNativeAdSwift: NSObject, GADCustomEventNativeAd {
  /// Native ad view options.
  fileprivate var nativeAdViewAdOptions: GADNativeAdViewAdOptions?
  var delegate: GADCustomEventNativeAdDelegate?

  required override init() {
    super.init()
  }

  func request(
    withParameter serverParameter: String,
    request: GADCustomEventRequest,
    adTypes: [Any],
    options: [Any],
    rootViewController: UIViewController
  ) {
    let adLoader = SampleNativeAdLoader()
    let sampleRequest = SampleNativeAdRequest()

    // The Google Mobile Ads SDK requires the image assets to be downloaded automatically unless
    // the publisher specifies otherwise by using the GADNativeAdImageAdLoaderOptions object's
    // disableImageLoading property. If your network doesn't have an option like this and instead
    // only ever returns URLs for images (rather than the images themselves), your adapter should
    // download image assets on behalf of the publisher. This should be done after receiving the
    // native ad object from your network's SDK, and before calling the connector's
    // adapter:didReceiveMediatedNativeAd: method.
    sampleRequest.shouldDownloadImages = true
    sampleRequest.preferredImageOrientation = NativeAdImageOrientation.any
    sampleRequest.shouldRequestMultipleImages = false
    if let options = options as? [GADAdLoaderOptions] {
      for loaderOptions: GADAdLoaderOptions in options {
        if let imageOptions = loaderOptions as? GADNativeAdImageAdLoaderOptions {
          sampleRequest.shouldRequestMultipleImages = imageOptions.shouldRequestMultipleImages
          // If the GADNativeAdImageAdLoaderOptions' disableImageLoading property is
          // YES, the adapter should send just the URLs for the images.
          sampleRequest.shouldDownloadImages = !imageOptions.disableImageLoading
        } else if let mediaOptions = loaderOptions as? GADNativeAdMediaAdLoaderOptions {
          switch mediaOptions.mediaAspectRatio {
          case GADMediaAspectRatio.landscape:
            sampleRequest.preferredImageOrientation = NativeAdImageOrientation.landscape
          case GADMediaAspectRatio.portrait:
            sampleRequest.preferredImageOrientation = NativeAdImageOrientation.portrait
          default: sampleRequest.preferredImageOrientation = NativeAdImageOrientation.any
          }
        } else if let options = loaderOptions as? GADNativeAdViewAdOptions {
          nativeAdViewAdOptions = options
        }
      }
    }
    // This custom event uses the server parameter to carry an ad unit ID, which is the most common
    // use case.
    adLoader.adUnitID = serverParameter
    adLoader.delegate = self
    adLoader.fetchAd(sampleRequest)
  }

  // Indicates if the custom event handles user clicks. Return YES if the custom event should handle
  // user clicks.
  func handlesUserClicks() -> Bool {
    return false
  }
  func handlesUserImpressions() -> Bool {
    return false
  }
}

extension SampleCustomEventNativeAdSwift: SampleNativeAdLoaderDelegate {
  func adLoader(_ adLoader: SampleNativeAdLoader, didReceive nativeAd: SampleNativeAd) {
    let mediatedAd = SampleMediatedNativeAdSwift(
      sampleNativeAd: nativeAd, nativeAdViewAdOptions: nativeAdViewAdOptions)
    delegate?.customEventNativeAd(self, didReceive: mediatedAd)
  }

  func adLoader(_ adLoader: SampleNativeAdLoader, didFailToLoadAdWith errorCode: SampleErrorCode) {
    let error = NSError(domain: customEventErrorDomain, code: errorCode.rawValue, userInfo: nil)
    delegate?.customEventNativeAd(self, didFailToLoadWithError: error)
  }
}
