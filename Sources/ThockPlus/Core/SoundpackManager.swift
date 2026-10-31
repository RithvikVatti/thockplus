import Foundation
import AppKit

public struct SoundpackMetadata: Codable, Sendable {
    public let name: String
    public let brand: String?
    public let author: String?
    public let supportsKeyUp: Bool?
    public let category: String // "keyboard" or "mouse"
    
    public init(name: String, brand: String? = nil, author: String? = nil, supportsKeyUp: Bool? = true, category: String) {
        self.name = name
        self.brand = brand
        self.author = author
        self.supportsKeyUp = supportsKeyUp
        self.category = category
    }
}

public struct SoundpackRegistryEntry: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let brand: String
    public let author: String
    public let category: String
    public let downloadURL: String
    public let size: Int
    public var isInstalled: Bool = false
    public var isDownloading: Bool = false
}

public struct InstalledSoundpack: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let brand: String
    public let category: String
    public let folderURL: URL
}

@MainActor
public final class SoundpackManager: ObservableObject {
    public static let shared = SoundpackManager()
    
    @Published public var keyboardRegistry: [SoundpackRegistryEntry] = []
    @Published public var mouseRegistry: [SoundpackRegistryEntry] = []
    @Published public var installedPacks: [InstalledSoundpack] = []
    
    @Published public var selectedKeyboardPackID: String = "52722920-07ec-45b4-91cc-6f29cad794d2" {
        didSet {
            UserDefaults.standard.set(selectedKeyboardPackID, forKey: "selectedKeyboardPackID")
            reloadActiveSoundpacks()
        }
    }
    
    @Published public var selectedMousePackID: String = "3222385c-d428-4d98-8ce9-1cbc992c3373" {
        didSet {
            UserDefaults.standard.set(selectedMousePackID, forKey: "selectedMousePackID")
            reloadActiveSoundpacks()
        }
    }
    
    @Published public var isLoadingManifest: Bool = false
    @Published public var statusMessage: String? = nil
    
    public var soundpacksDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("ThockPlus/Soundpacks", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    private init() {
        self.selectedKeyboardPackID = UserDefaults.standard.string(forKey: "selectedKeyboardPackID") ?? "52722920-07ec-45b4-91cc-6f29cad794d2"
        self.selectedMousePackID = UserDefaults.standard.string(forKey: "selectedMousePackID") ?? "3222385c-d428-4d98-8ce9-1cbc992c3373"
        
        refreshInstalledPacks()
        Task {
            await fetchManifest()
        }
    }
    
    public func openSoundpacksFolder() {
        NSWorkspace.shared.open(soundpacksDirectory)
    }
    
    public func refreshInstalledPacks() {
        let base = soundpacksDirectory
        guard let items = try? FileManager.default.contentsOfDirectory(at: base, includingPropertiesForKeys: nil) else { return }
        
        var list: [InstalledSoundpack] = []
        for folder in items where folder.hasDirectoryPath {
            let configURL = folder.appendingPathComponent("config.json")
            if let data = try? Data(contentsOf: configURL),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let meta = json["metadata"] as? [String: Any] {
                let name = meta["name"] as? String ?? folder.lastPathComponent
                let brand = meta["brand"] as? String ?? "Custom"
                let category = meta["category"] as? String ?? "keyboard"
                list.append(InstalledSoundpack(
                    id: folder.lastPathComponent,
                    name: name,
                    brand: brand,
                    category: category,
                    folderURL: folder
                ))
            }
        }
        self.installedPacks = list
        updateRegistryInstallationStatus()
    }
    
    public func fetchManifest() async {
        self.isLoadingManifest = true
        let manifestURL = URL(string: "https://raw.githubusercontent.com/kamillobinski/thock-soundpacks/refs/heads/main/manifest.json")!
        
        do {
            let (data, _) = try await URLSession.shared.data(from: manifestURL)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let soundpacks = json["soundpacks"] as? [String: Any] else {
                self.isLoadingManifest = false
                return
            }
            
            var kbList: [SoundpackRegistryEntry] = []
            if let kbArr = soundpacks["keyboard"] as? [[String: Any]] {
                for item in kbArr {
                    if let entry = parseEntry(item, defaultCategory: "keyboard") {
                        kbList.append(entry)
                    }
                }
            }
            
            var mouseList: [SoundpackRegistryEntry] = []
            if let mouseArr = soundpacks["mouse"] as? [[String: Any]] {
                for item in mouseArr {
                    if let entry = parseEntry(item, defaultCategory: "mouse") {
                        mouseList.append(entry)
                    }
                }
            }
            
            self.keyboardRegistry = kbList
            self.mouseRegistry = mouseList
            self.isLoadingManifest = false
            updateRegistryInstallationStatus()
        } catch {
            print("[Thock+] Error fetching manifest: \(error)")
            self.isLoadingManifest = false
        }
    }
    
    private func parseEntry(_ item: [String: Any], defaultCategory: String) -> SoundpackRegistryEntry? {
        guard let id = item["id"] as? String,
              let meta = item["metadata"] as? [String: Any],
              let name = meta["name"] as? String,
              let download = item["download"] as? [String: Any],
              let url = download["url"] as? String else {
            return nil
        }
        let brand = meta["brand"] as? String ?? "Generic"
        let author = meta["author"] as? String ?? "Community"
        let size = download["size"] as? Int ?? 0
        let category = meta["category"] as? String ?? defaultCategory
        
        return SoundpackRegistryEntry(
            id: id,
            name: name,
            brand: brand,
            author: author,
            category: category,
            downloadURL: url,
            size: size,
            isInstalled: false,
            isDownloading: false
        )
    }
    
    private func updateRegistryInstallationStatus() {
        let installedIDs = Set(installedPacks.map { $0.id })
        
        for i in 0..<keyboardRegistry.count {
            keyboardRegistry[i].isInstalled = installedIDs.contains(keyboardRegistry[i].id)
        }
        for i in 0..<mouseRegistry.count {
            mouseRegistry[i].isInstalled = installedIDs.contains(mouseRegistry[i].id)
        }
    }
    
    public func downloadAndInstall(entry: SoundpackRegistryEntry) async {
        guard let url = URL(string: entry.downloadURL) else { return }
        
        // Mark downloading
        if entry.category == "keyboard" {
            if let idx = keyboardRegistry.firstIndex(where: { $0.id == entry.id }) {
                keyboardRegistry[idx].isDownloading = true
            }
        } else {
            if let idx = mouseRegistry.firstIndex(where: { $0.id == entry.id }) {
                mouseRegistry[idx].isDownloading = true
            }
        }
        
        do {
            let (tempURL, _) = try await URLSession.shared.download(from: url)
            let destFolder = soundpacksDirectory.appendingPathComponent(entry.id, isDirectory: true)
            try? FileManager.default.createDirectory(at: destFolder, withIntermediateDirectories: true)
            
            // Extract via ditto
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
            proc.arguments = ["-xk", tempURL.path, destFolder.path]
            try proc.run()
            proc.waitUntilExit()
            
            try? FileManager.default.removeItem(at: tempURL)
            
            refreshInstalledPacks()
            
            // Auto-select newly installed pack
            if entry.category == "keyboard" {
                self.selectedKeyboardPackID = entry.id
            } else {
                self.selectedMousePackID = entry.id
            }
        } catch {
            print("[Thock+] Error downloading soundpack \(entry.name): \(error)")
        }
        
        if entry.category == "keyboard" {
            if let idx = keyboardRegistry.firstIndex(where: { $0.id == entry.id }) {
                keyboardRegistry[idx].isDownloading = false
            }
        } else {
            if let idx = mouseRegistry.firstIndex(where: { $0.id == entry.id }) {
                mouseRegistry[idx].isDownloading = false
            }
        }
    }
    
    private func reloadActiveSoundpacks() {
        KeyboardMouseEngine.shared.loadActivePacks(
            keyboardPackURL: soundpacksDirectory.appendingPathComponent(selectedKeyboardPackID),
            mousePackURL: soundpacksDirectory.appendingPathComponent(selectedMousePackID)
        )
    }
}
