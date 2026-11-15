// SPDX-License-Identifier: GPL-3.0-only
// Key catalog adapted from GestaltX Capabilities.swift.
// Copyright (C) 2026 huamidev. Elyra adaptation (C) 2026 Elyra contributors.
import Foundation
public struct Capability: Identifiable, Sendable {
    public let id: String
    public let category: String
    public let title: String
    public let detail: String
    public let keys: [String]
    public let value: Int64
    public let caution: Bool
    public func stage(in document: inout PlistValue) throws {
        if id == "dynamicIsland" { document = try DynamicIslandEngine.enablingFlag(in: document); return }
        guard case .dictionary = document.value(at: ["CacheExtra"]) else { throw ElyraError.invalid("This document has no CacheExtra dictionary.") }
        guard id != "siriOnDevice" else { throw ElyraError.invalid("On-Device Siri has a device-specific type. Restore a recorded original instead of guessing.") }
        for key in keys {
            let target: PlistValue
            if id == "ipadApps" { target = .array([.integer(1), .integer(2)]) }
            else if (value == 0 || value == 1), case .boolean? = document.value(at: ["CacheExtra", key]) { target = .boolean(value == 1) }
            else { target = .integer(value) }
            try document.set(target, at: ["CacheExtra", key])
        }
    }
    public static let all: [Self] = [
        .init(id: "dynamicIsland", category: "display", title: "Dynamic Island", detail: "Enable the alternate Dynamic Island capability.", keys: ["YlEtTtHlNesRBMal1CqRaA"], value: 1, caution: false),
        .init(id: "aod", category: "display", title: "Always-On Display", detail: "Display behavior depends on the panel. May increase power use and burn-in risk.", keys: ["2OOJf1VhaM7NxfRok3HbWQ", "j8/Omm6s1lsmTDFsXjsBfA"], value: 1, caution: true),
        .init(id: "aodVibrancy", category: "display", title: "AOD Vibrancy", detail: "Adjust Always-On rendering capabilities.", keys: ["ykpu7qyhqFweVMKtxNylWA"], value: 1, caution: false),
        .init(id: "aodHighLuminance", category: "display", title: "High-Luminance Always-On Display", detail: "Allow Always-On Display to reach a higher brightness level.", keys: ["7brdL5xrEUWnlF9C0kdg5A"], value: 1, caution: false),
        .init(id: "aodFlipbook", category: "display", title: "Always-On Display Flipbook", detail: "Enable AOD flipbook widgets on the Lock Screen.", keys: ["aoJSd/MXk7M40NgXTM6x+g"], value: 1, caution: false),
        .init(id: "aodFlipbookCount", category: "display", title: "AOD Flipbook Count", detail: "Set how many AOD flipbook entries are allowed. Experimental; the accepted range varies by build.", keys: ["qqrspu7CpuPdZwSDxNY+Fg"], value: 3, caution: true),
        .init(id: "parallax", category: "display", title: "Disable Wallpaper Parallax", detail: "Stop the wallpaper from moving with device motion.", keys: ["UIParallaxCapability"], value: 0, caution: false),
        .init(id: "hdrPhotoDisplay", category: "display", title: "HDR Photo Display", detail: "Enable true HDR rendering for photos.", keys: ["a1r7npIrhXsZ7SmKRKC1eA"], value: 1, caution: false),
        .init(id: "pwm", category: "display", title: "Pulse Width Modulation", detail: "Advertise PWM display support. Actual dimming behavior depends on the panel.", keys: ["6IejgN+1Fmu5/QrZFOIeNw"], value: 1, caution: true),
        .init(id: "displayPort", category: "display", title: "DisplayPort Output", detail: "Advertise DisplayPort output support. Compatible hardware is still required.", keys: ["CoWnN4xo783YGn4wLrUatA"], value: 1, caution: true),
        .init(id: "liquidGlass", category: "display", title: "Liquid Glass Low-Power Rendering", detail: "Use the low-performance rendering capability on iOS 26 and later.", keys: ["SAGvsp6O6kAQ4fEfDJpC4Q"], value: 1, caution: false),
        .init(id: "bootChime", category: "device", title: "Boot & Shutdown Chime", detail: "Expose the startup and shutdown sound capability.", keys: ["QHxt+hGLaBPbQJbXiUJX3w"], value: 1, caution: false),
        .init(id: "chargeLimit", category: "device", title: "Charge Limit", detail: "Show charging limit settings. Actual charging control depends on hardware.", keys: ["37NVydb//GP/GrhuTN+exg"], value: 1, caution: false),
        .init(id: "tapToWake", category: "device", title: "Tap to Wake", detail: "Expose tap-to-wake on devices where it is hidden.", keys: ["yZf3GTRMGTuwSV/lD7Cagw"], value: 1, caution: false),
        .init(id: "cameraControl", category: "device", title: "Camera Control", detail: "Show Camera Control settings. Does not add a physical button.", keys: ["CwvKxM2cEogD3p+HYgaW0Q", "oOV1jhJbdV3AddkcCg0AEA"], value: 1, caution: false),
        .init(id: "actionButton", category: "device", title: "Action Button", detail: "Show the Action Button settings page.", keys: ["cT44WE1EohiwRzhsZ8xEsw"], value: 1, caution: false),
        .init(id: "collisionSOS", category: "device", title: "Collision SOS", detail: "Show collision detection in Emergency SOS settings. Hardware support is still required.", keys: ["HCzWusHQwZDea6nNhaKndw"], value: 1, caution: false),
        .init(id: "audioMix", category: "device", title: "Audio Mix", detail: "Enable the audio mix capability for supported media.", keys: ["aVL5GE3tx0LSCI/ErfrJGA"], value: 1, caution: false),
        .init(id: "spatialFaceTimeAudio", category: "device", title: "Spatial FaceTime Audio", detail: "Enable spatial audio playback for FaceTime.", keys: ["/EVOCjM/Nmb2roP5ebtEFA"], value: 1, caution: false),
        .init(id: "pencil", category: "ipad", title: "Apple Pencil", detail: "Expose Apple Pencil settings. Hardware support is still required.", keys: ["yhHcB0iH0d1XzPO/CFd3ow"], value: 1, caution: false),
        .init(id: "stageManager", category: "ipad", title: "Stage Manager", detail: "Expose Stage Manager support. Layout behavior varies by device.", keys: ["qeaj75wk3HF4DwQ8qbIi7g"], value: 1, caution: true),
        .init(id: "ipadApps", category: "ipad", title: "iPad App Compatibility", detail: "Allow iPad app compatibility types on iPhone.", keys: ["9MZ5AdH43csAUajl/dU+IQ"], value: 1, caution: false),
        .init(id: "ai", category: "intelligence", title: "Apple Intelligence Capability", detail: "Set the generative models capability. Availability also depends on hardware, region and Apple services.", keys: ["A62OafQ85EJAiiqKn4agtg"], value: 1, caution: false),
        .init(id: "siriAIMode", category: "intelligence", title: "Siri AI Mode", detail: "Set SiriMode to 2 without spoofing hardware. Experimental; resource downloads and availability are not guaranteed.", keys: ["a3n5T9sFtlyQ74NEp9ESxg"], value: 2, caution: true),
        .init(id: "siriOnDevice", category: "intelligence", title: "On-Device Siri", detail: "Siri uses a device-specific capability type. Changing it may affect the Apple Intelligence Siri interface. Keep the current value or restore the recorded original.", keys: ["K/R1GfGfCkXvEhaPS2Vrng"], value: 1, caution: true),
        .init(id: "audioIntelligence", category: "intelligence", title: "Audio Intelligence", detail: "Advertise the iOS 27 audio intelligence capability.", keys: ["rb2tKZxlj0Gm2tBmUQSLqQ"], value: 1, caution: true),
        .init(id: "personalTranslator", category: "intelligence", title: "Personal Translator", detail: "Advertise the personal translator capability.", keys: ["M1n2sAqf33NAOgZRGxQYBA"], value: 1, caution: true),
        .init(id: "photosCleanUp", category: "intelligence", title: "Photos Clean Up", detail: "Advertise the photos inpainting (Clean Up) capability.", keys: ["XNCjqOupLM/S8fNyxRNQTA"], value: 1, caution: true),
        .init(id: "handwritingSynthesis", category: "intelligence", title: "Handwriting Synthesis", detail: "Advertise the handwriting synthesis model capability.", keys: ["YgYIIViDt1kgzyIsIV61vA"], value: 1, caution: true),
        .init(id: "alwaysListeningSiri", category: "intelligence", title: "Always-Listening Hey Siri", detail: "Advertise always-listening Hey Siri support.", keys: ["TusANsf9Lfe3P/9fIXXSrQ"], value: 1, caution: true),
        .init(id: "internal", category: "advanced", title: "Apple Internal Features", detail: "Expose internal menus. Some system services may behave differently.", keys: ["EqrsVvjcYDdxHBiQmGhAWw"], value: 1, caution: true),
        .init(id: "storage", category: "advanced", title: "Internal Build", detail: "Changes the system-wide InternalBuild flag, not just storage information. System services may behave differently. Revert restores the recorded original value.", keys: ["LBJfwOEzExRxzlAnSuI7eg"], value: 1, caution: true),
        .init(id: "srd", category: "advanced", title: "Security Research Device", detail: "Change the SRD capability flag. This does not turn the device into an Apple SRD.", keys: ["XYlJKKkj2hztRP1NWWnhlw"], value: 1, caution: true),
        .init(id: "internalSettings", category: "advanced", title: "Internal Settings Bundle", detail: "Expose Apple's internal settings bundle. Some system services may behave differently.", keys: ["Oji6HRoPi7rH7HPdWVakuw"], value: 1, caution: true),
    ]
}
