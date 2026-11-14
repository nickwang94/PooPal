import SwiftUI

/// Bristol stool scale, types 1–7.
enum BristolType: Int, CaseIterable, Identifiable, Codable {
    case separateLumps = 1
    case lumpySausage
    case crackedSausage
    case smoothSnake
    case softBlobs
    case mushy
    case watery

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .separateLumps: "硬球球"
        case .lumpySausage: "疙瘩条"
        case .crackedSausage: "裂纹条"
        case .smoothSnake: "光滑条"
        case .softBlobs: "软团团"
        case .mushy: "糊糊状"
        case .watery: "水水状"
        }
    }

    var hint: String {
        switch self {
        case .separateLumps: "一颗颗硬硬的，可能有点便秘"
        case .lumpySausage: "成条但疙疙瘩瘩，偏干"
        case .crackedSausage: "成条有裂纹，挺正常"
        case .smoothSnake: "光滑柔软，最理想"
        case .softBlobs: "软软的小团，边缘清楚"
        case .mushy: "糊糊的，有点稀"
        case .watery: "水样，注意补水哦"
        }
    }

    /// Strong color: dry types amber, normal types glaze, loose types coral.
    var tint: Color {
        switch self {
        case .separateLumps, .lumpySausage: Theme.amber
        case .crackedSausage, .smoothSnake, .softBlobs: Theme.glaze
        case .mushy, .watery: Theme.coral
        }
    }

    var paleTint: Color {
        switch self {
        case .separateLumps, .lumpySausage: Theme.amberPale
        case .crackedSausage, .smoothSnake, .softBlobs: Theme.glazePale
        case .mushy, .watery: Theme.coralPale
        }
    }

    var group: String {
        switch self {
        case .separateLumps, .lumpySausage: "偏干"
        case .crackedSausage, .smoothSnake: "理想"
        case .softBlobs: "偏软"
        case .mushy, .watery: "偏稀"
        }
    }
}
