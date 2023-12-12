//
//  PDFView.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 12/3/23.
//

import Foundation
import PDFKit
import SwiftUI

/// A SwiftUI wrapper for displaying a PDF document.
struct PDFViewWrapper: UIViewRepresentable {

  /// The URL of the PDF document to be displayed.
  var pdfURL: URL

  /// Creates a PDFView and configures it to automatically scale its content.
  /// - Parameter context: The context in which the view is being created.
  /// - Returns: A PDFView instance.
  func makeUIView(context: Context) -> PDFView {
    let pdfView = PDFView()
    pdfView.autoScales = true
    return pdfView
  }

  /// Updates the PDFView with the specified document if it exists.
  /// - Parameters:
  ///   - uiView: The PDFView to be updated.
  ///   - context: The context in which the view is being updated.
  func updateUIView(_ uiView: PDFView, context: Context) {
    if let document = PDFDocument(url: pdfURL) {
      uiView.document = document
    }
  }
}
