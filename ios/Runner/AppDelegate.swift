import UIKit
import Flutter
import GoogleMaps // 👈 1. เพิ่มบรรทัดนี้

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // 🔴 2. เพิ่มตรงนี้! ใส่ API Key ของคุณในเครื่องหมายคำพูด
    GMSServices.provideAPIKey("AIzaSyC2ZsplIdFTiU5yK9oyq5N1Nu-s72_tWM4") 
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}