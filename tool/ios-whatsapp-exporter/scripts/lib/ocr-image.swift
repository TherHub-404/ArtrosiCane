import Foundation
import Vision
import AppKit

guard CommandLine.arguments.count > 1 else {
  fputs("Usage: swift ocr-image.swift <image-path>\n", stderr)
  exit(1)
}

let path = CommandLine.arguments[1]
let url = URL(fileURLWithPath: path)

guard let image = NSImage(contentsOf: url) else {
  fputs("Unable to load image at \(path)\n", stderr)
  exit(2)
}

var rect = NSRect(origin: .zero, size: image.size)
guard let cgImage = image.cgImage(forProposedRect: &rect, context: nil, hints: nil) else {
  fputs("Unable to create CGImage for \(path)\n", stderr)
  exit(3)
}

let request = VNRecognizeTextRequest()
request.recognitionLevel = .accurate
request.usesLanguageCorrection = false

let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
try handler.perform([request])

for observation in request.results ?? [] {
  if let topCandidate = observation.topCandidates(1).first {
    print(topCandidate.string)
  }
}
