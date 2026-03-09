import UIKit
import Photos

/// Saves images to the Photos library in a named album
enum PhotoLibraryService {
    static func save(_ image: UIImage, toAlbum albumName: String = "DartImages",
                     completion: ((Result<Void, Error>) -> Void)? = nil) {
        requestPermission { granted in
            guard granted else {
                completion?(.failure(PhotoError.permissionDenied))
                return
            }
            createAsset(from: image) { assetResult in
                switch assetResult {
                case .failure(let err):
                    completion?(.failure(err))
                case .success(let asset):
                    ensureAlbum(named: albumName) { album in
                        guard let album else {
                            completion?(.success(()))
                            return
                        }
                        addAsset(asset, to: album) { success in
                            completion?(success ? .success(()) : .failure(PhotoError.albumInsertFailed))
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Internals

private extension PhotoLibraryService {
    enum PhotoError: LocalizedError {
        case permissionDenied
        case assetCreationFailed
        case assetFetchFailed
        case albumInsertFailed

        var errorDescription: String? {
            switch self {
            case .permissionDenied: return "Keine Berechtigung für Fotos."
            case .assetCreationFailed: return "Foto konnte nicht erstellt werden."
            case .assetFetchFailed: return "Foto konnte nicht geladen werden."
            case .albumInsertFailed: return "Foto konnte nicht ins Album eingefügt werden."
            }
        }
    }

    static func requestPermission(_ completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        switch status {
        case .authorized, .limited:
            completion(true)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                completion(newStatus == .authorized || newStatus == .limited)
            }
        default:
            completion(false)
        }
    }

    static func createAsset(from image: UIImage,
                            completion: @escaping (Result<PHAsset, Error>) -> Void) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { success, error in
            if !success || error != nil {
                completion(.failure(error ?? PhotoError.assetCreationFailed))
                return
            }
            let fetch = PHAsset.fetchAssets(with: .image, options: {
                let o = PHFetchOptions()
                o.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                o.fetchLimit = 1
                return o
            }())
            if let asset = fetch.firstObject {
                completion(.success(asset))
            } else {
                completion(.failure(PhotoError.assetFetchFailed))
            }
        }
    }

    static func ensureAlbum(named title: String,
                            completion: @escaping (PHAssetCollection?) -> Void) {
        if let existing = fetchAlbum(named: title) {
            completion(existing)
            return
        }
        var placeholder: PHObjectPlaceholder?
        PHPhotoLibrary.shared().performChanges({
            let req = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: title)
            placeholder = req.placeholderForCreatedAssetCollection
        }) { success, _ in
            guard success, let id = placeholder?.localIdentifier else {
                completion(nil)
                return
            }
            let coll = PHAssetCollection.fetchAssetCollections(
                withLocalIdentifiers: [id], options: nil
            ).firstObject
            completion(coll)
        }
    }

    static func fetchAlbum(named title: String) -> PHAssetCollection? {
        let opts = PHFetchOptions()
        opts.predicate = NSPredicate(format: "localizedTitle = %@", title)
        return PHAssetCollection.fetchAssetCollections(
            with: .album, subtype: .any, options: opts
        ).firstObject
    }

    static func addAsset(_ asset: PHAsset, to album: PHAssetCollection,
                         completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.shared().performChanges({
            if let req = PHAssetCollectionChangeRequest(for: album) {
                req.addAssets([asset] as NSArray)
            }
        }) { success, _ in
            completion(success)
        }
    }
}
