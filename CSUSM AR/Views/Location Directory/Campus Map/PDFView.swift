//
//  PDFView.swift
//  CSUSM AR
//
//  Created by Salman Burhan on 12/3/23.
//

import Foundation
import SwiftUI
import PDFKit

struct PDFViewWrapper: UIViewRepresentable {
    var pdfURL: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if let document = PDFDocument(url: pdfURL) {
            uiView.document = document
        }
    }
}

