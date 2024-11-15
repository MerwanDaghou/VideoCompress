import Flutter
import AVFoundation

public class CompressManagerPlugin: NSObject, FlutterPlugin {
    //private let channel: FlutterMethodChannel
    var assetReader: AVAssetReader?
    var assetWriter: AVAssetWriter?

//    init(channel: FlutterMethodChannel) {
//        self.channel = channel
//    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "CompressVideo", binaryMessenger: registrar.messenger())
        let instance = CompressManagerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
            if(call.method.elementsEqual("compressVideoIOS")) {
                let args = call.arguments as! Dictionary<String, Any>

                let inputPath = args["inputFile"] as! String
                let outputPath = args["outputFile"] as! String
                let inputURL = URL(fileURLWithPath: inputPath)
                let outputURL = URL(fileURLWithPath: outputPath)

                let width = args["width"] as! Double
                let height = args["height"] as! Double
                let size = CGSize(width: width, height: height)

                let frameRate = args["frameRate"] as! Int32
                let bitrate = args["bitrate"] as! Int?


                do {
                    try startCompression(inputURL: inputURL,outputURL: outputURL, videoSize: size, frameRate: frameRate, bitrate: bitrate) { (compressedURL, error) in if let compressedURL = compressedURL {
                        print("Compressed video saved to: \(compressedURL)")
                        result(compressedURL.path)
                    } else if let error = error {
                        print("Compression failed with error: \(error.localizedDescription)")
                        result(nil)
                    }
                    else {
                        result(nil)
                    }

                    }
                }
                catch {
                    result(nil)
                }
            }
    }


    // ------------------------------------------------------------------
    // AVAssetWriter re-encoding
    // ------------------------------------------------------------------

    func startCompression(inputURL: URL,outputURL: URL, videoSize: CGSize, frameRate: Int32, bitrate: Int?,completion: @escaping (URL?, Error?) -> Void) throws {

        //video file to make the asset

        var audioFinished = false
        var videoFinished = false

        let asset = AVAsset(url: inputURL);

        //create asset reader
        do{
            assetReader = try AVAssetReader(asset: asset)
        } catch{
            assetReader = nil
        }

        if(assetReader == nil) {
            completion(nil,nil)
            fatalError("asset reader is nil")
            return;
        }

        let videoTrack = asset.tracks(withMediaType: AVMediaType.video).first!
        let audioTrack = asset.tracks(withMediaType: AVMediaType.audio).first!

        let videoFormatDescription = videoTrack.formatDescriptions.first as! CMFormatDescription
        let audioFormatDescription = audioTrack.formatDescriptions.first as! CMFormatDescription


                // HANDLE ROTATIONS
        let txf = videoTrack.preferredTransform
        let bit = videoTrack.estimatedDataRate
        print("initial bitrate ",bit)
        print("optmized bitrate ",bit/2)

        print("video transform : ",txf)
        // Get the natural size of the video track
        let size = videoTrack.naturalSize

        print("natural size width ",size.width)
        print("natural size height ",size.height)
        var preferredTransform = videoTrack.preferredTransform
        var videoRotateSize = videoSize
        var rotation = preferredTransform

        // Check the transform's rotation type
        if preferredTransform.a == 0 && preferredTransform.d == 0 {
            // 90 or -90 degree rotation (portrait/landscape switch)
            // Swap the width and height for these cases.
            videoRotateSize = CGSize(width: videoSize.height, height: videoSize.width)
        } else if preferredTransform.a == 1 && preferredTransform.d == 1 {
            // No rotation (no transform applied)
            rotation = CGAffineTransform.identity
        } else {
            // Other transforms (like 180-degree rotations, flips, etc.)
            // Keep the natural size as is.
            // You could handle additional flips, but for the most common cases, this suffices.
            rotation = preferredTransform
        }

        // The compressed general value
        var finalBitRate = 2500000

        if(bitrate != nil) {
            finalBitRate = bitrate!
        }
        // If the origin is lower than the final bitrate this is because original video is already very
        // compressed
        // So we / 2 the original video bitrate
        if(finalBitRate > Int(bit/2)) {
            finalBitRate = Int(bit/2)
        }

        print("final bite rate : ",finalBitRate)

        // Define custom compression settings.
        let compressionSettings: [String: Any] = [
            AVVideoAverageBitRateKey: finalBitRate,              // Target bitrate (e.g., 500_000 for 500 kbps or 1_000_000 for 1000 kbps).
            AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel, // H.264 Profile Level.
            AVVideoMaxKeyFrameIntervalKey: frameRate,              // Maximum key frame interval (1 key frame every 30 frames).
            AVVideoAllowFrameReorderingKey: true,           // Allow frame reordering for better compression.
            AVVideoH264EntropyModeKey: AVVideoH264EntropyModeCABAC // Better compression than CAVLC.
        ]

        // Define video output settings.
        let videoOutputSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: videoRotateSize.width,
            AVVideoHeightKey: videoRotateSize.height,
            AVVideoCompressionPropertiesKey: compressionSettings
        ]

        let audioOutputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVEncoderBitRateKey: 128_000,                    // Target bitrate (e.g., 64 kbps for speech).
            AVNumberOfChannelsKey: 2,                       // Stereo audio.
            AVSampleRateKey: 44_100, // Standard audio sample rate.
            AVEncoderAudioQualityKey: AVAudioQuality.medium,
        ]

        let videoReaderSettings: [String:Any] =  [(kCVPixelBufferPixelFormatTypeKey as String?)!:kCVPixelFormatType_32ARGB ]

//                    let audioReaderSettings: [String: Any] = [
//                        AVFormatIDKey: kAudioFormatLinearPCM,
//                        AVSampleRateKey: 44100,
//                        AVNumberOfChannelsKey: 2,
//                        AVLinearPCMBitDepthKey: 16,
//                        AVLinearPCMIsFloatKey: false,
//                        AVLinearPCMIsBigEndianKey: false,
//                    ]

        let assetReaderVideoOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: videoReaderSettings)
        let assetReaderAudioOutput = AVAssetReaderTrackOutput(track: audioTrack,outputSettings: nil)


        if assetReader!.canAdd(assetReaderVideoOutput){
            assetReader!.add(assetReaderVideoOutput)
        }else{
            completion(nil,nil)
            fatalError("Couldn't add video output reader")
        }

        if assetReader!.canAdd(assetReaderAudioOutput){
            assetReader!.add(assetReaderAudioOutput)
        }else{
            completion(nil,nil)
            fatalError("Couldn't add audio output reader")
        }

        let audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: nil,sourceFormatHint: audioFormatDescription)
                    audioInput.expectsMediaDataInRealTime = true


        let videoInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoOutputSettings,sourceFormatHint: videoFormatDescription)

        videoInput.transform = rotation
        //we need to add samples to the video input

        videoInput.expectsMediaDataInRealTime = true  // Needed for real-time encoding.


        let videoInputQueue = DispatchQueue(label: "videoQueue")
        let audioInputQueue = DispatchQueue(label: "audioQueue")

        do{
            self.assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: AVFileType.mp4)
        }catch{
            self.assetWriter = nil
        }
        if(assetWriter == nil) {
            completion(nil,nil)
            fatalError("Asset writer is nil")
            return
        }

        assetWriter!.shouldOptimizeForNetworkUse = true
        assetWriter!.add(videoInput)
        assetWriter!.add(audioInput)

        assetWriter!.startWriting()
        assetReader!.startReading()

        assetWriter!.startSession(atSourceTime: CMTime.zero)


        let closeWriter:()->Void = {
            if (videoFinished && audioFinished){
                self.assetWriter?.finishWriting(completionHandler: {
                    completion((self.assetWriter?.outputURL)!,nil)
                })
                self.assetReader?.cancelReading()
            }
        }

        audioInput.requestMediaDataWhenReady(on: audioInputQueue) {
            while(audioInput.isReadyForMoreMediaData){
                let sample = assetReaderAudioOutput.copyNextSampleBuffer()
                if (sample != nil){
                    audioInput.append(sample!)
                }else{
                    audioInput.markAsFinished()
                    DispatchQueue.main.async {
                        audioFinished = true
                        closeWriter()
                    }
                    break;
                }
            }
        }

        videoInput.requestMediaDataWhenReady(on: videoInputQueue) {
            //request data here
            while(videoInput.isReadyForMoreMediaData){
                let sample = assetReaderVideoOutput.copyNextSampleBuffer()
                if (sample != nil){
                    videoInput.append(sample!)
                }else{
                    videoInput.markAsFinished()
                    DispatchQueue.main.async {
                        videoFinished = true
                        closeWriter()
                    }
                    break;
                }
            }
        }

    }

}