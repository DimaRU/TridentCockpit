//
//  MP4SamplerProtocol.swift
//
//  Created by Dmitriy Borovikov on 21.06.2020.
//  Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//

import AVFoundation

protocol MP4SamplerDelegate: class {
    func didOpen(_ reader: MP4Reader)
    func didSet(config: Data, withID: Int, type: AVMediaType)
    func output(data: Data, withID: Int, currentTime: Double, keyframe: Bool)
}

protocol MP4SamplerProtocol: Running {
    var delegate: MP4SamplerDelegate? { get set }
}
