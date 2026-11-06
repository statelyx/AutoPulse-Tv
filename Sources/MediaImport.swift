import Foundation
import CoreTransferable
import UniformTypeIdentifiers
import AVFoundation
import UIKit
import ImageIO

struct PickedMedia: Transferable {
    let url: URL
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .movie, importing: { received in
            try copyTemporary(received.file)
        })
        FileRepresentation(importedContentType: .image, importing: { received in
            try copyTemporary(received.file)
        })
    }
    private static func copyTemporary(_ original: URL) throws -> PickedMedia {
        let size = try original.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        guard size <= LocalMedia.byteLimit else { throw MediaError.mediaTooLarge }
        let target = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString).appendingPathExtension(original.pathExtension)
        try FileManager.default.copyItem(at: original, to: target)
        return PickedMedia(url: target)
    }
}

actor MediaImporter {
    static let shared = MediaImporter()

    func copy(_ input: URL, title: String? = nil) async throws -> MediaSource {
        let access = input.startAccessingSecurityScopedResource()
        defer { if access { input.stopAccessingSecurityScopedResource() } }
        let values = try input.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
        guard values.isRegularFile == true else { throw MediaError.unsupportedFile }
        guard let size = values.fileSize, size > 0, size <= LocalMedia.byteLimit else { throw MediaError.mediaTooLarge }
        let type = UTType(filenameExtension: input.pathExtension)
        let photo = type?.conforms(to: .image) == true
        guard photo || type?.conforms(to: .movie) == true else { throw MediaError.unsupportedFile }
        let directory = LocalMedia.directory
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let id = UUID().uuidString
        let target = directory.appendingPathComponent(id).appendingPathExtension(photo ? "jpg" : input.pathExtension.lowercased())
        let movie = directory.appendingPathComponent(id + "-presentation.mp4")
        do {
            if photo {
                guard let image = Self.thumbnail(input, maximum: 2560),
                      let data = image.jpegData(compressionQuality: 0.92) else { throw MediaError.unsupportedFile }
                try data.write(to: target, options: [.atomic, .completeFileProtectionUnlessOpen])
                try await Self.makePhotoMovie(image: image, destination: movie)
            } else {
                let asset = AVURLAsset(url: input)
                guard try await asset.load(.isPlayable) else { throw MediaError.unsupportedFile }
                try FileManager.default.copyItem(at: input, to: target)
                try FileManager.default.setAttributes([.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication], ofItemAtPath: target.path)
            }
            try Task.checkCancellation()
            return MediaSource(title: title ?? input.deletingPathExtension().lastPathComponent,
                url: target, group: photo ? "Fotoğraflarım" : "Cihazımdaki videolar",
                kind: photo ? .photo : .video, localFileName: target.lastPathComponent,
                photoMovieFileName: photo ? movie.lastPathComponent : nil)
        } catch {
            try? FileManager.default.removeItem(at: target)
            try? FileManager.default.removeItem(at: movie)
            throw error
        }
    }

    nonisolated static func thumbnail(_ url: URL, maximum: Int) -> UIImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: maximum
              ] as CFDictionary) else { return nil }
        return UIImage(cgImage: image)
    }

    // A still photograph encoded as ordinary H.264 media, sent through Apple's
    // native video route. No phone UI is captured or transmitted.
    private static func makePhotoMovie(image: UIImage, destination: URL) async throws {
        let width = 1920, height = 1080
        let writer = try AVAssetWriter(outputURL: destination, fileType: .mp4)
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: width, AVVideoHeightKey: height
        ])
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
            kCVPixelBufferWidthKey as String: width, kCVPixelBufferHeightKey as String: height,
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ])
        guard writer.canAdd(input) else { throw MediaError.photoConversion }
        writer.add(input)
        guard writer.startWriting() else { throw writer.error ?? MediaError.photoConversion }
        writer.startSession(atSourceTime: .zero)
        var buffer: CVPixelBuffer?
        guard CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB,
            [kCVPixelBufferCGImageCompatibilityKey: true, kCVPixelBufferCGBitmapContextCompatibilityKey: true] as CFDictionary,
            &buffer) == kCVReturnSuccess, let buffer else { writer.cancelWriting(); throw MediaError.photoConversion }
        CVPixelBufferLockBaseAddress(buffer, [])
        guard let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer), width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue),
            let cgImage = image.cgImage else {
            CVPixelBufferUnlockBaseAddress(buffer, []); writer.cancelWriting(); throw MediaError.photoConversion
        }
        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        let scale = min(CGFloat(width) / image.size.width, CGFloat(height) / image.size.height)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        context.draw(cgImage, in: CGRect(x: (CGFloat(width) - size.width) / 2,
            y: (CGFloat(height) - size.height) / 2, width: size.width, height: size.height))
        CVPixelBufferUnlockBaseAddress(buffer, [])
        do {
            // Repeated frames make a seekable, interoperable ten-second clip.
            for frame in 0..<50 {
                let deadline = Date().addingTimeInterval(15)
                while !input.isReadyForMoreMediaData {
                    try Task.checkCancellation()
                    guard writer.status == .writing, Date() < deadline else { throw MediaError.photoConversion }
                    try await Task.sleep(for: .milliseconds(10))
                }
                guard adaptor.append(buffer, withPresentationTime: CMTime(value: Int64(frame), timescale: 5)) else {
                    throw writer.error ?? MediaError.photoConversion
                }
            }
            writer.endSession(atSourceTime: CMTime(seconds: 10, preferredTimescale: 5))
            input.markAsFinished()
            await writer.finishWriting()
            guard writer.status == .completed else { throw writer.error ?? MediaError.photoConversion }
        } catch { writer.cancelWriting(); throw error }
    }
}
